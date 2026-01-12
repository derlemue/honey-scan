#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Funktion: Efficient Sync Feed -> Local F2B (honey-feed jail)
#           - Headless Installation Support
#           - Persistence Configuration (15 Days DB)
#           - No interference with standard/legacy Jails
# ==============================================================================

# --- KONFIGURATION ---
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
FEED_URL="https://feed.sec.lemue.org/banned_ips.txt"

BAN_TIME=1209600 # 14 Tage
DB_PURGE_AGE=1296000 # 15 Tage (slightly longer than ban time to ensure persistence)
AUTO_UPDATE=true 
SCRIPT_URL="https://raw.githubusercontent.com/derlemue/honey-scan/main/scripts/banned_ips.sh"
SCRIPT_URL_BACKUP="https://raw.githubusercontent.com/derlemue/honey-scan/main/scripts/banned_ips.sh" 
DEBUG_UPDATE=true 

FEED_JAIL="honey-feed"

# --- COLORS & AESTHETICS ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- DEPENDENCY CHECK (Fail2Ban) ---
install_fail2ban() {
    echo -e "${BLUE}[INFO]${NC} Installing Fail2Ban (Headless/Auto)..."
    export DEBIAN_FRONTEND=noninteractive
    if command -v apt-get &>/dev/null; then
        apt-get update -q && apt-get install -y -q fail2ban
    elif command -v yum &>/dev/null; then
        yum install -y fail2ban
    else
        echo -e "${RED}[ERROR]${NC} No compatible package manager found. Please install fail2ban manually."
        exit 1
    fi
    
    if ! command -v fail2ban-client &>/dev/null; then
        echo -e "${RED}[ERROR]${NC} Installation failed. Exiting."
        exit 1
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Fail2Ban installed successfully."
}

if ! command -v fail2ban-client &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} Fail2Ban is not installed but required."
    
    # Check for interactive flag or assume headless if no tty
    if [ -t 0 ]; then
        echo -ne "${CYAN}[PROMPT]${NC} Would you like to install fail2ban now? (y/N) [15s timeout]: "
        read -t 15 -n 1 user_input
        echo "" 
        if [[ "$user_input" =~ ^[Yy]$ || -z "$user_input" ]]; then
            install_fail2ban
        else
             echo -e "${RED}[ERROR]${NC} Fail2Ban is required. Exiting."
             exit 1
        fi
    else
        # Headless mode: Auto-install
        echo -e "${BLUE}[INFO]${NC} Running in headless mode. Proceeding with auto-installation."
        install_fail2ban
    fi
fi

# --- BANNER ---
print_banner() {
    echo -e "${YELLOW}"
    echo "██╗  ██╗ ██████╗ ███╗   ██╗███████╗██╗   ██╗    ███████╗███████╗ ██████╗"
    echo "██║  ██║██╔═══██╗████╗  ██║██╔════╝╚██╗ ██╔╝    ██╔════╝██╔════╝██╔════╝"
    echo "███████║██║   ██║██╔██╗ ██║█████╗   ╚████╔╝     ███████╗█████╗  ██║     "
    echo "██╔══██║██║   ██║██║╚██╗██║██╔══╝    ╚██╔╝      ╚════██║██╔══╝  ██║     "
    echo "██║  ██║╚██████╔╝██║ ╚████║███████╗   ██║       ███████║███████╗╚██████╗"
    echo "╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝       ╚══════╝╚══════╝ ╚═════╝"
    echo -e "${NC}"
    echo -e "${BLUE}[INFO]${NC} Honey-Scan Banning Client - Version 3.1.1"
    echo -e "${BLUE}[INFO]${NC} Target Jail: ${YELLOW}$FEED_JAIL${NC}"
    echo -e "${BLUE}[INFO]${NC} Feed URL: ${YELLOW}$FEED_URL${NC}"
    echo "----------------------------------------------------------------"
}

print_banner

# --- SINGLETON CHECK ---
# Legacy fix: Remove old lock directory if it exists
LOCK_FILE="/var/lock/honey_client_bans.lock"
[ -d "$LOCK_FILE" ] && rm -rf "$LOCK_FILE"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo -e "${RED}[ERROR]${NC} Another instance is already running. Exiting."
    exit 1
fi

