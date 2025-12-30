#!/bin/bash

# ==========================================
#  lemueIO Active Intelligence Feed - Client Shield
# ==========================================
#  Version: 3.2.0
#  Description: Fetches malicious IPs from honey-scan and bans them via Fail2Ban.
# ==========================================

RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Dependency Check: Fail2Ban
if ! command -v fail2ban-client &> /dev/null; then
    echo -e "${RED}"
    echo "################################################"
    echo "#     FAIL2BAN IST NICHT INSTALLIERT!          #"
    echo "#     SYSTEM IST NICHT GESCHÜTZT!              #"
    echo "################################################"
    echo -e "${NC}"
    
    read -p "Soll Fail2Ban jetzt installiert werden? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ "$EUID" -ne 0 ]; then
             echo "Bitte als root ausführen (sudo)."
             exit 1
        fi
        apt-get update && apt-get install -y fail2ban
        if [ $? -ne 0 ]; then
            echo "Installation fehlgeschlagen."
            exit 1
        fi
    else
        echo "Abbruch. Ohne Fail2Ban kann dieser Schutz nicht aktiviert werden."
        exit 1
    fi
fi

# 2. Service Check
if ! systemctl is-active --quiet fail2ban; then
    echo "Fail2Ban läuft nicht. Starte Service..."
    systemctl start fail2ban
    if [ $? -ne 0 ]; then
        echo "Konnte Fail2Ban nicht starten."
        exit 1
    fi
fi

# 3. Fetch Feed
FEED_URL="http://23.88.40.46:8888/feed/banned_ips.txt"
TMP_FILE="/tmp/banned_ips.txt"

echo "Lade Feed von $FEED_URL..."
wget -q -O $TMP_FILE $FEED_URL || curl -s -o $TMP_FILE $FEED_URL

if [ ! -s $TMP_FILE ]; then
    echo "Fehler: Feed ist leer oder nicht erreichbar."
    exit 1
fi

# 4. Ban Execution
JAIL="sshd" # Default Jail
COUNT=0

echo "Verarbeite IPs..."
while read ip; do
    # Simple IP validation
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # Check if already banned to avoid noise (fail2ban handles duplicates usually fine, but cleaner log)
        # fail2ban-client set $JAIL banip $ip
        fail2ban-client set $JAIL banip $ip > /dev/null 2>&1
        ((COUNT++))
    fi
done < $TMP_FILE

echo "Fertig. $COUNT IPs wurden an Fail2Ban übergeben."
rm $TMP_FILE
