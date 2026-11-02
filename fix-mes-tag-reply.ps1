# Reply when ANY group member @tags the robot. Do not reply to untagged messages.
# ASCII-safe for Windows PowerShell 5.1.
#
# Run: powershell -ExecutionPolicy Bypass -File .\fix-mes-tag-reply.ps1

$ErrorActionPreference = "Stop"
$GroupId = "965235"

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
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

$openclaw = Find-OpenClaw
if (-not $openclaw) { throw "openclaw not found" }
Write-Host "Using: $openclaw"

# Anyone in this group may trigger the robot by tagging it.
& $openclaw config set channels.tt.enabled true
& $openclaw config set channels.tt.groupPolicy open
& $openclaw config set ("channels.tt.groups.{0}.enabled" -f $GroupId) true
& $openclaw config set ("channels.tt.groups.{0}.requireMention" -f $GroupId) true

# Text fallbacks when TT does not pass a native @ mention flag.
# Keep ASCII-only patterns so this .ps1 never breaks on download.
$patterns = '["(?i)RAJAN\\s*SUMAN","(?i)xiaolongxia","(?i)@RAJAN"]'
& $openclaw config set agents.entries.main.groupChat.mentionPatterns $patterns
if ($LASTEXITCODE -ne 0) {
    & $openclaw config set messages.groupChat.mentionPatterns $patterns
}

Write-Host "Config saved. Reloading gateway..."
$ErrorActionPreference = "Continue"
& $openclaw gateway stop
Start-Sleep -Seconds 3
& $openclaw gateway start
Start-Sleep -Seconds 5
& $openclaw gateway status
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Done."
Write-Host "Robot replies only when tagged. Anyone in the group can tag it."
Write-Host "Test: in INDIA SMT MES ISSUE send @ robot then: how are you?"
Write-Host "If still silent, run: openclaw logs --follow  then tag again."
