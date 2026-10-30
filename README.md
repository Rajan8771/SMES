# SMES

SMT MES auto-reply for the OClaw robot **RAJAN SUMAN的小龙虾** in the group 【INDIA】 SMT MES ISSUE (TT group id `965235`).

## Why the 09:00 message came from your personal account

OpenClaw cron `announce` sends through the **logged-in channel account**.

If `channels.tt` is logged in as your personal TT/Feishu user (for example `IN908771`), the reminder `Please update SMT MES issues` appears as **your** right-side green bubble with your landscape avatar — not as the AppRobot **RAJAN SUMAN的小龙虾**.

Cron cannot fake the robot while TT is still your personal session. Fix the login (or use Feishu App credentials), then Run MES again.

## Make the robot send the reminder

On the OClaw PC (no Git needed):

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Rajan8771/SMES/cursor/mes-robot-sender-bc04/fix-mes-robot-sender.ps1" -OutFile "$env:TEMP\fix-mes-robot-sender.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\fix-mes-robot-sender.ps1"
```

The script:

1. Keeps MES delivery as `announce` → channel `tt` → group `965235` (or Feishu if you pass `-FeishuChatId`).
2. Prints `openclaw channels status --probe` so you can see who is logged in.
3. Warns if status looks like personal / `IN908771`.
4. Prints logout / login steps for the robot.

### Path A — TT session must be the robot

```powershell
openclaw channels logout --channel tt
openclaw channels login --channel tt
openclaw channels status --probe
openclaw gateway restart
```

Log in as the **robot** TT account (same identity as RAJAN SUMAN的小龙虾), not your staff account. Then Control UI → Cron Jobs → MES → Run.

### Path B — Feishu/Lark AppRobot (preferred when the group shows robots)

The chat UI with an **External** tag and **4 robots** is Feishu/Lark. For AppRobot posts:

```powershell
openclaw channels login --channel feishu
```

Use **manual** setup. Paste the App ID + App Secret for **RAJAN SUMAN的小龙虾** (Feishu Open Platform / Lark Developer). Do not use personal QR login.

Copy the group `chat_id` from Feishu group settings (looks like `oc_xxx`), then:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:TEMP\fix-mes-robot-sender.ps1" -FeishuChatId "oc_xxx"
```

### How to verify

After MES → Run, the group must show the line from **RAJAN SUMAN的小龙虾** (robot name/avatar). It must **not** be a right-side green bubble from your personal landscape avatar.

## First-time workspace setup

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
cd $env:USERPROFILE
Invoke-WebRequest -Uri "https://github.com/Rajan8771/SMES/archive/refs/heads/cursor/mes-robot-sender-bc04.zip" -OutFile "$env:TEMP\SMES.zip"
Expand-Archive -Path "$env:TEMP\SMES.zip" -DestinationPath $env:USERPROFILE -Force
cd "$env:USERPROFILE\SMES-cursor-mes-robot-sender-bc04"
powershell -ExecutionPolicy Bypass -File .\setup-mes-bot.ps1
```

`setup-mes-bot.ps1` copies `workspace\` into `%USERPROFILE%\.openclaw\workspace`, allows group replies without @mention, retargets the MES cron job, and runs the robot-sender check.

`fix-mes-job.ps1` alone retargets MES to TT group `965235` on schedule `0 9,21 * * *` Asia/Calcutta. It does not change who is logged in — use `fix-mes-robot-sender.ps1` for that.

## Gateway down (`ERR_CONNECTION_REFUSED` on 18789)

If Control UI refuses connections, bring the gateway back first (from the gateway-fix branch / PR when available), then run the robot-sender script and MES → Run.

Put real line checks in `workspace\MES.md`, then run setup again. The bot quotes only those checks. It does not invent machine settings.
