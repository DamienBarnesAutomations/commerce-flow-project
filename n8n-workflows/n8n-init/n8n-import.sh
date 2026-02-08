#!/bin/sh
set -e

INIT_MARKER="/home/node/.n8n/init_complete"

if [ ! -f "$INIT_MARKER" ]; then
  echo "Injecting environment variables into credentials template..."

  # This clever line reads the template and evaluates the variables
  # It then outputs the 'real' JSON to a temporary file
  
  eval "echo \"$(cat /home/node/.n8n-files/workflows/n8n-init/creds-template.json)\"" > /tmp/creds_to_import.json
    
  echo "Importing credentials..."
  n8n import:credentials --input=/tmp/creds_to_import.json

  if [ -f "/home/node/.n8n-files/workflows/workflows.json" ]; then
    echo "Importing workflows..."
    eval "echo \"$(cat /home/node/.n8n-files/workflows/workflows.json)\"" > /tmp/workflows.json
    n8n import:workflow --input=/tmp/workflows.json
  fi

  rm /tmp/creds_to_import.json
  touch "$INIT_MARKER"
else
  echo "Initialization already complete."
fi

exec n8n
