# ONE-COMMAND bootstrap: download SMES robot-webhook scripts and start Robot posts.
#
# You still need 2 Feishu Custom Bot webhook URLs (1 per group). Create them first:
#   Group -> Settings -> Bots -> Add -> Custom bot -> Copy webhook
#
# Then run:
#   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Rajan8771/SMES/cursor/mes-robot-webhook-bc04/start-robot-messages.ps1?v=1" -OutFile "$env:TEMP\start-robot-messages.ps1"
#   powershell -ExecutionPolicy Bypass -File "$env:TEMP\start-robot-messages.ps1" `
#     -MesIssueWebhook "https://open.feishu.cn/open-apis/bot/v2/hook/...." `
#     -SmtTeWebhook "https://open.feishu.cn/open-apis/bot/v2/hook/...."

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$MesIssueWebhook,
    [Parameter(Mandatory = $true)][string]$SmtTeWebhook
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$branch = "cursor/mes-robot-webhook-bc04"
$zipUrl = "https://github.com/Rajan8771/SMES/archive/refs/heads/$branch.zip"
$zip = Join-Path $env:TEMP "SMES-robot-webhook.zip"
$extractRoot = Join-Path $env:USERPROFILE "SMES-robot-webhook-src"
$dest = Join-Path $env:USERPROFILE "SMES-robot-webhook"

Write-Host "Downloading $branch ..."
Invoke-WebRequest -Uri $zipUrl -OutFile $zip
if (Test-Path $extractRoot) { Remove-Item $extractRoot -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $extractRoot -Force

$folder = Get-ChildItem $extractRoot -Directory | Select-Object -First 1
if (-not $folder) { throw "Zip extract failed" }

if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
Copy-Item $folder.FullName $dest -Recurse -Force
Write-Host "Scripts ready: $dest"

$setup = Join-Path $dest "setup-robot-webhook-daily.ps1"
powershell -ExecutionPolicy Bypass -File $setup -MesIssueWebhook $MesIssueWebhook -SmtTeWebhook $SmtTeWebhook -InstallDir $dest
