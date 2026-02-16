# 1. Get Server Details from User
Write-Host "--- Server Sync Setup ---" -ForegroundColor Cyan
$User = Read-Host "Enter Server Username (e.g., root)"
$IP   = Read-Host "Enter Server IP Address"

Write-Host "Attempting to pull production files from $User@$IP..." -ForegroundColor Yellow

# 2. Download files using SCP
# This will prompt for your SSH password or use your SSH key automatically
try {
    Write-Host "Downloading .env..."
    scp "$($User)@$($IP):/app/.env" ./.env

    Write-Host "Downloading acme.json..."
    if (-not (Test-Path "letsencrypt")) { New-Item -ItemType Directory -Path "letsencrypt" | Out-Null }
    scp "$($User)@$($IP):/app/letsencrypt/acme.json" ./letsencrypt/acme.json

    if ($LASTEXITCODE -ne 0) { throw "SCP failed. Check your credentials and paths." }
    Write-Host "Success: Files synced from server." -ForegroundColor Green
} catch {
    Write-Host "Error: Could not sync files. $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Creating local folder structure..." -ForegroundColor Cyan
$folders = @(
    "flows2", 
    "public/images/product", 
    "public/images/tmp", 
    "public/images/cake-order/tmp", 
    "n8n-workflows"
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

# 4. Set Permissions for acme.json (Strict for Traefik)
# Note: On Windows, Docker handles the translation, but we ensure the file exists.
Write-Host "Applying permissions to acme.json..."
docker exec -it traefik sh -c "chmod 600 /letsencrypt/acme.json"


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
        Invoke-RestMethod -Method Post -Uri "https://api.telegram.org/bot$($env:TELEGRAM_BOT_TOKEN)/setWebhook?url=$($env:TELEGRAM_WEBHOOK_URL)" | Out-Null
        Invoke-RestMethod -Method Post -Uri "https://api.telegram.org/bot$($env:CAKE_ORDER_TELEGRAM_BOT_TOKEN)/setWebhook?url=$($env:CAKE_ORDER_TELEGRAM_WEBHOOK_URL)" | Out-Null
        Write-Host "Success: Webhooks updated." -ForegroundColor Green
    } catch {
        Write-Host "Warning: Webhook update failed." -ForegroundColor Yellow
    }
}

Write-Host "Setup Complete! Local environment is mirrored from server." -ForegroundColor Green