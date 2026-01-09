#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Funktion: Sync Feed -> Local F2B (14 Tage) & TCP/UDP Dual-Block
# ==============================================================================

# --- SINGLETON CHECK ---
LOCK_FILE="/var/lock/honey_client_bans.lock"
PID_FILE="/var/run/honey_client_bans.pid"

# 1. Try FLOCK (Best method)
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "$(date): Another instance is holding the lock. Exiting."
    exit 1
fi

# 2. Double Check PID (Fallback for weird filesystems)
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "$(date): PID file exists and process $OLD_PID is running. Exiting."
        exit 1
    fi
fi
echo $$ > "$PID_FILE"

# Cleanup PID on exit
trap 'rm -f "$PID_FILE"' EXIT

# --- KONFIGURATION ---
ENV_FILE="/root/.env.apikeys"
FEED_URL="https://feed.sec.lemue.org/banned_ips.txt"
BAN_TIME=1209600 # 14 Tage
AUTO_UPDATE=true 
SCRIPT_PATH="/root/client_banned_ips.sh"

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
