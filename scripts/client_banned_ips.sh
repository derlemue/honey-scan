#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Funktion: Efficient Sync Feed -> Local F2B (sshd) & TCP/UDP Dual-Block
# ==============================================================================

# --- KONFIGURATION ---
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
FEED_URL="https://feed.sec.lemue.org/banned_ips.txt"
BAN_TIME=1209600 # 14 Tage
AUTO_UPDATE=true 
SCRIPT_URL="https://raw.githubusercontent.com/derlemue/honey-scan/main/scripts/client_banned_ips.sh"
JAIL="sshd"

# --- COLORS & AESTHETICS ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- DEPENDENCY CHECK (Fail2Ban) ---
if ! command -v fail2ban-client &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} Fail2Ban is not installed but required."
    echo -ne "${CYAN}[PROMPT]${NC} Would you like to install fail2ban now? (y/N) [15s timeout]: "
    read -t 15 -n 1 user_input
    echo "" # Newline after input

    if [[ "$user_input" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}[INFO]${NC} Installing Fail2Ban..."
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y fail2ban
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
    else
        echo -e "${RED}[ERROR]${NC} Fail2Ban is required for this script. Exiting."
        exit 1
    fi
fi

# --- BANNER ---
echo -e "${CYAN}"
echo "  _    _  ____  _   _ ______     __  _____  _____          _   _ "
echo " | |  | |/ __ \| \ | |  ____|   / / / ____|/ ____|   /\   | \ | |"
echo " | |__| | |  | |  \| | |__     / / | (___ | |       /  \  |  \| |"
echo " |  __  | |  | | . \` |  __|   / /   \___ \| |      / /\ \ | . \` |"
echo " | |  | | |__| | |\  | |____ / /    ____) | |____ / ____ \| |\  |"
echo " |_|  |_|\____/|_| \_|______/_/    |_____/ \_____/_/    \_\_| \_|"
echo -e "${NC}"
echo -e "${BLUE}[INFO]${NC} Honey-Scan Banning Client - Version 2.5.6"
echo -e "${BLUE}[INFO]${NC} Target Jail: ${YELLOW}$JAIL${NC}"
echo -e "${BLUE}[INFO]${NC} Feed URL: ${YELLOW}$FEED_URL${NC}"
echo -e "${BLUE}[INFO]${NC} Auto-Update: ${YELLOW}${AUTO_UPDATE}${NC}"
echo "----------------------------------------------------------------"

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
    # Use cache-buster to avoid CDN issues
    if curl -s -f "${SCRIPT_URL}?v=$(date +%s)" -o "$TEMP_FILE"; then
        if ! bash -n "$TEMP_FILE"; then
            rm -f "$TEMP_FILE"
            return
        fi
        
        LOCAL_HASH=$(md5sum "$0" | awk '{print $1}')
        REMOTE_HASH=$(md5sum "$TEMP_FILE" | awk '{print $1}')
        
        if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
            echo -e "${YELLOW}[UPDATE]${NC} New version found. Updating..."
            cp "$TEMP_FILE" "$0"
            chmod +x "$0"
            rm -f "$TEMP_FILE"
            echo -e "${BLUE}[INFO]${NC} Honey-Scan Banning Client - Version 2.5.8"
echo -e "${BLUE}[INFO]${NC} Target Jail: ${YELLOW}$JAIL${NC}"
echo -e "${BLUE}[INFO]${NC} Feed URL: ${YELLOW}$FEED_URL${NC}"
echo -e "${BLUE}[INFO]${NC} Auto-Update: ${YELLOW}${AUTO_UPDATE}${NC}"
echo "----------------------------------------------------------------"
            exec bash "$0" "--restarted" "$@"
        fi
        rm -f "$TEMP_FILE"
    fi
}
self_update "$@"

# --- FAIL2BAN CONFIGURATION ---
echo -e "${BLUE}[INFO]${NC} Configuring Fail2Ban jail '${YELLOW}$JAIL${NC}'..."

# Ensure Jail is Running
if ! fail2ban-client status "$JAIL" &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} Jail '$JAIL' is not active. Attempting to start..."
    fail2ban-client start "$JAIL" 2>/dev/null || { echo -e "${RED}[ERROR]${NC} Could not start $JAIL jail."; exit 1; }
fi

# 1. Enforce ALL PORTS blocking (TCP & UDP)
# We use defaults-debian.conf in jail.d to ensure we override system defaults reliability.
OVERRIDE_CONF="/etc/fail2ban/jail.d/defaults-debian.conf"

# Detect valid nftables action
# We prefer nftables-allports, but fallback to multiport or common if missing.
# This prevents "silent failure" if the specific action file is missing.
NFT_ACTION="nftables-allports"
if [ -f "/etc/fail2ban/action.d/nftables-allports.conf" ]; then
    NFT_ACTION="nftables-allports"
elif [ -f "/etc/fail2ban/action.d/nftables-multiport.conf" ]; then
    NFT_ACTION="nftables-multiport"
    echo -e "${YELLOW}[WARN]${NC} 'nftables-allports' not found. Falling back to '${NFT_ACTION}'."
elif [ -f "/etc/fail2ban/action.d/nftables.conf" ]; then
    NFT_ACTION="nftables"
    echo -e "${YELLOW}[WARN]${NC} 'nftables-allports' not found. Falling back to '${NFT_ACTION}'."
