# Bring the OClaw gateway back up on the Control UI port (18789).
# Safe to run more than once. No Git required.
# Run: powershell -ExecutionPolicy Bypass -File .\fix-gateway.ps1

$ErrorActionPreference = "Continue"
$PreferredPort = 18789
$AltPort = 52813
$OpenBrowser = $true

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
        "$env:USERPROFILE\.openclaw\bin\openclaw.cmd",
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
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFail
    )
    Write-Host ("openclaw " + ($Arguments -join " "))
    & $Exe @Arguments
    $code = $LASTEXITCODE
    if (-not $AllowFail -and $code -ne 0) {
        throw "openclaw exited with code $code"
    }
    return $code
}

function Get-ListeningPorts {
    param([int[]]$Ports)
    $listening = @{}
    foreach ($port in $Ports) { $listening[$port] = $false }

    $lines = @()
    try {
        $lines = netstat -ano -p tcp 2>$null
    } catch {
        Write-Host "netstat failed: $_"
        return $listening
    }

    foreach ($line in $lines) {
        if ($line -notmatch "LISTENING") { continue }
        foreach ($port in $Ports) {
            if ($line -match ":$port\s") {
                $listening[$port] = $true
            }
        }
    }
    return $listening
}

function Test-GatewayUp {
    param(
        [Parameter(Mandatory = $true)][string]$Exe
    )
    $statusText = ""
    try {
        $statusText = & $Exe @("gateway", "status", "--json") 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -and $statusText) {
            if ($statusText -match '"running"\s*:\s*true' -or
                $statusText -match '"status"\s*:\s*"(running|ok|up|active)"' -or
                $statusText -match '"state"\s*:\s*"(running|ok|up|active)"') {
                return $true
            }
            if ($statusText -match '"running"\s*:\s*false') {
                return $false
            }
        }
    } catch {
        # --json may not exist on older builds; fall through to plain status.
    }

    $plain = & $Exe @("gateway", "status") 2>&1 | Out-String
    Write-Host $plain.Trim()
    if ($LASTEXITCODE -ne 0) { return $false }
    if ($plain -match "(?i)not running|stopped|inactive|down|offline") { return $false }
    if ($plain -match "(?i)running|listening|active|ok|up") { return $true }

    $ports = Get-ListeningPorts -Ports @($PreferredPort, $AltPort)
    return ($ports[$PreferredPort] -or $ports[$AltPort])
}

function Wait-ForGateway {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [int]$Seconds = 20
    )
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 2
        if (Test-GatewayUp -Exe $Exe) { return $true }
    }
    return (Test-GatewayUp -Exe $Exe)
}

function Get-ConfiguredGatewayPort {
    param([Parameter(Mandatory = $true)][string]$Exe)
    try {
        $out = & $Exe @("config", "get", "gateway.port") 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -and $out -match "(\d{2,5})") {
            return [int]$Matches[1]
        }
    } catch {}
    return $null
}

function Align-GatewayPort {
    param([Parameter(Mandatory = $true)][string]$Exe)
    $current = Get-ConfiguredGatewayPort -Exe $Exe
    if ($null -ne $current) {
        Write-Host "Configured gateway.port = $current"
    } else {
        Write-Host "Could not read gateway.port from config (will still set $PreferredPort)."
    }

    if ($null -ne $current -and $current -eq $PreferredPort) {
        return $false
    }

    Write-Host ""
    Write-Host "Aligning gateway.port to $PreferredPort so Control UI matches http://127.0.0.1:$PreferredPort/"
    Write-Host "This updates local OpenClaw config and reinstalls the Windows gateway login item (--force)."
    Invoke-OpenClaw -Exe $Exe -Arguments @("config", "set", "gateway.port", "$PreferredPort") -AllowFail | Out-Null
    Invoke-OpenClaw -Exe $Exe -Arguments @("gateway", "install", "--force") -AllowFail | Out-Null
    Invoke-OpenClaw -Exe $Exe -Arguments @("gateway", "restart") -AllowFail | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "gateway restart returned $LASTEXITCODE. Trying schtasks OpenClaw Gateway."
        & schtasks /End /TN "OpenClaw Gateway" 2>$null | Out-Host
        Start-Sleep -Seconds 2
        & schtasks /Run /TN "OpenClaw Gateway" 2>$null | Out-Host
    }
    return $true
}

