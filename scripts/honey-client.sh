#!/bin/bash

# Configuration
API_URL="https://sec.lemue.org"
QUEUE_DIR="/var/lib/honey-scan/queue"
LOG_FILE="/var/log/honey-client.log"
FEED_JAIL="honey-feed"
LOCK_DIR="/var/lock/honey_client_export.lock"
PID_FILE="/var/run/honey_client_export.pid"

# Ensure queue directory exists
mkdir -p "$QUEUE_DIR"
chmod 700 "$QUEUE_DIR"

# --- SINGLETON CHECK ---
# (Simplified from legacy, keeping robust)
exec 200>"$PID_FILE.lock"
flock -n 200 || { echo "$(date): Script already running. Exiting." >> "$LOG_FILE"; exit 1; }
echo $$ > "$PID_FILE"

# Load API Key
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
POSSIBLE_ENV_FILES=(
    "$SCRIPT_DIR/.env.apikeys"
    "/usr/local/bin/.env.apikeys"
    "/root/honey-scan/.env.apikeys"
    "./.env.apikeys"
)

for env_file in "${POSSIBLE_ENV_FILES[@]}"; do
    if [ -f "$env_file" ]; then
        export $(grep -v '^#' "$env_file" | xargs)
        if [ -n "$API_KEY" ]; then break; fi
    fi
done

# Helper: Log
log() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Helper: Flush Queue
flush_queue() {
    # Check if queue has files
    shopt -s nullglob
    QUEUE_FILES=("$QUEUE_DIR"/*.json)
    
    if [ ${#QUEUE_FILES[@]} -eq 0 ]; then
        return
    fi
    
    log "Attempting to flush ${#QUEUE_FILES[@]} items from queue..."
    
    for qfile in "${QUEUE_FILES[@]}"; do
        # Extract data
        IP=$(jq -r '.ip' "$qfile")
        MEMO=$(jq -r '.memo' "$qfile")
        
        # Send
        if send_to_api "$IP" "$MEMO" "true"; then
            log "Queue: Successfully sent $IP. Removing $qfile"
            rm -f "$qfile"
            sleep 0.5 # Flood protection
        else
            log "Queue: Failed to send $IP. Keep in queue."
            # Stop flushing if API is down
            break
        fi
    done
}

# Helper: Send to API
# Returns 0 on success, 1 on failure
send_to_api() {
    local ip="$1"
    local memo="$2"
    local is_retry="$3"
    
    URL="$API_URL/api/v1/config/black_list/add"
    PAYLOAD=$(jq -n --arg ip "$ip" --arg memo "$memo" '{ip: $ip, memo: $memo}')
    
    # Send request with strict timeout (5s connect, 10s max)
    HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 \
        -X POST "$URL" \
        -H "Authorization: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD")
        
    if [[ "$HTTP_CODE" =~ ^2 ]]; then
        return 0
    else
        log "API Error for $ip. HTTP Code: $HTTP_CODE"
        return 1
    fi
}

# Helper: Queue Item
queue_item() {
    local ip="$1"
    local memo="$2"
    local timestamp=$(date +%s)
    local qfile="$QUEUE_DIR/${timestamp}_${ip}.json"
    
    jq -n --arg ip "$ip" --arg memo "$memo" '{ip: $ip, memo: $memo, created: '"$timestamp"'}' > "$qfile"
    log "Queued $ip due to API failure."
    
    # Prune old files (>72h = 259200s)
    find "$QUEUE_DIR" -name "*.json" -type f -mmin +4320 -delete
}

# Helper: Check Dedup
is_in_honey_feed() {
    local ip="$1"
    if command -v fail2ban-client &>/dev/null; then
        # Check if IP is currently banned in honey-feed
        # fail2ban-client status honey-feed checks might be slow if list is huge?
        # Alternative: keep a local cache of honey-feed? 
        # For now, trust fail2ban-client or 'ipset' if used by honey-nftables
        # Let's check fail2ban-client for correctness first.
        if fail2ban-client status "$FEED_JAIL" 2>/dev/null | grep -q "$ip"; then
            return 0 # Found
        fi
    fi
    return 1 # Not found
}

# --- MAIN LOGIC ---

TARGET_IP="$1"

if [ -z "$TARGET_IP" ]; then
    echo "Usage: $0 <ip_address>"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    log "Error: API_KEY missing."
    exit 1
fi

# 1. Dedup Check
if is_in_honey_feed "$TARGET_IP"; then
    log "Dedup: IP $TARGET_IP is already in $FEED_JAIL. Skipping report."
    exit 0
fi

# 2. Try Send
MEMO="Fail2ban Client Jail"
if send_to_api "$TARGET_IP" "$MEMO" "false"; then
    log "Success: Reported $TARGET_IP."
    # 3. Flush Queue (Piggyback)
    flush_queue
else
    # 4. Queue on Failure
    queue_item "$TARGET_IP" "$MEMO"
fi
