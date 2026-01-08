#!/bin/bash

# Default Configuration
API_URL="https://sec.lemue.org"
UPDATE_URL="https://feed.sec.lemue.org/scripts/hfish-client.sh"
API_KEY="" 

# Load API Key from .env.apikeys if available
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
POSSIBLE_ENV_FILES=(
    "$SCRIPT_DIR/.env.apikeys"
    "/usr/local/bin/.env.apikeys"
    "/usr/bin/local/.env.apikeys"
    "/root/honey-scan/.env.apikeys"
    "./.env.apikeys"
)

for env_file in "${POSSIBLE_ENV_FILES[@]}"; do
    if [ -f "$env_file" ]; then
        # export variables from file
        export $(grep -v '^#' "$env_file" | xargs)
        # If API_KEY was loaded, break
        if [ -n "$API_KEY" ]; then
             break
        fi
    fi
done

# Self-Update Logic
self_update() {
    # Skip if running with --no-update argument to prevent infinite loops if something goes wrong
    if [[ "$*" == *"--no-update"* ]]; then
        return
    fi

    echo "Checking for updates..."
    
    # Create temp file
    TMP_FILE=$(mktemp)
    
    # Download latest version
    if wget -q "$UPDATE_URL" -O "$TMP_FILE"; then
        # Check if download was successful and is a valid script (basic check)
        if grep -q "bash" "$TMP_FILE"; then
            # Compare with current script
            # Calculate MD5 for simple comparison
            CURRENT_HASH=$(md5sum "$0" | awk '{print $1}')
            NEW_HASH=$(md5sum "$TMP_FILE" | awk '{print $1}')
            
            if [ "$CURRENT_HASH" != "$NEW_HASH" ]; then
                echo "Update found! Installing..."
                # Preserve permissions
                chmod --reference="$0" "$TMP_FILE"
                mv "$TMP_FILE" "$0"
                echo "Updated to latest version. Restarting..."
                # Re-run the script with the same arguments, adding --no-update to skip check this time
                exec "$0" "$@" --no-update
            else
                echo "Script is up to date."
                rm "$TMP_FILE"
            fi
        else
            echo "Warning: Downloaded update file seems invalid. Skipping update."
            rm "$TMP_FILE"
        fi
    else
        echo "Warning: Failed to check for updates."
        rm "$TMP_FILE"
    fi
}

# Run update check
self_update "$@"

# Filter out --no-update from args for the rest of the script
ARGS=()
for arg in "$@"; do
    [[ "$arg" == "--no-update" ]] && continue
    ARGS+=("$arg")
done
set -- "${ARGS[@]}"

# Help / Usage
usage() {
    echo "Usage: $0 <ip_address> [api_key] OR $0 --sync"
    echo "  --sync       : Sync last 200 banned IPs from Fail2Ban to API"
    echo "  <ip_address> : The attacker IP to ban (required)"
    echo "  [api_key]    : Your HFish API Key (optional if configured in script)"
    echo ""
    echo "You can also set the API_KEY variable directly in this script:"
    echo "  sudo nano $0"
    exit 1
}

# Sync History Logic
sync_history() {
    if ! command -v fail2ban-client &> /dev/null; then
        echo "Error: fail2ban-client not found. Cannot sync history."
        exit 1
    fi

    echo "Syncing up to 200 banned IPs from Fail2Ban..."
    
    # Get all jails
    JAILS=$(fail2ban-client status 2>/dev/null | grep "Jail list:" | sed 's/.*Jail list://' | tr ',' ' ')
    
    if [ -z "$JAILS" ]; then
        echo "No jails found or Fail2Ban not running."
        exit 0
    fi

    # Collect IPs from all jails
    ALL_IPS=""
    for JAIL in $JAILS; do
        IPS=$(fail2ban-client status "$JAIL" 2>/dev/null | grep -E "Banned IP list:|Invalid" | sed 's/.*Banned IP list://' | tr ',' ' ')
        ALL_IPS="$ALL_IPS $IPS"
    done

    # Process IPs: unique, clean, take last 200
    # Note: 'fail2ban-client status' output order is not strictly chronological, but good enough for snapshot
    UNIQUE_IPS=$(echo "$ALL_IPS" | tr ' ' '\n' | grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" | sort -u | head -n 200)
    
    COUNT=0
    TOTAL=$(echo "$UNIQUE_IPS" | wc -w)
    
    echo "Found $TOTAL unique IPs to sync."

    for IP in $UNIQUE_IPS; do
        ((COUNT++))
        echo "[$COUNT/$TOTAL] Syncing $IP..."
        
        # Reuse API key logic
        if [ -z "$API_KEY" ]; then
             echo "Error: API_KEY not configured."
             exit 1
        fi

        URL="$API_URL/api/v1/config/black_list/add?api_key=$API_KEY"
        PAYLOAD="{\"ip\": \"$IP\", \"memo\": \"Fail2ban Start Sync\"}"
        
        RESPONSE=$(curl -k -s -X POST "$URL" -H "Content-Type: application/json" -d "$PAYLOAD")
        echo "  Response: $RESPONSE"
        
        # Small delay to be nice to the API
        sleep 0.5
    done
    
    echo "Sync completed."
}

# Check arguments
if [ "$1" == "--sync" ]; then
    sync_history
    exit 0
fi

if [ -z "$1" ]; then
    usage
fi

TARGET_IP="$1"

# Check for API Key in args, then env var, then script variable
if [ -n "$2" ]; then
    API_KEY="$2"
fi

if [ -z "$API_KEY" ]; then
    echo "Error: API_KEY is missing. Provide it as the second argument or edit the script."
    usage
fi

# Construct the URL
URL="$API_URL/api/v1/config/black_list/add?api_key=$API_KEY"

# Payload
payload=$(cat <<EOF
{
  "ip": "$TARGET_IP",
  "memo": "Fail2ban Client Jail"
}
EOF
)

response=$(curl -k -s -X POST "$URL" \
     -H "Content-Type: application/json" \
     -d "$payload")

# Log result
KEY_MASKED="${API_KEY:0:5}..."
echo "$(date): IP $TARGET_IP sent with key $KEY_MASKED. Response: $response" >> /var/log/hfish-client-export.log
