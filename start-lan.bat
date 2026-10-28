@echo off
cd /d "%~dp0"
where python >nul 2>&1
if errorlevel 1 (
  echo Install Python from https://www.python.org/downloads/ and tick "Add python.exe to PATH".
  pause
  exit /b 1
)
if not exist .venv\Scripts\python.exe (
  python -m venv .venv
)
.venv\Scripts\python.exe -m pip install -r requirements.txt
netsh advfirewall firewall add rule name="SMES 8000" dir=in action=allow protocol=TCP localport=8000 >nul 2>&1
if errorlevel 1 (
  echo Windows Firewall did not allow port 8000. Right-click this file and choose "Run as administrator".
)
echo.
echo Other users on your Wi-Fi must open the "Other users on LAN" address printed below.
echo.
.venv\Scripts\python.exe -m smes.lan
pause
