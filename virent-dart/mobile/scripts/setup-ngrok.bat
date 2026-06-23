@echo off
echo ============================================
echo   Virent — Ngrok Setup
echo ============================================
set DEST=%APPDATA%\Virent
if not exist "%DEST%" mkdir "%DEST%"
echo Downloading ngrok...
powershell -Command "Invoke-WebRequest -Uri 'https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip' -OutFile '%TEMP%\ngrok.zip'"
powershell -Command "Expand-Archive -Path '%TEMP%\ngrok.zip' -DestinationPath '%DEST%' -Force"
del "%TEMP%\ngrok.zip" 2>nul
echo Configuring authtoken...
"%DEST%\ngrok.exe" config add-authtoken 3FRM4bQ1jHlEDzjmJQTeUdPEmUN_8JJjhy7GELTC4EZw7SwR
echo Done! Start Virent.
pause