# --- AUTO UPDATE ---
self_update() {
    if [ "$AUTO_UPDATE" != "true" ]; then return; fi
    # Break loop if already restarted
    for arg in "$@"; do
        if [ "$arg" == "--restarted" ]; then return; fi
    done

    if ! command -v curl &> /dev/null || ! command -v md5sum &> /dev/null; then return; fi

    TEMP_FILE=$(mktemp)
    # Primary update attempt
    if curl -s --max-time 30 --connect-timeout 10 --retry 3 --retry-delay 5 --retry-connrefused -f "${SCRIPT_URL}?v=$(date +%s)" -o "$TEMP_FILE"; then
        [ "$DEBUG_UPDATE" = true ] && echo -e "${CYAN}[DEBUG]${NC} Primary update download successful."
    elif curl -s --max-time 30 --connect-timeout 10 --retry 3 --retry-delay 5 --retry-connrefused -f "${SCRIPT_URL_BACKUP}?v=$(date +%s)" -o "$TEMP_FILE"; then
        [ "$DEBUG_UPDATE" = true ] && echo -e "${CYAN}[DEBUG]${NC} Backup update download successful."
    else
        echo -e "${RED}[ERROR]${NC} Failed to download update from both primary and backup sources."
        rm -f "$TEMP_FILE"
        return
    fi

    # Security: Check if file is empty
    if [ ! -s "$TEMP_FILE" ]; then
        echo -e "${RED}[ERROR]${NC} Downloaded update is empty. Aborting."
        rm -f "$TEMP_FILE"
        return
    fi

    if ! bash -n "$TEMP_FILE"; then
        echo -e "${RED}[ERROR]${NC} Downloaded update has syntax errors. Aborting."
        rm -f "$TEMP_FILE"
        return
    fi
    
    LOCAL_HASH=$(md5sum "$0" | awk '{print $1}')
    REMOTE_HASH=$(md5sum "$TEMP_FILE" | awk '{print $1}')
    
    [ "$DEBUG_UPDATE" = true ] && echo -e "${CYAN}[DEBUG]${NC} Local Hash:  $LOCAL_HASH"
    [ "$DEBUG_UPDATE" = true ] && echo -e "${CYAN}[DEBUG]${NC} Remote Hash: $REMOTE_HASH"

    if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        echo -e "${YELLOW}[UPDATE]${NC} New version found. Updating..."
        cp "$TEMP_FILE" "$0"
        chmod +x "$0"
        rm -f "$TEMP_FILE"
        echo -e "----------------------------------------------------------------"
        exec bash "$0" "--restarted" "$@"
    fi
    rm -f "$TEMP_FILE"
}
self_update "$@"

# --- FAIL2BAN CONFIGURATION ---
echo -e "${BLUE}[INFO]${NC} Checking Fail2Ban configuration..."

NEED_RESTART=false

# 1. Custom Action Content
ACTION_FILE="/etc/fail2ban/action.d/honey-nftables.conf"
TEMP_ACTION=$(mktemp)
cat > "$TEMP_ACTION" <<'EOF'
[Definition]
# Option:  actionstart
actionstart = nft add table inet f2b-table
              nft add chain inet f2b-table f2b-chain { type filter hook input priority filter - 1\; }
              nft add set inet f2b-table addr-set-<name> { type ipv4_addr\; }
              nft add rule inet f2b-table f2b-chain ip saddr @addr-set-<name> reject

# Option:  actionstop
actionstop = nft delete set inet f2b-table addr-set-<name>

# Option:  actionban
actionban = nft add element inet f2b-table addr-set-<name> { <ip> }

# Option:  actionunban
actionunban = nft delete element inet f2b-table addr-set-<name> { <ip> }

[Init]
name = default
EOF

if [ ! -f "$ACTION_FILE" ] || ! cmp -s "$TEMP_ACTION" "$ACTION_FILE"; then
    echo -e "${BLUE}[INFO]${NC} Updating custom firewall action ($ACTION_FILE)..."
    mv "$TEMP_ACTION" "$ACTION_FILE"
    NEED_RESTART=true
else
    rm -f "$TEMP_ACTION"
fi

# 2. Jail Configuration
NFT_ACTION="honey-nftables"
CURRENT_WHITELIST="127.0.0.1/8 ::1"

# 2a. Feed Jail Filter (Dummy)
FEED_FILTER="/etc/fail2ban/filter.d/honey-feed.conf"
TEMP_FEED_FILTER=$(mktemp)
cat > "$TEMP_FEED_FILTER" <<EOF
[Definition]
failregex =
ignoreregex =
EOF

