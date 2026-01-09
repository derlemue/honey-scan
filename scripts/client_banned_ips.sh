#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh (Honey-Scan Advanced Version)
# Beschreibung: Port-Scan, API-Sync (14 Tage), TCP/UDP Dual-Stack Block
# Pfad: /root/client_banned_ips.sh
# ==============================================================================

# --- KONFIGURATION ---
ENV_FILE="/root/.env.apikeys"
BAN_TIME=1209600 # 14 Tage in Sekunden
AUTO_UPDATE=false # Auf false, um lokale Änderungen zu schützen
SCRIPT_PATH="/root/client_banned_ips.sh"
API_URL="http://localhost:5000/api/ban" # Deine API-URL

# --- LADE API-KEY ---
if [ -f "$ENV_FILE" ]; then
    API_KEY=$(grep "^BOOTSTRAP_API_KEY=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
fi

# --- NFTABLES FIREWALL LOGIK (TCP & UDP) ---
apply_firewall_block() {
    local IP=$1
    local JAIL=${2:-"sshd"}
    # Ermittle die geschützten Ports dieses Jails
    local PORTS=$(fail2ban-client get "$JAIL" action nftables port 2>/dev/null | tr -d ' ')
    
    if [ -n "$IP" ] && [ -n "$PORTS" ]; then
        # Blockiert IP für TCP & UDP auf den definierten Ports
        nft add rule inet filter input ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        
        # Docker-User Chain Support (für Container-Dienste)
        if nft list chain inet filter DOCKER-USER >/dev/null 2>&1; then
            nft add rule inet filter DOCKER-USER ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
        fi
    fi
}

# --- FUNKTION: CLIENT-PORTS SCANNEN ---
scan_attacker_ports() {
    local IP=$1
    # Einfacher Scan der wichtigsten Ports des Angreifers (Honey-Scan Logik)
    # Erfordert nmap, falls installiert, sonst Fallback auf 'nc'
    if command -v nmap >/dev/null 2>&1; then
        nmap -sS -T4 -p 21,22,23,80,443,3306,8080 "$IP" | grep "open" | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//'
    else
        echo "unknown"
    fi
}

# --- HAUPTLOGIK ---

# FALL 1: Globaler Sync (--sync)
if [ "$1" == "--sync" ]; then
    echo "Starte Honey-Scan Sync (14 Tage Modus)..."
    
    # 1. Lokale Fail2Ban Jails abrufen
    JAILS=$(fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://' | tr -d ',')
    
    # 2. Von API globale Banliste holen (Beispiel-Logik)
    if [ -n "$API_KEY" ]; then
        echo "Rufe globale Bans von API ab..."
        # Hier wird die API abgefragt (Pfad anpassen falls nötig)
        GLOBAL_BANS=$(curl -s -H "Authorization: $API_KEY" "$API_URL/list" | jq -r '.[]' 2>/dev/null)
        
        for G_IP in $GLOBAL_BANS; do
            # Nur hinzufügen, wenn IP noch nicht im Jail ist (Duplikatsprüfung)
            for JAIL in $JAILS; do
                if ! fail2ban-client status "$JAIL" | grep -q "$G_IP"; then
                    echo "Füge globale IP $G_IP zum Jail $JAIL hinzu (14 Tage)..."
                    fail2ban-client set "$JAIL" banip "$G_IP" "$BAN_TIME"
                    apply_firewall_block "$G_IP" "$JAIL"
                fi
            done
        done
    fi
    
    # 3. Alle bereits in F2B vorhandenen IPs für UDP/TCP in nftables nachziehen
    for JAIL in $JAILS; do
        BANNED_IPS=$(fail2ban-client status "$JAIL" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -d ',')
        for IP in $BANNED_IPS; do
            apply_firewall_block "$IP" "$JAIL"
        done
    done
    echo "Sync abgeschlossen."

# FALL 2: Einzelne IP (Normaler Aufruf durch Fail2Ban)
elif [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    IP=$1
    echo "Verarbeite neuen Ban für IP: $IP"
    
    # 1. Lokale Firewall sofort setzen (TCP & UDP)
    apply_firewall_block "$IP"
    
    # 2. Angreifer scannen
    echo "Scanne offene Ports des Angreifers..."
    OPEN_PORTS=$(scan_attacker_ports "$IP")
    
    # 3. An API melden
    if [ -n "$API_KEY" ]; then
        curl -s -X POST -H "Authorization: $API_KEY" \
             -d "ip=$IP" \
             -d "ports=$OPEN_PORTS" \
             -d "reason=honeypot_detection" \
             "$API_URL" > /dev/null
        echo "Angriff an API gemeldet (Ports: $OPEN_PORTS)."
    fi

else
    echo "Usage: $0 <ip_address> OR $0 --sync"
    echo "--------------------------------------------------"
    echo "Status: API Key $([ -n "$API_KEY" ] && echo 'OK' || echo 'MISSING')"
    echo "Feature: 14-Day Reciprocal Banning & UDP/TCP Dual-Block"
    exit 1
fi
