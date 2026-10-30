# Start the OpenClaw gateway so the robot can reply and Cron Jobs can open.
# Run: powershell -ExecutionPolicy Bypass -File .\fix-gateway.ps1

$ErrorActionPreference = "Continue"
$PreferredPort = 18789

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

    $root = Join-Path $env:LOCALAPPDATA "Programs\OClaw"
    if (Test-Path $root) {
        $found = Get-ChildItem -Path $root -Filter "openclaw.cmd" -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

function Get-ListeningPorts {
    $ports = @()
    foreach ($port in @(18789, 52813)) {
        $hit = netstat -ano | Select-String -Pattern (":$port\s+") | Select-String "LISTENING"
        if ($hit) { $ports += $port }
    }
    return $ports
}

function Test-HttpPort {
    param([int]$Port)
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/" -UseBasicParsing -TimeoutSec 3
        return $true
    } catch {
        # Connection refused vs other errors: still useful if something answered
        if ($_.Exception.Response) { return $true }
        return $false
    }
}

$openclaw = Find-OpenClaw
if (-not $openclaw) {
    throw "openclaw not found. Open the OClaw app first, then rerun this script."
}
Write-Host "Using: $openclaw"

Write-Host ""
Write-Host "=== gateway status (before) ==="
& $openclaw gateway status
Write-Host "listening ports: $((Get-ListeningPorts) -join ', ')"

Write-Host ""
Write-Host "Setting gateway.port=$PreferredPort"
& $openclaw config set gateway.port $PreferredPort
& $openclaw config set gateway.mode local

Write-Host ""
Write-Host "Starting gateway..."
& $openclaw gateway start
Start-Sleep -Seconds 5

$statusText = (& $openclaw gateway status 2>&1 | Out-String)
Write-Host $statusText

$listening = Get-ListeningPorts
if ($listening.Count -eq 0 -or ($statusText -notmatch "running")) {
    Write-Host "Start did not bring the port up. Reinstalling service and restarting..."
    & $openclaw gateway install --force
    & $openclaw gateway restart
    Start-Sleep -Seconds 8
    if ($LASTEXITCODE -ne 0) {
        schtasks /Run /TN "OpenClaw Gateway" 2>$null | Out-Host
        Start-Sleep -Seconds 5
    }
}

$listening = Get-ListeningPorts
Write-Host ""
Write-Host "=== gateway status (after) ==="
& $openclaw gateway status
Write-Host "listening ports: $($listening -join ', ')"

$url = $null
if ($listening -contains 18789 -or (Test-HttpPort 18789)) {
    $url = "http://127.0.0.1:18789/"
} elseif ($listening -contains 52813 -or (Test-HttpPort 52813)) {
    $url = "http://127.0.0.1:52813/"
}

if (-not $url) {
    Write-Host ""
    Write-Host "Gateway still not listening. Open the OClaw app tray and click Restart."
    Write-Host "Then run: openclaw logs --follow"
    exit 1
}

Write-Host ""
Write-Host "Gateway OK. Opening Control UI: $url"
Start-Process $url
Write-Host "Next: Cron Jobs -> MES -> Run"
Write-Host "Or in TT group 【INDIA】 SMT MES ISSUE send: Glue line 17, final VI, CPU not working since 10:00."
