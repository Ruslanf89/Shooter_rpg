"""Northvale brain server: AI personalities for the first location's NPCs, villagers and mobs.

Runs on http://127.0.0.1:8765 (started automatically by the game). Uses Ollama + Qwen3 for words,
SQLite for memory (memory.py), Piper / Windows voices for speech (voice.py).

  GET  /health                    -> is everything ready
  POST /config {lang, model}      -> language of the lines (uk / en) and the Qwen3 model
  POST /reset                     -> a new game: forget the player
  POST /talk {...}                -> one dialogue turn: NPC line + 3 replies for the player
  POST /bark {kind, event}        -> a short voiced shout (from a ready pool, instant)
  POST /chat {a, b}               -> an overheard conversation between two villagers
  POST /event {kind, text, ...}   -> something happened in the valley
"""

import json
import os
import queue
import random
import re
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

import llm                     # noqa: E402
from memory import Memory      # noqa: E402
from voice import Voice        # noqa: E402

PORT = 8765
with open(os.path.join(HERE, "personas.json"), encoding="utf-8") as f:
    P = json.load(f)

CONFIG = {"lang": "uk", "model": os.environ.get("NORTHVALE_MODEL", "qwen3:8b"), "gpu_layers": 26, "mode": "menu"}
CONFIG_FILE = os.path.join(HERE, "config.json")
if os.path.exists(CONFIG_FILE):
    with open(CONFIG_FILE, encoding="utf-8") as f:
        CONFIG.update(json.load(f))

mem = Memory(os.path.join(HERE, "northvale.db"))
voice = Voice(ROOT, os.path.join(HERE, "cache", "voice"))
work = queue.Queue()            # background jobs: bark pools to fill, memories to summarize
queued = set()
STATE = {"model_loaded": False, "started": time.time()}
INTERACTIVE = [0]               # conversations in progress: background jobs wait for them
INTERACTIVE_LOCK = threading.Lock()


class Priority:
    """While a conversation is being answered, background jobs (shout pools) pause."""
    def __enter__(self):
        with INTERACTIVE_LOCK:
            INTERACTIVE[0] += 1

    def __exit__(self, *a):
        with INTERACTIVE_LOCK:
            INTERACTIVE[0] -= 1


def clean_choice(c):
    c = re.sub(r"\s*[\(\[][^)\]]*[\)\]]\s*$", "", str(c)).strip()
    c = re.sub(r"^\s*(\d+[\.\)]|[-*])\s*", "", c)
    c = c.strip(" \"\u201c\u201d\u00ab\u00bb")
    # junk the model sometimes leaks into choices: "net: +1", "attitude 2", single words
    if len(c) < 4 or re.search(r"[:=]\s*[+-]?\d+\s*$", c) or not re.search(r"[A-Za-z\u0400-\u04ff]{3}", c):
        return ""
    return c

MOB_KINDS = ["bandit", "captain", "kobold", "geomancer", "cultist"]
MOB_EVENTS = ["aggro", "hurt", "flee", "ally_down", "taunt", "kill_player"]
VIL_EVENTS = ["greet_day", "greet_night", "react_boss", "react_crime", "react_raid", "react_quest"]


# --------------------------------------------------------------------------- helpers

def lang_rule():
    if CONFIG["lang"] == "uk":
        return ("Пиши ЛИШЕ українською мовою, природно і живо, без русизмів. "
                "Write every line and every choice in Ukrainian only.")
    return "Write in natural, simple English."


def voice_key(spec):
    keys = spec.get("voice") if isinstance(spec, dict) else None
    if keys:
        return keys["uk" if CONFIG["lang"] == "uk" else "en"]
    return ""


def villager_voice(gender):
    base = {"m": "vil_m", "f": "vil_f", "kid": "kid"}.get(gender, "vil_m")
    return base + "_uk" if CONFIG["lang"] == "uk" else base


def audio_out(path):
    return path.replace("\\", "/") if path else ""


def ctx_text(ctx):
    bits = []
    if ctx.get("time"):
        bits.append(f"time: {ctx['time']}")
    if ctx.get("weather"):
        bits.append(f"weather: {ctx['weather']}")
    if ctx.get("place"):
        bits.append(f"place: {ctx['place']}")
    if ctx.get("player_level"):
        bits.append(f"the player is level {ctx['player_level']}")
    return ", ".join(bits)


