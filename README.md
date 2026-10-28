# SMES

SMT MES auto-reply for the OClaw robot **RAJAN SUMAN的小龙虾** in the TT group 【INDIA】 SMT MES ISSUE (group id 965235).

On the OClaw PC, in this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-mes-bot.ps1
```

The script copies `workspace\` into `%USERPROFILE%\.openclaw\workspace`, allows that group to receive a reply without an @mention, and restarts the gateway.

Put real line checks in `workspace\MES.md`, then run the script again. The bot quotes only those checks. It does not invent machine settings.
