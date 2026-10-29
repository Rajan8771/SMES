@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title SMES - keep this window open
color 0E

set "LOG=%~dp0start-log.txt"
echo ===== SMES start %DATE% %TIME% ===== > "%LOG%"
echo Folder: %CD% >> "%LOG%"

echo.
echo ================================================
echo   SMES START
echo   Keep this window OPEN
echo ================================================
echo.
echo Log file: %LOG%
echo.

if not exist "smes\main.py" (
  echo ERROR: smes\main.py missing. Unzip the zip fully.>> "%LOG%"
  echo ERROR: Wrong folder. Unzip smes-source.zip completely.
  echo Current folder: %CD%
  echo.
  pause
  exit /b 1
)

set "PYEXE="
where py >nul 2>&1 && for /f "delims=" %%I in ('where py') do (
  if not defined PYEXE set "PYEXE=py -3"
)
if not defined PYEXE where python >nul 2>&1 && set "PYEXE=python"
if not defined PYEXE where python3 >nul 2>&1 && set "PYEXE=python3"

if not defined PYEXE (
  echo ERROR: Python not found on PATH.>> "%LOG%"
  echo.
  echo Python is not installed or not on PATH.
  echo 1. Open https://www.python.org/downloads/
  echo 2. Install Python 3
  echo 3. Tick "Add python.exe to PATH"
  echo 4. Close this window and run start-here.bat again
  echo.
  start "" "https://www.python.org/downloads/"
  pause
  exit /b 1
)

echo Using Python launcher: %PYEXE% >> "%LOG%"
echo Using: %PYEXE%
echo.

if not exist ".venv\Scripts\python.exe" (
  echo Creating .venv ... >> "%LOG%"
  echo Creating virtual environment...
  %PYEXE% -m venv .venv >> "%LOG%" 2>&1
  if errorlevel 1 (
    echo ERROR: venv failed.>> "%LOG%"
    echo Failed to create .venv. Reinstall Python with Add to PATH.
    type "%LOG%"
    pause
    exit /b 1
  )
)

echo Installing packages... >> "%LOG%"
echo Installing packages (first time can take 1-2 minutes)...
".venv\Scripts\python.exe" -m pip install -r requirements.txt >> "%LOG%" 2>&1
if errorlevel 1 (
  echo ERROR: pip install failed. See start-log.txt>> "%LOG%"
  echo Package install failed. Open start-log.txt
  type "%LOG%"
  pause
  exit /b 1
)

net session >nul 2>&1
if not errorlevel 1 (
  echo Adding firewall rule for port 8000 on all profiles... >> "%LOG%"
  netsh advfirewall firewall delete rule name="SMES 8000" >nul 2>&1
  netsh advfirewall firewall add rule name="SMES 8000" dir=in action=allow protocol=TCP localport=8000 profile=any enable=yes >> "%LOG%" 2>&1
) else (
  echo Not admin - firewall rule skipped.>> "%LOG%"
  echo.
  echo WARNING: Not running as Administrator.
  echo Other PCs will often get ERR_CONNECTION_TIMED_OUT.
  echo Close this, then right-click start-here.bat -^> Run as administrator
  echo Or run fix-firewall.bat as administrator, then start again.
  echo.
)

echo.
echo Starting server on 0.0.0.0:8000 ... >> "%LOG%"
echo.
echo ================================================
echo   When you see "Uvicorn running"...
echo   THIS PC:     http://127.0.0.1:8000
echo   OTHER USERS: http://172.24.88.169:8000
echo   (or the LAN URL printed below)
echo ================================================
echo.
echo Opening Chrome on this PC...
start "" "http://127.0.0.1:8000"

".venv\Scripts\python.exe" -m smes.lan
set "ERR=%ERRORLEVEL%"
echo Server exited code %ERR% >> "%LOG%"
echo.
echo Server stopped. If the page refused to connect, this window closed too early
echo or Python failed. Read start-log.txt
echo.
pause
exit /b %ERR%
