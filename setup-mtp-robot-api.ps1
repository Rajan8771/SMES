# Wire MTP robot OPPO_MES appId + appSecret into OpenClaw (Feishu/Lark AppRobot channel).
#
# Where the values come from (MTP Launch Guide screenshot):
#   1. Open MTP -> OPPO_MES (robot, online)
#   2. Launch Guide -> "Basic Data" -> edit
#      OR sidebar -> Basic Information
#   3. Copy appId and appSecret
#   4. (Optional) robot card -> Access Guide for message API docs
#
# Run on the OClaw PC:
#   powershell -ExecutionPolicy Bypass -File .\setup-mtp-robot-api.ps1 `
#     -AppId "cli_xxxxxxxx" `
#     -AppSecret "xxxxxxxx" `
#     -MesIssueChatId "oc_xxxxxxxx" `
#     -SmtTeChatId "oc_xxxxxxxx"
#
# Chat ids are optional on first run. Add them later after the robot is in each group:
#   Group Settings -> copy chat_id (starts with oc_)

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$AppId,
    [Parameter(Mandatory = $true)][string]$AppSecret,
    # feishu (China), lark (intl), or a custom https:// API base if MTP uses one
    [string]$Domain = "feishu",
    [string]$MesIssueChatId = "",
    [string]$SmtTeChatId = "",
    [string]$TtGroupId = "965235",
    [switch]$SkipWorkspaceCopy,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Test-LooksLikeAppId {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    if ($Value -match '(?i)^(YOUR|PASTE|xxx|placeholder|example)') { return $false }
    if ($Value.Length -lt 8) { return $false }
    return $true
}

function Test-LooksLikeChatId {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    return ($Value -match '^oc_[A-Za-z0-9]+$' -and $Value.Length -gt 10)
}

if (-not (Test-LooksLikeAppId $AppId)) {
    throw "AppId looks empty or like a placeholder. Copy the real appId from MTP Basic Information / Basic Data."
}
if (-not (Test-LooksLikeAppId $AppSecret)) {
    throw "AppSecret looks empty or like a placeholder. Copy the real appSecret from MTP Basic Information / Basic Data."
}
if (-not (Test-LooksLikeChatId $MesIssueChatId)) {
    throw "MesIssueChatId must be empty or a real oc_... chat id from group Settings."
}
if (-not (Test-LooksLikeChatId $SmtTeChatId)) {
    throw "SmtTeChatId must be empty or a real oc_... chat id from group Settings."
}

Write-Host "=== MTP OPPO_MES robot API setup ==="
Write-Host "AppId length: $($AppId.Length) (value not printed)"
Write-Host "AppSecret length: $($AppSecret.Length) (value not printed)"
Write-Host "Domain: $Domain"
if ($MesIssueChatId) { Write-Host "MES ISSUE chat: $MesIssueChatId" } else { Write-Host "MES ISSUE chat: (skip for now)" }
if ($SmtTeChatId) { Write-Host "SMT TE chat: $SmtTeChatId" } else { Write-Host "SMT TE chat: (skip for now)" }

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
        "$env:LOCALAPPDATA\Programs\OClaw\openclaw.cmd",
        "$env:APPDATA\npm\openclaw.cmd"
    )) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    if ($env:LOCALAPPDATA) {
        $root = Join-Path $env:LOCALAPPDATA "Programs\OClaw"
        if (Test-Path $root) {
            $found = Get-ChildItem -Path $root -Filter "openclaw.cmd" -Recurse -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($found) { return $found.FullName }
        }
    }
    return $null
}

function Invoke-OpenClaw {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFail
    )
    Write-Host ("openclaw " + ($Arguments -join " "))
    if ($DryRun) {
        Write-Host "[DryRun] skipped"
        return 0
    }
    & $Exe @Arguments
    $code = $LASTEXITCODE
    if (-not $AllowFail -and $code -ne 0) {
        throw "openclaw exited with code $code"
    }
    return $code
}

# --- Copy workspace agent files (MES reply rules) ---
if (-not $SkipWorkspaceCopy) {
    $Root = Split-Path -Parent $MyInvocation.MyCommand.Path
    $Source = Join-Path $Root "workspace"
    $Dest = Join-Path $env:USERPROFILE ".openclaw\workspace"
    if (Test-Path $Source) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $Dest | Out-Null
        }
        foreach ($name in @("AGENTS.md", "SOUL.md", "IDENTITY.md", "USER.md", "MES.md")) {
            $from = Join-Path $Source $name
            $to = Join-Path $Dest $name
            if (-not (Test-Path $from)) { continue }
            Write-Host "Workspace: $name -> $to"
            if (-not $DryRun) {
                if (Test-Path $to) { Copy-Item $to "$to.bak" -Force }
                Copy-Item $from $to -Force
            }
        }
    } else {
        Write-Host "No workspace\ folder next to this script - skip copy."
    }
}

