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
    
    echo "Gathering IDs and publishing..."
    
    echo "Activating workflows individually..."
    for id in $(n8n list:workflow | tail -n +3 | awk '{print $1}' | sed '/^$/d'); do
      echo "Attempting to publish: $id"
      n8n publish:workflow --id="$id"
    done
  fi


  rm /tmp/creds_to_import.json
  touch "$INIT_MARKER"
else
  echo "Initialization already complete."
fi

exec n8n
