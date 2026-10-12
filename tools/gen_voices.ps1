# Generates spoken dialogue (assets/voice/<line_id>.wav) from data/dialogue.json.
# English voices use the Windows text-to-speech voices; voices with "engine": "piper"
# (Ukrainian) use the offline Piper TTS in tools/piper with models from tools/voices.
# Run from the project folder:
#   powershell -ExecutionPolicy Bypass -File tools\gen_voices.ps1          (only missing lines)
#   powershell -ExecutionPolicy Bypass -File tools\gen_voices.ps1 -Force   (regenerate all)
param([switch]$Force)

Add-Type -AssemblyName System.Speech
$root = Split-Path -Parent $PSScriptRoot
$data = [System.IO.File]::ReadAllText((Join-Path $root "data\dialogue.json"), [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$out = Join-Path $root "assets\voice"
New-Item -ItemType Directory -Force $out | Out-Null
$piper = Join-Path $PSScriptRoot "piper\piper.exe"

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$fmt = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
$count = 0
foreach ($p in $data.lines.PSObject.Properties) {
    $id = $p.Name
    $voiceKey = $p.Value[0]
    $text = $p.Value[1]
    $file = Join-Path $out "$id.wav"
    if ((Test-Path $file) -and -not $Force) { continue }
    $v = $data.voices.$voiceKey
    if ($v.engine -eq "piper") {
        # pass the text through a UTF-8 file so Cyrillic survives the pipe
        $tmp = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllText($tmp, $text, (New-Object System.Text.UTF8Encoding($false)))
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
    $count++
}
$synth.Dispose()
"Generated $count voice lines in $out"
