# Honest fix: @RAJAN SUMAN AppRobot lives on Feishu/Lark, not on personal TT login.
# channels.tt can NEVER answer an @ to that AppRobot. Connect Feishu with the robot app.
#
# What you need before running:
#   1. Feishu/Lark Open Platform App ID + App Secret for the AppRobot
#   2. Group chat_id from group Settings (starts with oc_)
#
# Run:
#   powershell -ExecutionPolicy Bypass -File .\fix-feishu-robot-reply.ps1 -ChatId "oc_xxxxxxxx"
#
# Login is interactive:
#   openclaw channels login --channel feishu

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ChatId = ""
)

$ErrorActionPreference = "Stop"

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
    )) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

Write-Host "=== Why @hello gets no reply ==="
Write-Host "Group UI tags AppRobot (BOT badge). OpenClaw was using channels.tt (personal TT)."
Write-Host "An @ to the AppRobot is a Feishu/Lark event. TT config does not receive it."
Write-Host "So requireMention / mentionPatterns on channels.tt cannot fix this."
Write-Host ""

$openclaw = Find-OpenClaw
if (-not $openclaw) { throw "openclaw not found" }
Write-Host "Using: $openclaw"
Write-Host ""

Write-Host "Step 1: Connect the AppRobot Feishu/Lark app (interactive)."
Write-Host "  Choose MANUAL setup. Paste App ID + App Secret for the AppRobot."
Write-Host "  Do NOT use personal QR / IN008771."
Write-Host "Starting: openclaw channels login --channel feishu"
Write-Host ""
& $openclaw channels login --channel feishu
if ($LASTEXITCODE -ne 0) {
    throw "Feishu login failed or was cancelled. Without App ID/Secret, @ reply cannot work."
}

Write-Host ""
Write-Host "Step 2: Group settings for tagged replies (anyone who @ the robot)."
& $openclaw config set channels.feishu.enabled true
& $openclaw config set channels.feishu.groupPolicy open
& $openclaw config set channels.feishu.requireMention true

if ($ChatId -and $ChatId.StartsWith("oc_")) {
    & $openclaw config set ("channels.feishu.groups.{0}.enabled" -f $ChatId) true
    & $openclaw config set ("channels.feishu.groups.{0}.requireMention" -f $ChatId) true
    Write-Host ("Enabled Feishu group {0}" -f $ChatId)
} else {
    Write-Host "No -ChatId given. After login, open the group -> Settings, copy chat_id (oc_...)."
    Write-Host "Then rerun:"
    Write-Host '  powershell -ExecutionPolicy Bypass -File .\fix-feishu-robot-reply.ps1 -ChatId "oc_xxx"'
}

Write-Host ""
Write-Host "Step 3: Restart gateway"
$ErrorActionPreference = "Continue"
& $openclaw gateway stop
Start-Sleep -Seconds 3
& $openclaw gateway start
Start-Sleep -Seconds 5
& $openclaw channels status --probe
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Test in the group: @ the AppRobot then hello"
Write-Host "Watch logs: openclaw logs --follow"
Write-Host "You must see Feishu inbound for the @. If only tt lines appear, Feishu is still not connected."
Write-Host ""
Write-Host "LIMIT: Without Feishu App ID/Secret for this AppRobot, this cannot be fixed from TT alone."
