﻿# Stop the robot from answering every group message.
# After this, it only replies when someone @mentions it.
# The daily "Please update SMT MES issues" cron post is unchanged.
#
# Run: powershell -ExecutionPolicy Bypass -File .\fix-mes-mention.ps1

$ErrorActionPreference = "Stop"
$GroupId = "965235"

function Find-OpenClaw {
    $cmd = Get-Command openclaw -ErrorAction SilentlyContinue
    if ($cmd) {
        if ($cmd.Source -like "*.ps1") {
            $cmdShim = Join-Path (Split-Path $cmd.Source) "openclaw.cmd"
            if (Test-Path $cmdShim) { return $cmdShim }
        }
        return $cmd.Source
    }
    $candidates = @(
        "$env:USERPROFILE\.openclaw\bin\openclaw.cmd",
        "$env:LOCALAPPDATA\Programs\OClaw\resources\openclaw\openclaw.cmd",
        "$env:LOCALAPPDATA\Programs\OClaw\openclaw.cmd",
        "$env:APPDATA\npm\openclaw.cmd"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

$openclaw = Find-OpenClaw
if (-not $openclaw) {
    throw "openclaw not found. Open the OClaw app, then rerun this script."
}

Write-Host "Using: $openclaw"
Write-Host ("Group {0}: requireMention=true (reply only on @mention)" -f $GroupId)

& $openclaw config set ("channels.tt.groups.{0}.requireMention" -f $GroupId) true
if ($LASTEXITCODE -ne 0) { throw "config set requireMention failed: $LASTEXITCODE" }

& $openclaw config set ("channels.tt.groups.{0}.enabled" -f $GroupId) true
if ($LASTEXITCODE -ne 0) { throw "config set enabled failed: $LASTEXITCODE" }

Write-Host "Config saved. Reloading gateway..."
$ErrorActionPreference = "Continue"
& $openclaw gateway stop
Start-Sleep -Seconds 3
& $openclaw gateway start
Start-Sleep -Seconds 5
& $openclaw gateway status
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Done. The robot will not reply to every person."
Write-Host "It replies only when someone @mentions it in the INDIA SMT MES ISSUE group."
Write-Host "The daily 9:00 AM / 9:00 PM reminder still posts on its own."
Write-Host "If gateway status looks stuck, open OClaw Settings and click Restart once."
