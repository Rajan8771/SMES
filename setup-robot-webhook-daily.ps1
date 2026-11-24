# FASTEST way to send daily MES reminder as ROBOT (not personal IN008771).
#
# Why this works: Feishu/Lark Custom Bot webhook. OpenClaw TT is not used,
# so green personal bubbles stop. Message shows Robot badge in the group.
#
# Steps (2 minutes):
# 1) Open 【INDIA】SMT MES ISSUE -> group Settings -> Bots -> Add -> Custom bot
#    Name it e.g. MES Daily Robot (or RAJAN SUMAN的小龙虾). Copy webhook URL.
# 2) Same for INDIA SMT TE. Copy second webhook URL.
# 3) Run this script with both URLs. It will:
#      - stop personal OpenClaw MES cron (IN008771)
#      - save webhooks
#      - schedule 9:00 AM + 9:00 PM India
#      - SEND NOW so you can verify Robot badge immediately
#
# Example:
#   powershell -ExecutionPolicy Bypass -File .\setup-robot-webhook-daily.ps1 `
#     -MesIssueWebhook "https://open.feishu.cn/open-apis/bot/v2/hook/AAAA" `
#     -SmtTeWebhook "https://open.feishu.cn/open-apis/bot/v2/hook/BBBB"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$MesIssueWebhook,
    [Parameter(Mandatory = $true)][string]$SmtTeWebhook,
    [string]$Text = "Please update SMT MES issues",
    [string]$InstallDir = ""
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here "lib\RobotWebhook.ps1")

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

function Stop-PersonalMesCron {
    $path = Join-Path $env:USERPROFILE ".openclaw\cron\jobs.json"
    if (-not (Test-Path $path)) {
        Write-Host "No OpenClaw cron file yet - skip personal stop."
        return
    }

    $openclaw = Find-OpenClaw
    if ($openclaw) {
        $ErrorActionPreference = "Continue"
        & $openclaw gateway stop 2>$null | Out-Null
        Start-Sleep -Seconds 2
        $ErrorActionPreference = "Stop"
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $path "$path.bak-webhook-$stamp" -Force

    $raw = Get-Content -Path $path -Raw -Encoding UTF8
    $data = $raw | ConvertFrom-Json
    $wrapped = $false
    if ($data -is [System.Array]) { $jobs = $data }
    elseif ($null -ne $data.PSObject.Properties["jobs"]) { $jobs = @($data.jobs); $wrapped = $true }
    else { Write-Host "cron jobs.json format unknown - skip"; return }

    $changed = 0
    foreach ($job in $jobs) {
        $name = [string]$job.name
        $chan = ""
        if ($job.delivery -and $job.delivery.channel) { $chan = [string]$job.delivery.channel }
        $isMes = ($name -eq "MES") -or ($name -like "*MES*") -or ($name -like "*SMT*")
        $isTt = ($chan -eq "tt" -or $chan -eq "")
        if (-not $isMes) { continue }
        # Disable TT (personal) MES announce jobs; leave other non-TT alone.
        if (-not $isTt -and $chan -ne "tt") {
            # still disable old MES announce so only webhook sends daily text
            if ($job.delivery -and [string]$job.delivery.mode -eq "announce") {
                # continue to disable
            } else {
                continue
            }
        }

        if ($job.PSObject.Properties.Name -contains "enabled") { $job.enabled = $false }
        else { $job | Add-Member -NotePropertyName enabled -NotePropertyValue $false -Force }

        if (-not $job.delivery) {
            $job | Add-Member -NotePropertyName delivery -NotePropertyValue ([pscustomobject]@{ mode = "none" }) -Force
        } else {
            if ($job.delivery.PSObject.Properties.Name -contains "mode") { $job.delivery.mode = "none" }
            else { $job.delivery | Add-Member -NotePropertyName mode -NotePropertyValue "none" -Force }
        }
        $changed++
        Write-Host ("Disabled personal/OpenClaw cron job: {0}" -f $name)
    }

    if ($wrapped) { $data.jobs = @($jobs); $out = $data } else { $out = @($jobs) }
    ($out | ConvertTo-Json -Depth 20) | Set-Content -Path $path -Encoding UTF8
    Write-Host ("Personal MES cron disabled count={0}" -f $changed)

    if ($openclaw) {
        $ErrorActionPreference = "Continue"
        & $openclaw gateway start 2>$null | Out-Null
        $ErrorActionPreference = "Stop"
    }
}

function Install-RobotScripts {
    param([string]$Target)
    if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Path $Target | Out-Null }
    $lib = Join-Path $Target "lib"
    if (-not (Test-Path $lib)) { New-Item -ItemType Directory -Path $lib | Out-Null }

    Copy-Item (Join-Path $here "lib\RobotWebhook.ps1") (Join-Path $lib "RobotWebhook.ps1") -Force
    Copy-Item (Join-Path $here "run-robot-webhook-daily.ps1") (Join-Path $Target "run-robot-webhook-daily.ps1") -Force
    Copy-Item (Join-Path $here "send-robot-now.ps1") (Join-Path $Target "send-robot-now.ps1") -Force
    Write-Host ("Installed runner scripts under {0}" -f $Target)
    return $Target
}

function Register-IndiaDailyTasks {
    param([string]$RunnerPath)

    $taskName = "SMES-MES-Robot-Webhook"
    $ps = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$RunnerPath`""

    # Remove old task if present
    $ErrorActionPreference = "Continue"
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    $ErrorActionPreference = "Stop"

    $action = New-ScheduledTaskAction -Execute $ps -Argument $arg
    $t1 = New-ScheduledTaskTrigger -Daily -At 9:00AM
    $t2 = New-ScheduledTaskTrigger -Daily -At 9:00PM
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($t1, $t2) -Settings $settings -Principal $principal -Force | Out-Null
    Write-Host ("Scheduled task '{0}' -> 09:00 and 21:00 (PC local clock)." -f $taskName)
    Write-Host "Factory PC clock must be India time (Asia/Calcutta). Check: tzutil /g"
}

# ---- main ----
Write-Host "=== SMES robot webhook setup (bypasses personal TT) ==="
Test-RobotWebhookUrl -Url $MesIssueWebhook
Test-RobotWebhookUrl -Url $SmtTeWebhook

if (-not $InstallDir) {
    $InstallDir = Join-Path $env:USERPROFILE "SMES-robot-webhook"
}
$InstallDir = Install-RobotScripts -Target $InstallDir
Save-RobotWebhookConfig -MesIssueWebhook $MesIssueWebhook -SmtTeWebhook $SmtTeWebhook -Text $Text

Write-Host ""
Write-Host "Stopping personal OpenClaw MES cron (IN008771 green bubble)..."
Stop-PersonalMesCron

Write-Host ""
$runner = Join-Path $InstallDir "run-robot-webhook-daily.ps1"
Register-IndiaDailyTasks -RunnerPath $runner

Write-Host ""
Write-Host "Sending TEST message as ROBOT to both groups NOW..."
Send-RobotToBothGroups -MesIssueWebhook $MesIssueWebhook -SmtTeWebhook $SmtTeWebhook -Text $Text

Write-Host ""
Write-Host "DONE."
Write-Host "1) Open both groups - you must see Robot badge (NOT green personal bubble)."
Write-Host "2) Daily auto: 9:00 AM and 9:00 PM when PC is on."
Write-Host "3) Manual retest: powershell -ExecutionPolicy Bypass -File `"$InstallDir\send-robot-now.ps1`""
