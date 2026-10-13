"""Northvale brain server: AI personalities for the first location's NPCs, villagers and mobs.

Runs on http://127.0.0.1:8765 (started automatically by the game). Uses Ollama + Qwen3 for words,
SQLite for memory (memory.py), Piper / Windows voices for speech (voice.py).

  GET  /health                     -> is everything ready
  POST /config {lang, model, ...}  -> language of the lines (uk / en), model, play/menu mode
  POST /reset                      -> a new game: forget the player
  POST /talk {...}                 -> one dialogue turn (whole answer); with "prefetch": write a greeting ahead
  POST /talk_stream {...}          -> the same, streamed as lines of JSON: the words while they're
                                      written, a WAV per finished sentence, then the reply choices
  POST /bark {kind, event}         -> a short voiced shout (from a ready pool, instant)
  POST /chat {a, b}                -> an overheard conversation between two villagers
  POST /event {kind, text, ...}    -> something happened in the valley
"""

import hashlib
import json
import os
import queue
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
VP = P["voice_profiles"]

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
GREETING_TTL = 1200             # prepared greetings stay good for 20 minutes

MOB_KINDS = ["bandit", "captain", "kobold", "geomancer", "cultist"]
MOB_EVENTS = ["aggro", "hurt", "flee", "ally_down", "taunt", "kill_player"]
VIL_EVENTS = ["greet_day", "greet_night", "react_boss", "react_crime", "react_raid", "react_quest"]


class Priority:
    """While a conversation is being answered, background jobs (shout pools) pause."""
    def __enter__(self):
        with INTERACTIVE_LOCK:
            INTERACTIVE[0] += 1

    def __exit__(self, *a):
        with INTERACTIVE_LOCK:
            INTERACTIVE[0] -= 1


# One model, one answer at a time. A live conversation (the player is waiting) goes first; any
# background answer (greetings written ahead, shout pools, memory) stops halfway and is retried later.
LANE = threading.Condition()
LANE_STATE = {"busy": False, "live": 0}


class Lane:
    def __init__(self, live):
        self.live = live

    def __enter__(self):
        with LANE:
            if self.live:
                LANE_STATE["live"] += 1
            while LANE_STATE["busy"] or (not self.live and LANE_STATE["live"] > 0):
                LANE.wait(0.5)
            LANE_STATE["busy"] = True

    def __exit__(self, *a):
        with LANE:
            LANE_STATE["busy"] = False
            if self.live:
                LANE_STATE["live"] -= 1
            LANE.notify_all()


def live_waiting():
    return LANE_STATE["live"] > 0


def background_llm(*args, job=None, **kw):
    """A model call that gives way to live conversations. `job` (optional dict) can be aborted
    before it starts ("abort") and tells whether it is being written right now ("started")."""
    while True:
        with Lane(False):
            if job is not None:
                if job.get("abort"):
                    return None
                job["started"] = True
            try:
                return llm.chat_json(*args, cancel=live_waiting, **kw)
            except llm.Cancelled:
                if job is not None:
                    job["started"] = False
        time.sleep(0.3)


def save_config():
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(CONFIG, f)


# --------------------------------------------------------------------------- helpers

def lang_rule():
    if CONFIG["lang"] == "uk":
        return ("Пиши ЛИШЕ українською мовою, природно і живо, без русизмів. "
                "Write every line and every choice in Ukrainian only.")
    return "Write in natural, simple English."


def profile_for(key, pick=""):
    """A voice profile; for villagers and kids one of several, chosen steadily by `pick` (their id)."""
    v = VP.get(key)
    if isinstance(v, list):
        return v[int(hashlib.md5(pick.encode("utf-8")).hexdigest(), 16) % len(v)] if pick else v[0]
    return v or VP["vil_m"][0]


def villager_profile(gender, pick):
    return profile_for({"m": "vil_m", "f": "vil_f", "kid": "kid"}.get(gender, "vil_m"), pick)


