# Point the existing MES cron job at TT group 965235.
# Safe to run more than once. Does not use device pairing.

$ErrorActionPreference = "Stop"
$GroupId = "965235"
$Message = "Send exactly this text and add nothing else: Please update SMT MES issues"
$path = Join-Path $env:USERPROFILE ".openclaw\cron\jobs.json"

if (-not (Test-Path $path)) {
    throw "Cron store not found: $path"
}

function Stop-OpenClawGateway {
    & openclaw gateway stop
    if ($LASTEXITCODE -ne 0) {
        Write-Host "gateway stop returned $LASTEXITCODE. Stopping the Windows login item."
        & schtasks /End /TN "OpenClaw Gateway" | Out-Host
    }
    Start-Sleep -Seconds 4
}

function Start-OpenClawGateway {
    & openclaw gateway start
    if ($LASTEXITCODE -ne 0) {
        Write-Host "gateway start returned $LASTEXITCODE. Starting the Windows login item."
        & schtasks /Run /TN "OpenClaw Gateway" | Out-Host
    }
}

Stop-OpenClawGateway

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item $path "$path.bak-$stamp" -Force
Write-Host "Backup: $path.bak-$stamp"

$raw = Get-Content -Path $path -Raw -Encoding UTF8
$data = $raw | ConvertFrom-Json
$wrapped = $false
if ($data -is [System.Array]) {
    $jobs = $data
} elseif ($null -ne $data.PSObject.Properties["jobs"]) {
    $jobs = @($data.jobs)
    $wrapped = $true
} else {
    throw "jobs.json is not a job list."
}

$mes = @($jobs | Where-Object { $_.name -eq "MES" })
if ($mes.Count -eq 0) {
    throw "No cron job named MES was found."
}
if ($mes.Count -gt 1) {
    throw "More than one cron job is named MES."
}

$job = $mes[0]
Write-Host "Before: channel=$($job.delivery.channel) to=$($job.delivery.to)"

if (-not $job.payload) {
    $job | Add-Member -NotePropertyName payload -NotePropertyValue ([pscustomobject]@{ kind = "agentTurn" })
}
$job.payload | Add-Member -NotePropertyName kind -NotePropertyValue "agentTurn" -Force
$job.payload | Add-Member -NotePropertyName message -NotePropertyValue $Message -Force

if (-not $job.delivery) {
    $job | Add-Member -NotePropertyName delivery -NotePropertyValue ([pscustomobject]@{})
}
$job.delivery | Add-Member -NotePropertyName mode -NotePropertyValue "announce" -Force
$job.delivery | Add-Member -NotePropertyName channel -NotePropertyValue "tt" -Force
$job.delivery | Add-Member -NotePropertyName to -NotePropertyValue $GroupId -Force

$job | Add-Member -NotePropertyName wakeMode -NotePropertyValue "now" -Force
$job | Add-Member -NotePropertyName sessionTarget -NotePropertyValue "isolated" -Force
if ($job.schedule) {
    $job.schedule | Add-Member -NotePropertyName expr -NotePropertyValue "0 9 * * *" -Force
    $job.schedule | Add-Member -NotePropertyName tz -NotePropertyValue "Asia/Calcutta" -Force
}

if ($wrapped) {
    $data.jobs = $jobs
    $out = $data
} else {
    $out = $jobs
}

$json = $out | ConvertTo-Json -Depth 40
[System.IO.File]::WriteAllText($path, $json)
Write-Host "After: channel=tt to=$GroupId"

Start-OpenClawGateway
Write-Host "MES job fixed. In Cron Jobs, click Run on MES."
Write-Host "The group should receive: Please update SMT MES issues"
