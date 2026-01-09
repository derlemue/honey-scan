#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Beschreibung: Sync Fail2Ban -> API + UDP/TCP Sperre (Minecraft Bedrock Fix)
# Version: 1.2.0 (Key: BOOTSTRAP_API_KEY | Protocol: TCP/UDP)
# ==============================================================================

# --- KONFIGURATION ---
ENV_FILE="../.env.apikeys"
AUTO_UPDATE=true
REMOTE_URL="https://raw.githubusercontent.com/derlemue/honey-scan/main/scripts/client_banned_ips.sh"
SCRIPT_PATH=$(readlink -f "$0")

# --- LADE API-KEY AUS DATEI ---
# Wir suchen nach BOOTSTRAP_API_KEY in ../.env.apikeys
if [ -f "$ENV_FILE" ]; then
    API_KEY=$(grep -E '^BOOTSTRAP_API_KEY=' "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
fi

# --- AUTO-UPDATE LOGIK ---
if [ "$AUTO_UPDATE" = "true" ] && [ "$1" != "--no-update" ]; then
    echo "Checking for updates..."
    TMP_FILE="/tmp/client_banned_ips_update.sh"
    # Benutze -L um Redirects auf GitHub zu folgen
    if curl -s -L -o "$TMP_FILE" "$REMOTE_URL"; then
        if ! diff -qB "$SCRIPT_PATH" "$TMP_FILE" > /dev/null; then
            echo "New version found. Updating script..."
            mv "$TMP_FILE" "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            echo "Update installed. Restarting..."
            exec "$SCRIPT_PATH" "$@" --no-update
        fi
        rm -f "$TMP_FILE"
    fi
    echo "Script is up to date."
fi

# --- NFTABLES FUNKTION (DER UDP FIX) ---
apply_nft_ban() {
    local IP=$1
    local JAIL=${2:-"sshd"}
    # Holt die Ports (z.B. 22,80,19132) und entfernt Leerzeichen
    local PORTS=$(fail2ban-client get "$JAIL" action nftables port 2>/dev/null | tr -d ' ')
    
    if [ -n "$PORTS" ] && [ -n "$IP" ]; then
        # Regel für die Standard Input Chain
        # meta l4proto { tcp, udp } blockiert beides gleichzeitig
        nft add rule inet filter input ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        
        # Docker Fix: Falls Docker läuft, umgeht es oft die 'input' Chain. 
        # Wir prüfen, ob die DOCKER-USER Chain existiert und sperren dort ebenfalls.
        if nft list chain inet filter DOCKER-USER >/dev/null 2>&1; then
            nft add rule inet filter DOCKER-USER ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop
