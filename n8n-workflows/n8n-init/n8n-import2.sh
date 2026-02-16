#!/bin/bash

# Define paths for easier management
CREDS_TEMPLATE="/home/node/.n8n-files/workflows/n8n-init/creds-template.json"
WORKFLOWS_FILE="/home/node/.n8n-files/workflows/workflows.json"
TEMP_CREDS="/tmp/creds_to_import.json"

# Check if we should run the import logic
if [ "$CURRENT_ENV" = "dev" ]; then
    echo "Dev environment detected. Skipping automated imports."
else
    echo "Running import for $CURRENT_ENV environment..."
    
    # Process Credentials
    if [ -f "$CREDS_TEMPLATE" ]; then
        echo "Injecting environment variables into credentials template..."
        # Escapes quotes and evaluates variables within the JSON template
        eval "echo \"$(sed 's/"/\\"/g' "$CREDS_TEMPLATE")\"" > "$TEMP_CREDS"
        
        echo "Importing credentials..."
        n8n import:credentials --input="$TEMP_CREDS"
        rm -f "$TEMP_CREDS"
    fi

    # Process Workflows
    if [ -f "$WORKFLOWS_FILE" ]; then
        echo "Importing workflows..."
        n8n import:workflow --input="$WORKFLOWS_FILE"
        
        echo "Activating workflows..."
        # List workflows and activate them by ID
        n8n list:workflow | awk -F'|' 'NR>1 {
            gsub(/^[ \t]+|[ \t]+$/, "", $1);
            gsub(/^[ \t]+|[ \t]+$/, "", $2);
            if ($1 ~ /^[0-9]+$/) {
                print "Activating: " $2 " (ID: " $1 ")";
                system("n8n update:workflow --id=" $1 " --active=true");
            }
        }'
    fi
fi

# Start n8n
echo "Starting n8n..."
exec n8n