def relation_text(r):
    def word(v, neg, pos):
        return pos if v > 25 else (neg if v < -25 else "neutral")
    return (f"trust {r['trust']} ({word(r['trust'], 'distrustful', 'trusting')}), fear {r['fear']}, "
            f"affection {r['affection']} ({word(r['affection'], 'dislikes him', 'likes him')})")


def merge_rel(a, b):
    return {k: max(-100, min(100, a[k] + b[k])) for k in a}


# --------------------------------------------------------------------------- dialogue

TALK_SCHEMA = {
    "type": "object",
    "properties": {
        "line": {"type": "string"},
        "choices": {"type": "array", "items": {"type": "string"}, "minItems": 3, "maxItems": 3},
        "attitude": {"type": "integer", "minimum": -3, "maximum": 3},
    },
    "required": ["line", "choices", "attitude"],
}


def describe_speaker(req):
    """(memory id, name, role, persona, style, voice key) for a quest NPC or a villager."""
    npc = req.get("npc", "")
    if npc in P["npcs"]:
        n = P["npcs"][npc]
        name = n["name_uk"] if CONFIG["lang"] == "uk" else n["name"]
        return npc, name, n["role"], n["persona"], n["style"], voice_key(n)
    pers = req.get("personality", "kind")
    gender = req.get("gender", "m")
    persona = P["kid"] if gender == "kid" else P["villagers"].get(pers, P["villagers"]["kind"])
    role = ("a child of Ashford" if gender == "kid" else f"{req.get('job', 'villager')} of Ashford") + \
        (f", {req.get('age', '')}" if req.get("age") else "")
    return "vil:" + npc, req.get("name", "Villager"), role, persona, "Simple village speech, short.", villager_voice(gender)


PREFETCH = {}                 # memory id -> (time, quest state, ready answer): opening lines written ahead
PREPARING = {}                # memory id -> Event, while its greeting is being written


def talk(req):
    """One dialogue turn. With "prefetch": true the opening line is written ahead (while the player
    walks up) and kept for two minutes; the real request then gets it instantly."""
    mid = describe_speaker(req)[0]
    said = req.get("choice") or ""
    qstate = (req.get("quest") or {}).get("state", "")
    if not said and not req.get("prefetch"):
        busy = PREPARING.get(mid)
        if busy:
            busy.wait(90)          # the greeting is being written right now: wait for it, don't start over
        hit = PREFETCH.pop(mid, None)
        if hit and time.time() - hit[0] < 120 and hit[1] == qstate:
            return _remember(mid, "", hit[2])
    if req.get("prefetch"):
        if mid in PREPARING or (mid in PREFETCH and time.time() - PREFETCH[mid][0] < 120 and PREFETCH[mid][1] == qstate):
            return {"ok": True}
        done = threading.Event()
        PREPARING[mid] = done
        try:
            PREFETCH[mid] = (time.time(), qstate, _compose(req, background=True))
        finally:
            PREPARING.pop(mid, None)
            done.set()
        return {"ok": True}
    return _remember(mid, said, _compose(req))


def _remember(mid, said, out):
    """Stores the turn in memory (only when the player actually hears it)."""
    if said:
        mem.add_talk(mid, "player", said)
    mem.add_talk(mid, "npc", out["line"])
    att = out.pop("attitude", 0)
    mem.change_relation(mid, affection=att, trust=1 if att > 0 else (-1 if att < 0 else 0))
    if mem.unsummarized(mid):
        enqueue(("summary", mid, out.pop("_name", mid)))
    out.pop("_name", None)
    return out


