# Make the MES cron reminder come from the robot identity, not a personal TT login.
# Safe to run more than once. Windows PowerShell compatible.
# Run: powershell -ExecutionPolicy Bypass -File .\fix-mes-robot-sender.ps1
#
# Why the 09:00 line looked like "you":
# OpenClaw cron announce sends through the logged-in channel account.
# If channels.tt is logged in as a personal TT user (green bubble / landscape avatar),
# the group sees that person - not AppRobot "RAJAN SUMAN xiaolongxia".
#
# Preferred fix paths (pick one):
#   A) TT session: log out personal TT, log in as the robot TT account, then Run MES.
#   B) Feishu/Lark AppRobot: configure channels.feishu with the robot App ID/Secret,
#      point MES delivery at the Feishu chat id (oc_...), then Run MES.

[CmdletBinding()]
param(
    [string]$TtGroupId = "965235",
    [string]$FeishuChatId = "",
    # ASCII-only default: Windows PowerShell may mis-parse UTF-8 Chinese from raw.githubusercontent.com.
    [string]$ExpectedRobotName = "RAJAN SUMAN xiaolongxia",
    [string[]]$PersonalAccountHints = @("IN008771"),
    [switch]$SkipCronEdit,
    [switch]$KeepLastRouteJobs
)

$ErrorActionPreference = "Stop"
$Message = "Send exactly this text and add nothing else: Please update SMT MES issues"
if (-not $env:USERPROFILE) {
    if ($env:HOME) { $env:USERPROFILE = $env:HOME }
    else { $env:USERPROFILE = [Environment]::GetFolderPath("UserProfile") }
}
if (-not $env:USERPROFILE) {
    throw "USERPROFILE is not set. Run this script on the OClaw Windows PC."
}
$CronPath = Join-Path $env:USERPROFILE ".openclaw\cron\jobs.json"
$ConfigCandidates = @(
    (Join-Path $env:USERPROFILE ".openclaw\openclaw.json"),
    (Join-Path $env:USERPROFILE ".openclaw\config.json"),
    (Join-Path $env:USERPROFILE ".oclaw\openclaw.json")
)

function Find-OpenClaw {
    $cmd = Get-Command openclaw -ErrorAction SilentlyContinue
    if ($cmd) {
        if ($cmd.Source -like "*.ps1") {
            $parent = Split-Path $cmd.Source
            if ($parent) {
                $cmdShim = Join-Path $parent "openclaw.cmd"
                if (Test-Path -LiteralPath $cmdShim) { return $cmdShim }
            }
        }
        return $cmd.Source
    }

    $candidates = @()
    if ($env:USERPROFILE) {
        $candidates += (Join-Path $env:USERPROFILE ".openclaw\bin\openclaw.cmd")
    }
    if ($env:LOCALAPPDATA) {
        $candidates += (Join-Path $env:LOCALAPPDATA "Programs\OClaw\resources\openclaw\openclaw.cmd")
        $candidates += (Join-Path $env:LOCALAPPDATA "Programs\OClaw\openclaw.cmd")
    }
    if ($env:APPDATA) {
        $candidates += (Join-Path $env:APPDATA "npm\openclaw.cmd")
    }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }

    if ($env:LOCALAPPDATA) {
        $root = Join-Path $env:LOCALAPPDATA "Programs\OClaw"
        if (Test-Path -LiteralPath $root) {
            $found = Get-ChildItem -Path $root -Filter "openclaw.cmd" -Recurse -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($found) { return $found.FullName }
        }
    }
    return $null
}

function Invoke-OpenClawText {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFail
    )
    Write-Host ("openclaw " + ($Arguments -join " "))
    $text = & $Exe @Arguments 2>&1 | Out-String
    $code = $LASTEXITCODE
    if (-not $AllowFail -and $code -ne 0) {
        throw "openclaw exited with code $code"
    }
    return @{ Code = $code; Text = $text }
}

function Get-OpenClawConfigPath {
    foreach ($path in $ConfigCandidates) {
        if ($path -and (Test-Path -LiteralPath $path)) { return $path }
    }
    return $null
}

function Test-LooksPersonal {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    foreach ($hint in $PersonalAccountHints) {
        if ($Text -match [regex]::Escape($hint)) { return $true }
    }
    if ($Text -match "(?i)personal|self|human user|not a bot|landscape") { return $true }
    if ($Text -match "(?i)$([regex]::Escape($ExpectedRobotName))") { return $false }
    return $false
}

