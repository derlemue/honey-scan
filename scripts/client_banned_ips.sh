#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Funktion: Efficient Sync Feed -> Local F2B (sshd) & TCP/UDP Dual-Block
# ==============================================================================

# --- KONFIGURATION ---
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

# --- BANNER ---
echo -e "${CYAN}"
echo "  _    _  ____  _   _ ______     __  _____  _____          _   _ "
echo " | |  | |/ __ \| \ | |  ____|   / / / ____|/ ____|   /\   | \ | |"
echo " | |__| | |  | |  \| | |__     / / | (___ | |       /  \  |  \| |"
echo " |  __  | |  | | . \` |  __|   / /   \___ \| |      / /\ \ | . \` |"
echo " | |  | | |__| | |\  | |____ / /    ____) | |____ / ____ \| |\  |"
echo " |_|  |_|\____/|_| \_|______/_/    |_____/ \_____/_/    \_\_| \_|"
echo -e "${NC}"
echo -e "${BLUE}[INFO]${NC} Honey-Scan Banning Client - Version 2.0.0"
echo -e "${BLUE}[INFO]${NC} Target Jail: ${YELLOW}$JAIL${NC}"
echo -e "${BLUE}[INFO]${NC} Feed URL: ${YELLOW}$FEED_URL${NC}"
echo "----------------------------------------------------------------"

# --- SINGLETON CHECK ---
LOCK_DIR="/var/lock/honey_client_bans.lock"
PID_FILE="/var/run/honey_client_bans.pid"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if [ "$OLD_PID" != "$$" ] && kill -0 "$OLD_PID" 2>/dev/null; then
            echo -e "${RED}[ERROR]${NC} Process $OLD_PID is already running. Exiting."
            exit 1
        fi
    fi
    rm -rf "$LOCK_DIR"
    mkdir "$LOCK_DIR"
fi
echo $$ > "$PID_FILE"
cleanup() { rm -f "$PID_FILE"; rm -rf "$LOCK_DIR"; }
trap cleanup EXIT

# --- AUTO UPDATE ---
self_update() {
    if [ "$AUTO_UPDATE" != "true" ]; then return; fi
    if ! command -v curl &> /dev/null || ! command -v md5sum &> /dev/null; then return; fi

    TEMP_FILE=$(mktemp)
    if curl -s -f "$SCRIPT_URL" -o "$TEMP_FILE"; then
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
            echo -e "${GREEN}[SUCCESS]${NC} Update successful. Restarting script..."
            exec "$0" "$@"
        fi
        rm -f "$TEMP_FILE"
    fi
}
self_update

# --- FIREWALL FUNKTION ---

# Probe all open ports (TCP/UDP)
DETECTED_PORTS=$(ss -tuln | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -un | tr '\n' ',' | sed 's/,$//')
echo -e "${BLUE}[INFO]${NC} Detected Open Ports: ${YELLOW}$DETECTED_PORTS${NC}"

setup_firewall_set() {
    # Discovery of correct nftables table/chain
    local TABLE="inet"
    local FAMILY="inet"
    local CHAIN="input"
    local SET_NAME="honey-scan-set"
    
    if nft list table inet f2b-table &>/dev/null; then
        TABLE="f2b-table"
        CHAIN="f2b-chain"
        FAMILY="inet"
    elif nft list table ip filter &>/dev/null; then
        TABLE="filter"
        FAMILY="ip"
        if nft list chain ip filter INPUT &>/dev/null; then CHAIN="INPUT"; else CHAIN="input"; fi
    fi

    # 1. Create set if missing
    nft add set "$FAMILY" "$TABLE" "$SET_NAME" { type ipv4_addr\; flags timeout\; } 2>/dev/null
    
    # 2. Add rule for set if missing
    if ! nft list chain "$FAMILY" "$TABLE" "$CHAIN" | grep -q "$SET_NAME"; then
        echo -e "${YELLOW}[INFO]${NC} Adding global protection rule for $SET_NAME..."
        nft add rule "$FAMILY" "$TABLE" "$CHAIN" ip saddr "@$SET_NAME" meta l4proto { tcp, udp } th dport { $DETECTED_PORTS } drop
    fi
    
    echo "$TABLE $CHAIN $FAMILY $SET_NAME"
}

