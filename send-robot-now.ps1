# Send "Please update SMT MES issues" RIGHT NOW as Feishu/Lark custom robot
# (Robot badge). Does NOT use OpenClaw TT / IN008771.
#
# First time:
#   powershell -ExecutionPolicy Bypass -File .\send-robot-now.ps1 `
#     -MesIssueWebhook "https://open.feishu.cn/open-apis/bot/v2/hook/...." `
#     -SmtTeWebhook "https://open.feishu.cn/open-apis/bot/v2/hook/...."
#
# After setup-robot-webhook-daily.ps1 saved config:
#   powershell -ExecutionPolicy Bypass -File .\send-robot-now.ps1

[CmdletBinding()]
param(
    [string]$MesIssueWebhook = "",
    [string]$SmtTeWebhook = "",
    [string]$Text = "Please update SMT MES issues"
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here "lib\RobotWebhook.ps1")

if ($MesIssueWebhook -and $SmtTeWebhook) {
    Send-RobotToBothGroups -MesIssueWebhook $MesIssueWebhook -SmtTeWebhook $SmtTeWebhook -Text $Text
} else {
    Send-RobotToBothGroups -Text $Text
}

Write-Host ""
Write-Host "Check both groups NOW. Message must show Robot badge (not your green bubble)."
