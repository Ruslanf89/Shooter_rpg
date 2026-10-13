"""Turns lines into WAV files: Piper for Ukrainian (one persistent process per voice model), the
Windows speech voices for English (one persistent PowerShell process). Voice keys and their
settings come from data/dialogue.json, the same voices as the recorded lines."""

import hashlib
import json
import os
import subprocess
import threading

SAPI_SCRIPT = r"""
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$fmt = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
while ($true) {
  $line = [Console]::In.ReadLine()
  if ($line -eq $null) { break }
  try {
    $j = $line | ConvertFrom-Json
    $esc = [System.Security.SecurityElement]::Escape($j.text)
    $ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'><voice name='$($j.voice)'><prosody pitch='$($j.pitch)' rate='$($j.rate)'>$esc</prosody></voice></speak>"
    $s.SetOutputToWaveFile($j.out, $fmt)
    $s.SpeakSsml($ssml)
    $s.SetOutputToNull()
    [Console]::Out.WriteLine("OK " + $j.out)
  } catch { [Console]::Out.WriteLine("ERR " + $_) }
  [Console]::Out.Flush()
}
"""


class Voice:
    def __init__(self, root, cache_dir):
        self.root = root
        self.cache = cache_dir
        os.makedirs(cache_dir, exist_ok=True)
        with open(os.path.join(root, "data", "dialogue.json"), encoding="utf-8-sig") as f:
            self.voices = json.load(f).get("voices", {})
        self.piper_exe = os.path.join(root, "tools", "piper", "piper.exe")
        self._piper = {}       # model -> Popen
        self._sapi = None
        self._locks = {}
        self._lock = threading.Lock()

    def available(self):
        return os.path.exists(self.piper_exe)

    def _lock_for(self, key):
        with self._lock:
            return self._locks.setdefault(key, threading.Lock())

    def _piper_proc(self, model):
        p = self._piper.get(model)
        if p is None or p.poll() is not None:
            p = subprocess.Popen(
                [self.piper_exe, "--model", os.path.join(self.root, "tools", "voices", model), "--json-input", "--quiet"],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                text=True, encoding="utf-8", creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
            self._piper[model] = p
        return p

    def _sapi_proc(self):
        if self._sapi is None or self._sapi.poll() is not None:
            self._sapi = subprocess.Popen(
                ["powershell", "-NoProfile", "-NonInteractive", "-Command", SAPI_SCRIPT],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                text=True, encoding="utf-8", creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        return self._sapi

    def say(self, voice_key, text):
        """Returns the path of a WAV with `text` spoken by `voice_key` (cached by content)."""
        text = text.replace("*", "").strip()
        if not text:
            return ""
        v = self.voices.get(voice_key) or self.voices.get("vil_m_uk" if voice_key.endswith("_uk") or voice_key.startswith("uk") else "vil_m", {})
        name = hashlib.sha1(f"{voice_key}|{text}".encode("utf-8")).hexdigest()[:20] + ".wav"
        out = os.path.join(self.cache, name)
        if os.path.exists(out):
            return out
        try:
            if v.get("engine") == "piper":
                model = v["model"]
                with self._lock_for(model):
                    p = self._piper_proc(model)
                    p.stdin.write(json.dumps({"text": text, "output_file": out}, ensure_ascii=False) + "\n")
                    p.stdin.flush()
                    p.stdout.readline()        # piper prints the file path when the file is written
            else:
                with self._lock_for("sapi"):
                    p = self._sapi_proc()
                    rate = 1.0 + int(v.get("rate", 0)) * 0.08
                    p.stdin.write(json.dumps({"text": text, "out": out, "voice": v.get("voice", "Microsoft David Desktop"),
                                              "pitch": v.get("pitch", "+0%"), "rate": f"{rate:.2f}"}) + "\n")
                    p.stdin.flush()
                    p.stdout.readline()
        except Exception as e:
            print("voice error:", e, flush=True)
            return ""
        return out if os.path.exists(out) else ""

    def close(self):
        for p in list(self._piper.values()) + ([self._sapi] if self._sapi else []):
            try:
                p.kill()
            except Exception:
                pass