function Get-JsonPropertyNames {
    param($Object)
    if ($null -eq $Object) { return @() }
    return @($Object.PSObject.Properties | ForEach-Object { $_.Name })
}

function Ensure-MesCronJob {
    param(
        [Parameter(Mandatory = $true)][string]$Channel,
        [Parameter(Mandatory = $true)][string]$To,
        [switch]$DisableLastRoute
    )

    if (-not (Test-Path $CronPath)) {
        throw "Cron store not found: $CronPath"
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $CronPath "$CronPath.bak-robot-$stamp" -Force
    Write-Host "Cron backup: $CronPath.bak-robot-$stamp"

    $raw = Get-Content -Path $CronPath -Raw -Encoding UTF8
    $data = $raw | ConvertFrom-Json
    $wrapped = $false
    if ($data -is [System.Array]) {
        $jobs = @($data)
    } elseif ($null -ne $data.PSObject.Properties["jobs"]) {
        $jobs = @($data.jobs)
        $wrapped = $true
    } else {
        throw "jobs.json is not a job list."
    }

    $mes = @($jobs | Where-Object { $_.name -eq "MES" })
    if ($mes.Count -eq 0) {
        throw "No cron job named MES was found. Create it in Control UI Cron Jobs first, or run setup-mes-bot.ps1 / fix-mes-job.ps1."
    }
    if ($mes.Count -gt 1) {
        throw "More than one cron job is named MES."
    }

    $job = $mes[0]
    Write-Host "MES before: channel=$($job.delivery.channel) to=$($job.delivery.to) mode=$($job.delivery.mode)"

    if (-not $job.payload) {
        $job | Add-Member -NotePropertyName payload -NotePropertyValue ([pscustomobject]@{ kind = "agentTurn" })
    }
    $job.payload | Add-Member -NotePropertyName kind -NotePropertyValue "agentTurn" -Force
    $job.payload | Add-Member -NotePropertyName message -NotePropertyValue $Message -Force

    if (-not $job.delivery) {
        $job | Add-Member -NotePropertyName delivery -NotePropertyValue ([pscustomobject]@{})
    }
    $job.delivery | Add-Member -NotePropertyName mode -NotePropertyValue "announce" -Force
    $job.delivery | Add-Member -NotePropertyName channel -NotePropertyValue $Channel -Force
    $job.delivery | Add-Member -NotePropertyName to -NotePropertyValue $To -Force

    # Drop last-route / session sticky fields that can re-target a personal DM.
    foreach ($drop in @("accountId", "account", "lastTo", "sessionKey", "threadId")) {
        if ((Get-JsonPropertyNames $job.delivery) -contains $drop) {
            $job.delivery.PSObject.Properties.Remove($drop)
            Write-Host "Removed delivery.$drop (avoids personal last-route)."
        }
    }

    $job | Add-Member -NotePropertyName wakeMode -NotePropertyValue "now" -Force
    $job | Add-Member -NotePropertyName sessionTarget -NotePropertyValue "isolated" -Force
    if ($job.schedule) {
        foreach ($field in @("expr", "cron", "expression")) {
            if ((Get-JsonPropertyNames $job.schedule) -contains $field) {
                $job.schedule.$field = "0 9,21 * * *"
            }
        }
        if (-not ((Get-JsonPropertyNames $job.schedule) -contains "expr") -and
            -not ((Get-JsonPropertyNames $job.schedule) -contains "cron")) {
            $job.schedule | Add-Member -NotePropertyName expr -NotePropertyValue "0 9,21 * * *"
        }
        $job.schedule | Add-Member -NotePropertyName tz -NotePropertyValue "Asia/Calcutta" -Force
    }

    if ($DisableLastRoute) {
        $disabledCount = 0
        foreach ($other in $jobs) {
            if ($null -eq $other) { continue }
            if ($other.name -eq "MES") { continue }
            $otherMode = $null
            $otherChannel = $null
            $otherTo = $null
            if ($other.delivery) {
                $otherMode = [string]$other.delivery.mode
                $otherChannel = [string]$other.delivery.channel
                $otherTo = [string]$other.delivery.to
            }
            $looksLastRoute =
                ($otherMode -match "(?i)last|session|route") -or
                [string]::IsNullOrWhiteSpace($otherTo) -or
                ($otherTo -match "(?i)^(last|self|me|dm)$")
            $looksMesText = $false
            if ($other.payload -and $other.payload.message) {
                $looksMesText = ([string]$other.payload.message) -match "Please update SMT MES issues"
            }
            if ($looksMesText -or ($looksLastRoute -and $otherChannel -match "(?i)^(tt|feishu|lark)$")) {
                $other | Add-Member -NotePropertyName enabled -NotePropertyValue $false -Force
                if ((Get-JsonPropertyNames $other) -contains "disabled") {
                    $other.disabled = $true
                } else {
                    $other | Add-Member -NotePropertyName disabled -NotePropertyValue $true -Force
                }
                $disabledCount++
                Write-Host "Disabled non-MES/last-route style job: name=$($other.name) channel=$otherChannel to=$otherTo mode=$otherMode"
            }
        }
        if ($disabledCount -eq 0) {
            Write-Host "No extra last-route / duplicate MES text jobs needed disabling."
        }
    }

    if ($wrapped) {
        $data.jobs = $jobs
        $out = $data
    } else {
        $out = $jobs
    }

    $json = $out | ConvertTo-Json -Depth 40
    [System.IO.File]::WriteAllText($CronPath, $json)
    Write-Host "MES after: channel=$Channel to=$To mode=announce"
}

function Write-RobotLoginSteps {
    param(
        [string]$ChannelLabel,
        [string]$LogoutChannel
    )

    Write-Host ""
    Write-Host "=== Robot sender steps (OClaw PC) ==="
    Write-Host "Goal: group INDIA SMT MES ISSUE should show $ExpectedRobotName, not your personal green bubble."
    Write-Host ""
    Write-Host "Path A - keep TT, switch the logged-in TT account to the robot:"
    Write-Host "  1. Close the personal TT / Feishu desktop session that is logged in as you (e.g. IN008771)."
    Write-Host "  2. In an OClaw / admin terminal on this PC run:"
    Write-Host "       openclaw channels logout --channel $LogoutChannel"
    Write-Host "  3. Log TT back in as the robot account (the same identity as $ExpectedRobotName),"
    Write-Host "     not your personal staff account:"
    Write-Host "       openclaw channels login --channel $LogoutChannel"
    Write-Host "  4. Confirm identity:"
    Write-Host "       openclaw channels status --probe"
    Write-Host "     Sender / account line must NOT show IN008771 or your personal name."
    Write-Host "  5. Restart gateway, then Control UI -> Cron Jobs -> MES -> Run."
    Write-Host ""
    Write-Host "Path B - preferred when the group UI is Feishu/Lark with AppRobot robots:"
    Write-Host "  1. openclaw channels login --channel feishu"
    Write-Host "     Choose manual setup. Paste the App ID + App Secret for $ExpectedRobotName"
    Write-Host "     from Feishu Open Platform / Lark Developer (not your personal user QR)."
    Write-Host "  2. In Feishu group settings, copy the chat_id (looks like oc_xxx)."
    Write-Host "  3. Re-run this script with -FeishuChatId oc_xxx so MES announce uses channel=feishu."
    Write-Host "  4. openclaw channels status --probe"
    Write-Host "  5. Control UI -> Cron Jobs -> MES -> Run."
    Write-Host ""
    Write-Host "Verify: next message must show robot name/avatar as an incoming robot post,"
    Write-Host "not a right-side green bubble from your personal landscape avatar."
}

# --- main ---

Write-Host "MES robot-sender check"
Write-Host "Expected robot: $ExpectedRobotName"
Write-Host "TT group id (fallback): $TtGroupId"
if ($FeishuChatId) {
    Write-Host "Feishu chat id override: $FeishuChatId"
}
Write-Host ""

$openclaw = Find-OpenClaw
$configPath = Get-OpenClawConfigPath
$statusText = ""
$ttLooksPersonal = $false
$feishuConfigured = $false
$ttConfigured = $false

if ($configPath) {
    Write-Host "Config file: $configPath"
    try {
        $cfg = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cfg.channels -and $cfg.channels.tt) {
            $ttConfigured = $true
            Write-Host "channels.tt.enabled = $($cfg.channels.tt.enabled)"
        }
        if ($cfg.channels -and ($cfg.channels.feishu -or $cfg.channels.lark)) {
            $feishuConfigured = $true
            Write-Host "channels.feishu/lark is present in config."
        }
    } catch {
        Write-Host "Could not parse config JSON: $_"
    }
} else {
    Write-Host "No openclaw.json found under %USERPROFILE%\.openclaw (ok if OClaw stores config elsewhere)."
}

