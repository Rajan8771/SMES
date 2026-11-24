# Called by Windows Task Scheduler at 09:00 and 21:00 India time.
# Posts via Feishu custom-bot webhooks (Robot), never via personal TT.

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here "lib\RobotWebhook.ps1")

$logDir = Join-Path $env:USERPROFILE ".openclaw\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$log = Join-Path $logDir ("robot-webhook-{0}.log" -f (Get-Date -Format "yyyyMMdd"))

function Write-Log([string]$msg) {
    $line = "{0} {1}" -f (Get-Date -Format "o"), $msg
    Add-Content -Path $log -Value $line -Encoding UTF8
    Write-Host $line
}

try {
    Write-Log "START robot webhook daily"
    Send-RobotToBothGroups
    Write-Log "OK sent to both groups"
} catch {
    Write-Log ("FAIL {0}" -f $_.Exception.Message)
    throw
}