# Initialize Firewall Set
FW_CONFIG=$(setup_firewall_set)
TABLE=$(echo "$FW_CONFIG" | awk '{print $1}')
CHAIN=$(echo "$FW_CONFIG" | awk '{print $2}')
FAMILY=$(echo "$FW_CONFIG" | awk '{print $3}')
SET_NAME=$(echo "$FW_CONFIG" | awk '{print $4}')

# --- ENSURE JAIL ACTIVE ---
if ! fail2ban-client status "$JAIL" &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} Jail '$JAIL' is not active. Attempting to start..."
    fail2ban-client start "$JAIL" 2>/dev/null || { echo -e "${RED}[ERROR]${NC} Could not start $JAIL jail."; exit 1; }
fi

# --- CORE LOGIC ---

# 1. Remote IPs holen
echo -e "${BLUE}[STEP 1/3]${NC} Fetching remote ban list..."
REMOTE_FILE=$(mktemp)
curl -s "$FEED_URL" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'> "$REMOTE_FILE"
REMOTE_COUNT=$(wc -l < "$REMOTE_FILE")
echo -e "${GREEN}[OK]${NC} Received ${YELLOW}$REMOTE_COUNT${NC} IPs from feed."

# 2. Sync IPs to nftables set (High Efficiency)
echo -e "${BLUE}[STEP 2/3]${NC} Syncing IPs to nftables set ($SET_NAME)..."
# Add elements with timeout (14 days)
# We do this in batches to avoid command line length limits
cat "$REMOTE_FILE" | xargs -n 500 bash -c 'nft add element '$FAMILY' '$TABLE' '$SET_NAME' { $(echo "$@" | sed "s/ / timeout '$BAN_TIME's, /g") timeout '$BAN_TIME's } 2>/dev/null' --

# 3. Compare for Fail2Ban (sshd sync)
echo -e "${BLUE}[STEP 3/3]${NC} Checking for new Fail2Ban entries..."
LOCAL_BANS=$(fail2ban-client status "$JAIL" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -d ',')
TEMP_LOCAL=$(mktemp)
echo "$LOCAL_BANS" | tr ' ' '\n' | sort -u > "$TEMP_LOCAL"

# Find NEW IPs for F2B
NEW_IPS=$(comm -23 <(sort -u "$REMOTE_FILE") "$TEMP_LOCAL" | grep -v '^$')
NEW_COUNT=$(echo "$NEW_IPS" | wc -l)

rm -f "$REMOTE_FILE" "$TEMP_LOCAL"

if [ "$NEW_COUNT" -eq 0 ] || [ "$NEW_IPS" = "0" ]; then
    echo -e "${GREEN}[DONE]${NC} All IPs synchronized."
    echo -e "${BLUE}[HINT]${NC} Verify with: ${CYAN}nft list set $FAMILY $TABLE $SET_NAME${NC}"
    exit 0
fi

echo -e "${YELLOW}[ACTION]${NC} Adding ${YELLOW}$NEW_COUNT${NC} NEW IPs to Fail2Ban..."
for IP in $NEW_IPS; do
    if [ -n "$IP" ]; then
        fail2ban-client set "$JAIL" banip "$IP" "$BAN_TIME" > /dev/null
    fi
done

echo "----------------------------------------------------------------"
echo -e "${GREEN}[SUCCESS]${NC} Sync completed at $(date)"
echo -e "${BLUE}[HINT]${NC} Verify with: ${CYAN}nft list set $FAMILY $TABLE $SET_NAME${NC}"
