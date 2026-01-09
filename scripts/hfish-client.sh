#!/bin/bash

# Default Configuration
API_URL="https://sec.lemue.org"
UPDATE_URL="https://raw.githubusercontent.com/derlemue/honey-scan/refs/heads/main/scripts/hfish-client.sh"
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
        
        # Support BOOTSTRAP_API_KEY as fallback
        if [ -z "$API_KEY" ] && [ -n "$BOOTSTRAP_API_KEY" ]; then
            API_KEY="$BOOTSTRAP_API_KEY"
        fi
        
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
    
    # Download latest version (verbose)
    if wget "$UPDATE_URL" -O "$TMP_FILE"; then
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
    echo "  --sync       : Sync ALL banned IPs from Fail2Ban to API"
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

    echo "Syncing banned IPs from Fail2Ban..."
    
    # Check for prerequisites
    if ! command -v comm &> /dev/null; then
        echo "Error: 'comm' command not found. Please install coreutils."
        exit 1
    fi

    # 1. Fetch Remote List
    REMOTE_FEED_URL="https://raw.githubusercontent.com/derlemue/honey-scan/refs/heads/main/feed/banned_ips.txt"
    TEMP_REMOTE=$(mktemp)
    TEMP_LOCAL=$(mktemp)
    TEMP_DIFF=$(mktemp)

    echo "Fetching current banned list from $REMOTE_FEED_URL..."
    curl -s -k "$REMOTE_FEED_URL" | sort > "$TEMP_REMOTE"
    
    REMOTE_COUNT=$(wc -l < "$TEMP_REMOTE")
    echo "Fetched $REMOTE_COUNT IPs from remote feed."

    # 2. Get Local Fail2Ban IPs
    JAILS=$(fail2ban-client status 2>/dev/null | grep "Jail list:" | sed 's/.*Jail list://' | tr ',' ' ')
    
    if [ -z "$JAILS" ]; then
        echo "No jails found or Fail2Ban not running."
        rm -f "$TEMP_REMOTE" "$TEMP_LOCAL" "$TEMP_DIFF"
        exit 0
    fi

    ALL_IPS=""
    for JAIL in $JAILS; do
        IPS=$(fail2ban-client status "$JAIL" 2>/dev/null | grep -E "Banned IP list:|Invalid" | sed 's/.*Banned IP list://' | tr ',' ' ')
        ALL_IPS="$ALL_IPS $IPS"
    done

    # Sort local IPs for comparison
    echo "$ALL_IPS" | tr ' ' '\n' | grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" | sort -u > "$TEMP_LOCAL"
    LOCAL_COUNT=$(wc -l < "$TEMP_LOCAL")

    # 3. Calculate Difference (Local - Remote)
    # comm -23 suppresses col 2 (unique to file 2) and col 3 (common), leaving unique to file 1 (Local)
    comm -23 "$TEMP_LOCAL" "$TEMP_REMOTE" > "$TEMP_DIFF"
    
    DIFF_COUNT=$(wc -l < "$TEMP_DIFF")
    
    echo "Local IPs: $LOCAL_COUNT | Remote IPs: $REMOTE_COUNT | New IPs to sync: $DIFF_COUNT"

    if [ "$DIFF_COUNT" -eq 0 ]; then
        echo "No new IPs to sync."
        rm -f "$TEMP_REMOTE" "$TEMP_LOCAL" "$TEMP_DIFF"
        exit 0
    fi

    COUNT=0
    # Read line by line from difference file
    while IFS= read -r IP; do
        ((COUNT++))
        echo "[$COUNT/$DIFF_COUNT] Syncing $IP..."
        
        # Reuse API key logic
        if [ -z "$API_KEY" ]; then
             echo "Error: API_KEY not configured."
             exit 1
        fi

        URL="$API_URL/api/v1/config/black_list/add"
        PAYLOAD="{\"ip\": \"$IP\", \"memo\": \"Fail2ban Start Sync\"}"
        
        RESPONSE=$(curl -k -s -X POST "$URL" \
            -H "Authorization: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD")
        echo "  Response: $RESPONSE"
        
        # 500ms delay
        sleep 0.5
    done < "$TEMP_DIFF"
    
    # Cleanup
    rm -f "$TEMP_REMOTE" "$TEMP_LOCAL" "$TEMP_DIFF"
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
URL="$API_URL/api/v1/config/black_list/add"

# Payload
payload=$(cat <<EOF
{
  "ip": "$TARGET_IP",
  "memo": "Fail2ban Client Jail"
}
EOF
)

response=$(curl -k -s -X POST "$URL" \
     -H "Authorization: $API_KEY" \
     -H "Content-Type: application/json" \
     -d "$payload")

# Log result
KEY_MASKED="${API_KEY:0:5}..."
echo "$(date): IP $TARGET_IP sent with key $KEY_MASKED. Response: $response" >> /var/log/hfish-client-export.log

# User Feedback
echo "Success: Blocked $TARGET_IP and reported to API."
