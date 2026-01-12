#!/bin/bash

# ==============================================================================
# Script: banned_ips.sh (Honey-Scan Dynamic Manager v4.0.0)
# Function: 
#   1. Syncs Feed -> 'honey-feed' (Silent, 14d)
#   2. Configures Existing Jails -> 'honey-client' (Report, 48h)
#   3. Auto-Discovers Services -> Creates 'honey-<service>' Jails (Report, 48h)
# ==============================================================================

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# --- CONFIGURATION ---
FEED_URL="https://feed.sec.lemue.org/banned_ips.txt"
FEED_JAIL="honey-feed"

STRATEGIC_BANTIME=1209600 # 14 Days (Feed)
TACTICAL_BANTIME=172800   # 48 Hours (Tactical/Dynamic Jails)
DB_PURGE_AGE=1296000      # 15 Days

AUTO_UPDATE=true 
SCRIPT_URL="https://raw.githubusercontent.com/derlemue/honey-scan/main/scripts/banned_ips.sh"

# --- AESTHETICS ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
    echo -e "${BLUE}[INFO]${NC} Honey-Scan Dynamic Manager - Version 4.0.0"
}

print_banner

# --- DEPENDENCIES ---
install_deps() {
    echo -e "${BLUE}[INFO]${NC} Checking dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    
    MISSING=false
    for cmd in fail2ban-client jq ss curl; do
        if ! command -v $cmd &>/dev/null; then
            MISSING=true
            break
        fi
    done

    if [ "$MISSING" = true ]; then
        if [ -t 0 ]; then
             echo -ne "${CYAN}[PROMPT]${NC} Install missing dependencies (Fail2Ban, jq, iproute2)? (Y/n): "
             read -t 15 -n 1 user_input
             echo ""
             [[ "$user_input" =~ ^[Nn]$ ]] && { echo -e "${RED}[ERROR]${NC} Aborted."; exit 1; }
        else
             echo -e "${BLUE}[INFO]${NC} Auto-installing dependencies..."
        fi
        
        apt-get update -q
        apt-get install -y -q fail2ban jq iproute2 curl
    else
        echo -e "${GREEN}[OK]${NC} Dependencies met."
    fi
}

install_deps

# --- COMPONENT SETUP ---
setup_components() {
    echo -e "${BLUE}[INFO]${NC} Setting up Honey-Client components..."
    
    # 1. Install Client Script
    CLIENT_SCRIPT_SOURCE=""
    for src in "scripts/honey-client.sh" "./honey-client.sh" "/root/honey-client.sh"; do
        if [ -f "$src" ]; then CLIENT_SCRIPT_SOURCE="$src"; break; fi
    done
    
    if [ -n "$CLIENT_SCRIPT_SOURCE" ]; then
        cp "$CLIENT_SCRIPT_SOURCE" "/usr/local/bin/honey-client.sh"
        chmod +x "/usr/local/bin/honey-client.sh"
    elif [ ! -f "/usr/local/bin/honey-client.sh" ]; then
         # TODO: Download fallback could go here
         echo -e "${RED}[ERROR]${NC} honey-client.sh not found (checked scripts/, ./, /root/)!"
         exit 1
    fi
    
    # 2. Install Action Config
    ACTION_CONF_SOURCE=""
    for src in "config/honey-client.conf" "./honey-client.conf" "/root/honey-client.conf"; do
        if [ -f "$src" ]; then ACTION_CONF_SOURCE="$src"; break; fi
    done
    
    if [ -n "$ACTION_CONF_SOURCE" ]; then
        cp "$ACTION_CONF_SOURCE" "/etc/fail2ban/action.d/honey-client.conf"
    else
        # Fallback creation
        cat > "/etc/fail2ban/action.d/honey-client.conf" <<EOF
[Definition]
actionban = /usr/local/bin/honey-client.sh <ip>
actionunban = 
[Init]
EOF
    fi

    # 3. Honey-Firewall Action
    cat > "/etc/fail2ban/action.d/honey-nftables.conf" <<EOF
[Definition]
actionstart = nft add table inet f2b-table
              nft add chain inet f2b-table f2b-chain { type filter hook input priority filter - 1\; }
              nft add set inet f2b-table addr-set-<name> { type ipv4_addr\; }
              nft add rule inet f2b-table f2b-chain ip saddr @addr-set-<name> reject
actionstop = nft delete set inet f2b-table addr-set-<name>
actionban = nft add element inet f2b-table addr-set-<name> { <ip> }
actionunban = nft delete element inet f2b-table addr-set-<name> { <ip> }
EOF
}

