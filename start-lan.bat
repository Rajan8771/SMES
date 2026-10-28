@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title SMES LAN Server
color 0A

echo.
echo ============================================
echo   SMES - starting for your LAN
echo ============================================
echo.

set "PY="
where py >nul 2>&1 && set "PY=py -3"
if not defined PY where python >nul 2>&1 && set "PY=python"
if not defined PY where python3 >nul 2>&1 && set "PY=python3"
if not defined PY (
  echo ERROR: Python is not installed or not on PATH.
  echo Install from https://www.python.org/downloads/
  echo During install, tick "Add python.exe to PATH".
  echo.
  pause
  exit /b 1
)

echo Using: %PY%
echo.

if not exist "smes\main.py" (
  echo ERROR: smes\main.py not found.
  echo Unzip smes-source.zip fully, then run this file from that folder.
  echo Current folder: %CD%
  echo.
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
  echo Creating virtual environment...
  %PY% -m venv .venv
  if errorlevel 1 (
    echo ERROR: could not create .venv. Install Python with "Add to PATH" ticked.
    pause
    exit /b 1
  )
)

echo Installing packages...
".venv\Scripts\python.exe" -m pip install --upgrade pip >nul
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 (
  echo ERROR: pip install failed.
  pause
  exit /b 1
)

echo.
echo Opening Windows Firewall for port 8000...
net session >nul 2>&1
if errorlevel 1 (
  echo WARNING: not running as Administrator.
  echo Right-click start-lan.bat -^> Run as administrator
  echo so other PCs can connect through Windows Firewall.
) else (
  netsh advfirewall firewall delete rule name="SMES 8000" >nul 2>&1
  netsh advfirewall firewall add rule name="SMES 8000" dir=in action=allow protocol=TCP localport=8000
  if errorlevel 1 (
    echo WARNING: firewall rule failed.
  ) else (
    echo Firewall rule OK: TCP 8000 allowed.
  )
)

echo.
echo ============================================
echo   Starting board now...
echo ============================================
echo.
".venv\Scripts\python.exe" -m smes.lan
echo.
echo Server stopped.
pause
