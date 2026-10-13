"""Turns lines into WAV files. Ukrainian: Piper with a voice profile per character (model, speaker,
speed, expressiveness - see "voice_profiles" in personas.json). English: the Windows speech voices
(one persistent PowerShell process), with the settings of data/dialogue.json."""

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

NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)


class Voice:
    def __init__(self, root, cache_dir):
        self.root = root
        self.cache = cache_dir
        os.makedirs(cache_dir, exist_ok=True)
        with open(os.path.join(root, "data", "dialogue.json"), encoding="utf-8-sig") as f:
            self.sapi_voices = json.load(f).get("voices", {})
        self.piper_exe = os.path.join(root, "tools", "piper", "piper.exe")
        self._piper = {}       # (model, length, noise, noise_w) -> Popen
        self._sapi = None
        self._locks = {}
        self._lock = threading.Lock()

    def available(self):
        return os.path.exists(self.piper_exe)

    def _lock_for(self, key):
        with self._lock:
            return self._locks.setdefault(key, threading.Lock())

    def _piper_proc(self, key):
        p = self._piper.get(key)
        if p is None or p.poll() is not None:
            model, length, noise, noise_w = key
            p = subprocess.Popen(
                [self.piper_exe, "--model", os.path.join(self.root, "tools", "voices", model), "--json-input", "--quiet",
                 "--length_scale", str(length), "--noise_scale", str(noise), "--noise_w", str(noise_w),
                 "--sentence_silence", "0.12"],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                text=True, encoding="utf-8", creationflags=NO_WINDOW)
            self._piper[key] = p
        return p

    def _sapi_proc(self):
        if self._sapi is None or self._sapi.poll() is not None:
            self._sapi = subprocess.Popen(
                ["powershell", "-NoProfile", "-NonInteractive", "-Command", SAPI_SCRIPT],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                text=True, encoding="utf-8", creationflags=NO_WINDOW)
        return self._sapi

    def say(self, profile, text, lang="uk"):
        """WAV path of `text` spoken with `profile` (a voice profile dict), cached by content."""
        text = text.replace("*", "").strip()
        if not text or not profile:
            return ""
        spec = {"en": profile.get("en", "vil_m")} if lang == "en" else \
            {k: profile.get(k) for k in ("model", "speaker", "length", "noise", "noise_w")}
        name = hashlib.sha1((json.dumps(spec, sort_keys=True) + "|" + text).encode("utf-8")).hexdigest()[:20] + ".wav"
        out = os.path.join(self.cache, name)
        if os.path.exists(out):
            return out
        try:
            if lang == "en":
                v = self.sapi_voices.get(spec["en"], {})
                with self._lock_for("sapi"):
                    p = self._sapi_proc()
                    rate = 1.0 + int(v.get("rate", 0)) * 0.08
                    p.stdin.write(json.dumps({"text": text, "out": out, "voice": v.get("voice", "Microsoft David Desktop"),
                                              "pitch": v.get("pitch", "+0%"), "rate": f"{rate:.2f}"}) + "\n")
                    p.stdin.flush()
                    p.stdout.readline()
            else:
                key = (spec["model"], spec.get("length") or 1.0, spec.get("noise") or 0.667, spec.get("noise_w") or 0.8)
                with self._lock_for(key):
                    p = self._piper_proc(key)
                    line = {"text": text, "output_file": out}
                    if spec.get("speaker") is not None:
                        line["speaker_id"] = int(spec["speaker"])
                    p.stdin.write(json.dumps(line, ensure_ascii=False) + "\n")
                    p.stdin.flush()
                    p.stdout.readline()        # piper prints the file path when the file is written
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
