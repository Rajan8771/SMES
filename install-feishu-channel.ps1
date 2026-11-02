# Install / enable Feishu so cron can post as AppRobot.
# Your log showed: channels.feishu: unknown channel id: feishu
# That means the Feishu plugin is not loaded on OpenClaw 2026.4.x.
#
# Run:
#   powershell -ExecutionPolicy Bypass -File .\install-feishu-channel.ps1

$ErrorActionPreference = "Continue"

function Find-OpenClaw {
    $cmd = Get-Command openclaw -ErrorAction SilentlyContinue
    if ($cmd) {
        if ($cmd.Source -like "*.ps1") {
            $shim = Join-Path (Split-Path $cmd.Source) "openclaw.cmd"
            if (Test-Path $shim) { return $shim }
        }
        return $cmd.Source
    }
    foreach ($c in @(
        "$env:USERPROFILE\.openclaw\bin\openclaw.cmd",
        "$env:LOCALAPPDATA\Programs\OClaw\resources\openclaw\openclaw.cmd",
        "$env:LOCALAPPDATA\Programs\OClaw\openclaw.cmd"
    )) { if (Test-Path $c) { return $c } }
    return $null
}

$openclaw = Find-OpenClaw
if (-not $openclaw) { throw "openclaw not found" }
Write-Host "Using: $openclaw"
& $openclaw --version

Write-Host ""
Write-Host "1) Try plugin install..."
& $openclaw plugins install "@openclaw/feishu"
Write-Host "exit=$LASTEXITCODE"

Write-Host ""
Write-Host "2) Try channels login (installs plugin if missing, then asks App ID/Secret)..."
Write-Host "   Choose MANUAL. Paste AppRobot App ID + App Secret. Not IN008771 QR."
& $openclaw channels login --channel feishu

Write-Host ""
Write-Host "3) If still unknown channel, point plugins.load.paths at bundled feishu (2026.4.x bug)."
$candidates = @(
    (Join-Path $env:LOCALAPPDATA "Programs\OClaw\resources\openclaw\dist\extensions\feishu"),
    (Join-Path $env:LOCALAPPDATA "Programs\OClaw\resources\openclaw\extensions\feishu"),
    (Join-Path $env:USERPROFILE ".openclaw\extensions\feishu")
)
$feishuPath = $null
foreach ($p in $candidates) {
    if (Test-Path (Join-Path $p "package.json")) { $feishuPath = $p; break }
    if (Test-Path $p) { $feishuPath = $p; break }
}
if ($feishuPath) {
    Write-Host "Found feishu extension: $feishuPath"
    & $openclaw config set plugins.load.paths "[\"$($feishuPath -replace '\\','/')\"]"
} else {
    Write-Host "No local feishu extension folder found."
    Write-Host "Upgrade OpenClaw: openclaw update   (Feishu needs 2026.5.29+ officially)"
}

Write-Host ""
Write-Host "4) Restart gateway and probe"
& $openclaw gateway stop
Start-Sleep -Seconds 3
& $openclaw gateway start
Start-Sleep -Seconds 5
& $openclaw channels status --probe

Write-Host ""
Write-Host "SUCCESS look: channels status shows feishu connected (not only TT)."
Write-Host "Then get REAL chat ids (oc_ followed by long hex), NOT oc_MES / oc_TE placeholders."
Write-Host "Group -> Settings -> chat_id, then rerun setup-robot-daily-both-groups.ps1"
