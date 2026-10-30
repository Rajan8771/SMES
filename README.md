# SMES

SMT MES auto-reply for the OClaw robot **RAJAN SUMAN的小龙虾** in the TT group 【INDIA】 SMT MES ISSUE (group id 965235).

On the OClaw PC, Git is not required. Paste this in PowerShell:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
cd $env:USERPROFILE
Invoke-WebRequest -Uri "https://github.com/Rajan8771/SMES/archive/refs/heads/cursor/mes-auto-reply-bc04.zip" -OutFile "$env:TEMP\SMES.zip"
Expand-Archive -Path "$env:TEMP\SMES.zip" -DestinationPath $env:USERPROFILE -Force
cd "$env:USERPROFILE\SMES-cursor-mes-auto-reply-bc04"
powershell -ExecutionPolicy Bypass -File .\setup-mes-bot.ps1
```

The script copies `workspace\` into `%USERPROFILE%\.openclaw\workspace`, allows that group to receive a reply without an @mention, and restarts the gateway.

`fix-mes-job.ps1` retargets the existing MES cron job so it posts `Please update SMT MES issues` to TT group 965235 every day at 9:00 AM and 9:00 PM India time.

If the Control UI shows `ERR_CONNECTION_REFUSED` on port 18789, the gateway is down. On the OClaw PC:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Rajan8771/SMES/cursor/mes-auto-reply-bc04/fix-gateway.ps1" -OutFile "$env:TEMP\fix-gateway.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\fix-gateway.ps1"
```

Put real line checks in `workspace\MES.md`, then run the setup script again. The bot quotes only those checks. It does not invent machine settings.
