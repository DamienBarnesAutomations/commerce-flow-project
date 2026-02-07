#!/bin/bash

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required."
    exit 1
fi

# 1. tr -d '\r' removes those Windows Carriage Returns
# 2. grep removes comments and empty lines
# 3. sed removes 'export ' if present
# 4. jq builds the JSON object
cat .env | tr -d '\r' | grep -v '^#' | grep '=' | sed 's/^export //g' | jq -R -s '
  split("\n") | 
  map(select(length > 0)) | 
  map(capture("(?<key>[^=]+)=(?<value>.*)")) | 
  from_entries
' > env_secrets.json

echo "Done! The \r characters are gone. Check env_secrets.json"
