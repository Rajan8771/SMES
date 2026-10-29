@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title SMES diagnose
color 0A
set "LOG=%~dp0diagnose-log.txt"

echo SMES diagnose %DATE% %TIME% > "%LOG%"
echo.
echo Writing diagnose-log.txt ...
echo.

echo === IP addresses === >> "%LOG%"
ipconfig | findstr /i "IPv4 Ethernet Wireless Wi-Fi Adapter" >> "%LOG%"
echo. >> "%LOG%"

echo === Port 8000 listeners === >> "%LOG%"
netstat -ano | findstr ":8000" >> "%LOG%"
if errorlevel 1 (
  echo NOTHING listening on port 8000. >> "%LOG%"
  echo.
  echo RESULT: SMES is NOT running on this PC.
  echo Fix: right-click start-here.bat -^> Run as administrator, leave it open.
) else (
  echo.
  echo Port 8000 is in use on this PC.
)

echo. >> "%LOG%"
echo === Firewall rules named SMES === >> "%LOG%"
netsh advfirewall firewall show rule name="SMES 8000" >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo === Local health check === >> "%LOG%"
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 http://127.0.0.1:8000/api/health; '127.0.0.1 OK: ' + $r.Content } catch { '127.0.0.1 FAIL: ' + $_.Exception.Message }" >> "%LOG%"
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 http://172.24.88.169:8000/api/health; '172.24.88.169 OK: ' + $r.Content } catch { '172.24.88.169 FAIL: ' + $_.Exception.Message }" >> "%LOG%"

echo.
type "%LOG%"
echo.
echo ================================================
echo Read the RESULT above.
echo - If 127.0.0.1 FAIL: run start-here.bat on THIS PC
echo - If 127.0.0.1 OK but 172.24.88.169 FAIL: run fix-firewall.bat as admin
echo - If both OK here but other PC times out: ask IT for TCP 8000
echo ================================================
echo.
pause
