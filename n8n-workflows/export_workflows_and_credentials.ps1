# Export-N8n.ps1
# Exports all n8n credentials and workflows, then filters to only those updated since last run.

$TimestampFile = Join-Path $PSScriptRoot "last_export_timestamp.txt"
$OutputDir = Join-Path $PSScriptRoot "n8n_exports"
$ContainerName = "n8n_app"
$ContainerPath = "/home/node/.n8n-files/workflows"

$AllWorkflowsFile = Join-Path $OutputDir "all_workflows.json"
$AllCredentialsFile = Join-Path $OutputDir "all_credentials.json"
$UpdatedWorkflowsFile = Join-Path $OutputDir "updated_workflows.json"
$UpdatedCredentialsFile = Join-Path $OutputDir "updated_credentials.json"

$ContainerWorkflowsPath = "$ContainerPath/all_workflows.json"
$ContainerCredsPath = "$ContainerPath/creds-template.json"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Read last timestamp from file
$LastTimestamp = [datetime]::MinValue
if (Test-Path $TimestampFile) {
    $raw = (Get-Content $TimestampFile -Raw).Trim()
    $LastTimestamp = [datetime]::Parse($raw)
    Write-Host "Last export timestamp: $LastTimestamp"
} else {
    Write-Host "No previous timestamp found - treating all items as updated."
}

$ExportStart = Get-Date

# Export all workflows
Write-Host "Exporting all workflows..."
docker exec $ContainerName n8n export:workflow --all --output=$ContainerWorkflowsPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Workflow export failed."
    exit 1
}

docker cp "${ContainerName}:${ContainerWorkflowsPath}" $AllWorkflowsFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to copy workflows from container."
    exit 1
}
Write-Host "All workflows saved to: $AllWorkflowsFile"

# Export all credentials
Write-Host "Exporting all credentials..."
docker exec $ContainerName n8n export:credentials --all --decrypted --output=$ContainerCredsPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Credentials export failed."
    exit 1
}

docker cp "${ContainerName}:${ContainerCredsPath}" $AllCredentialsFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to copy credentials from container."
    exit 1
}
Write-Host "All credentials saved to: $AllCredentialsFile"

# Parse exported JSON
$allWorkflows = Get-Content $AllWorkflowsFile -Raw | ConvertFrom-Json
$allCredentials = Get-Content $AllCredentialsFile -Raw | ConvertFrom-Json

# n8n may wrap items in a "data" property
if ($allWorkflows.PSObject.Properties.Name -contains "data") {
    $allWorkflows = $allWorkflows.data
}
if ($allCredentials.PSObject.Properties.Name -contains "data") {
    $allCredentials = $allCredentials.data
}

# Filter to items updated since last timestamp
Write-Host "Filtering items updated since: $LastTimestamp"

if ($LastTimestamp -eq [datetime]::MinValue) {
    $updatedWorkflows = $allWorkflows
    $updatedCredentials = $allCredentials
} else {
    $updatedWorkflows = $allWorkflows | Where-Object {
        $d = $_.updatedAt
        if (-not $d) { return $false }
        try { [datetime]::Parse($d).ToUniversalTime() -gt $LastTimestamp.ToUniversalTime() }
        catch { $false }
    }
    $updatedCredentials = $allCredentials | Where-Object {
        $d = $_.updatedAt
        if (-not $d) { return $false }
        try { [datetime]::Parse($d).ToUniversalTime() -gt $LastTimestamp.ToUniversalTime() }
        catch { $false }
    }
}

# Use @() to force array output so ConvertTo-Json always emits [...] even for single items.
# Use WriteAllText with explicit LF line endings instead of Set-Content (which uses CRLF on Windows).
if (@($updatedWorkflows).Count -gt 0) {
    $json = @($updatedWorkflows) | ConvertTo-Json -Depth 20
    $json = $json -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($UpdatedWorkflowsFile, $json, [System.Text.Encoding]::UTF8)
    Write-Host "Updated workflows ($(@($updatedWorkflows).Count)): $UpdatedWorkflowsFile"
} else {
    Write-Host "No workflows updated since last run - skipping file write."
}

if (@($updatedCredentials).Count -gt 0) {
    $json = @($updatedCredentials) | ConvertTo-Json -Depth 20
    $json = $json -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($UpdatedCredentialsFile, $json, [System.Text.Encoding]::UTF8)
    Write-Host "Updated credentials ($(@($updatedCredentials).Count)): $UpdatedCredentialsFile"
} else {
    Write-Host "No credentials updated since last run - skipping file write."
}

# Save current timestamp for next run
$now = (Get-Date).ToUniversalTime().ToString("o")
Set-Content -Path $TimestampFile -Value $now -Encoding UTF8
Write-Host "Timestamp saved: $now"

$elapsed = [math]::Round(((Get-Date) - $ExportStart).TotalSeconds, 1)
Write-Host "Done. Export completed in ${elapsed}s"