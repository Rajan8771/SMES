# One-time setup for the SMT MES auto-reply bot on the OClaw PC.
# Run: powershell -ExecutionPolicy Bypass -File .\setup-mes-bot.ps1

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Source = Join-Path $Root "workspace"
$Dest = Join-Path $env:USERPROFILE ".openclaw\workspace"
$GroupId = "965235"

if (-not (Test-Path $Source)) {
    throw "Missing workspace folder: $Source"
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$files = @("AGENTS.md", "SOUL.md", "IDENTITY.md", "USER.md", "MES.md")
foreach ($name in $files) {
    $from = Join-Path $Source $name
    $to = Join-Path $Dest $name
    if (-not (Test-Path $from)) {
        throw "Missing $from"
    }
    if (Test-Path $to) {
        Copy-Item $to "$to.bak" -Force
    }
    Copy-Item $from $to -Force
    Write-Host "Wrote $to"
}

function Find-OpenClaw {
    $cmd = Get-Command openclaw -ErrorAction SilentlyContinue
    if ($cmd) {
        # The npm PowerShell shim is blocked by the default execution policy.
        if ($cmd.Source -like "*.ps1") {
            $cmdShim = Join-Path (Split-Path $cmd.Source) "openclaw.cmd"
            if (Test-Path $cmdShim) { return $cmdShim }
        }
        return $cmd.Source
    }

    $candidates = @(
        "$env:LOCALAPPDATA\Programs\OClaw\resources\openclaw\openclaw.cmd",
        "$env:LOCALAPPDATA\Programs\OClaw\openclaw.cmd",
        "$env:APPDATA\npm\openclaw.cmd"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) { return $candidate }
    }

    $root = Join-Path $env:LOCALAPPDATA "Programs\OClaw"
    if (Test-Path $root) {
        $found = Get-ChildItem -Path $root -Filter "openclaw.cmd" -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

function Invoke-OpenClaw {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    Write-Host ("openclaw " + ($Arguments -join " "))
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "openclaw exited with code $LASTEXITCODE"
    }
}

$openclaw = Find-OpenClaw
if (-not $openclaw) {
    Write-Host ""
    Write-Host "Workspace files are in place. The openclaw command was not found, so the group switch is not on yet."
    Write-Host "Open the OClaw terminal and run:"
    Write-Host "  openclaw config set agents.defaults.workspace ~/.openclaw/workspace"
    Write-Host "  openclaw config set channels.tt.enabled true"
    Write-Host "  openclaw config set channels.tt.groupPolicy open"
    Write-Host "  openclaw config set channels.tt.groups.$GroupId.enabled true"
    Write-Host "  openclaw config set channels.tt.groups.$GroupId.requireMention false"
    Write-Host "  openclaw gateway restart"
    exit 1
}

Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "agents.defaults.workspace", "~/.openclaw/workspace")
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.tt.enabled", "true")
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.tt.groupPolicy", "open")
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.tt.groups.$GroupId.enabled", "true")
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.tt.groups.$GroupId.requireMention", "false")
Invoke-OpenClaw -Exe $openclaw -Arguments @("gateway", "restart")

Write-Host ""
Write-Host "MES auto-reply is on for TT group $GroupId."
Write-Host "In the INDIA SMT MES ISSUE group send: Glue line 17, final VI, CPU not working since 10:00."
Write-Host "Add real line checks to $Dest\MES.md"
Write-Host "If the TT log says connection closed code=1008, log out of the robot account on the TT desktop and restart OClaw once."
