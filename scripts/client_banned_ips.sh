#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Beschreibung: Sync Fail2Ban IPs zu API + lokale UDP/TCP Sperre (Bedrock Fix)
# ==============================================================================

# --- KONFIGURATION ---
API_KEY="DEIN_API_KEY_HIER"  # Oder in der honey-api config
API_URL="http://localhost:5000/api/ban" # Beispiel URL
AUTO_UPDATE=true
REMOTE_URL="https://raw.githubusercontent.com/derlemue/honey-scan/main/scripts/client_banned_ips.sh"
SCRIPT_PATH=$(readlink -f "$0")

# --- AUTO-UPDATE ---
if [ "$AUTO_UPDATE" = "true" ] && [ "$1" != "--no-update" ]; then
    echo "Checking for updates..."
    TMP_FILE="/tmp/client_banned_ips_update.sh"
    if curl -s -o "$TMP_FILE" "$REMOTE_URL"; then
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

# --- HILFSFUNKTION FÜR NFTABLES (DER UDP FIX) ---
apply_nft_ban() {
    local IP=$1
    local JAIL=${2:-"sshd"}
    # Ports aus Fail2Ban holen
    local PORTS=$(fail2ban-client get "$JAIL" action nftables port 2>/dev/null | tr -d ' ')
    
    if [ -n "$PORTS" ] && [ -n "$IP" ]; then
        # Sperrt TCP UND UDP (Wichtig für Bedrock Port 19132)
        nft add rule inet filter input ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        # Docker Fix
        if nft list chain inet filter DOCKER-USER >/dev/null 2>&1; then
            nft add rule inet filter DOCKER-USER ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        fi
    fi
}

# --- HAUPTLOGIK ---

if [ "$1" == "--sync" ]; then
    echo "Starting Sync ALL banned IPs..."
    # Alle Jails abrufen
    JAILS=$(fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://' | tr -d ',')
    
    for JAIL in $JAILS; do
        BANNED_IPS=$(fail2ban-client status "$JAIL" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -d ',')
        for IP in $BANNED_IPS; do
            echo "Syncing $IP from Jail $JAIL (UDP/TCP Fix)..."
            apply_nft_ban "$IP" "$JAIL"
            # Hier käme dein API-Call hin, falls nötig:
            # curl -s -X POST -H "Authorization: $API_KEY" -d "ip=$IP" "$API_URL"
        done
    done
    echo "Sync complete."

elif [ -n "$1" ]; then
    # Einzel-IP Modus (wird oft von Fail2Ban direkt aufgerufen)
    IP=$1
    echo "Banning single IP: $IP (UDP/TCP Fix)..."
    apply_nft_ban "$IP"
    # API Call
    curl -s -X POST -H "Authorization: $API_KEY" -d "ip=$IP" "$API_URL"
    echo "Ban reported to API."

else
    # Hilfe anzeigen
    echo "Usage: $0 <ip_address> [api_key] OR $0 --sync"
    echo "  --sync       : Sync ALL banned IPs from Fail2Ban to API and apply UDP fixes"
    echo "  <ip_address> : The attacker IP to ban locally (UDP/TCP) and report to API"
    exit 1
fi
