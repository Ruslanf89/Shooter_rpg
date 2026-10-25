# Generates spoken dialogue (assets/voice/<line_id>.wav) from data/dialogue.json.
# English voices use the Windows text-to-speech voices; voices with "engine": "piper"
# (Ukrainian) use the offline Piper TTS in tools/piper with models from tools/voices.
# tools/voice_manifest.json remembers which text every voice file was made from, so lines whose
# text (or voice) changed are made again. Run from the project folder (or double-click gen_voices.bat):
#   powershell -ExecutionPolicy Bypass -File tools\gen_voices.ps1          (missing and changed lines)
#   powershell -ExecutionPolicy Bypass -File tools\gen_voices.ps1 -Force   (regenerate all)
param([switch]$Force)

Add-Type -AssemblyName System.Speech
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$data = [System.IO.File]::ReadAllText((Join-Path $root "data\dialogue.json"), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$out = Join-Path $root "assets\voice"
New-Item -ItemType Directory -Force $out | Out-Null
$piper = Join-Path $PSScriptRoot "piper\piper.exe"
$manifestPath = Join-Path $PSScriptRoot "voice_manifest.json"
$manifest = @{}
if (Test-Path $manifestPath) {
    $m = [System.IO.File]::ReadAllText($manifestPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    foreach ($p in $m.PSObject.Properties) { $manifest[$p.Name] = $p.Value }
}
$sha = [System.Security.Cryptography.SHA1]::Create()
function LineHash([string]$voice, [string]$text) {
    $bytes = $utf8.GetBytes("$voice`n$text")
    return (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
}

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$fmt = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
$count = 0
$failed = 0
foreach ($p in $data.lines.PSObject.Properties) {
    $id = $p.Name
    $voiceKey = $p.Value[0]
    $text = $p.Value[1]
    $file = Join-Path $out "$id.wav"
    $hash = LineHash $voiceKey $text
    if ((Test-Path $file) -and -not $Force) {
        if (-not $manifest.ContainsKey($id)) { $manifest[$id] = $hash; continue }   # made before the manifest existed
        if ($manifest[$id] -eq $hash) { continue }                                 # up to date
    }
    $v = $data.voices.$voiceKey
    if ($null -eq $v) { Write-Warning "$id : unknown voice $voiceKey"; $failed++; continue }
    if ($v.engine -eq "piper") {
        if (-not (Test-Path $piper)) { Write-Warning "$id : Piper not found in tools\piper"; $failed++; continue }
        # pass the text through a UTF-8 file so Cyrillic survives the pipe
        $tmp = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllText($tmp, $text, $utf8)
        $model = Join-Path $PSScriptRoot ("voices\" + $v.model)
        cmd /c "type `"$tmp`" | `"$piper`" --model `"$model`" $(if ($null -ne $v.speaker) { "--speaker $($v.speaker)" }) --length_scale $($v.length) --output_file `"$file`"" 2>$null | Out-Null
        Remove-Item $tmp
    } else {
        $rate = [int]$v.rate
        $escaped = [System.Security.SecurityElement]::Escape($text)
        $ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'><voice name='$($v.voice)'><prosody pitch='$($v.pitch)' rate='$(1.0 + $rate * 0.08)'>$escaped</prosody></voice></speak>"
        $synth.SetOutputToWaveFile($file, $fmt)
        $synth.SpeakSsml($ssml)
        $synth.SetOutputToNull()
    }
    if (Test-Path $file) { $manifest[$id] = $hash; $count++ } else { $failed++ }
}
$synth.Dispose()
# save the manifest sorted, one line per entry
$keys = $manifest.Keys | Sort-Object
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append("{`n")
$i = 0
foreach ($k in $keys) {
    $i++
    $sep = if ($i -lt $keys.Count) { "," } else { "" }
    [void]$sb.Append("`"$k`": `"$($manifest[$k])`"$sep`n")
}
[void]$sb.Append("}`n")
[System.IO.File]::WriteAllText($manifestPath, $sb.ToString(), $utf8)
"Generated $count voice lines in $out" + $(if ($failed -gt 0) { " ($failed failed)" } else { "" })
