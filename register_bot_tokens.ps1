
# 4. Set Permissions for acme.json (Strict for Traefik)
# Note: On Windows, Docker handles the translation, but we ensure the file exists.

# 6. Set Telegram Webhooks
Write-Host "Updating Telegram webhooks..." -ForegroundColor Cyan
if (Test-Path ".env") {
    Get-Content .env | ForEach-Object {
        if ($_ -match "^(?<key>[^=]+)=(?<value>.*)$") {
            $k = $Matches.key.Trim(); $v = $Matches.value.Trim()
            Set-Item -Path "Env:$k" -Value $v
        }
    }

    try {
        Write-Host "Attempting to set Telegram webhook for bot: $($env:TELEGRAM_BOT_TOKEN). url: https://$($env:DOMAIN_OR_IP)/api/telegram/admin/receive"
        Invoke-RestMethod -Method Post -Uri "https://api.telegram.org/bot$($env:TELEGRAM_BOT_TOKEN)/setWebhook?url=https://$($env:DOMAIN_OR_IP)/api/telegram/admin/receive" | Out-Null
        Invoke-RestMethod -Method Post -Uri "https://api.telegram.org/bot$($env:CAKE_ORDER_TELEGRAM_BOT_TOKEN)/setWebhook?url=https://$($env:DOMAIN_OR_IP)/api/cakeOrder/telegram/receive" | Out-Null
        Write-Host "Success: Webhooks updated." -ForegroundColor Green
    } catch {
        Write-Host "Warning: Webhook update failed. $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "Setup Complete! Local environment is mirrored from server." -ForegroundColor Green