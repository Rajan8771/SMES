# Check that MTP OPPO_MES credentials are present in OpenClaw Feishu config.
# Does not print secrets. Safe to run any time.
#
#   powershell -ExecutionPolicy Bypass -File .\verify-mtp-robot-api.ps1

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
    )) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    return $null
}

function Get-ConfigPath {
    foreach ($p in @(
        (Join-Path $env:USERPROFILE ".openclaw\openclaw.json"),
        (Join-Path $env:USERPROFILE ".openclaw\config.json")
    )) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

Write-Host "=== Verify MTP OPPO_MES robot API ==="

$openclaw = Find-OpenClaw
if ($openclaw) {
    Write-Host "openclaw: $openclaw"
    & $openclaw --version
    Write-Host ""
    Write-Host "Channel probe:"
    & $openclaw channels status --probe
} else {
    Write-Host "openclaw not found on this machine."
}

$cfgPath = Get-ConfigPath
if (-not $cfgPath) {
    Write-Host "No OpenClaw config file under ~/.openclaw"
    Write-Host "Run setup-mtp-robot-api.ps1 with appId/appSecret from MTP Basic Information."
    exit 1
}

Write-Host ""
Write-Host "Config: $cfgPath"
$raw = Get-Content -Path $cfgPath -Raw -Encoding UTF8
$data = $raw | ConvertFrom-Json

$feishu = $null
if ($data.channels -and $data.channels.feishu) { $feishu = $data.channels.feishu }

$ok = $true
if (-not $feishu) {
    Write-Host "FAIL: channels.feishu missing. Robot API is not set."
    $ok = $false
} else {
    $enabled = $feishu.enabled
    $appId = [string]$feishu.appId
    $appSecret = [string]$feishu.appSecret
    if ((-not $appId) -and $feishu.accounts -and $feishu.accounts.default) {
        $appId = [string]$feishu.accounts.default.appId
        $appSecret = [string]$feishu.accounts.default.appSecret
    }

    Write-Host ("feishu.enabled = {0}" -f $enabled)
    Write-Host ("feishu.domain  = {0}" -f $feishu.domain)
    if ($appId) {
        Write-Host ("appId set     = yes (len={0}, starts={1}...)" -f $appId.Length, $appId.Substring(0, [Math]::Min(4, $appId.Length)))
    } else {
        Write-Host "appId set     = NO  <- paste from MTP Basic Data / Basic Information"
        $ok = $false
    }
    if ($appSecret) {
        Write-Host ("appSecret set = yes (len={0})" -f $appSecret.Length)
    } else {
        Write-Host "appSecret set = NO  <- paste from MTP Basic Data / Basic Information"
        $ok = $false
    }

    $groups = $feishu.groups
    if ($groups) {
        $names = @($groups.PSObject.Properties | ForEach-Object { $_.Name })
        Write-Host ("feishu groups = {0}" -f (($names -join ", ")))
    } else {
        Write-Host "feishu groups = (none yet) - add oc_ chat ids after robot joins the groups"
    }
}

Write-Host ""
if ($ok) {
    Write-Host "PASS: MTP robot API credentials are present."
    Write-Host "If probe does not show feishu connected, check MTP robot permissions + event subscription, then: openclaw gateway restart"
    exit 0
} else {
    Write-Host "FAIL: complete MTP Basic Information (appId/appSecret), then run setup-mtp-robot-api.ps1"
    exit 1
}
