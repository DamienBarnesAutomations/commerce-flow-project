docker cp workflows.json n8n_app:/tmp/workflows.json
docker exec -it n8n_app n8n import:workflow --input=/tmp/workflows.json