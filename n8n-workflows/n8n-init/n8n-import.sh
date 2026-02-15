#!/bin/bash

# Check if CURRENT_ENV is set to 'dev'
if [ "$CURRENT_ENV" = "dev" ]; then
  echo "Current environment is 'dev'. Skipping import script."
  exec n8n
fi

# Your actual import logic starts here...
echo "Running import for $CURRENT_ENV environment..."
echo "Injecting environment variables into credentials template..."

eval "echo \"$(sed 's/"/\\"/g' /home/node/.n8n-files/workflows/n8n-init/creds-template.json)\"" > /tmp/creds_to_import.json    
  
echo "Importing credentials..."
n8n import:credentials --input=/tmp/creds_to_import.json

if [ -f "/home/node/.n8n-files/workflows/workflows.json" ]; then
  echo "Importing workflows..."
  n8n import:workflow --input=/home/node/.n8n-files/workflows/workflows.json
  
  echo "Gathering IDs and publishing..."
  
  echo "Activating workflows individually..."
  # We use n8n list:workflow, skip the header, and have awk print "ID|Name"
# The 'IFS=|' tells the read command to split the line at the pipe
  n8n list:workflow | awk -F'|' '
  {
    gsub(/^[ \t]+|[ \t]+$/, "", $1);
    gsub(/^[ \t]+|[ \t]+$/, "", $2);
    if ($1 != "") {
      system("echo \"Attempting to publish: " $2 " (ID: " $1 ")\"");
      system("n8n publish:workflow --id=\"" $1 "\"");
    }
  }'



fi

rm /tmp/creds_to_import.json

exec n8n