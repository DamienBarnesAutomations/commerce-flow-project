docker cp workflows.json standard_brain:/tmp/workflows.json
docker exec -it standard_brain n8n import:workflow --input=/tmp/workflows.json