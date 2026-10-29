@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title SMES firewall fix
color 0B

echo.
echo ================================================
echo   SMES - open Windows Firewall for port 8000
echo ================================================
echo.

net session >nul 2>&1
if errorlevel 1 (
  echo This file MUST be Run as administrator.
  echo Right-click fix-firewall.bat -^> Run as administrator
  echo.
  pause
  exit /b 1
)

echo Removing old SMES firewall rules...
netsh advfirewall firewall delete rule name="SMES 8000" >nul 2>&1
netsh advfirewall firewall delete rule name="SMES" >nul 2>&1

echo Adding inbound allow for TCP 8000 on Domain, Private, Public...
netsh advfirewall firewall add rule name="SMES 8000" dir=in action=allow protocol=TCP localport=8000 profile=any enable=yes
if errorlevel 1 (
  echo FAILED to add firewall rule.
  pause
  exit /b 1
)

echo.
echo Firewall rule added.
echo.
echo Now on THIS PC check these in order:
echo   1. start-here.bat is still running (black window open)
echo   2. Open http://127.0.0.1:8000 on THIS PC
echo   3. Open http://172.24.88.169:8000 on THIS PC
echo   4. Then try http://172.24.88.169:8000 from the other PC
echo.
echo If step 2 or 3 fails: server is not running. Start start-here.bat first.
echo If step 2 and 3 work but other PC times out: company network is blocking
echo peer connections. Ask IT to allow TCP 8000 to 172.24.88.169.
echo.
pause