else
    # Fallback for very old systems or iptables users
    NFT_ACTION="iptables-allports"
    echo -e "${YELLOW}[WARN]${NC} No nftables action found. Falling back to '${NFT_ACTION}'."
fi

# Define the ACTION line. We explicitly construct it to avoid variable expansion issues.
# Simplified for compatibility: We remove parameters [name=..., port=...] as 'allports' implies Global blocking.
ACTION_SPEC="action = $NFT_ACTION"

# Check if hfish-client action exists
if [ -f "/etc/fail2ban/action.d/hfish-client.conf" ]; then
    echo -e "${BLUE}[INFO]${NC} Detected 'hfish-client' action. Adding to configuration..."
    ACTION_SPEC="$ACTION_SPEC
         hfish-client"
fi

CONFIG_CONTENT="[sshd]
enabled = true
# Redundantly set banaction to ensure Fail2Ban knows what to use for banning itself
banaction = $NFT_ACTION
# Enforce our detected action (All Ports)
$ACTION_SPEC"

# Logic: Always recreate the file to ensure clean state
if [ -f "$OVERRIDE_CONF" ]; then
    echo -e "${BLUE}[INFO]${NC} Replacing existing Fail2Ban configuration ($OVERRIDE_CONF)..."
    rm -f "$OVERRIDE_CONF"
else
    echo -e "${BLUE}[INFO]${NC} Creating Fail2Ban configuration ($OVERRIDE_CONF)..."
fi

bash -c "cat > $OVERRIDE_CONF" <<EOF
$CONFIG_CONTENT
EOF

# Restart is necessary to clear old ghost actions (like sendmail)
echo -e "${BLUE}[INFO]${NC} Restarting Fail2Ban to ensure clean configuration load..."
service fail2ban restart &>/dev/null || systemctl restart fail2ban &>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} Fail2Ban restarted successfully."
else
    echo -e "${YELLOW}[WARN]${NC} Service restart failed. Trying client reload..."
    fail2ban-client reload &>/dev/null
fi

# Set Ban Time dynamically
# Note: This affects new bans.
if fail2ban-client set "$JAIL" bantime "$BAN_TIME" &>/dev/null; then
    echo -e "${GREEN}[OK]${NC} Jail '$JAIL' bantime set to ${YELLOW}$BAN_TIME${NC} seconds."
else
    echo -e "${RED}[WARN]${NC} Could not set bantime dynamically. Using jail defaults."
fi

# --- CORE LOGIC ---

# 1. Fetch Remote IPs
echo -e "${BLUE}[STEP 1/3]${NC} Fetching remote ban list..."
REMOTE_FILE=$(mktemp)
curl -s "$FEED_URL" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'> "$REMOTE_FILE"
REMOTE_COUNT=$(wc -l < "$REMOTE_FILE")
echo -e "${GREEN}[OK]${NC} Received ${YELLOW}$REMOTE_COUNT${NC} IPs from feed."

# 2. Sync IPs to Fail2Ban
echo -e "${BLUE}[STEP 2/3]${NC} Syncing IPs to Fail2Ban jail '$JAIL'..."

# Get currently banned IPs to avoid redundant calls (Optimization)
EXISTING_BANS_FILE=$(mktemp)
fail2ban-client status "$JAIL" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -s ' ' '\n' | sort -u > "$EXISTING_BANS_FILE"

# Prepare IPs to ban: Remote IPs minus Existing Bans
IPS_TO_BAN_FILE=$(mktemp)
sort -u "$REMOTE_FILE" | comm -23 - "$EXISTING_BANS_FILE" > "$IPS_TO_BAN_FILE"

COUNT_TO_BAN=$(wc -l < "$IPS_TO_BAN_FILE")

if [ "$COUNT_TO_BAN" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} No new IPs to ban. All feed IPs are already jailed."
else
    echo -e "${BLUE}[INFO]${NC} Found ${YELLOW}$COUNT_TO_BAN${NC} new IPs to ban."
    
    # Process in chunks to give feedback
    CURRENT=0
    
    while IFS= read -r ip; do
        fail2ban-client set "$JAIL" banip "$ip" &>/dev/null
        ((CURRENT++))
        
        # Progress bar every 50 IPs
        if ((CURRENT % 50 == 0)); then
             echo -ne "\r${BLUE}[INFO]${NC} Banning progress: $CURRENT / $COUNT_TO_BAN"
        fi
    done < "$IPS_TO_BAN_FILE"
    echo "" # Newline
    echo -e "${GREEN}[OK]${NC} Finished banning new IPs."
fi

rm -f "$EXISTING_BANS_FILE" "$IPS_TO_BAN_FILE" "$REMOTE_FILE"

# 3. Summary
echo -e "${BLUE}[STEP 3/3]${NC} Verification..."
TOTAL_BANS=$(fail2ban-client status "$JAIL" | grep "Currently banned:" | sed 's/.*Currently banned://' | tr -d ' ')
echo -e "${BLUE}[INFO]${NC} Total currently banned IPs in jail '$JAIL': ${YELLOW}$TOTAL_BANS${NC}"

echo "----------------------------------------------------------------"
echo -e "${GREEN}[SUCCESS]${NC} Sync completed at $(date)"
