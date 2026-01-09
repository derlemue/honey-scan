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
SCRIPT_URL="https://raw.githubusercontent.com/derlemue/honey-scan/refs/heads/main/scripts/client_banned_ips.sh"
SCRIPT_PATH="/root/client_banned_ips.sh"

# --- SINGLETON CHECK ---
LOCK_DIR="/var/lock/honey_client_bans.lock"
PID_FILE="/var/run/honey_client_bans.pid"

# Atomic Lock using mkdir
if [ -f "$LOCK_DIR" ]; then
    rm -f "$LOCK_DIR"
fi

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    STALE_LOCK=false
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if [ "$OLD_PID" = "$$" ]; then
            # This is us after an exec-update
            STALE_LOCK=true
        elif kill -0 "$OLD_PID" 2>/dev/null; then
            echo "$(date): Process $OLD_PID is running. Exiting."
            exit 1
        else
            STALE_LOCK=true
        fi
    else
        STALE_LOCK=true
    fi

    if [ "$STALE_LOCK" = true ]; then
        rm -rf "$LOCK_DIR"
        if ! mkdir "$LOCK_DIR" 2>/dev/null; then
             exit 1
        fi
    fi
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