# --- main ---

$openclaw = Find-OpenClaw
if (-not $openclaw) {
    Write-Host "openclaw.cmd was not found."
    Write-Host "Open the OClaw app, then run this script again from PowerShell."
    exit 1
}
Write-Host "Using: $openclaw"
Write-Host ""

$up = Test-GatewayUp -Exe $openclaw
if (-not $up) {
    Write-Host "Gateway is not running. Starting..."
    Invoke-OpenClaw -Exe $openclaw -Arguments @("gateway", "start") -AllowFail | Out-Null
    if (-not (Wait-ForGateway -Exe $openclaw -Seconds 20)) {
        Write-Host "Still down after start. Trying gateway install, then restart..."
        Invoke-OpenClaw -Exe $openclaw -Arguments @("gateway", "install") -AllowFail | Out-Null
        Invoke-OpenClaw -Exe $openclaw -Arguments @("gateway", "restart") -AllowFail | Out-Null
        if (-not (Wait-ForGateway -Exe $openclaw -Seconds 20)) {
            Write-Host "CLI restart did not bring the gateway up. Using Windows task: OpenClaw Gateway"
            & schtasks /End /TN "OpenClaw Gateway" 2>$null | Out-Host
            Start-Sleep -Seconds 3
            & schtasks /Run /TN "OpenClaw Gateway" 2>$null | Out-Host
            Wait-ForGateway -Exe $openclaw -Seconds 25 | Out-Null
        }
    }
} else {
    Write-Host "Gateway status looks up."
}

$ports = Get-ListeningPorts -Ports @($PreferredPort, $AltPort)
Write-Host ""
Write-Host "Listening check:"
Write-Host "  port $PreferredPort : $(if ($ports[$PreferredPort]) { 'YES' } else { 'no' })"
Write-Host "  port $AltPort : $(if ($ports[$AltPort]) { 'YES' } else { 'no' })"

# Prefer 18789. If only the alternate port is listening, or config points elsewhere, align.
$needAlign = $false
$configPort = Get-ConfiguredGatewayPort -Exe $openclaw
if ($ports[$AltPort] -and -not $ports[$PreferredPort]) {
    $needAlign = $true
} elseif ($null -ne $configPort -and $configPort -ne $PreferredPort) {
    $needAlign = $true
}

if ($needAlign) {
    Align-GatewayPort -Exe $openclaw | Out-Null
    Wait-ForGateway -Exe $openclaw -Seconds 25 | Out-Null
    $ports = Get-ListeningPorts -Ports @($PreferredPort, $AltPort)
    Write-Host ""
    Write-Host "Listening check after port align:"
    Write-Host "  port $PreferredPort : $(if ($ports[$PreferredPort]) { 'YES' } else { 'no' })"
    Write-Host "  port $AltPort : $(if ($ports[$AltPort]) { 'YES' } else { 'no' })"
}

$uiUrl = $null
if ($ports[$PreferredPort]) {
    $uiUrl = "http://127.0.0.1:$PreferredPort/"
} elseif ($ports[$AltPort]) {
    $uiUrl = "http://127.0.0.1:$AltPort/"
    Write-Host "Preferred port $PreferredPort is still closed; Control UI may be on $AltPort."
}

Write-Host ""
if ($uiUrl) {
    Write-Host "Control UI: $uiUrl"
    if ($OpenBrowser) {
        try {
            Start-Process $uiUrl
        } catch {
            Write-Host "Could not open the browser automatically. Paste the URL above."
        }
    }
} else {
    Write-Host "Gateway still does not appear to be listening on $PreferredPort or $AltPort."
    Write-Host "Open the OClaw app once, then run this script again."
    Write-Host "Fallback URL to try: http://127.0.0.1:$PreferredPort/"
    exit 1
}

Write-Host ""
Write-Host "Next: in Control UI open Cron Jobs, select MES, click Run (one test message)."
Write-Host "Daily schedule should be: 0 9,21 * * *  timezone Asia/Calcutta  to group 965235"
Write-Host "If MES is missing or points at the wrong group, run fix-mes-job.ps1 after the gateway is up."
