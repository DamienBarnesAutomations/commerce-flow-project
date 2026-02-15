# 1. Configuration
$envFile = ".env"
$outFile = "env_secrets.json"

# 2. Check for the CURRENT_ENV bypass (from our first step)
# This checks the environment variable of the Windows session
if ($env:CURRENT_ENV -eq "dev") {
    Write-Host "Environment is 'dev'. Skipping JSON conversion."
    exit 0
}

if (Test-Path $envFile) {
    # 3. Initialize an [ordered] hashtable to preserve sequence
    $jsonData = [ordered]@{}

    # 4. Process the file line by line
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        
        # Skip comments and empty lines
        if ($line -match '^[^#].*=') {
            # Remove 'export ' if present
            $cleanLine = $line -replace '^export\s+', ''
            
            # Split only on the FIRST '=' to protect values with '=' in them
            $parts = $cleanLine.Split('=', 2)
            
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            
            # Add to our ordered dictionary
            $jsonData[$key] = $value
        }
    }

    # 5. Convert to JSON and save
    # 'Compress' is optional; remove it if you want pretty-printed JSON
    $jsonData | ConvertTo-Json | Out-File -FilePath $outFile -Encoding utf8

    Write-Host "Done! Order maintained in $outFile"
} else {
    Write-Warning "Could not find $envFile"
}