if [ ! -f "$FEED_FILTER" ] || ! cmp -s "$TEMP_FEED_FILTER" "$FEED_FILTER"; then
    echo -e "${BLUE}[INFO]${NC} Creating/Updating Feed Filter ($FEED_FILTER)..."
    mv "$TEMP_FEED_FILTER" "$FEED_FILTER"
    NEED_RESTART=true
else
    rm -f "$TEMP_FEED_FILTER"
fi

# 2b. Feed Jail Configuration
FEED_CONF="/etc/fail2ban/jail.d/honey-feed.conf"
TEMP_FEED_CONFIG=$(mktemp)

# Conditional Reporting: Check if hfish-client exists
REPORTING_ACTION=""
# Check for hfish-client in PATH or standard locations
if command -v hfish-client &>/dev/null; then
    REPORTING_ACTION="hfish-client"
    # Note: We assume if the binary exists, the action config is either present 
    # or the user is responsible for it on a custom setup. 
    # For a purely clean install, reporting is disabled unless hfish-client is pre-installed.
elif [ -f "/usr/local/bin/hfish-client" ]; then
     # Fallback check if not in PATH
     REPORTING_ACTION="hfish-client"
fi

[ -n "$REPORTING_ACTION" ] && echo -e "${BLUE}[INFO]${NC} Reporting enabled (found hfish-client)." || echo -e "${YELLOW}[INFO]${NC} Reporting disabled (hfish-client not found)."

cat > "$TEMP_FEED_CONFIG" <<EOF
[$FEED_JAIL]
enabled = true
# Persist Ban Time (14 Days)
bantime = $BAN_TIME
# Redundantly set banaction
banaction = $NFT_ACTION
# Whitelist
ignoreip = $CURRENT_WHITELIST
# Firewall Action AND Reporting (if available)
action = $NFT_ACTION
         $REPORTING_ACTION
EOF

if [ ! -f "$FEED_CONF" ] || ! cmp -s "$TEMP_FEED_CONFIG" "$FEED_CONF"; then
    echo -e "${BLUE}[INFO]${NC} Creating/Updating Feed Jail configuration ($FEED_CONF)..."
    mv "$TEMP_FEED_CONFIG" "$FEED_CONF"
    NEED_RESTART=true
else
    rm -f "$TEMP_FEED_CONFIG"
    echo -e "${GREEN}[OK]${NC} Feed Jail configuration up to date."
fi

# 3. Persistence Configuration (fail2ban.local)
# Ensure clean overrides for persistence
F2B_LOCAL="/etc/fail2ban/fail2ban.local"
if [ ! -f "$F2B_LOCAL" ]; then
    echo -e "${BLUE}[INFO]${NC} Creating persistence configuration ($F2B_LOCAL)..."
    echo "[Definition]" > "$F2B_LOCAL"
    echo "dbpurgeage = $DB_PURGE_AGE" >> "$F2B_LOCAL"
    NEED_RESTART=true
else
    # Check if correct value is set
    if ! grep -q "dbpurgeage = $DB_PURGE_AGE" "$F2B_LOCAL"; then
         echo -e "${BLUE}[INFO]${NC} Updating persistence configuration to 15 days..."
         # Use sed to replace or append
         if grep -q "dbpurgeage" "$F2B_LOCAL"; then
             sed -i "s/^dbpurgeage = .*/dbpurgeage = $DB_PURGE_AGE/" "$F2B_LOCAL"
         else
             # Append under Definition if exists, or just append
             echo "dbpurgeage = $DB_PURGE_AGE" >> "$F2B_LOCAL"
         fi
         NEED_RESTART=true
    fi
fi


# 4. Service Maintenance
if ! fail2ban-client status "$FEED_JAIL" &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} Jail '$FEED_JAIL' is not active. Restart required."
    NEED_RESTART=true
fi

# 5. Restart Logic
if [ "$NEED_RESTART" = true ]; then
    echo -e "${BLUE}[INFO]${NC} Configuration changed or service down. Restarting Fail2Ban..."
    service fail2ban restart &>/dev/null || systemctl restart fail2ban &>/dev/null
    systemctl enable fail2ban &>/dev/null
    
    # Wait for service to come up
    sleep 2
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${NC} Fail2Ban restarted and enabled successfully."
    else
        echo -e "${YELLOW}[WARN]${NC} Service restart failed. Trying client reload..."
        fail2ban-client reload &>/dev/null
    fi