def speak(profile, text):
    path = voice.say(profile, text, CONFIG["lang"])
    return path.replace("\\", "/") if path else ""


def fx_of(profile):
    """How the game should play this voice: effect bus and pitch."""
    return {"fx": profile.get("fx", "plain"), "pitch": float(profile.get("pitch", 1.0))}


def clean_choice(c):
    c = re.sub(r"\s*[\(\[][^)\]]*[\)\]]\s*$", "", str(c)).strip()
    c = re.sub(r"^\s*(\d+[\.\)]|[-*])\s*", "", c)
    c = c.strip(" \"“”«»")
    # junk the model sometimes leaks into choices: "net: +1", "attitude 2", single words
    if len(c) < 4 or re.search(r"[:=]\s*[+-]?\d+\s*$", c) or not re.search(r"[A-Za-zЀ-ӿ]{3}", c):
        return ""
    return c


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


def partial_field(buf, field="line"):
    """The text of a JSON string field while the JSON is still being written: (text, finished)."""
    m = re.search(r'"' + field + r'"\s*:\s*"', buf)
    if not m:
        return None, False
    i, out = m.end(), []
    while i < len(buf):
        ch = buf[i]
        if ch == "\\":
            if i + 1 >= len(buf):
                break
            nxt = buf[i + 1]
            if nxt == "u":
                if i + 6 > len(buf):
                    break
                try:
                    out.append(chr(int(buf[i + 2:i + 6], 16)))
                except ValueError:
                    pass
                i += 6
                continue
            out.append({"n": " ", "t": " ", '"': '"', "\\": "\\", "/": "/"}.get(nxt, nxt))
            i += 2
            continue
        if ch == '"':
            return "".join(out), True
        out.append(ch)
        i += 1
    return "".join(out), False


def parse_json(text):
    try:
        return json.loads(text)
    except Exception:
        m = re.search(r"\{.*\}", text, flags=re.S)
        try:
            return json.loads(m.group(0)) if m else {}
        except Exception:
            return {}


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
    """(memory id, name, role, persona, style, voice profile) for a quest NPC or a villager."""
    npc = req.get("npc", "")
    if npc in P["npcs"]:
        n = P["npcs"][npc]
        name = n["name_uk"] if CONFIG["lang"] == "uk" else n["name"]
        return npc, name, n["role"], n["persona"], n["style"], profile_for(npc)
    pers = req.get("personality", "kind")
    gender = req.get("gender", "m")
    persona = P["kid"] if gender == "kid" else P["villagers"].get(pers, P["villagers"]["kind"])
    role = ("a child of Ashford" if gender == "kid" else f"{req.get('job', 'villager')} of Ashford") + \
        (f", {req.get('age', '')}" if req.get("age") else "")
    return ("vil:" + npc, req.get("name", "Villager"), role, persona, "Simple village speech, short.",
            villager_profile(gender, npc))


def build_prompt(req):
    mid, name, role, persona, style, prof = describe_speaker(req)
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
    said = req.get("choice") or ""
    if q.get("state") == "offer" and said:
        task = (f"You asked him for help with: \"{q.get('text', '')}\". Answer what he just said, "
                "add a new detail; do not repeat your earlier words.")
    elif q.get("state") == "offer":
        task = f"Ask the player for help in your own words, keeping every fact exactly: \"{q.get('text', '')}\""
    elif q.get("state") == "done":
        task = f"He has just done your task '{q.get('title', '')}'. Thank him your way. Meaning: \"{q.get('text', '')}\""
    elif q.get("state") == "active":
        task = f"He is still doing your task '{q.get('title', '')}'. You may remind him briefly."
    user = ((f"Talk so far:\n{history}\n" if history else "") +
            (f"Task: {task}\n" if task else "") +
            (f"Player: \"{said}\"" if said else "The player comes up to talk.") +
            "\nGive 'line' (your reply), 'choices' (3 short replies for the player, a decent tired soldier: "
            "friendly, a question, blunt or joking; under 10 words, no labels) and 'attitude' (-3..3).")
    return mid, name, prof, system, user


