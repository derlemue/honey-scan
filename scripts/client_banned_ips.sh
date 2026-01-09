#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Funktion: Sync Feed -> Local F2B (14 Tage) & TCP/UDP Dual-Block
# ==============================================================================

# --- KONFIGURATION ---
ENV_FILE="/root/.env.apikeys"
FEED_URL="https://feed.sec.lemue.org/banned_ips.txt"
API_URL="http://localhost:5000/api/ban"
BAN_TIME=1209600 # 14 Tage
AUTO_UPDATE=false 
SCRIPT_PATH="/root/client_banned_ips.sh"

# --- LADE API-KEY ---
if [ -f "$ENV_FILE" ]; then
    API_KEY=$(grep "^BOOTSTRAP_API_KEY=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
fi

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

# --- HAUPTLOGIK ---

# FALL 1: Synchronisation mit dem externen Feed (--sync)
if [ "$1" == "--sync" ]; then
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

# FALL 2: Neue IP von lokalem Fail2Ban gemeldet (Push an API)
elif [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    IP=$1
    echo "Lokaler Ban erkannt: $IP"
    
    # Sofortiger lokaler Schutz für TCP & UDP
    apply_firewall_block "$IP"
    
    # An API melden (Honey-Scan Bestandteil)
    if [ -n "$API_KEY" ]; then
        curl -s -X POST -H "Authorization: $API_KEY" \
             -d "ip=$IP" \
             -d "reason=local_detection" \
             "$API_URL" > /dev/null
        echo "IP an API gepusht."
    fi

else
    echo "Verwendung: $0 <ip_address> OR $0 --sync"
    echo "Status: API-Key $([ -n "$API_KEY" ] && echo 'GELADEN' || echo 'FEHLT')"
    exit 1
fi
