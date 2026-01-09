#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Funktion: Sync Feed -> Local F2B (14 Tage) & TCP/UDP Dual-Block
# ==============================================================================

# --- KONFIGURATION (MOVED TO TOP) ---
ENV_FILE="/root/.env.apikeys"
FEED_URL="https://feed.sec.lemue.org/banned_ips.txt"
BAN_TIME=1209600 # 14 Tage
AUTO_UPDATE=true 
SCRIPT_URL="https://feed.sec.lemue.org/scripts/client_banned_ips.sh"
SCRIPT_PATH="/root/client_banned_ips.sh"

# --- AUTO UPDATE (BEFORE LOCK CHECK) ---
self_update() {
    if [ "$AUTO_UPDATE" != "true" ]; then return; fi
    
    # Check if curl and md5sum exist
    if ! command -v curl &> /dev/null || ! command -v md5sum &> /dev/null; then
        return
    fi

    TEMP_FILE="/tmp/client_banned_ips.sh.tmp"
    if curl -s -f "$SCRIPT_URL" -o "$TEMP_FILE"; then
        # Check syntax
        if ! bash -n "$TEMP_FILE"; then
            rm -f "$TEMP_FILE"
            return
        fi
        
        # Compare hash
        LOCAL_HASH=$(md5sum "$0" | awk '{print $1}')
        REMOTE_HASH=$(md5sum "$TEMP_FILE" | awk '{print $1}')
        
        if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
            echo "$(date): New version found. Updating..."
            cp "$TEMP_FILE" "$0"
            chmod +x "$0"
            rm -f "$TEMP_FILE"
            echo "$(date): Update successful. Restarting script..."
            exec "$0" "$@"
        fi
        rm -f "$TEMP_FILE"
    fi
}
self_update

# --- SINGLETON CHECK ---
LOCK_DIR="/var/lock/honey_client_bans.lock"
PID_FILE="/var/run/honey_client_bans.pid"

# Atomic Lock using mkdir (Works on all POSIX systems, NFS safe)
# 1. Handle Legacy Lock FILE from previous versions
if [ -f "$LOCK_DIR" ]; then
    echo "$(date): Detected legacy lock file from old version. Removing to upgrade to folder lock."
    rm -f "$LOCK_DIR"
fi

# 2. Try to acquire lock
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    # Lock exists. Check if it's stale.
    STALE_LOCK=false
    
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            echo "$(date): Process $OLD_PID is running. Exiting."
            exit 1
        else
            echo "$(date): Stale lock detected (PID $OLD_PID not found). cleaning up..."
            STALE_LOCK=true
        fi
    else
        echo "$(date): Lock directory exists but no PID file. cleaning up..."
        STALE_LOCK=true
    fi

    if [ "$STALE_LOCK" = true ]; then
        rm -rf "$LOCK_DIR"
        # Retry once
        if ! mkdir "$LOCK_DIR" 2>/dev/null; then
             echo "$(date): Failed to acquire lock after cleanup. Exiting."
             exit 1
        fi
        echo "$(date): Stale lock removed. Proceeding..."
    fi
fi

# Write PID
echo $$ > "$PID_FILE"

# Cleanup on exit
cleanup() {
    rm -f "$PID_FILE"
    rm -rf "$LOCK_DIR"
}
trap cleanup EXIT

# --- FIREWALL FUNKTION (DER UDP/BEDROCK FIX) ---
apply_firewall_block() {
    local IP=$1
    local JAIL=${2:-"sshd"}
    # Ermittle Ports (z.B. 22,80,19132)
    local PORTS=$(fail2ban-client get "$JAIL" action nftables port 2>/dev/null | tr -d ' ')
    
    if [ -n "$IP" ] && [ -n "$PORTS" ]; then
        # Füge Regel für TCP UND UDP hinzu (meta l4proto)
        nft add rule inet filter input ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        
        # Docker-Chain Support
        if nft list chain inet filter DOCKER-USER >/dev/null 2>&1; then
            nft add rule inet filter DOCKER-USER ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        fi
    fi
}

# --- HAUPTLOGIK (SYNC ONLY) ---

echo "Abgleich mit Feed: $FEED_URL"

# 1. Remote IPs holen
REMOTE_IPS=$(curl -s "$FEED_URL" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

# 2. Lokale Jails ermitteln
JAILS=$(fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://' | tr -d ',')

for JAIL in $JAILS; do
    echo "Prüfe Jail: $JAIL"
    # 3. Bereits lokal gebannte IPs holen für Duplikatsprüfung
    LOCAL_BANS=$(fail2ban-client status "$JAIL" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -d ',')
    
    for R_IP in $REMOTE_IPS; do
        # 4. Nur hinzufügen, wenn IP noch NICHT lokal vorhanden ist
        if [[ ! $LOCAL_BANS =~ $R_IP ]]; then
            echo "Neu: $R_IP -> 14 Tage Ban & Firewall Block (TCP/UDP)"
            fail2ban-client set "$JAIL" banip "$R_IP" "$BAN_TIME" > /dev/null
            apply_firewall_block "$R_IP" "$JAIL"
        else
            # IP ist schon in F2B, aber wir stellen sicher, dass die UDP-Regel sitzt
            apply_firewall_block "$R_IP" "$JAIL"
        fi
    done
done
echo "Sync abgeschlossen."
