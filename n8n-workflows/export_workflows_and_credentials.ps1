# Export-N8n.ps1
# Exports all n8n credentials and workflows, then filters to only those updated since last run.

$TimestampFile = Join-Path $PSScriptRoot "last_export_timestamp.txt"
$OutputDir = Join-Path $PSScriptRoot "n8n_exports"
$ContainerName = "n8n_app"
$ContainerPath = "/home/node/.n8n-files/workflows"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# Read last timestamp from file
$LastTimestamp = ""
if (Test-Path $TimestampFile) {
    $LastTimestamp = (Get-Content $TimestampFile -Raw).Trim()
    Write-Host "Last export timestamp: $LastTimestamp"
} else {
    Write-Host "No previous timestamp found - treating all items as updated."
}

$ExportStart = Get-Date

# Export all workflows into container
Write-Host "Exporting all workflows..."
docker exec $ContainerName n8n export:workflow --all --output=$ContainerPath/all_workflows.json
if ($LASTEXITCODE -ne 0) { Write-Error "Workflow export failed."; exit 1 }

# Export all credentials into container
Write-Host "Exporting all credentials..."
docker exec $ContainerName n8n export:credentials --all --decrypted --output=$ContainerPath/all_credentials.json
if ($LASTEXITCODE -ne 0) { Write-Error "Credentials export failed."; exit 1 }

# Run a Node.js script inside the container to filter and write the updated files
$nodeScript = @'
const fs = require('fs');
const path = require('path');

const dir = '/home/node/.n8n-files/workflows';
const lastTimestamp = process.argv[2] ? new Date(process.argv[2]) : null;

function filterUpdated(items) {
    if (!lastTimestamp) return items;
    return items.filter(item => {
        if (!item.updatedAt) return false;
        return new Date(item.updatedAt) > lastTimestamp;
    });
}

function loadJson(file) {
    const raw = JSON.parse(fs.readFileSync(file, 'utf8'));
    return Array.isArray(raw) ? raw : (raw.data ?? []);
}

const allWorkflows = loadJson(path.join(dir, 'all_workflows.json'));
const allCredentials = loadJson(path.join(dir, 'all_credentials.json'));

const updatedWorkflows = filterUpdated(allWorkflows);
const updatedCredentials = filterUpdated(allCredentials);

fs.writeFileSync(path.join(dir, 'updated_workflows.json'), JSON.stringify(updatedWorkflows, null, 2), 'utf8');
fs.writeFileSync(path.join(dir, 'updated_credentials.json'), JSON.stringify(updatedCredentials, null, 2), 'utf8');

console.log(`Updated workflows: ${updatedWorkflows.length}`);
console.log(`Updated credentials: ${updatedCredentials.length}`);
'@

Write-Host "Filtering updated items inside container..."
docker exec $ContainerName node -e $nodeScript -- $LastTimestamp
if ($LASTEXITCODE -ne 0) { Write-Error "Filtering script failed."; exit 1 }

# Copy all four files out of the container
Write-Host "Copying files from container..."
docker cp "${ContainerName}:${ContainerPath}/all_workflows.json"       (Join-Path $OutputDir "all_workflows.json")
docker cp "${ContainerName}:${ContainerPath}/all_credentials.json"     (Join-Path $OutputDir "all_credentials.json")
docker cp "${ContainerName}:${ContainerPath}/updated_workflows.json"   (Join-Path $OutputDir "updated_workflows.json")
docker cp "${ContainerName}:${ContainerPath}/updated_credentials.json" (Join-Path $OutputDir "updated_credentials.json")

Write-Host "Exports saved to: $OutputDir"

# Save current timestamp for next run
$now = (Get-Date).ToUniversalTime().ToString("o")
Set-Content -Path $TimestampFile -Value $now -Encoding UTF8
Write-Host "Timestamp saved: $now"

$elapsed = [math]::Round(((Get-Date) - $ExportStart).TotalSeconds, 1)
Write-Host "Done. Export completed in ${elapsed}s"