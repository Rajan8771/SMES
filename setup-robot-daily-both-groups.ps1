﻿# Daily AppRobot reminder in BOTH groups at 9:00 AM and 9:00 PM India time.
# Message: Please update SMT MES issues
# Must send as Feishu/Lark AppRobot (Robot badge), NOT personal IN008771.
#
# You need each group's Feishu chat_id (oc_...). Group -> Settings -> chat_id.
#
# Example:
#   powershell -ExecutionPolicy Bypass -File .\setup-robot-daily-both-groups.ps1 `
#     -MesIssueChatId "oc_aaa" -SmtTeChatId "oc_bbb"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$MesIssueChatId,
    [Parameter(Mandatory = $true)][string]$SmtTeChatId,
    [string]$Channel = "feishu",
    [string]$CronExpr = "0 9,21 * * *",
    [string]$TimeZone = "Asia/Calcutta"
)

$ErrorActionPreference = "Stop"
$Prompt = "Send exactly this text and add nothing else: Please update SMT MES issues"
$path = Join-Path $env:USERPROFILE ".openclaw\cron\jobs.json"

foreach ($id in @($MesIssueChatId, $SmtTeChatId)) {
    if (-not $id.StartsWith("oc_")) {
        throw "Chat id must look like oc_.... Got: $id. Open group Settings and copy chat_id."
    }
    if ($id -match '^oc_(MES|TE|xxx|YOUR)' -or $id.Length -lt 10) {
        throw "Placeholder chat id refused: $id. Use the real Feishu chat_id from group Settings (long oc_... value)."
    }
}

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
        "$env:LOCALAPPDATA\Programs\OClaw\resources\openclaw\openclaw.cmd"
    )) { if (Test-Path $c) { return $c } }
    return $null
}

function New-MesJob {
    param([string]$Name, [string]$To)
    return [pscustomobject]@{
        name = $Name
        enabled = $true
        schedule = [pscustomobject]@{ kind = "cron"; expr = $CronExpr; tz = $TimeZone }
        sessionTarget = "isolated"
        wakeMode = "now"
        payload = [pscustomobject]@{ kind = "agentTurn"; message = $Prompt }
        delivery = [pscustomobject]@{ mode = "announce"; channel = $Channel; to = $To }
    }
}

$openclaw = Find-OpenClaw
if (-not $openclaw) { throw "openclaw not found" }

Write-Host "Using: $openclaw"
Write-Host "Channel: $Channel"
Write-Host "Schedule: $CronExpr ($TimeZone) -> both groups"

# Feishu plugin must exist first (OpenClaw 2026.4.x often lacks it until installed).
Write-Host "Checking Feishu channel plugin..."
$probe = & $openclaw channels status 2>&1 | Out-String
if ($probe -notmatch "feishu") {
    Write-Host "Feishu not listed. Installing plugin / starting login wizard..."
    & $openclaw plugins install "@openclaw/feishu"
    Write-Host "Run next (interactive App ID/Secret): openclaw channels login --channel feishu"
    Write-Host "Or: powershell -File .\install-feishu-channel.ps1"
    throw "channels.feishu is unknown until the Feishu plugin is installed and logged in. Fix that first, then rerun this script with real oc_ chat ids."
}

# Ensure Feishu is the outbound path for AppRobot.
& $openclaw config set channels.feishu.enabled true
if ($LASTEXITCODE -ne 0) {
    throw "Cannot set channels.feishu (unknown channel). Install Feishu plugin first: install-feishu-channel.ps1"
}
& $openclaw config set channels.feishu.groupPolicy open
& $openclaw config set ("channels.feishu.groups.{0}.enabled" -f $MesIssueChatId) true
& $openclaw config set ("channels.feishu.groups.{0}.enabled" -f $SmtTeChatId) true

$ErrorActionPreference = "Continue"
& $openclaw gateway stop
Start-Sleep -Seconds 3
$ErrorActionPreference = "Stop"

if (-not (Test-Path $path)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
    [System.IO.File]::WriteAllText($path, '{ "version": 1, "jobs": [] }')
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item $path "$path.bak-both-$stamp" -Force

$raw = Get-Content -Path $path -Raw -Encoding UTF8
$data = $raw | ConvertFrom-Json
$wrapped = $true
if ($data -is [System.Array]) {
    $jobs = [System.Collections.ArrayList]@($data)
    $wrapped = $false
} elseif ($null -ne $data.PSObject.Properties["jobs"]) {
    $jobs = [System.Collections.ArrayList]@($data.jobs)
} else {
    throw "jobs.json format unknown"
}

# Disable old personal-TT MES jobs so IN008771 stops posting.
$keep = [System.Collections.ArrayList]@()
foreach ($job in $jobs) {
    $n = [string]$job.name
    if ($n -eq "MES" -or $n -like "MES daily*") {
        Write-Host "Removing old job: $n"
        continue
    }
    [void]$keep.Add($job)
}

[void]$keep.Add((New-MesJob -Name "MES daily MES ISSUE" -To $MesIssueChatId))
[void]$keep.Add((New-MesJob -Name "MES daily SMT TE" -To $SmtTeChatId))

if ($wrapped) {
    $data.jobs = @($keep.ToArray())
    $out = $data
} else {
    $out = @($keep.ToArray())
}
[System.IO.File]::WriteAllText($path, ($out | ConvertTo-Json -Depth 40))

$ErrorActionPreference = "Continue"
& $openclaw gateway start
Start-Sleep -Seconds 5
& $openclaw channels status --probe
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Jobs ready:"
Write-Host ("  - MES daily MES ISSUE -> {0}" -f $MesIssueChatId)
Write-Host ("  - MES daily SMT TE -> {0}" -f $SmtTeChatId)
Write-Host "Times: 9:00 AM and 9:00 PM India"
Write-Host "Text: Please update SMT MES issues"
Write-Host ""
Write-Host "In Control UI -> Cron Jobs, click Run on each job once to test."
Write-Host "Expect Robot badge + Content generated by AI (not your green bubble)."
Write-Host "If still personal: Feishu AppRobot App ID/Secret is not the logged-in channel."
Write-Host "  openclaw channels login --channel feishu"