def finish_turn(out, name):
    line = str(out.get("line", "")).strip() or "..."
    choices = [clean_choice(c) for c in out.get("choices", []) if clean_choice(c)][:3]
    try:
        att = max(-3, min(3, int(out.get("attitude", 0) or 0)))
    except (TypeError, ValueError):
        att = 0
    return {"line": line, "choices": choices, "attitude": att, "_name": name}


def compose(req, job=None):
    """A whole answer at once. With `job` it's a greeting written ahead, which gives way to live talks."""
    mid, name, prof, system, user = build_prompt(req)
    with Priority():
        if job is None:
            with Lane(True):
                out = llm.chat_json(CONFIG["model"], system, user, TALK_SCHEMA, temperature=0.7)
        else:
            out = background_llm(CONFIG["model"], system, user, TALK_SCHEMA, temperature=0.7, job=job)
    if out is None:
        return None
    res = finish_turn(out, name)
    res["audio"] = speak(prof, res["line"])
    res.update(fx_of(prof))
    return res


PREFETCH = {}                 # memory id -> (time, quest state, ready answer): opening lines written ahead
PREPARING = {}                # memory id -> job {done: Event, started, abort} while its greeting is on the way


def remember(mid, said, out):
    """Stores the turn in memory (only when the player actually hears it)."""
    if said:
        mem.add_talk(mid, "player", said)
    mem.add_talk(mid, "npc", out["line"])
    att = out.pop("attitude", 0)
    mem.change_relation(mid, affection=att, trust=1 if att > 0 else (-1 if att < 0 else 0))
    name = out.pop("_name", mid)
    if mem.unsummarized(mid):
        enqueue(("summary", mid, name))
    return out


def take_prepared(mid, qstate):
    job = PREPARING.get(mid)
    if job:
        if job["started"]:
            job["done"].wait(90)   # the greeting is being written right now: wait for it, don't start over
        else:
            job["abort"] = True    # still waiting its turn behind others: answer live instead
            return None
    hit = PREFETCH.pop(mid, None)
    if hit and time.time() - hit[0] < GREETING_TTL and hit[1] == qstate:
        return hit[2]
    return None


def prepare(req):
    """Writes a greeting ahead (when entering the location, after a talk, when walking up)."""
    mid = describe_speaker(req)[0]
    qstate = (req.get("quest") or {}).get("state", "")
    if mid in PREPARING or (mid in PREFETCH and time.time() - PREFETCH[mid][0] < GREETING_TTL and PREFETCH[mid][1] == qstate):
        return {"ok": True}
    job = {"done": threading.Event(), "started": False, "abort": False}
    PREPARING[mid] = job
    try:
        res = compose(req, job)
        if res is not None:
            PREFETCH[mid] = (time.time(), qstate, res)
    finally:
        PREPARING.pop(mid, None)
        job["done"].set()
    return {"ok": True}


def talk(req):
    if req.get("prefetch"):
        return prepare(req)
    mid = describe_speaker(req)[0]
    said = req.get("choice") or ""
    if not said:
        hit = take_prepared(mid, (req.get("quest") or {}).get("state", ""))
        if hit:
            return remember(mid, "", hit)
    return remember(mid, said, compose(req))


def queue_sentences(text, spoken, out_q):
    """Hands every finished sentence (after `spoken`) to the speech queue."""
    while True:
        m = re.search(r"[.!?…]+[\"»”)]*\s", text[spoken:])
        if not m:
            return spoken
        end = spoken + m.end()
        s = text[spoken:end].strip()
        if len(s) > 1:
            out_q.put(s)
        spoken = end


