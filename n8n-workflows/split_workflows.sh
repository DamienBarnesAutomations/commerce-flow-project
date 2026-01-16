#!/bin/bash

# 1. Define Paths
# Adjust these to where your folders actually sit on your Linux host
EXPORT_PATH="./workflows.json"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
TARGET_DIR="./workflows_$TIMESTAMP"

# 2. Run the Docker Export
echo "📦 Exporting workflows from Docker..."
#docker exec standard_brain n8n export:workflow --all --output=/home/node/.n8n-files/workflows/workflows.json

# 3. Create the new subfolder
mkdir -p "$TARGET_DIR"

# 4. Check if export succeeded
if [ ! -f "$EXPORT_PATH" ]; then
    echo "❌ Error: Export file not found at $EXPORT_PATH"
    exit 1
fi

# 5. Split the JSON into individual files
cat "$EXPORT_PATH" | jq -c '.[]' | while read -r workflow; do
    
    # Extract ID and Raw Name
    eval $(echo "$workflow" | jq -r '@sh "WID=\(.id) WNAME=\(.name)"')
    
    # Apply your specific formatting
    TEMP_NAME=$(echo "$WNAME" | tr -cd '[:alnum:] ')
    CLEAN_NAME=$(echo "$TEMP_NAME" | awk '{
        for (i=1; i<=NF; i++) {
            $i = toupper(substr($i,1,1)) substr($i,2)
        }
        print $0
    }' | sed 's/ /_/g')

    FILE_NAME="${CLEAN_NAME}.json"
    
    # Save the file
    echo "$workflow" > "$TARGET_DIR/$FILE_NAME"
    echo "   ✅ Saved: $FILE_NAME"
done

echo "✨ All done! Original file kept at $EXPORT_PATH"