setup_components

# --- JAIL CONFIGURATION ---
configure_jails() {
    echo -e "${BLUE}[INFO]${NC} Configuring Jails..."
    NEED_RESTART=false

    # 1. Honey Feed (Strategic: 14d, Silent)
    FEED_CONF="/etc/fail2ban/jail.d/honey-feed.conf"
    # Create Filter
    echo -e "[Definition]\nfailregex =\nignoreregex =" > "/etc/fail2ban/filter.d/honey-feed.conf"
    
    # Create Jail
    cat > "$FEED_CONF.tmp" <<EOF
[$FEED_JAIL]
enabled = true
bantime = $STRATEGIC_BANTIME
banaction = honey-nftables
action = honey-nftables
ignoreip = 127.0.0.1/8 ::1
EOF
    if [ ! -f "$FEED_CONF" ] || ! cmp -s "$FEED_CONF.tmp" "$FEED_CONF"; then
        mv "$FEED_CONF.tmp" "$FEED_CONF"
        NEED_RESTART=true
        echo -e "${GREEN}[UPDATE]${NC} Configured '$FEED_JAIL'."
    else
        rm "$FEED_CONF.tmp"
    fi

    # 2. Existing Jails (Tactical: 48h, Reporting)
    # Get List of ACTIVE jails (excluding honey-feed)
    # Actually, we should iterate over CONF files or running jails?
    # Running jails is safer to avoid touching disabled ones.
    
    # However, to configure them PERSISTENTLY requires conf files. 
    # Strategy: Create an override file for ALL standard jails we detect.
    
    JAILS=$(fail2ban-client status 2>/dev/null | grep "Jail list:" | sed 's/.*Jail list://' | tr ',' ' ')
    
    for jail in $JAILS; do
        jail=$(echo "$jail" | xargs) # trim
        if [[ "$jail" == "honey-"* ]]; then continue; fi # Skip honey-* jails managed by us elsewhere
        
        echo -e "${CYAN}[PATCH]${NC} Updating legacy jail: $jail"
        
        # Create Override
        OVERRIDE="/etc/fail2ban/jail.d/99-honey-override-$jail.conf"
        cat > "$OVERRIDE.tmp" <<EOF
[$jail]
bantime = $TACTICAL_BANTIME
# Append honey-client to existing actions? Hard to know what existing is.
# Simplest: Force honey-nftables + honey-client? 
# Or assume default action and ADD honey-client.
# Let's force our stack for consistency: Block at Firewall, Report to API.
banaction = honey-nftables
action = honey-nftables
         honey-client
EOF
        if [ ! -f "$OVERRIDE" ] || ! cmp -s "$OVERRIDE.tmp" "$OVERRIDE"; then
            mv "$OVERRIDE.tmp" "$OVERRIDE"
            NEED_RESTART=true
        else
            rm "$OVERRIDE.tmp"
        fi
    done

    # 3. Dynamic Service Discovery (Auto-Honey)
    # Scan listening ports
    # Output: Process names
    SERVICES=$(ss -tulpn | grep LISTEN | awk '{print $7}' | sed 's/.*"\(.*\)".*/\1/' | sort -u)
    
    # Mapping Table (Process -> Filter)
    declare -A FILTER_MAP
    FILTER_MAP=( ["sshd"]="sshd" ["nginx"]="nginx-http-auth" ["apache2"]="apache-auth" ["vsftpd"]="vsftpd" ["mysqld"]="mysqld-auth" )
    
    ACTIVE_HONEY_JAILS=""
    
    for svc in $SERVICES; do
        if [[ -n "${FILTER_MAP[$svc]}" ]]; then
            JAIL_NAME="honey-$svc"
            FILTER="${FILTER_MAP[$svc]}"
            ACTIVE_HONEY_JAILS="$ACTIVE_HONEY_JAILS $JAIL_NAME"
            
            # Check if this service is already covered by a legacy jail? 
            # E.g. if 'sshd' jail exists, 'honey-sshd' might be duplicate.
            # fail2ban handles duplicates by last-one-wins usually, or error.
            # To be safe: If legacy jail 'sshd' exists, DO NOT create 'honey-sshd'.
            
            if echo "$JAILS" | grep -q "\b$svc\b"; then
                echo -e "${YELLOW}[SKIP]${NC} Service '$svc' already covered by legacy jail."
                continue
            fi
            
            CONF="/etc/fail2ban/jail.d/$JAIL_NAME.conf"
            cat > "$CONF.tmp" <<EOF
[$JAIL_NAME]
enabled = true
filter = $FILTER
bantime = $TACTICAL_BANTIME
banaction = honey-nftables
action = honey-nftables
         honey-client
EOF
            if [ ! -f "$CONF" ] || ! cmp -s "$CONF.tmp" "$CONF"; then
                mv "$CONF.tmp" "$CONF"
                echo -e "${GREEN}[NEW]${NC} Created Dynamic Jail: $JAIL_NAME"
                NEED_RESTART=true
            else
                rm "$CONF.tmp"
            fi
        fi
    done
    
    # 4. Cleanup Stale Honey Jails
    # Find all honey-*.conf, if not in ACTIVE_HONEY_JAILS and not honey-feed, delete.
    for f in /etc/fail2ban/jail.d/honey-*.conf; do
        [ -e "$f" ] || continue
        base=$(basename "$f" .conf)
        if [[ "$base" == "$FEED_JAIL" ]]; then continue; fi
        
        # Check if still active
        if [[ "$ACTIVE_HONEY_JAILS" != *"$base"* ]]; then
             echo -e "${YELLOW}[CLEAN]${NC} Removing stale jail config: $f"
             rm -f "$f"
             NEED_RESTART=true
        fi
    done
    
    # 5. Restart if needed
    if [ "$NEED_RESTART" = true ]; then
        echo -e "${BLUE}[INFO]${NC} Restarting Fail2Ban..."
        systemctl restart fail2ban
        sleep 2
    else
        echo -e "${GREEN}[OK]${NC} Configuration stable."
    fi
}

