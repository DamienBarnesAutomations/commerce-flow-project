#!/bin/sh
set -e

echo "Injecting environment variables into credentials template..."

eval "echo \"$(sed 's/"/\\"/g' /home/node/.n8n-files/workflows/n8n-init/creds-template.json)\"" > /tmp/creds_to_import.json    
  
echo "Importing credentials..."
n8n import:credentials --input=/tmp/creds_to_import.json

if [ -f "/home/node/.n8n-files/workflows/workflows.json" ]; then
  echo "Importing workflows..."
  n8n import:workflow --input=/home/node/.n8n-files/workflows/workflows.json
  
  echo "Gathering IDs and publishing..."
  
  echo "Activating workflows individually..."
  for id in $(n8n list:workflow | tail -n +2 | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}'); do
    echo "Attempting to publish: $id"
    n8n publish:workflow --id="$id"
  done
fi
rm /tmp/creds_to_import.json

exec n8n
