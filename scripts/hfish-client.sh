#!/bin/bash

IP=$1
API_KEY="nXYzlupNuFFiUZvGRrfaRTySjsIIfYChnpIDnDWIczkvIdMYXhdotcdtLLsBKuMU"
# ÄNDERUNG: API Key direkt in die URL eingebaut (?api_key=...)
URL="https://sec.lemue.org/api/v1/config/black_list/add?api_key=$API_KEY"

# Payload (Header api_key entfernt, da jetzt in URL)
payload=$(cat <<EOF
{
  "ip": "$IP",
  "memo": "Fail2ban Client Jail"
}
EOF
)

response=$(curl -k -s -X POST "$URL" \
     -H "Content-Type: application/json" \
     -d "$payload")

echo "$(date): IP $IP gesendet. Response: $response" >> /var/log/hfish-client-export.log