configure_jails

# --- PERSISTENCE ---
setup_persistence() {
    # Update local config for DB Purge Age
    F2B_LOCAL="/etc/fail2ban/fail2ban.local"
    if ! grep -q "dbpurgeage = $DB_PURGE_AGE" "$F2B_LOCAL" 2>/dev/null; then
         echo "[Definition]" > "$F2B_LOCAL"
         echo "dbpurgeage = $DB_PURGE_AGE" >> "$F2B_LOCAL"
         systemctl restart fail2ban
    fi
    
    # Cron
    ABS_PATH=$(realpath "$0")
    CRON_CMD="*/15 * * * * $ABS_PATH >> /var/log/banned_ips.log 2>&1"
    (crontab -l 2>/dev/null | grep -v "banned_ips.sh"; echo "$CRON_CMD") | crontab -
    (crontab -l 2>/dev/null | grep -v "@reboot.*banned_ips.sh"; echo "@reboot $ABS_PATH >> /var/log/banned_ips.log 2>&1") | crontab -
}

setup_persistence

# --- SYNC FEED (Strategic) ---
sync_feed() {
    echo -e "${BLUE}[SYNC]${NC} Processing Feed..."
    
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
    fail2ban-client status "$FEED_JAIL" 2>/dev/null | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -s ' ' '\n' | sort -u > "$EXISTING_BANS_FILE"

    IPS_TO_BAN_FILE=$(mktemp)
    sort -u "$REMOTE_FILE" | comm -23 - "$EXISTING_BANS_FILE" > "$IPS_TO_BAN_FILE"

    COUNT_TO_BAN=$(wc -l < "$IPS_TO_BAN_FILE")

    if [ "$COUNT_TO_BAN" -eq 0 ]; then
        echo -e "${GREEN}[OK]${NC} No new IPs to ban."
    else
        echo -e "${BLUE}[INFO]${NC} Found ${YELLOW}$COUNT_TO_BAN${NC} new IPs to ban."
        CURRENT=0
        START_TIME=$(date +%s)
        MAX_RUNTIME=600

        while IFS= read -r ip; do
            NOW=$(date +%s)
            if [ $((NOW - START_TIME)) -gt "$MAX_RUNTIME" ]; then
                 echo -e "\n${RED}[WARN]${NC} Max runtime exceeded. Stopping import."
                 break
            fi

            fail2ban-client set "$FEED_JAIL" banip "$ip" &>/dev/null
            ((CURRENT++))
            if ((CURRENT % 50 == 0)); then
                 echo -ne "\r${BLUE}[INFO]${NC} Banning progress: $CURRENT / $COUNT_TO_BAN"
            fi
        done < "$IPS_TO_BAN_FILE"
        echo -e "\n${GREEN}[OK]${NC} Finished banning new IPs."
    fi

    # 3. Unban Stale IPs
    echo -e "${BLUE}[INFO]${NC} Checking for stale bans..."
    IPS_TO_UNBAN_FILE=$(mktemp)
    sort -u "$REMOTE_FILE" | comm -13 - "$EXISTING_BANS_FILE" > "$IPS_TO_UNBAN_FILE"
    COUNT_TO_UNBAN=$(wc -l < "$IPS_TO_UNBAN_FILE")

    if [ "$COUNT_TO_UNBAN" -gt 0 ]; then
        echo -e "${YELLOW}[INFO]${NC} Found ${YELLOW}$COUNT_TO_UNBAN${NC} stale IPs to unban."
        UNBANNED=0
        while IFS= read -r ip; do
            [[ -z "$ip" ]] && continue
            fail2ban-client set "$FEED_JAIL" unbanip "$ip" &>/dev/null
            ((UNBANNED++))
            if ((UNBANNED % 50 == 0)); then
                 echo -ne "\r${BLUE}[INFO]${NC} Unbanning progress: $UNBANNED / $COUNT_TO_UNBAN"
            fi
        done < "$IPS_TO_UNBAN_FILE"
        echo -e "\n${GREEN}[OK]${NC} Finished unbanning stale IPs."
    else
        echo -e "${GREEN}[OK]${NC} No stale bans found."
    fi

    rm -f "$EXISTING_BANS_FILE" "$IPS_TO_BAN_FILE" "$REMOTE_FILE" "$IPS_TO_UNBAN_FILE"
    
    # 3. Summary
    echo -e "${BLUE}[STEP 3/3]${NC} Verification..."
    TOTAL_BANS=$(fail2ban-client status "$FEED_JAIL" 2>/dev/null | grep "Currently banned:" | sed 's/.*Currently banned://' | tr -d ' ')
    echo -e "${BLUE}[INFO]${NC} Total currently banned IPs in jail '$FEED_JAIL': ${YELLOW}$TOTAL_BANS${NC}"
}

sync_feed

echo -e "${GREEN}[SUCCESS]${NC} Run Complete."
