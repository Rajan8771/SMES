# Shared Feishu/Lark custom-bot webhook helpers.
# Custom bot posts show as Robot (not personal IN008771).

$script:DefaultMesText = "Please update SMT MES issues"

function Test-RobotWebhookUrl {
    param([Parameter(Mandatory = $true)][string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) {
        throw "Webhook URL is empty."
    }
    if ($Url -notmatch '^https://(open\.(feishu\.cn|larksuite\.com)|www\.feishu\.cn)/open-apis/bot/v2/hook/') {
        throw ("Webhook URL looks wrong: {0}. Expected Feishu/Lark bot/v2/hook URL from group Settings -> Bots -> Custom bot." -f $Url)
    }
    if ($Url -match 'YOUR|xxxx|placeholder|example' -or $Url.Length -lt 60) {
        throw ("Placeholder webhook refused: {0}" -f $Url)
    }
}

function Send-RobotWebhookMessage {
    param(
        [Parameter(Mandatory = $true)][string]$WebhookUrl,
        [string]$Text = $script:DefaultMesText,
        [string]$Label = "group"
    )

    Test-RobotWebhookUrl -Url $WebhookUrl

    $bodyObj = @{
        msg_type = "text"
        content  = @{ text = $Text }
    }
    $json = $bodyObj | ConvertTo-Json -Compress -Depth 5

    Write-Host ("Sending robot message to {0}..." -f $Label)
    $resp = Invoke-RestMethod -Method Post -Uri $WebhookUrl -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
    # Feishu returns StatusCode=0 on success for custom bots.
    if ($null -ne $resp.StatusCode -and [int]$resp.StatusCode -ne 0) {
        throw ("Webhook failed for {0}: StatusCode={1} msg={2}" -f $Label, $resp.StatusCode, $resp.StatusMessage)
    }
    if ($null -ne $resp.code -and [int]$resp.code -ne 0) {
        throw ("Webhook failed for {0}: code={1} msg={2}" -f $Label, $resp.code, $resp.msg)
    }
    Write-Host ("OK robot posted to {0}" -f $Label)
    return $resp
}

function Get-RobotWebhookConfigPath {
    return (Join-Path $env:USERPROFILE ".openclaw\mes-robot-webhooks.json")
}

function Save-RobotWebhookConfig {
    param(
        [Parameter(Mandatory = $true)][string]$MesIssueWebhook,
        [Parameter(Mandatory = $true)][string]$SmtTeWebhook,
        [string]$Text = $script:DefaultMesText
    )
    Test-RobotWebhookUrl -Url $MesIssueWebhook
    Test-RobotWebhookUrl -Url $SmtTeWebhook

    $dir = Join-Path $env:USERPROFILE ".openclaw"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    $cfg = [pscustomobject]@{
        text            = $Text
        mesIssueWebhook = $MesIssueWebhook
        smtTeWebhook    = $SmtTeWebhook
        updatedAt       = (Get-Date).ToString("o")
    }
    $path = Get-RobotWebhookConfigPath
    ($cfg | ConvertTo-Json -Depth 5) | Set-Content -Path $path -Encoding UTF8
    Write-Host ("Saved config: {0}" -f $path)
    return $path
}

function Read-RobotWebhookConfig {
    $path = Get-RobotWebhookConfigPath
    if (-not (Test-Path $path)) {
        throw ("Missing webhook config: {0}. Run setup-robot-webhook-daily.ps1 first." -f $path)
    }
    return (Get-Content -Path $path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Send-RobotToBothGroups {
    param(
        [string]$MesIssueWebhook,
        [string]$SmtTeWebhook,
        [string]$Text = $script:DefaultMesText
    )

    if (-not $MesIssueWebhook -or -not $SmtTeWebhook) {
        $cfg = Read-RobotWebhookConfig
        if (-not $MesIssueWebhook) { $MesIssueWebhook = [string]$cfg.mesIssueWebhook }
        if (-not $SmtTeWebhook) { $SmtTeWebhook = [string]$cfg.smtTeWebhook }
        if (-not $Text -or $Text -eq $script:DefaultMesText) {
            if ($cfg.text) { $Text = [string]$cfg.text }
        }
    }

    Send-RobotWebhookMessage -WebhookUrl $MesIssueWebhook -Text $Text -Label "INDIA SMT MES ISSUE"
    Send-RobotWebhookMessage -WebhookUrl $SmtTeWebhook -Text $Text -Label "INDIA SMT TE"
}
