# STOP the daily MES reminder that posts as your personal TT id (IN008771).
# Until Feishu AppRobot is connected, cron announce on channels.tt = YOUR green bubble.
#
# Run:
#   powershell -ExecutionPolicy Bypass -File .\stop-personal-mes-cron.ps1

$ErrorActionPreference = "Stop"
$path = Join-Path $env:USERPROFILE ".openclaw\cron\jobs.json"
if (-not (Test-Path $path)) { throw "Missing $path" }

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

Write-Host "Stopping personal-TT MES announce (this was posting as YOUR id)..."

$openclaw = Find-OpenClaw
if ($openclaw) {
    $ErrorActionPreference = "Continue"
    & $openclaw gateway stop
    Start-Sleep -Seconds 3
    $ErrorActionPreference = "Stop"
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item $path "$path.bak-stop-$stamp" -Force

$raw = Get-Content -Path $path -Raw -Encoding UTF8
$data = $raw | ConvertFrom-Json
$wrapped = $false
if ($data -is [System.Array]) { $jobs = $data }
elseif ($null -ne $data.PSObject.Properties["jobs"]) { $jobs = @($data.jobs); $wrapped = $true }
else { throw "jobs.json format unknown" }

$changed = 0
foreach ($job in $jobs) {
    $name = [string]$job.name
    $isMes = ($name -eq "MES") -or ($name -like "*MES*morning*") -or ($name -like "*MES*update*")
    if (-not $isMes) { continue }

    if ($job.PSObject.Properties.Name -contains "enabled") {
        $job.enabled = $false
    } else {
        $job | Add-Member -NotePropertyName enabled -NotePropertyValue $false -Force
    }

    if (-not $job.delivery) {
        $job | Add-Member -NotePropertyName delivery -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $job.delivery | Add-Member -NotePropertyName mode -NotePropertyValue "none" -Force
    Write-Host ("Disabled job: {0} (was channel={1} to={2})" -f $name, $job.delivery.channel, $job.delivery.to)
    $changed++
}

if ($changed -eq 0) { throw "No MES cron job found to disable." }

if ($wrapped) { $data.jobs = $jobs; $out = $data } else { $out = $jobs }
[System.IO.File]::WriteAllText($path, ($out | ConvertTo-Json -Depth 40))

if ($openclaw) {
    $ErrorActionPreference = "Continue"
    & $openclaw gateway start
    Start-Sleep -Seconds 4
    $ErrorActionPreference = "Stop"
}

Write-Host ""
Write-Host "Done. Daily text will NOT post as IN008771 anymore."
Write-Host "AppRobot daily post needs Feishu App ID+Secret, then fix-feishu-robot-reply.ps1."
