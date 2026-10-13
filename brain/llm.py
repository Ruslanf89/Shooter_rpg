"""Talks to the local Ollama server (http://127.0.0.1:11434) and asks Qwen3 for JSON answers."""

import json
import re
import urllib.request

OLLAMA = "http://127.0.0.1:11434"


def _post(path, payload, timeout=120):
    req = urllib.request.Request(OLLAMA + path, data=json.dumps(payload).encode("utf-8"),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


def alive():
    try:
        with urllib.request.urlopen(OLLAMA + "/api/tags", timeout=2) as r:
            return [m["name"] for m in json.loads(r.read().decode("utf-8")).get("models", [])]
    except Exception:
        return None


GPU_LAYERS = [26]     # qwen3:8b has 36 layers: 22 on the GPU leaves room for the game itself


def chat_json(model, system, user, schema, temperature=0.8, max_tokens=400):
    """One chat turn with a JSON-schema answer. Thinking is off (fast replies for games)."""
    payload = {
        "model": model,
        "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
        "format": schema,
        "think": False,
        "stream": False,
        "keep_alive": "30m",
        "options": {"temperature": temperature, "num_predict": max_tokens, "num_ctx": 2048, "num_gpu": GPU_LAYERS[0], "num_thread": 4},
    }
    out = _post("/api/chat", payload)
    text = out.get("message", {}).get("content", "")
    text = re.sub(r"<think>.*?</think>", "", text, flags=re.S).strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        m = re.search(r"\{.*\}", text, flags=re.S)
        return json.loads(m.group(0)) if m else {}


def warm(model):
    """Loads the model into memory so the first real answer is quick."""
    try:
        _post("/api/generate", {"model": model, "prompt": "", "keep_alive": "30m",
                                "options": {"num_ctx": 2048, "num_gpu": GPU_LAYERS[0], "num_thread": 4}}, timeout=300)
        return True
    except Exception:
        return False