if ($openclaw) {
    Write-Host "Using: $openclaw"
    Write-Host ""
    Write-Host "--- channel status (probe) ---"
    $probe = Invoke-OpenClawText -Exe $openclaw -Arguments @("channels", "status", "--probe") -AllowFail
    $statusText = $probe.Text
    Write-Host $statusText.Trim()
    Write-Host "------------------------------"

    $jsonProbe = Invoke-OpenClawText -Exe $openclaw -Arguments @("channels", "status", "--probe", "--json") -AllowFail
    if ($jsonProbe.Code -eq 0 -and $jsonProbe.Text) {
        $statusText = $statusText + "`n" + $jsonProbe.Text
    }

    if ($statusText -match "(?i)\btt\b") { $ttConfigured = $true }
    if ($statusText -match "(?i)feishu|\blark\b") { $feishuConfigured = $true }
    $ttLooksPersonal = Test-LooksPersonal -Text $statusText

    Write-Host ""
    if ($ttLooksPersonal) {
        Write-Host "CHECK FAIL: TT/Feishu status text looks like a PERSONAL account (hint match: $($PersonalAccountHints -join ', '))."
        Write-Host "That is why 'Please update SMT MES issues' showed as your green outgoing bubble."
    } elseif ($statusText -match [regex]::Escape($ExpectedRobotName) -or $statusText -match "(?i)bot|approbot|app_id|appId") {
        Write-Host "CHECK OK-ish: status mentions robot/bot identity. Still confirm the next Run is not a green self-bubble."
    } else {
        Write-Host "CHECK WARN: could not prove robot identity from status text."
        Write-Host "Open Control UI Channels and confirm the logged-in TT account is $ExpectedRobotName, not IN008771."
    }
} else {
    Write-Host "openclaw.cmd was not found on PATH."
    Write-Host "Open the OClaw app once, then re-run this script so channel status can be printed."
}

