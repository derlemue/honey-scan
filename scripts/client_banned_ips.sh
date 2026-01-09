#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Beschreibung: Sync Fail2Ban -> API + UDP Fix (Minecraft Bedrock)
# Pfad: /root/client_banned_ips.sh
# ==============================================================================

# --- KONFIGURATION (ABSOLUTE PFADE) ---
ENV_FILE="/root/.env.apikeys"
# Setze AUTO_UPDATE auf false, solange der Fix nicht im GitHub Repo ist!
AUTO_UPDATE=false 
REMOTE_URL="https://raw.githubusercontent.com/derlemue/honey-scan/main/scripts/client_banned_ips.sh"
SCRIPT_PATH="/root/client_banned_ips.sh"

# --- LADE API-KEY ---
if [ -f "$ENV_FILE" ]; then
    # Extrahiert BOOTSTRAP_API_KEY direkt
    API_KEY=$(grep "^BOOTSTRAP_API_KEY=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
fi

# --- AUTO-UPDATE LOGIK ---
if [ "$AUTO_UPDATE" = "true" ] && [ "$1" != "--no-update" ]; then
    echo "Checking for updates..."
    TMP_FILE="/tmp/client_banned_ips_update.sh"
    if curl -s -L -o "$TMP_FILE" "$REMOTE_URL"; then
        if ! diff -qB "$SCRIPT_PATH" "$TMP_FILE" > /dev/null; then
            echo "New version found. Updating..."
            mv "$TMP_FILE" "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            exec "$SCRIPT_PATH" "$@" --no-update
        fi
        rm -f "$TMP_FILE"
    fi
fi

# --- NFTABLES FUNKTION (DER UDP FIX) ---
apply_nft_ban() {
    local IP=$1
    local JAIL=${2:-"sshd"}
    # Ports holen (z.B. 22,80,19132)
    local PORTS=$(fail2ban-client get "$JAIL" action nftables port 2>/dev/null | tr -d ' ')
    
    if [ -n "$PORTS" ] && [ -n "$IP" ]; then
        # Sperrt TCP UND UDP (Der Fix für Minecraft Bedrock)
        nft add rule inet filter input ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        
        # Docker Fix (Wichtig für Container-Dienste)
        if nft list chain inet filter DOCKER-USER >/dev/null 2>&1; then
            nft add rule inet filter DOCKER-USER ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        fi
    fi
}

# --- HAUPTLOGIK ---

if [ "$1" == "--sync" ]; then
    echo "Starting Sync... (API Key: $([ -z "$API_KEY" ] && echo 'MISSING' || echo 'LOADED'))"
    
    # Alle aktiven Jails durchlaufen
    JAILS=$(fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://' | tr -d ',')
    
    for JAIL in $JAILS; do
        BANNED_IPS=$(fail2ban-client status "$JAIL" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -d ',')
        for IP in $BANNED_IPS; do
            echo "Processing $IP (Jail: $JAIL) -> Applying TCP/UDP Fix..."
            apply_nft_ban "$IP" "$JAIL"
            
            # API Call (falls Key vorhanden)
            if [ -n "$API_KEY" ]; then
                curl -s -X POST -H "Authorization: $API_KEY" -d "ip=$IP" "http://localhost:5000/api/ban" > /dev/null
            fi
        done
    done
    echo "Sync fertig. Alle IPs sind nun für TCP und UDP (Port 19132 etc.) gesperrt."

elif [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Einzel-IP Modus für Fail2Ban Actions
    IP=$1
    echo "Banning $IP (TCP/UDP)..."
    apply_nft_ban "$IP"
    if [ -n "$API_KEY" ]; then
        curl -s -X POST -H "Authorization: $API_KEY" -d "ip=$IP" "http://localhost:5000/api/ban" > /dev/null
    fi

else
    # Status-Anzeige
    echo "Usage: $0 <ip_address> OR $0 --sync"
    echo "--------------------------------------------------"
    echo "API Key Status: $([ -n "$API_KEY" ] && echo 'FOUND' || echo 'NOT FOUND in /root/.env.apikeys')"
    echo "UDP Protection: ENABLED"
    exit 1
fi
