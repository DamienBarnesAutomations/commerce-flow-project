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
    n8n update:workflow --all --active=true
  fi

  rm /tmp/creds_to_import.json
  touch "$INIT_MARKER"
else
  echo "Initialization already complete."
fi

exec n8n