def talk_stream(req, emit):
    """One dialogue turn, streamed: start (voice fx), text (growing), audio (one per sentence), done."""
    mid, name, role, persona, style, prof = describe_speaker(req)
    said = req.get("choice") or ""
    emit({"t": "start", **fx_of(prof)})
    if not said:
        hit = take_prepared(mid, (req.get("quest") or {}).get("state", ""))
        if hit:
            out = remember(mid, "", hit)
            emit({"t": "text", "s": out["line"]})
            if out.get("audio"):
                emit({"t": "audio", "path": out["audio"], "i": 0})
            emit({"t": "done", "line": out["line"], "choices": out["choices"]})
            return
    mid, name, prof, system, user = build_prompt(req)
    tts_q = queue.Queue()

    def tts_worker():
        i = 0
        while True:
            s = tts_q.get()
            if s is None:
                return
            path = speak(prof, s)
            if path:
                emit({"t": "audio", "path": path, "i": i})
                i += 1

    th = threading.Thread(target=tts_worker, daemon=True)
    th.start()
    buf, shown, spoken = "", "", 0
    with Priority(), Lane(True):
        for piece in llm.chat_stream(CONFIG["model"], system, user, TALK_SCHEMA, temperature=0.7):
            buf += piece
            text, closed = partial_field(buf)
            if text is None:
                continue
            if text != shown:
                shown = text
                emit({"t": "text", "s": text})
            spoken = queue_sentences(text + (" " if closed else ""), spoken, tts_q)
    res = finish_turn(parse_json(buf), name)
    line = res["line"] if res["line"] != "..." else (shown or "...")
    res["line"] = line
    if line != shown:
        emit({"t": "text", "s": line})
    rest = line[spoken:].strip() if spoken <= len(line) else ""
    if rest:
        tts_q.put(rest)
    tts_q.put(None)
    th.join(60)
    remember(mid, said, res)
    emit({"t": "done", "line": line, "choices": res["choices"]})


