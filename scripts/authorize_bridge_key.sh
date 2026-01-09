#!/bin/bash
# Authorize an API Key in the Threat Intelligence Bridge (honey-api)
# Usage: ./authorize_bridge_key.sh [API_KEY]

API_KEY=${1:-"ff56ec66-8cfa-4ee4-93e1-92f64b76971b"}

echo "Authorizing API Key: $API_KEY"

# Check if redis container is running
if docker ps | grep -q "honey-api-redis-1"; then
    docker exec honey-api-redis-1 redis-cli sadd ti:api_keys "$API_KEY"
    echo "Done."
else
    echo "Error: honey-api-redis-1 container not found."
    exit 1
fi