$deliveryChannel = "tt"
$deliveryTo = $TtGroupId
if (-not [string]::IsNullOrWhiteSpace($FeishuChatId)) {
    $deliveryChannel = "feishu"
    $deliveryTo = $FeishuChatId.Trim()
    Write-Host "Delivery target selected: feishu / $deliveryTo"
} else {
    Write-Host "Delivery target selected: tt / $deliveryTo (pass -FeishuChatId oc_xxx to use AppRobot path)"
}

function Invoke-SchtasksSafe {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $sch = Get-Command schtasks -ErrorAction SilentlyContinue
    if (-not $sch) {
        Write-Host "schtasks not available in this shell (ok on non-Windows). Skipping: schtasks $($Arguments -join ' ')"
        return
    }
    try {
        & $sch.Source @Arguments 2>$null | Out-Host
    } catch {
        Write-Host "schtasks failed (continuing): $_"
    }
}

if (-not $SkipCronEdit) {
    Write-Host ""
    Write-Host "Updating MES cron announce delivery..."
    # Gateway stop/start reduces races while rewriting jobs.json (same pattern as fix-mes-job.ps1).
    if ($openclaw) {
        Invoke-OpenClawText -Exe $openclaw -Arguments @("gateway", "stop") -AllowFail | Out-Null
        Start-Sleep -Seconds 3
    } else {
        Invoke-SchtasksSafe -Arguments @("/End", "/TN", "OpenClaw Gateway")
        Start-Sleep -Seconds 3
    }

    $disableLast = -not $KeepLastRouteJobs.IsPresent
    Ensure-MesCronJob -Channel $deliveryChannel -To $deliveryTo -DisableLastRoute:$disableLast

    if ($openclaw) {
        Invoke-OpenClawText -Exe $openclaw -Arguments @("gateway", "start") -AllowFail | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Invoke-SchtasksSafe -Arguments @("/Run", "/TN", "OpenClaw Gateway")
        }
    } else {
        Invoke-SchtasksSafe -Arguments @("/Run", "/TN", "OpenClaw Gateway")
    }
} else {
    Write-Host "SkipCronEdit set - left jobs.json unchanged."
}

Write-RobotLoginSteps -ChannelLabel $deliveryChannel -LogoutChannel $(if ($deliveryChannel -eq "feishu") { "feishu" } else { "tt" })

Write-Host ""
Write-Host "Done."
Write-Host "If status still shows personal login, logout/login first - cron announce cannot impersonate the AppRobot while TT is your user session."
Write-Host "Then: Control UI -> Cron Jobs -> MES -> Run, and confirm $ExpectedRobotName posted the line."
