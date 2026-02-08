#!/bin/sh
set -e

INIT_MARKER="/home/node/.n8n/init_complete"

if [ ! -f "$INIT_MARKER" ]; then
  echo "Injecting environment variables into credentials template..."

  # This clever line reads the template and evaluates the variables
  # It then outputs the 'real' JSON to a temporary file
  
  eval "echo \"$(sed 's/"/\\"/g' /home/node/.n8n-files/workflows/n8n-init/creds-template.json)\"" > /tmp/creds_to_import.json    
  
  echo "Importing credentials..."
  n8n import:credentials --input=/tmp/creds_to_import.json

  if [ -f "/home/node/.n8n-files/workflows/workflows.json" ]; then
    echo "Importing workflows..."
    n8n import:workflow --input=/home/node/.n8n-files/workflows/workflows.json
    
    echo "Activating workflows individually..."
    # 1. Get all IDs (using n8n list:workflow and cleaning the output)
    # 2. Loop through each ID and activate it
    for id in $(n8n list:workflow | grep -E '^[0-9]+' | awk '{print $1}'); do
        echo "Activating workflow ID: $id"
        n8n update:workflow --id=$id --active=true
    done
  fi


  rm /tmp/creds_to_import.json
  touch "$INIT_MARKER"
else
  echo "Initialization already complete."
fi

exec n8n