def _compose(req, background=False):
    mid, name, role, persona, style, vkey = describe_speaker(req)
    rel = mem.relation(mid)
    if mid.startswith("vil:"):
        rel = merge_rel(rel, mem.relation("village"))
    short = "1 to 8 words, sometimes just a yawn and one word" if req.get("npc") == "vesper" else "at most 3 short sentences (under 45 words)"
    # kept short on purpose: every token here costs time while the game is running
    memory = mem.summary(mid)
    news = "; ".join(mem.gossip(2))
    system = (
        f"You are {name}, {role}. {P['world_short']}\n"
        f"Character: {persona}\nSpeech: {style}\n{lang_rule()}\n"
        f"Stay in character, never mention AI or games. Your line: {short}.\n"
        f"Feelings to the player: {relation_text(rel)}."
        + (f"\nYou remember: {memory}" if memory else "")
        + (f"\nNews: {news}" if news else "")
        + f"\nNow: {ctx_text(req.get('ctx', {}))}."
    )
    history = "\n".join(f"{'Player' if w == 'player' else name}: {t}" for w, t in mem.recent_talk(mid, 6))
    q = req.get("quest") or {}
    task = ""
    if q.get("state") == "offer":
        task = f"Ask the player for help in your own words, keeping every fact exactly: \"{q.get('text', '')}\""
    elif q.get("state") == "done":
        task = f"He has just done your task '{q.get('title', '')}'. Thank him your way. Meaning: \"{q.get('text', '')}\""
    elif q.get("state") == "active":
        task = f"He is still doing your task '{q.get('title', '')}'. You may remind him briefly."
    said = req.get("choice") or ""
    user = ((f"Talk so far:\n{history}\n" if history else "") +
            (f"Task: {task}\n" if task else "") +
            (f"Player: \"{said}\"" if said else "The player comes up to talk.") +
            "\nGive 'line' (your reply), 'choices' (3 short replies for the player, a decent tired soldier: "
            "friendly, a question, blunt or joking; under 10 words, no labels) and 'attitude' (-3..3).")
    # prepared greetings also go before background jobs: the player is about to hear them
    with Priority():
        out = llm.chat_json(CONFIG["model"], system, user, TALK_SCHEMA, temperature=0.7)
    line = str(out.get("line", "")).strip() or "..."
    choices = [clean_choice(c) for c in out.get("choices", []) if clean_choice(c)][:3]
    att = max(-3, min(3, int(out.get("attitude", 0) or 0)))
    return {"line": line, "choices": choices, "audio": audio_out(voice.say(vkey, line)), "voice": vkey,
            "attitude": att, "_name": name}


def summarize(mid, name):
    rows = mem.unsummarized(mid)
    if not rows:
        return
    old = mem.summary(mid)
    convo = "\n".join(f"{'Player' if w == 'player' else name}: {t}" for _, w, t in rows)
    out = llm.chat_json(CONFIG["model"], "You keep the memory of a character in a game.",
                        f"Previous memory of {name} about the player: {old or '(none)'}\nNew conversation:\n{convo}\n\n"
                        f"Write the updated memory in English, from {name}'s point of view, at most 4 sentences: "
                        f"what the player said, did, promised, and how {name} feels about him.",
                        {"type": "object", "properties": {"memory": {"type": "string"}}, "required": ["memory"]},
                        temperature=0.3, max_tokens=250)
    mem.set_summary(mid, str(out.get("memory", old)), rows[-1][0])


# --------------------------------------------------------------------------- shouts (barks)

LINES_SCHEMA = {"type": "object", "properties": {"lines": {"type": "array", "items": {"type": "string"}, "minItems": 4, "maxItems": 8}},
                "required": ["lines"]}
MOOD_TEXT = {"neutral": "confident, it doesn't know him yet",
             "angry": "furious: the player has killed several of its kind",
             "afraid": "scared: the player has killed many of its kind and is feared by them all"}


def pool_key(kind, event, mood):
    return f"{CONFIG['lang']}|{kind}|{event}|{mood}"


def fill_pool(kind, event, mood):
    key = pool_key(kind, event, mood)
    ev = P["events"].get(event, event)
    if kind.startswith("vil:"):
        _, pers, gender = (kind.split(":") + ["kind", "m"])[:3]
        who = "a village child" if gender == "kid" else f"a {pers} villager of Ashford"
        persona = P["kid"] if gender == "kid" else P["villagers"].get(pers, "")
        vkey = villager_voice(gender)
        mood_line = f"The village's feelings about the player: {relation_text(mem.relation('village'))}."
    else:
        m = P["mobs"][kind]
        who, persona, vkey = m["name"], m["persona"], voice_key(m)
        mood_line = f"Its mood towards the player: {MOOD_TEXT[mood]}."
    system = f"You write short spoken lines for characters in a medieval fantasy game. Setting: {P['world']}\n{lang_rule()}"
    user = (f"Character: {who}. {persona}\n{mood_line}\n"
            f"Write 6 different short lines (2 to 10 words each) this character says when it {ev}. "
            "Make them vivid and varied, in character, no stage directions. Return JSON {\"lines\": [...]}")
    out = llm.chat_json(CONFIG["model"], system, user, LINES_SCHEMA, temperature=1.0, max_tokens=300)
    for text in out.get("lines", [])[:8]:
        text = str(text).strip().strip('"')
        if text:
            mem.add_bark(key, text, audio_out(voice.say(vkey, text)))
    mem.prune_pool(key)


