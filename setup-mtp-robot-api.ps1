# Wire MTP robot OPPO_MES appId + appSecret into OpenClaw (Feishu/Lark AppRobot channel).
#
# OpenClaw 2026.4.9 note:
#   `openclaw plugins install @openclaw/feishu` FAILS (plugin API needs >=2026.11.8).
#   Fix: load the bundled feishu extension via plugins.load.paths, then set credentials.
#
# Where the values come from (MTP Launch Guide):
#   MTP -> OPPO_MES -> Basic Data / Basic Information -> appId + appSecret
#
# Run on the OClaw PC:
#   powershell -ExecutionPolicy Bypass -File .\setup-mtp-robot-api.ps1 `
#     -AppId "22663" `
#     -AppSecret "xxxxxxxx"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$AppId,
    [Parameter(Mandatory = $true)][string]$AppSecret,
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
    if ($Value -match '^\d{3,}$') { return $true }
    if ($Value -match '(?i)^cli_[A-Za-z0-9]+$' -and $Value.Length -ge 8) { return $true }
    if ($Value.Length -ge 8) { return $true }
    return $false
}

function Test-LooksLikeAppSecret {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    if ($Value -match '(?i)^(YOUR_|PASTE_|xxx|placeholder|example$)') { return $false }
    if ($Value.Length -lt 12) { return $false }
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
if (-not (Test-LooksLikeAppSecret $AppSecret)) {
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
        "$env:LOCALAPPDATA\Programs\OClaw\resources\cli\openclaw.cmd",
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

function Find-BundledFeishu {
    $roots = @()
    if ($env:LOCALAPPDATA) {
        $roots += (Join-Path $env:LOCALAPPDATA "Programs\OClaw")
    }
    if ($env:USERPROFILE) {
        $roots += (Join-Path $env:USERPROFILE ".openclaw")
    }
    $rel = @(
        "resources\openclaw\dist\extensions\feishu",
        "resources\openclaw\extensions\feishu",
        "resources\cli\..\openclaw\dist\extensions\feishu",
        "resources\app\dist\extensions\feishu",
        "dist\extensions\feishu",
        "extensions\feishu"
    )
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        foreach ($r in $rel) {
            $p = [System.IO.Path]::GetFullPath((Join-Path $root $r))
            if (Test-Path (Join-Path $p "package.json")) { return $p }
            if (Test-Path $p) { return $p }
        }
        $hit = Get-ChildItem -Path $root -Directory -Filter "feishu" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName "package.json") } |
            Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Get-OpenClawConfigPath {
    foreach ($p in @(
        (Join-Path $env:USERPROFILE ".openclaw\openclaw.json"),
        (Join-Path $env:USERPROFILE ".openclaw\config.json")
    )) {
        if (Test-Path $p) { return $p }
    }
    $dir = Join-Path $env:USERPROFILE ".openclaw"
    if (-not (Test-Path $dir) -and -not $DryRun) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    return (Join-Path $dir "openclaw.json")
}

function Write-FeishuConfigDirect {
    param(
        [Parameter(Mandatory = $true)][string]$ConfigPath,
        [Parameter(Mandatory = $true)][string]$FeishuPathOrEmpty
    )
    if ($DryRun) {
        Write-Host "[DryRun] would patch $ConfigPath with feishu credentials"
        return
    }

    $obj = $null
    if (Test-Path $ConfigPath) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item $ConfigPath "$ConfigPath.bak-mtp-$stamp" -Force
        $obj = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } else {
        $obj = [pscustomobject]@{}
    }

    # Ensure nested objects exist without wiping unrelated keys.
    if (-not $obj.PSObject.Properties["plugins"]) {
        $obj | Add-Member -NotePropertyName plugins -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    if (-not $obj.plugins.PSObject.Properties["load"]) {
        $obj.plugins | Add-Member -NotePropertyName load -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    if ($FeishuPathOrEmpty) {
        $unix = ($FeishuPathOrEmpty -replace '\\', '/')
        $obj.plugins.load | Add-Member -NotePropertyName paths -NotePropertyValue @($unix) -Force
        Write-Host "Set plugins.load.paths -> $unix"
    }

    if (-not $obj.PSObject.Properties["channels"]) {
        $obj | Add-Member -NotePropertyName channels -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $feishu = [pscustomobject]@{
        enabled         = $true
        domain          = $Domain
        connectionMode  = "websocket"
        appId           = $AppId
        appSecret       = $AppSecret
        groupPolicy     = "open"
        requireMention  = $true
        dmPolicy        = "open"
        accounts        = [pscustomobject]@{
            default = [pscustomobject]@{
                appId     = $AppId
                appSecret = $AppSecret
            }
        }
    }
    if ($MesIssueChatId -or $SmtTeChatId) {
        $groups = [pscustomobject]@{}
        if ($MesIssueChatId) {
            $groups | Add-Member -NotePropertyName $MesIssueChatId -NotePropertyValue ([pscustomobject]@{
                enabled = $true; requireMention = $true
            }) -Force
        }
        if ($SmtTeChatId) {
            $groups | Add-Member -NotePropertyName $SmtTeChatId -NotePropertyValue ([pscustomobject]@{
                enabled = $true; requireMention = $true
            }) -Force
        }
        $feishu | Add-Member -NotePropertyName groups -NotePropertyValue $groups -Force
    }
    $obj.channels | Add-Member -NotePropertyName feishu -NotePropertyValue $feishu -Force

    if (-not $obj.PSObject.Properties["agents"]) {
        $obj | Add-Member -NotePropertyName agents -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    if (-not $obj.agents.PSObject.Properties["defaults"]) {
        $obj.agents | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $obj.agents.defaults | Add-Member -NotePropertyName workspace -NotePropertyValue "~/.openclaw/workspace" -Force

    $json = $obj | ConvertTo-Json -Depth 40
    [System.IO.File]::WriteAllText($ConfigPath, $json)
    Write-Host "Wrote Feishu/MTP credentials into $ConfigPath (secret not printed)"
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
    Write-Host "Credentials were validated. Install/open OClaw and rerun this script."
    if ($DryRun) { exit 0 }
    exit 1
}

Write-Host "Using: $openclaw"
$verText = ""
if (-not $DryRun) {
    $verText = & $openclaw --version 2>&1 | Out-String
    Write-Host $verText.Trim()
} else {
    Write-Host "[DryRun] openclaw --version skipped"
}

$isOld49 = ($verText -match '2026\.4\.')
Write-Host ""
Write-Host "1) Enable Feishu channel plugin..."
if ($isOld49) {
    Write-Host "OpenClaw 2026.4.x detected: npm @openclaw/feishu needs API 2026.11.8+ and will fail."
    Write-Host "Loading bundled feishu via plugins.load.paths instead."
} else {
    Invoke-OpenClaw -Exe $openclaw -Arguments @("plugins", "install", "@openclaw/feishu") -AllowFail | Out-Null
}

$feishuPath = Find-BundledFeishu
if ($feishuPath) {
    Write-Host "Found bundled feishu: $feishuPath"
} else {
    Write-Host "WARN: no bundled feishu extension found under OClaw install."
    Write-Host "Try: openclaw update   (needs 2026.5.29+ / plugin API 2026.11.8+ for npm feishu)"
}

$configPath = Get-OpenClawConfigPath
Write-Host ""
Write-Host "2) Write MTP appId/appSecret (direct config patch — avoids unknown channel id: feishu)..."
Write-FeishuConfigDirect -ConfigPath $configPath -FeishuPathOrEmpty $(if ($feishuPath) { $feishuPath } else { "" })

# Best-effort CLI mirrors (may fail on 2026.4.9 before plugin load; already patched JSON).
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "agents.defaults.workspace", "~/.openclaw/workspace") -AllowFail | Out-Null
if ($feishuPath) {
    $unix = ($feishuPath -replace '\\', '/')
    Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "plugins.load.paths", ("[`"{0}`"]" -f $unix)) -AllowFail | Out-Null
}

# Keep TT group config for personal-channel fallback.
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.tt.enabled", "true") -AllowFail | Out-Null
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", "channels.tt.groupPolicy", "open") -AllowFail | Out-Null
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", ("channels.tt.groups.{0}.enabled" -f $TtGroupId), "true") -AllowFail | Out-Null
Invoke-OpenClaw -Exe $openclaw -Arguments @("config", "set", ("channels.tt.groups.{0}.requireMention" -f $TtGroupId), "true") -AllowFail | Out-Null

Write-Host ""
Write-Host "3) Restart gateway and probe..."
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
Write-Host "If probe still has no feishu on OpenClaw 2026.4.9:"
Write-Host "  1) Confirm a feishu folder exists under OClaw (dist\extensions\feishu)"
Write-Host "  2) Or upgrade: openclaw update   then rerun this script"
Write-Host "  3) Alternate outbound-only path: Feishu Custom Bot webhook (PR mes-robot-webhook)"
Write-Host ""
Write-Host "Why DM said 'Service is busy, please try again later':"
Write-Host "  OPPO_MES was online with no backend. After feishu connects, send hi again."
Write-Host "Watch: openclaw logs --follow"
