#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Beschreibung: Sync Fail2Ban IPs -> API + UDP Fix (Minecraft Bedrock)
# Lädt API-Key aus .env.apikeys
# ==============================================================================

# --- WEGE ZUR ENV-DATEI ---
# Das Script sucht an diesen Orten nach dem API Key
ENV_PATHS=(
    "/root/honey-api/.env.apikeys"
    "$(dirname "$0")/.env.apikeys"
    "/root/.env.apikeys"
)

# --- AUTO-UPDATE KONFIGURATION ---
AUTO_UPDATE=true
REMOTE_URL="https://raw.githubusercontent.com/derlemue/honey-scan/main/scripts/client_banned_ips.sh"
SCRIPT_PATH=$(readlink -f "$0")

# --- LADE API-KEY AUS DATEI ---
HFISH_API_KEY=""
for path in "${ENV_PATHS[@]}"; do
    if [ -f "$path" ]; then
        # Extrahiert den Key ohne die Datei komplett zu 'sourcen' (Sicherheitsaspekt)
        HFISH_API_KEY=$(grep -E '^HFISH_API_KEY=' "$path" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        [ -n "$HFISH_API_KEY" ] && break
    fi
done

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
    echo "Script is up to date."
fi

# --- NFTABLES FUNKTION (UDP + TCP FIX) ---
apply_nft_ban() {
    local IP=$1
    local JAIL=${2:-"sshd"}
    local PORTS=$(fail2ban-client get "$JAIL" action nftables port 2>/dev/null | tr -d ' ')
    
    if [ -n "$PORTS" ] && [ -n "$IP" ]; then
        # Blockiert TCP & UDP (Wichtig für Bedrock 19132)
        nft add rule inet filter input ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        # Docker-Support: Falls vorhanden, auch dort blockieren
        if nft list chain inet filter DOCKER-USER >/dev/null 2>&1; then
            nft add rule inet filter DOCKER-USER ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        fi
    fi
}

# --- HAUPTLOGIK ---

if [ "$1" == "--sync" ]; then
    echo "Starting global Sync (API Key loaded)..."
    JAILS=$(fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://' | tr -d ',')
    
    for JAIL in $JAILS; do
        BANNED_IPS=$(fail2ban-client status "$JAIL" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -d ',')
        for IP in $BANNED_IPS; do
            echo "Fixing $IP in nftables (TCP/UDP)..."
            apply_nft_ban "$IP" "$JAIL"
            
            # API Meldung falls Key vorhanden
            if [ -n "$HFISH_API_KEY" ]; then
                # Beispielhafter API Call an deinen Honey-Scan Service
                curl -s -X POST -H "Authorization: $HFISH_API_KEY" -d "ip=$IP" "http://localhost:5000/api/ban" > /dev/null
            fi
        done
    done
    echo "Sync complete."

elif [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Einzel-IP Modus
    IP=$1
    echo "Banning $IP and reporting to API..."
    apply_nft_ban "$IP"
    if [ -n "$HFISH_API_KEY" ]; then
        curl -s -X POST -H "Authorization: $HFISH_API_KEY" -d "ip=$IP" "http://localhost:5000/api/ban" > /dev/null
    fi
    echo "Done."

else
    echo "Usage: $0 <ip_address> OR $0 --sync"
    echo "API Key Status: $([ -n "$HFISH_API_KEY" ] && echo 'LOADED' || echo 'NOT FOUND')"
    exit 1
fi
