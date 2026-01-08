#!/bin/bash
# API Key Management Script
# Usage: ./manage_keys.sh [list|create <memo>|delete <id>]

API_URL="http://localhost:4444"

# Determine script location to find .env.apikeys relative to project root
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

if [ -f "$PROJECT_ROOT/.env.apikeys" ]; then
    export $(grep -v '^#' "$PROJECT_ROOT/.env.apikeys" | xargs)
elif [ -f ".env.apikeys" ]; then
    export $(grep -v '^#' ".env.apikeys" | xargs)
fi

# If not in env, check if provided as arg (not recommended) or try to find in logs? 
# For now, rely on BOOTSTRAP_API_KEY being set.
if [ -z "$BOOTSTRAP_API_KEY" ]; then
    # Fallback to checking logs if we are in a pinch, or user manual input
    echo "BOOTSTRAP_API_KEY not found in environment or .env.apikeys."
    echo "Checking logs..."
    BOOTSTRAP_API_KEY=$(docker logs hfish-sidecar-v2 2>&1 | grep "BOOTSTRAP API KEY GENERATED" | tail -n1 | awk '{print $NF}' | tr -d '!')
    
    if [ -z "$BOOTSTRAP_API_KEY" ]; then
        echo "Error: Could not determine API Key. Please set BOOTSTRAP_API_KEY."
        exit 1
    fi
fi

COMMAND=$1

case $COMMAND in
    list)
        echo "Listing API Keys..."
        curl -s -H "api-key: $BOOTSTRAP_API_KEY" "$API_URL/api/v1/keys" | jq .
        ;;
    create)
        MEMO=$2
        if [ -z "$MEMO" ]; then
            echo "Usage: ./manage_keys.sh create <memo>"
            exit 1
        fi
        echo "Creating API Key for '$MEMO'..."
        curl -s -X POST -H "Content-Type: application/json" -H "api-key: $BOOTSTRAP_API_KEY" -d "{\"memo\":\"$MEMO\"}" "$API_URL/api/v1/keys" | jq .
        ;;
    delete)
        ID=$2
        if [ -z "$ID" ]; then
            echo "Usage: ./manage_keys.sh delete <id>"
            exit 1
        fi
        echo "Deleting API Key ID $ID..."
        curl -s -X DELETE -H "api-key: $BOOTSTRAP_API_KEY" "$API_URL/api/v1/keys/$ID" | jq .
        ;;
    *)
        echo "Usage: ./manage_keys.sh [list|create <memo>|delete <id>]"
        exit 1
        ;;
esac
