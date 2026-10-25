@echo off
rem Makes the voice files for new and changed dialogue lines (see gen_voices.ps1).
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File tools\gen_voices.ps1 %*
pause
