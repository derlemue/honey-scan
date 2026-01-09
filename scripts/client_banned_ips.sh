#!/bin/bash

# Script: client_banned_ips.sh (Fixed for UDP/Bedrock Support)
# Dieses Script stellt sicher, dass IPs für TCP UND UDP gesperrt werden.

# 1. Variablen definieren (Basierend auf deinem Screenshot)
JAIL="sshd"
ACTION="nftables"

# 2. Ports aus Fail2Ban abrufen
# Dies liefert die Liste: 22,68,80,81,...,19132,...
PORTS=$(fail2ban-client get "$JAIL" action "$ACTION" port)

# 3. Banned IPs abrufen
# Wir entfernen Kommas, um eine saubere Liste für die Bash-Schleife zu erhalten
BANNED_IPS=$(fail2ban-client status "$JAIL" | grep "Banned IP list" | sed 's/.*Banned IP list://' | tr -d ',')

echo "Aktualisiere nftables für Jail: $JAIL"
echo "Ports: $PORTS"

for IP in $BANNED_IPS; do
    if [ -n "$IP" ]; then
        echo "Sperre IP: $IP"
        
        # Regel für TCP (Standard)
        # Wir nutzen 'add', damit das Script auch bei bereits existierenden Regeln nicht abbricht
        nft add rule inet filter input ip saddr "$IP" tcp dport { $PORTS } drop 2>/dev/null
        
        # --- FIX: UDP REGEL HINZUFÜGEN ---
        # Dies blockiert Minecraft Bedrock (19132) und andere UDP-Dienste
        nft add rule inet filter input ip saddr "$IP" udp dport { $PORTS } drop 2>/dev/null
        
        # Optional: Falls du Docker nutzt, muss die Regel oft zusätzlich in die DOCKER-USER Chain
        # nft add rule inet filter DOCKER-USER ip saddr "$IP" udp dport { $PORTS } drop 2>/dev/null
    fi
done

echo "Fertig. UDP-Sperren für Minecraft Bedrock sind nun aktiv."