else
    echo -e "${GREEN}[OK]${NC} Fail2Ban is running and config is stable. Skipping restart."
fi

# --- PERSISTENCE SETUP (Cron) ---
setup_persistence() {
    ABS_PATH=$(realpath "$0" 2>/dev/null)
    if [ -z "$ABS_PATH" ]; then
        ABS_PATH=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
    fi
    
    CURRENT_CRON=$(crontab -l 2>/dev/null)
    NEW_CRON=""
    CHANGED=false
    
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ -z "$line" ]]; then continue; fi
        if [[ "$line" == *"banned_ips.sh"* && "$line" != *"$ABS_PATH"* ]]; then
             echo -e "${YELLOW}[CLEAN]${NC} Removing stale cron entry: $line"
             CHANGED=true
             continue
        fi
        NEW_CRON+="$line"$'\n'
    done <<< "$CURRENT_CRON"

    HAS_REBOOT=false
    HAS_PERIODIC=false
    
    if echo "$NEW_CRON" | grep -Fq "@reboot $ABS_PATH"; then HAS_REBOOT=true; fi
    if echo "$NEW_CRON" | grep -E "^[0-9*/,-]+ +[0-9*/,-]+ +[0-9*/,-]+ +[0-9*/,-]+ +[0-9*/,-]+ +.*$ABS_PATH" > /dev/null; then HAS_PERIODIC=true; fi

    if [ "$HAS_REBOOT" = false ]; then
        NEW_CRON+="@reboot $ABS_PATH >> /var/log/banned_ips.log 2>&1"$'\n'
        CHANGED=true
        echo -e "${GREEN}[OK]${NC} Added @reboot job."
    else
        [ "$DEBUG_UPDATE" = true ] && echo -e "${GREEN}[OK]${NC} @reboot job already exists."
    fi

    if [ "$HAS_PERIODIC" = false ]; then
        NEW_CRON+="*/15 * * * * $ABS_PATH >> /var/log/banned_ips.log 2>&1"$'\n'
        CHANGED=true
        echo -e "${GREEN}[OK]${NC} Added periodic job (15 min)."
    else
        EXISTING_JOB=$(echo "$NEW_CRON" | grep -E "^[0-9*/,-]+ +.*$ABS_PATH" | head -n 1)
        if [ "$CHANGED" = true ] || [ "$DEBUG_UPDATE" = true ]; then
             echo -e "${GREEN}[OK]${NC} Preserving existing periodic job: ${YELLOW}$EXISTING_JOB${NC}"
        fi
    fi
    
    if [ "$CHANGED" = true ]; then
        echo -n "$NEW_CRON" | crontab -
        echo -e "${GREEN}[SUCCESS]${NC} Persistence configuration updated."
    fi
}
setup_persistence

# Set Ban Time dynamically (Best Effort)
if fail2ban-client set "$FEED_JAIL" bantime "$BAN_TIME" &>/dev/null; then
    echo -e "${GREEN}[OK]${NC} Jail '$FEED_JAIL' bantime set to ${YELLOW}$BAN_TIME${NC} seconds."
fi

# --- CORE SET FOR PROCESSING ---
# 1. Fetch Remote IPs
echo -e "${BLUE}[STEP 1/3]${NC} Fetching remote ban list..."
REMOTE_FILE=$(mktemp)
DOWNLOAD_FILE=$(mktemp)

if curl -s --max-time 30 --connect-timeout 10 --retry 3 --retry-delay 5 --retry-connrefused -f "$FEED_URL" -o "$DOWNLOAD_FILE"; then
    echo -e "${GREEN}[OK]${NC} Received IPs from primary feed."
else
    echo -e "${RED}[ERROR]${NC} Failed to fetch feed from primary source."
    rm -f "$DOWNLOAD_FILE" "$REMOTE_FILE"
    exit 1
fi

if [ ! -s "$DOWNLOAD_FILE" ]; then
     echo -e "${RED}[ERROR]${NC} Downloaded feed is empty. Aborting."
     rm -f "$DOWNLOAD_FILE" "$REMOTE_FILE"
     exit 1
fi

grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' "$DOWNLOAD_FILE" > "$REMOTE_FILE"
REMOTE_COUNT=$(wc -l < "$REMOTE_FILE")
echo -e "${GREEN}[OK]${NC} Validated ${YELLOW}$REMOTE_COUNT${NC} IPs from feed."
rm -f "$DOWNLOAD_FILE"

# 2. Sync IPs to Fail2Ban
echo -e "${BLUE}[STEP 2/3]${NC} Syncing IPs to Fail2Ban jail '$FEED_JAIL'..."

EXISTING_BANS_FILE=$(mktemp)
fail2ban-client status "$FEED_JAIL" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -s ' ' '\n' | sort -u > "$EXISTING_BANS_FILE"

IPS_TO_BAN_FILE=$(mktemp)
sort -u "$REMOTE_FILE" | comm -23 - "$EXISTING_BANS_FILE" > "$IPS_TO_BAN_FILE"

COUNT_TO_BAN=$(wc -l < "$IPS_TO_BAN_FILE")

if [ "$COUNT_TO_BAN" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} No new IPs to ban. All feed IPs are already jailed."
else
    echo -e "${BLUE}[INFO]${NC} Found ${YELLOW}$COUNT_TO_BAN${NC} new IPs to ban."
    CURRENT=0
    
    # Safety: Add timeout loop for very large imports to prevent script hang
    START_TIME=$(date +%s)
    MAX_RUNTIME=600 # 10 Minutes max for the banning loop

    while IFS= read -r ip; do
        NOW=$(date +%s)
        ELAPSED=$((NOW - START_TIME))
        if [ "$ELAPSED" -gt "$MAX_RUNTIME" ]; then
             echo ""
             echo -e "${RED}[WARN]${NC} Max runtime exceeded ($MAX_RUNTIME s). Stopping import to allow next run to continue."
             break
        fi

        fail2ban-client set "$FEED_JAIL" banip "$ip" &>/dev/null
        ((CURRENT++))
        
        if ((CURRENT % 50 == 0)); then
             print_banner
             echo -ne "\r${BLUE}[INFO]${NC} Banning progress: $CURRENT / $COUNT_TO_BAN"
        fi
    done < "$IPS_TO_BAN_FILE"
    echo "" # Newline
    echo -e "${GREEN}[OK]${NC} Finished banning new IPs."
fi

# New: Remove IPs that are no longer in the feed
echo -e "${BLUE}[INFO]${NC} Checking for IPs to unban (no longer in feed)..."
IPS_TO_UNBAN_FILE=$(mktemp)
sort -u "$REMOTE_FILE" | comm -13 - "$EXISTING_BANS_FILE" > "$IPS_TO_UNBAN_FILE"

COUNT_TO_UNBAN=$(wc -l < "$IPS_TO_UNBAN_FILE")

if [ "$COUNT_TO_UNBAN" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} No stale bans found."
else
    echo -e "${YELLOW}[INFO]${NC} Found ${YELLOW}$COUNT_TO_UNBAN${NC} stale IPs to unban."
    UNBANNED=0
    while IFS= read -r ip; do
        if [[ -z "$ip" ]]; then continue; fi
        fail2ban-client set "$FEED_JAIL" unbanip "$ip" &>/dev/null
        ((UNBANNED++))
        
        if ((UNBANNED % 50 == 0)); then
             echo -ne "\r${BLUE}[INFO]${NC} Unbanning progress: $UNBANNED / $COUNT_TO_UNBAN"
        fi
    done < "$IPS_TO_UNBAN_FILE"
    echo "" # Newline
    echo -e "${GREEN}[OK]${NC} Finished unbanning stale IPs."
fi

rm -f "$EXISTING_BANS_FILE" "$IPS_TO_BAN_FILE" "$REMOTE_FILE" "$IPS_TO_UNBAN_FILE"

# 3. Summary
echo -e "${BLUE}[STEP 3/3]${NC} Verification..."
TOTAL_BANS=$(fail2ban-client status "$FEED_JAIL" | grep "Currently banned:" | sed 's/.*Currently banned://' | tr -d ' ')
echo -e "${BLUE}[INFO]${NC} Total currently banned IPs in jail '$FEED_JAIL': ${YELLOW}$TOTAL_BANS${NC}"

echo "----------------------------------------------------------------"
echo -e "${GREEN}[SUCCESS]${NC} Sync completed at $(date)"
