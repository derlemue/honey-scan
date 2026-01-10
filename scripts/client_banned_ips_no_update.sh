#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Funktion: Efficient Sync Feed -> Local F2B (sshd) & TCP/UDP Dual-Block
# ==============================================================================

# --- KONFIGURATION ---
FEED_URL="https://feed.sec.lemue.org/banned_ips.txt"
BAN_TIME=1209600 # 14 Tage
AUTO_UPDATE=false 
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
echo -e "${BLUE}[INFO]${NC} Honey-Scan Banning Client - Version 2.5.0"
echo -e "${BLUE}[INFO]${NC} Target Jail: ${YELLOW}$JAIL${NC}"
echo -e "${BLUE}[INFO]${NC} Feed URL: ${YELLOW}$FEED_URL${NC}"
echo "----------------------------------------------------------------"

# --- SINGLETON CHECK ---
LOCK_FILE="/var/lock/honey_client_bans.lock"
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
            echo -e "${GREEN}[SUCCESS]${NC} Update successful. Restarting script..."
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
# We create an override file to ensure the jail uses nftables-allports with TCP and UDP.
# This is critical because standard setup usually only blocks TCP on SSH port.
OVERRIDE_CONF="/etc/fail2ban/jail.d/99-honey-scan.conf"
if [ ! -f "$OVERRIDE_CONF" ]; then
    echo -e "${BLUE}[INFO]${NC} Creating Fail2Ban override for ALL-PORTS blocking..."
    bash -c "cat > $OVERRIDE_CONF" <<EOF
[sshd]
# Enforce blocking on ALL ports
banaction = nftables-allports
# Enforce both TCP and UDP
protocol = tcp, udp
EOF
    echo -e "${GREEN}[OK]${NC} Override created. Reloading Fail2Ban..."
    fail2ban-client reload &>/dev/null
else
    # Check if content matches, if not update
    if ! grep -q "protocol = tcp, udp" "$OVERRIDE_CONF"; then
        echo -e "${YELLOW}[UPDATE]${NC} Updating Fail2Ban override configuration..."
        bash -c "cat > $OVERRIDE_CONF" <<EOF
[sshd]
banaction = nftables-allports
protocol = tcp, udp
EOF
        fail2ban-client reload &>/dev/null
    fi
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
