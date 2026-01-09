#!/bin/bash

# ==============================================================================
# Script: client_banned_ips.sh
# Beschreibung: Synchronisiert Fail2Ban Bans mit nftables (Fix für UDP/Bedrock)
# Version: 1.1.0 (Fixed UDP Support)
# ==============================================================================

# --- KONFIGURATION ---
AUTO_UPDATE=true
REMOTE_URL="https://raw.githubusercontent.com/derlemue/honey-scan/main/scripts/client_banned_ips.sh"
SCRIPT_PATH=$(readlink -f "$0")

# --- AUTO-UPDATE FUNKTION ---
if [ "$AUTO_UPDATE" = "true" ]; then
    TMP_FILE="/tmp/client_banned_ips_update.sh"
    if curl -s -o "$TMP_FILE" "$REMOTE_URL"; then
        # Vergleiche lokale Datei mit Remote (ohne Berücksichtigung von Leerzeichen)
        if ! diff -qB "$SCRIPT_PATH" "$TMP_FILE" > /dev/null; then
            echo "[AutoUpdate] Neue Version gefunden. Aktualisiere..."
            mv "$TMP_FILE" "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            echo "[AutoUpdate] Update durchgeführt. Starte neu..."
            exec "$SCRIPT_PATH" "$@"
        fi
        rm -f "$TMP_FILE"
    fi
fi

# --- HAUPTTEIL ---

# 1. Parameter oder Defaults setzen
JAIL=${1:-"sshd"}
ACTION=${2:-"nftables"}

# 2. Ports dynamisch aus Fail2Ban auslesen
# Beispiel-Output: 22,80,19132...
PORTS=$(fail2ban-client get "$JAIL" action "$ACTION" port 2>/dev/null)

if [ -z "$PORTS" ]; then
    echo "[Error] Konnte keine Ports für Jail '$JAIL' finden."
    exit 1
fi

# 3. Liste der aktuell gebannten IPs abrufen
BANNED_IPS=$(fail2ban-client status "$JAIL" | grep "Banned IP list" | sed 's/.*Banned IP list://' | tr -d ',')

echo "Verarbeite Jail: $JAIL | Ports: $PORTS"

# 4. nftables Regeln anwenden
for IP in $BANNED_IPS; do
    if [ -n "$IP" ]; then
        # Prüfen ob IP valide ist (rudimentär)
        if [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            
            # --- DER FIX ---
            # Wir nutzen 'meta l4proto { tcp, udp }', um beide Protokolle abzudecken.
            # 'th dport' steht für 'transport header destination port'.
            
            # Bestehende IP-Sperre in nftables (falls vorhanden, Fehlermeldung ignorieren)
            nft add rule inet filter input ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
            
            # Falls Docker im Einsatz ist, zusätzlich in der DOCKER-USER Chain sperren
            if nft list chain inet filter DOCKER-USER >/dev/null 2>&1; then
                nft add rule inet filter DOCKER-USER ip saddr "$IP" meta l4proto { tcp, udp } th dport { $PORTS } drop 2>/dev/null
            fi
            
            echo "[Banned] $IP (TCP & UDP)"
        fi
    fi
done

echo "Synchronisierung abgeschlossen."
