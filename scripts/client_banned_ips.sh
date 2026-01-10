#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Funktion: Efficient Sync Feed -> Local F2B (sshd) & TCP/UDP Dual-Block
# ==============================================================================

# --- KONFIGURATION ---
FEED_URL="https://feed.sec.lemue.org/banned_ips.txt"
BAN_TIME=1209600 # 14 Tage
AUTO_UPDATE=true 
SCRIPT_URL="https://raw.githubusercontent.com/derlemue/honey-scan/refs/heads/main/scripts/client_banned_ips.sh"
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

apply_firewall_block() {
    local IP=$1
    local TARGET_PORTS=$2
    
    if [ -n "$IP" ] && [ -n "$TARGET_PORTS" ]; then
        # Füge Regel für TCP UND UDP hinzu
        nft add rule inet filter input ip saddr "$IP" meta l4proto { tcp, udp } th dport { $TARGET_PORTS } drop 2>/dev/null
        
        # Docker-Chain Support
        if nft list chain inet filter DOCKER-USER >/dev/null 2>&1; then
            nft add rule inet filter DOCKER-USER ip saddr "$IP" meta l4proto { tcp, udp } th dport { $TARGET_PORTS } drop 2>/dev/null
        fi
    fi
}

# --- ENSURE JAIL ACTIVE ---
if ! fail2ban-client status "$JAIL" &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} Jail '$JAIL' is not active. Attempting to start..."
    fail2ban-client start "$JAIL" 2>/dev/null || { echo -e "${RED}[ERROR]${NC} Could not start $JAIL jail."; exit 1; }
fi

# --- CORE LOGIC ---

# 1. Remote IPs holen
echo -e "${BLUE}[STEP 1/3]${NC} Fetching remote ban list..."
REMOTE_IPS=$(curl -s "$FEED_URL" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
REMOTE_COUNT=$(echo "$REMOTE_IPS" | wc -l)
echo -e "${GREEN}[OK]${NC} Received ${YELLOW}$REMOTE_COUNT${NC} IPs from feed."

# 2. Lokale Jails ermitteln (Diff)
echo -e "${BLUE}[STEP 2/3]${NC} Comparing with local bans (sshd)..."
LOCAL_BANS=$(fail2ban-client status "$JAIL" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -d ',')

# Create temporary files for diff
TEMP_REMOTE=$(mktemp)
TEMP_LOCAL=$(mktemp)

echo "$REMOTE_IPS" | tr ' ' '\n' | sort -u > "$TEMP_REMOTE"
echo "$LOCAL_BANS" | tr ' ' '\n' | sort -u > "$TEMP_LOCAL"

# Find IPs in remote but not in local
NEW_IPS=$(comm -23 "$TEMP_REMOTE" "$TEMP_LOCAL")
NEW_COUNT=$(echo "$NEW_IPS" | grep -v '^$' | wc -l)

rm -f "$TEMP_REMOTE" "$TEMP_LOCAL"

if [ "$NEW_COUNT" -eq 0 ]; then
    echo -e "${GREEN}[DONE]${NC} No new IPs to ban. All synchronized."
    exit 0
fi

echo -e "${YELLOW}[ACTION]${NC} Found ${YELLOW}$NEW_COUNT${NC} NEW IPs to add."

# 3. Neue IPs bannen
echo -e "${BLUE}[STEP 3/3]${NC} Applying bans and firewall rules..."
for IP in $NEW_IPS; do
    if [ -n "$IP" ]; then
        echo -e "  ${BLUE}»${NC} Banning: ${YELLOW}$IP${NC} (14d + Dual-Block on [${CYAN}$DETECTED_PORTS${NC}])"
        fail2ban-client set "$JAIL" banip "$IP" "$BAN_TIME" > /dev/null
        apply_firewall_block "$IP" "$DETECTED_PORTS"
    fi
done

echo "----------------------------------------------------------------"
echo -e "${GREEN}[SUCCESS]${NC} Sync completed at $(date)"
