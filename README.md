# SMES

SMT MES auto-reply for the OClaw robot **RAJAN SUMAN的小龙虾** / MTP app **OPPO_MES** in the TT group 【INDIA】 SMT MES ISSUE (group id 965235).

## Set the robot API (MTP OPPO_MES)

This matches the MTP **Launch Guide** for app `OPPO_MES` (type **robot**, online).

### 1) Copy credentials from MTP

1. Open MTP → application **OPPO_MES**
2. **Launch Guide** → section **Application information improvement** → **Basic Data** → **edit**  
   (or sidebar → **Basic Information**)
3. Copy **appId** and **appSecret**
4. Optional: under **Application Function Development** → **robot** → **Access Guide** for send/receive message docs and permissions

Do not paste secrets into chat or commit them to git.

### 2) Write credentials into OpenClaw on the factory PC

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
cd $env:USERPROFILE
Invoke-WebRequest -Uri "https://github.com/Rajan8771/SMES/archive/refs/heads/cursor/mtp-robot-api-377a.zip" -OutFile "$env:TEMP\SMES.zip"
Expand-Archive -Path "$env:TEMP\SMES.zip" -DestinationPath $env:USERPROFILE -Force
cd "$env:USERPROFILE\SMES-cursor-mtp-robot-api-377a"
powershell -ExecutionPolicy Bypass -File .\setup-mtp-robot-api.ps1 `
  -AppId "PASTE_APP_ID" `
  -AppSecret "PASTE_APP_SECRET"
```

If MTP uses international Lark instead of China Feishu, add `-Domain lark`.  
If MTP exposes a custom API host, pass `-Domain "https://your-mtp-api-host"`.

### 3) Finish on MTP + groups

1. In MTP, enable robot message permissions (see **robot → Access Guide**)
2. Subscribe to receive-message events (WebSocket / long connection)
3. Add the **OPPO_MES** robot into 【INDIA】 SMT MES ISSUE and INDIA SMT TE
4. In each group: Settings → copy `chat_id` (`oc_...`)
5. Rerun with chat ids:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-mtp-robot-api.ps1 `
  -AppId "PASTE_APP_ID" `
  -AppSecret "PASTE_APP_SECRET" `
  -MesIssueChatId "oc_MES_ISSUE" `
  -SmtTeChatId "oc_SMT_TE"
```

### 4) Verify

```powershell
powershell -ExecutionPolicy Bypass -File .\verify-mtp-robot-api.ps1
```

Expect `feishu` connected (not only personal TT). Then in the group: `@` the robot with a fault line such as `Glue line 17, final VI, CPU not working.`

---

## Workspace-only setup (no API credentials)

If the robot API is already connected and you only need reply rules:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
cd $env:USERPROFILE
Invoke-WebRequest -Uri "https://github.com/Rajan8771/SMES/archive/refs/heads/cursor/mtp-robot-api-377a.zip" -OutFile "$env:TEMP\SMES.zip"
Expand-Archive -Path "$env:TEMP\SMES.zip" -DestinationPath $env:USERPROFILE -Force
cd "$env:USERPROFILE\SMES-cursor-mtp-robot-api-377a"
powershell -ExecutionPolicy Bypass -File .\setup-mes-bot.ps1
```

The script copies `workspace\` into `%USERPROFILE%\.openclaw\workspace`, allows that group to receive a reply without an @mention, and restarts the gateway.

`fix-mes-job.ps1` retargets the existing MES cron job so it posts `Please update SMT MES issues` to TT group 965235 every day at 9:00 AM and 9:00 PM India time.

Put real line checks in `workspace\MES.md`, then run the script again. The bot quotes only those checks. It does not invent machine settings.