def bark(req):
    kind = req.get("kind", "bandit")
    event = req.get("event", "aggro")
    mood = "neutral" if kind.startswith("vil:") else mem.mood(kind)
    key = pool_key(kind, event, mood)
    b = mem.take_bark(key)
    if mem.fresh_count(key) < 4:
        enqueue(("pool", kind, event, mood))
    if b is None and mood != "neutral":
        b = mem.take_bark(pool_key(kind, event, "neutral"))
    return b or {"text": "", "audio": ""}


# --------------------------------------------------------------------------- overheard conversations

CHAT_SCHEMA = {"type": "object", "properties": {"lines": {"type": "array", "minItems": 2, "maxItems": 4, "items": {
    "type": "object", "properties": {"who": {"type": "string", "enum": ["A", "B"]}, "text": {"type": "string"}},
    "required": ["who", "text"]}}}, "required": ["lines"]}


def chat(req):
    a, b = req.get("a", {}), req.get("b", {})

    def desc(v):
        if v.get("gender") == "kid":
            return f"{v.get('name', 'a child')}, a village child ({P['kid']})"
        return f"{v.get('name', 'a villager')}, {v.get('job', 'villager')} ({P['villagers'].get(v.get('personality', 'kind'), '')})"
    system = f"You write overheard conversations between villagers in a medieval fantasy game. Setting: {P['world']}\n{lang_rule()}"
    user = (f"A: {desc(a)}\nB: {desc(b)}\nThey talk on the village square ({ctx_text(req.get('ctx', {}))}). "
            f"Latest news in the valley: " + ("; ".join(mem.gossip(4)) or "nothing special") + ". "
            f"What the village thinks of the player (the strange soldier): {relation_text(mem.relation('village'))}.\n"
            "Write a short natural exchange of 2 to 4 lines, alternating A and B, each line at most 14 words: everyday worries, "
            "or gossip about the news or the player. No narration.")
    with Priority():
        out = llm.chat_json(CONFIG["model"], system, user, CHAT_SCHEMA, temperature=0.85, max_tokens=300)
    lines = []
    for l in out.get("lines", [])[:4]:
        who = "a" if l.get("who") == "A" else "b"
        spk = a if who == "a" else b
        # the model sometimes writes the speaker into the line ("Олег каже: ...", "A: ...")
        text = re.sub(r"^[^:\n]{2,30}\s(каже|відповідає|питає|says|replies|asks|answers)\s*:\s*", "", str(l.get("text", "")).strip())
        text = re.sub(r"^(A|B|[A-ZА-ЯІЇЄҐ][\w'’-]{1,15})\s*:\s*", "", text).strip()
        if text:
            lines.append({"who": who, "text": text, "audio": audio_out(voice.say(villager_voice(spk.get("gender", "m")), text))})
    return {"lines": lines}


# --------------------------------------------------------------------------- world events

def event(req):
    kind = req.get("kind", "")
    text = req.get("text", "")
    imp = int(req.get("importance", 1))
    mob = req.get("mob", "")
    if kind == "kill" and mob:
        mem.faction_add(mob, kills=1)
        if mob in ("bandit", "captain", "cultist", "kobold", "geomancer"):
            mem.change_relation("village", trust=1)
        if mob in ("bandit", "captain"):
            mem.change_relation("brannock", affection=1)
        return {"ok": True}
    if kind == "flee" and mob:
        mem.faction_add(mob, fled=1)
        return {"ok": True}
    if kind == "quest_done":
        npc = req.get("npc", "")
        mem.change_relation(npc, trust=10, affection=6)
        mem.change_relation("village", trust=4)
    elif kind == "boss":
        mem.change_relation("village", trust=8, affection=4)
        for n in P["npcs"]:
            mem.change_relation(n, trust=5)
    elif kind == "crime":
        mem.change_relation("village", trust=-15, fear=15, affection=-10)
        for n in P["npcs"]:
            mem.change_relation(n, trust=-10, fear=5)
    if text:
        mem.add_event(kind, text, req.get("place", ""), imp)
    return {"ok": True}


