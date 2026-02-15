# 1. Define input and output
$envFile = ".env"
$outFile = "env_secrets.json"

if (Test-Path $envFile) {
    # 2. Read file, filter out comments/empty lines, and remove 'export '
    $entries = Get-Content $envFile | 
        Where-Object { $_ -match '=' -and -not $_.StartsWith('#') } | 
        ForEach-Object {
            $cleanLine = $_ -replace '^export\s+', ''
            # Split only on the FIRST equals sign to protect values containing '='
            $parts = $cleanLine.Split('=', 2)
            
            # Create a custom object for each pair
            [PSCustomObject]@{
                key   = $parts[0].Trim()
                value = $parts[1].Trim()
            }
        }

    # 3. Use PowerShell's built-in JSON converter
    # We transform the list of objects into a single dictionary (hash table)
    $hashTable = @{}
    foreach ($item in $entries) { $hashTable[$item.key] = $item.value }

    $hashTable | ConvertTo-Json | Out-File -FilePath $outFile -Encoding utf8

    Write-Host "Success! env_secrets.json created without needing jq."
} else {
    Write-Error ".env file not found."
}