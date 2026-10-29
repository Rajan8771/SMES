@echo off
echo Checking whether something is listening on port 8000...
echo.
netstat -ano | findstr ":8000"
if errorlevel 1 (
  echo.
  echo NOTHING is listening on port 8000.
  echo That is why Chrome shows ERR_CONNECTION_REFUSED.
  echo Run start-here.bat and leave it open, then try again.
) else (
  echo.
  echo Port 8000 is in use. Try http://127.0.0.1:8000
  echo Other users try http://172.24.88.169:8000
)
echo.
pause
