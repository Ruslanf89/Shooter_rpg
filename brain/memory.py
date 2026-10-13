"""SQLite memory of the Northvale brains: what each NPC talked about with the player, how they feel
about him, what happened in the valley (events that spread as gossip), how each mob kind feels
about him, and pools of ready-made voiced shouts for fights and greetings."""

import random
import sqlite3
import threading
import time

SCHEMA = """
CREATE TABLE IF NOT EXISTS talk (
    id INTEGER PRIMARY KEY, npc TEXT, who TEXT, text TEXT, ts REAL);
CREATE TABLE IF NOT EXISTS summary (
    npc TEXT PRIMARY KEY, text TEXT, upto INTEGER);
CREATE TABLE IF NOT EXISTS relation (
    npc TEXT PRIMARY KEY, trust INTEGER DEFAULT 0, fear INTEGER DEFAULT 0, affection INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS event (
    id INTEGER PRIMARY KEY, ts REAL, kind TEXT, text TEXT, place TEXT, importance INTEGER);
CREATE TABLE IF NOT EXISTS faction (
    kind TEXT PRIMARY KEY, kills INTEGER DEFAULT 0, fled INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS bark (
    id INTEGER PRIMARY KEY, pool TEXT, text TEXT, audio TEXT, used INTEGER DEFAULT 0);
CREATE INDEX IF NOT EXISTS bark_pool ON bark(pool);
CREATE INDEX IF NOT EXISTS talk_npc ON talk(npc);
"""


def clamp(v, lo=-100, hi=100):
    return max(lo, min(hi, v))


class Memory:
    def __init__(self, path):
        self.db = sqlite3.connect(path, check_same_thread=False)
        self.db.executescript(SCHEMA)
        self.lock = threading.Lock()

    def _q(self, sql, args=(), one=False):
        with self.lock:
            cur = self.db.execute(sql, args)
            rows = cur.fetchall()
            self.db.commit()
        return (rows[0] if rows else None) if one else rows

    # --- a new game forgets everything about the player (shout pools are kept: they're generic)
    def reset_world(self):
        for t in ("talk", "summary", "relation", "event", "faction"):
            self._q(f"DELETE FROM {t}")
        self._q("DELETE FROM bark WHERE pool LIKE '%|angry' OR pool LIKE '%|afraid'")

    # --- conversations
    def add_talk(self, npc, who, text):
        self._q("INSERT INTO talk(npc, who, text, ts) VALUES (?,?,?,?)", (npc, who, text, time.time()))

    def recent_talk(self, npc, n=10):
        rows = self._q("SELECT who, text FROM talk WHERE npc=? ORDER BY id DESC LIMIT ?", (npc, n))
        return list(reversed(rows))

    def talk_count(self, npc):
        return self._q("SELECT COUNT(*) FROM talk WHERE npc=?", (npc,), one=True)[0]

    def unsummarized(self, npc, keep=10):
        upto = (self._q("SELECT upto FROM summary WHERE npc=?", (npc,), one=True) or (0,))[0]
        rows = self._q("SELECT id, who, text FROM talk WHERE npc=? AND id>? ORDER BY id", (npc, upto))
        return rows[:-keep] if len(rows) > keep else []

    def summary(self, npc):
        r = self._q("SELECT text FROM summary WHERE npc=?", (npc,), one=True)
        return r[0] if r else ""

    def set_summary(self, npc, text, upto):
        self._q("INSERT OR REPLACE INTO summary(npc, text, upto) VALUES (?,?,?)", (npc, text, upto))

    # --- relationships (-100 .. 100)
    def relation(self, npc):
        r = self._q("SELECT trust, fear, affection FROM relation WHERE npc=?", (npc,), one=True)
        return {"trust": r[0], "fear": r[1], "affection": r[2]} if r else {"trust": 0, "fear": 0, "affection": 0}

    def change_relation(self, npc, trust=0, fear=0, affection=0):
        r = self.relation(npc)
        self._q("INSERT OR REPLACE INTO relation(npc, trust, fear, affection) VALUES (?,?,?,?)",
                (npc, clamp(r["trust"] + trust), clamp(r["fear"] + fear), clamp(r["affection"] + affection)))

    def change_all(self, prefix, **kw):
        """Changes everyone whose id starts with `prefix` (e.g. 'vil:' for all villagers) that we know."""
        for (npc,) in self._q("SELECT npc FROM relation WHERE npc LIKE ?", (prefix + "%",)):
            self.change_relation(npc, **kw)

    # --- world events and gossip
    def add_event(self, kind, text, place="", importance=1):
        self._q("INSERT INTO event(ts, kind, text, place, importance) VALUES (?,?,?,?,?)",
                (time.time(), kind, text, place, importance))

    def gossip(self, n=5):
        rows = self._q("SELECT text, importance, ts FROM event ORDER BY importance * 1.0 / (1 + (? - ts) / 600.0) DESC LIMIT ?",
                       (time.time(), n))
        return [r[0] for r in rows]

    # --- what each mob kind thinks of the player
    def faction(self, kind):
        r = self._q("SELECT kills, fled FROM faction WHERE kind=?", (kind,), one=True)
        return {"kills": r[0], "fled": r[1]} if r else {"kills": 0, "fled": 0}

    def faction_add(self, kind, kills=0, fled=0):
        f = self.faction(kind)
        self._q("INSERT OR REPLACE INTO faction(kind, kills, fled) VALUES (?,?,?)", (kind, f["kills"] + kills, f["fled"] + fled))

    def mood(self, kind):
        """neutral -> angry (the player killed a few of them) -> afraid (he killed many)."""
        k = self.faction(kind)["kills"]
        return "afraid" if k >= 10 else ("angry" if k >= 3 else "neutral")

    # --- ready-made voiced shouts
    def pool_size(self, pool):
        return self._q("SELECT COUNT(*) FROM bark WHERE pool=?", (pool,), one=True)[0]

    def add_bark(self, pool, text, audio):
        self._q("INSERT INTO bark(pool, text, audio) VALUES (?,?,?)", (pool, text, audio))

    def take_bark(self, pool):
        rows = self._q("SELECT id, text, audio, used FROM bark WHERE pool=? ORDER BY used, RANDOM() LIMIT 3", (pool,))
        if not rows:
            return None
        r = random.choice(rows[:2]) if len(rows) > 1 else rows[0]
        self._q("UPDATE bark SET used=used+1 WHERE id=?", (r[0],))
        return {"text": r[1], "audio": r[2]}

    def all_barks(self):
        return self._q("SELECT id, pool, text FROM bark")

    def set_bark_audio(self, bid, audio):
        self._q("UPDATE bark SET audio=? WHERE id=?", (audio, bid))

    def fresh_count(self, pool, max_used=2):
        return self._q("SELECT COUNT(*) FROM bark WHERE pool=? AND used<?", (pool, max_used), one=True)[0]

    def prune_pool(self, pool, keep=14):
        rows = self._q("SELECT id FROM bark WHERE pool=? ORDER BY used DESC, id", (pool,))
        for (bid,) in rows[: max(0, len(rows) - keep)]:
            self._q("DELETE FROM bark WHERE id=?", (bid,))