$openclaw = Find-OpenClaw
if (-not $openclaw) {
    Write-Host ""
    Write-Host "openclaw was not found on PATH."
    Write-Host "Credentials were validated. On the OClaw PC, install/open OClaw and rerun, or paste:"
    Write-Host "  openclaw plugins install @openclaw/feishu"
    Write-Host ("  openclaw config set channels.feishu.enabled true")
    Write-Host ("  openclaw config set channels.feishu.domain {0}" -f $Domain)
    Write-Host ("  openclaw config set channels.feishu.appId `"YOUR_APP_ID`"")
    Write-Host ("  openclaw config set channels.feishu.appSecret `"YOUR_APP_SECRET`"")
    Write-Host ("  openclaw config set channels.feishu.accounts.default.appId `"YOUR_APP_ID`"")
    Write-Host ("  openclaw config set channels.feishu.accounts.default.appSecret `"YOUR_APP_SECRET`"")
    Write-Host "  openclaw config set channels.feishu.groupPolicy open"
    Write-Host "  openclaw config set channels.feishu.requireMention true"
    Write-Host "  openclaw gateway restart"
    Write-Host "  openclaw channels status --probe"
    if ($DryRun) { exit 0 }
    exit 1
}

Write-Host "Using: $openclaw"
Invoke-OpenClaw -Exe $openclaw -Arguments @("--version") -AllowFail | Out-Null

Write-Host ""
Write-Host "1) Install Feishu plugin (needed for AppRobot API)..."
Invoke-OpenClaw -Exe $openclaw -Arguments @("plugins", "install", "@openclaw/feishu") -AllowFail | Out-Null

Write-Host ""
Write-Host "2) Write MTP appId/appSecret into channels.feishu..."
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "agents.defaults.workspace", "~/.openclaw/workspace")
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.feishu.enabled", "true")
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.feishu.domain", $Domain)
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.feishu.connectionMode", "websocket")
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.feishu.appId", $AppId)
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.feishu.appSecret", $AppSecret)
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.feishu.accounts.default.appId", $AppId)
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.feishu.accounts.default.appSecret", $AppSecret)
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.feishu.groupPolicy", "open")
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.feishu.requireMention", "true")
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.feishu.dmPolicy", "pairing")

# Keep TT group config for personal-channel fallback (do not use TT for AppRobot send).
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.tt.enabled", "true") -AllowFail | Out-Null
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.tt.groupPolicy", "open") -AllowFail | Out-Null
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", ("channels.tt.groups.{0}.enabled" -f $TtGroupId), "true") -AllowFail | Out-Null
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", ("channels.tt.groups.{0}.requireMention" -f $TtGroupId), "true") -AllowFail | Out-Null

if ($MesIssueChatId) {
    Write-Host ""
    Write-Host "3) Enable MES ISSUE group $MesIssueChatId"
    Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", ("channels.feishu.groups.{0}.enabled" -f $MesIssueChatId), "true")
    Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", ("channels.feishu.groups.{0}.requireMention" -f $MesIssueChatId), "true")
}
if ($SmtTeChatId) {
    Write-Host ""
    Write-Host "3b) Enable SMT TE group $SmtTeChatId"
    Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", ("channels.feishu.groups.{0}.enabled" -f $SmtTeChatId), "true")
    Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", ("channels.feishu.groups.{0}.requireMention" -f $SmtTeChatId), "true")
}

Write-Host ""
Write-Host "4) Restart gateway and probe..."
$ErrorActionPreference = "Continue"
Invoke-OpenClaw -Exe $openclaw -Arguments @("gateway", "stop") -AllowFail | Out-Null
Start-Sleep -Seconds 3
Invoke-OpenClaw -Exe $openclaw -Arguments @("gateway", "start") -AllowFail | Out-Null
Start-Sleep -Seconds 5
Invoke-OpenClaw -Exe $openclaw -Arguments @("channels", "status", "--probe") -AllowFail | Out-Null
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Done ==="
Write-Host "SUCCESS look: channels status shows feishu connected (not only personal TT)."
Write-Host ""
Write-Host "Still on MTP (recommended):"
Write-Host "  - Basic Information: confirm app is online"
Write-Host "  - robot Access Guide: enable receive/send message permissions"
Write-Host "  - Event subscription: im.message.receive_v1 (WebSocket / long connection)"
Write-Host "  - Add OPPO_MES robot into 【INDIA】SMT MES ISSUE and INDIA SMT TE"
Write-Host ""
Write-Host "Then copy each group chat_id (oc_...) and rerun with -MesIssueChatId / -SmtTeChatId."
Write-Host "Test: in the group @ the robot with a fault line, e.g. Glue line 17, final VI, CPU not working."
Write-Host "Watch: openclaw logs --follow"
