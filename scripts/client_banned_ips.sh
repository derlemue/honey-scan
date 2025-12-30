#!/bin/bash

# HFish Active Defense - Client Feed Script
# Fetches blocked IPs from the central HFish feed and adds them to a local Fail2Ban jail or ipset.

FEED_URL="http://YOUR_HFISH_IP:8888/feed/banned_ips.txt"
IPSET_NAME="hfish_blacklist"
TMP_FILE="/tmp/hfish_banned_ips.txt"

# Ensure ipset exists
ipset -L $IPSET_NAME >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating ipset $IPSET_NAME..."
    ipset create $IPSET_NAME hash:ip hashsize 4096
fi

# Fetch the feed
echo "Fetching feed from $FEED_URL..."
curl -s -o $TMP_FILE $FEED_URL

if [ $? -ne 0 ]; then
    echo "Error fetching feed."
    exit 1
fi

# Add IPs to ipset
count=0
while read ip; do
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ipset add $IPSET_NAME $ip -exist
        ((count++))
    fi
done < $TMP_FILE

echo "Processed $count IPs."
rm $TMP_FILE

# To use with iptables:
# iptables -I INPUT -m set --match-set hfish_blacklist src -j DROP
