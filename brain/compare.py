"""Runs the same Northvale moments through two Qwen3 models and prints the answers and timings.
Usage: python brain/compare.py [lang] [model ...]   (default: uk qwen3:4b qwen3:8b)"""

import os
import sys
import tempfile
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import server                                   # noqa: E402
from memory import Memory                       # noqa: E402

lang = sys.argv[1] if len(sys.argv) > 1 else "uk"
models = sys.argv[2:] or ["qwen3:4b", "qwen3:8b"]
server.voice.say = lambda profile, text, lang="uk": ""          # words only: speech isn't what we compare
CTX = {"time": "evening", "weather": "clear", "place": "Ashford"}

CASES = [
    ("Aldric greets", lambda: server.talk({"npc": "aldric", "ctx": CTX})),
    ("Maybell offers a quest", lambda: server.talk({"npc": "maybell", "ctx": CTX, "quest": {
        "state": "offer", "title": "The Lost Harvest",
        "text": "Bandits scattered my grain sacks all over the valley. Please find five sacks of grain and bring them back."}})),
    ("Brannock, player jokes", lambda: server.talk({"npc": "brannock", "ctx": CTX, "choice": "Sergeant, your guards sleep more than they guard."})),
    ("VesPer greets", lambda: server.talk({"npc": "vesper", "ctx": CTX})),
    ("Villager (gossip) greets", lambda: server.talk({"npc": "ashford_1", "name": "Wilma", "job": "baker", "personality": "gossip", "gender": "f", "ctx": CTX})),
]


def shouts(kind, event):
    server.fill_pool(kind, event, "neutral")
    key = server.pool_key(kind, event, "neutral")
    return [r[0] for r in server.mem._q("SELECT text FROM bark WHERE pool=?", (key,))]


for model in models:
    server.CONFIG.update({"model": model, "lang": lang})
    server.mem = Memory(os.path.join(tempfile.mkdtemp(), "compare.db"))
    server.llm.warm(model)
    print(f"\n==================== {model} ({lang}) ====================", flush=True)
    for title, fn in CASES:
        t = time.time()
        r = fn()
        print(f"\n[{title}]  {time.time() - t:.1f}s\n  NPC: {r['line']}\n  choices: " + " | ".join(r["choices"]), flush=True)
    for kind, ev in (("bandit", "aggro"), ("kobold", "flee")):
        t = time.time()
        lines = shouts(kind, ev)
        print(f"\n[{kind} {ev} shouts]  {time.time() - t:.1f}s\n  " + "\n  ".join(lines), flush=True)
    t = time.time()
    c = server.chat({"a": {"name": "Wilma", "job": "baker", "personality": "gossip", "gender": "f"},
                     "b": {"name": "Hob", "job": "farmer", "personality": "grumpy", "gender": "m"}, "ctx": CTX})
    print(f"\n[villagers chat]  {time.time() - t:.1f}s\n  " + "\n  ".join(f"{l['who'].upper()}: {l['text']}" for l in c["lines"]), flush=True)