def summarize(mid, name):
    rows = mem.unsummarized(mid)
    if not rows:
        return
    old = mem.summary(mid)
    convo = "\n".join(f"{'Player' if w == 'player' else name}: {t}" for _, w, t in rows)
    out = background_llm(CONFIG["model"], "You keep the memory of a character in a game.",
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


def kind_profile(kind):
    """Voice of a shout pool: a mob kind, or 'vil:<personality>:<m|f|kid>'."""
    if kind.startswith("vil:"):
        _, pers, gender = (kind.split(":") + ["kind", "m"])[:3]
        return villager_profile(gender, pers)
    return profile_for(kind)


def fill_pool(kind, event, mood):
    key = pool_key(kind, event, mood)
    ev = P["events"].get(event, event)
    if kind.startswith("vil:"):
        _, pers, gender = (kind.split(":") + ["kind", "m"])[:3]
        who = "a village child" if gender == "kid" else f"a {pers} villager of Ashford"
        persona = P["kid"] if gender == "kid" else P["villagers"].get(pers, "")
        mood_line = f"The village's feelings about the player: {relation_text(mem.relation('village'))}."
    else:
        m = P["mobs"][kind]
        who, persona = m["name"], m["persona"]
        mood_line = f"Its mood towards the player: {MOOD_TEXT[mood]}."
    system = f"You write short spoken lines for characters in a medieval fantasy game. Setting: {P['world']}\n{lang_rule()}"
    user = (f"Character: {who}. {persona}\n{mood_line}\n"
            f"Write 6 different short lines (2 to 10 words each) this character says when it {ev}. "
            "Make them vivid and varied, in character, no stage directions. Return JSON {\"lines\": [...]}")
    out = background_llm(CONFIG["model"], system, user, LINES_SCHEMA, temperature=1.0, max_tokens=300)
    prof = kind_profile(kind)
    for text in out.get("lines", [])[:8]:
        text = str(text).strip().strip('"')
        if text:
            mem.add_bark(key, text, speak(prof, text))
    mem.prune_pool(key)


def revoice_pools():
    """Shouts written with an older voice design get spoken again with the current one."""
    for bid, pool, text in mem.all_barks():
        lang, kind = (pool.split("|") + ["", ""])[:2]
        old_lang = CONFIG["lang"]
        CONFIG["lang"] = lang or old_lang
        try:
            mem.set_bark_audio(bid, speak(kind_profile(kind), text))
        finally:
            CONFIG["lang"] = old_lang
    CONFIG["voice_version"] = P.get("voice_version", 1)
    save_config()


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
    b = b or {"text": "", "audio": ""}
    b.update(fx_of(kind_profile(kind)))
    return b


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
        out = background_llm(CONFIG["model"], system, user, CHAT_SCHEMA, temperature=0.85, max_tokens=300)
    lines = []
    for l in out.get("lines", [])[:4]:
        who = "a" if l.get("who") == "A" else "b"
        spk = a if who == "a" else b
        # the model sometimes writes the speaker into the line ("Олег каже: ...", "A: ...")
        text = re.sub(r"^[^:\n]{2,30}\s(каже|відповідає|питає|says|replies|asks|answers)\s*:\s*", "", str(l.get("text", "")).strip())
        text = re.sub(r"^(A|B|[A-ZА-ЯІЇЄҐ][\w'’-]{1,15})\s*:\s*", "", text).strip()
        if text:
            prof = villager_profile(spk.get("gender", "m"), spk.get("npc", spk.get("name", "")))
            lines.append({"who": who, "text": text, "audio": speak(prof, text), **fx_of(prof)})
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
        if CONFIG.get("mode") == "play" and job[0] not in ("warm", "revoice"):
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
            elif job[0] == "revoice":
                revoice_pools()
        except Exception as e:
            print("job failed:", job, e, flush=True)
        finally:
            queued.discard(job)


def warm_pools():
    """Fills the shout pools the first location needs (only the empty ones; they persist)."""
    enqueue(("warm",))
    if CONFIG.get("voice_version") != P.get("voice_version", 1):
        enqueue(("revoice",))
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

    def _stream(self, fn, req):
        """Lines of JSON, written while they happen; the connection closes at the end."""
        self.send_response(200)
        self.send_header("Content-Type", "application/x-ndjson; charset=utf-8")
        self.send_header("Connection", "close")
        self.end_headers()
        lock = threading.Lock()

        def emit(obj):
            data = (json.dumps(obj, ensure_ascii=False) + "\n").encode("utf-8")
            with lock:
                try:
                    self.wfile.write(data)
                    self.wfile.flush()
                except OSError:
                    pass          # the player walked away: keep going quietly
        try:
            fn(req, emit)
        except Exception as e:
            print("stream failed:", repr(e), flush=True)
            emit({"t": "done", "line": "...", "choices": [], "error": str(e)})

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
            if self.path == "/talk_stream":
                self._stream(talk_stream, req)
            elif self.path == "/config":
                changed = req.get("lang", CONFIG["lang"]) != CONFIG["lang"] or req.get("model", CONFIG["model"]) != CONFIG["model"]
                CONFIG.update({k: v for k, v in req.items() if k in ("lang", "model", "gpu_layers", "mode")})
                llm.GPU_LAYERS[0] = int(CONFIG.get("gpu_layers", 26))
                save_config()
                if changed:
                    STATE["model_loaded"] = False
                warm_pools()
                self._send(200, {"ok": True, **CONFIG})
            elif self.path == "/reset":
                mem.reset_world()
                PREFETCH.clear()
                self._send(200, {"ok": True})
            elif self.path in ROUTES:
                self._send(200, ROUTES[self.path](req))
            else:
                self._send(404, {"error": "unknown"})
        except Exception as e:
            print("request failed:", self.path, repr(e), flush=True)
            try:
                self._send(500, {"error": str(e)})
            except OSError:
                pass


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