# --------------------------------------------------------------------------- background work

def enqueue(job):
    if job not in queued:
        queued.add(job)
        work.put(job)


def worker():
    while True:
        job = work.get()
        while INTERACTIVE[0] > 0:
            time.sleep(0.2)
        # while the game is being played, background writing must not steal the GPU from it
        if CONFIG.get("mode") == "play" and job[0] != "warm":
            time.sleep(12.0)
            while INTERACTIVE[0] > 0:
                time.sleep(0.2)
        try:
            if job[0] == "pool":
                fill_pool(*job[1:])
            elif job[0] == "summary":
                summarize(*job[1:])
            elif job[0] == "warm":
                STATE["model_loaded"] = llm.warm(CONFIG["model"])
        except Exception as e:
            print("job failed:", job, e, flush=True)
        finally:
            queued.discard(job)


def warm_pools():
    """Fills the shout pools the first location needs (only the empty ones; they persist)."""
    enqueue(("warm",))
    for kind in MOB_KINDS:
        for ev in MOB_EVENTS:
            if mem.pool_size(pool_key(kind, ev, "neutral")) < 4:
                enqueue(("pool", kind, ev, "neutral"))
    if mem.pool_size(pool_key("captain", "boss_intro", "neutral")) < 4:
        enqueue(("pool", "captain", "boss_intro", "neutral"))
    for pers in list(P["villagers"]) + ["kid"]:
        for g in (["kid"] if pers == "kid" else ["m", "f"]):
            for ev in VIL_EVENTS:
                k = f"vil:{pers}:{g}"
                if mem.pool_size(pool_key(k, ev, "neutral")) < 4:
                    enqueue(("pool", k, ev, "neutral"))


# --------------------------------------------------------------------------- HTTP

ROUTES = {"/talk": talk, "/bark": bark, "/chat": chat, "/event": event}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def _send(self, code, obj):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            models = llm.alive()
            self._send(200, {"ok": True, "ollama": models is not None, "model": CONFIG["model"],
                             "model_installed": bool(models) and any(m.startswith(CONFIG["model"]) for m in models),
                             "model_loaded": STATE["model_loaded"], "voice": voice.available(),
                             "jobs": work.qsize(), "lang": CONFIG["lang"]})
        else:
            self._send(404, {"error": "unknown"})

    def do_POST(self):
        try:
            n = int(self.headers.get("Content-Length", 0))
            req = json.loads(self.rfile.read(n).decode("utf-8")) if n else {}
            if self.path == "/config":
                changed = req.get("lang", CONFIG["lang"]) != CONFIG["lang"] or req.get("model", CONFIG["model"]) != CONFIG["model"]
                CONFIG.update({k: v for k, v in req.items() if k in ("lang", "model", "gpu_layers", "mode")})
                llm.GPU_LAYERS[0] = int(CONFIG.get("gpu_layers", 26))
                with open(CONFIG_FILE, "w", encoding="utf-8") as f:
                    json.dump(CONFIG, f)
                if changed:
                    STATE["model_loaded"] = False
                warm_pools()
                self._send(200, {"ok": True, **CONFIG})
            elif self.path == "/reset":
                mem.reset_world()
                self._send(200, {"ok": True})
            elif self.path in ROUTES:
                self._send(200, ROUTES[self.path](req))
            else:
                self._send(404, {"error": "unknown"})
        except Exception as e:
            print("request failed:", self.path, repr(e), flush=True)
            self._send(500, {"error": str(e)})


def main():
    llm.GPU_LAYERS[0] = int(CONFIG.get("gpu_layers", 26))
    CONFIG["mode"] = "menu"
    threading.Thread(target=worker, daemon=True).start()
    warm_pools()
    srv = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Northvale brain on http://127.0.0.1:{PORT} model={CONFIG['model']} lang={CONFIG['lang']}", flush=True)
    try:
        srv.serve_forever()
    finally:
        voice.close()


if __name__ == "__main__":
    main()
