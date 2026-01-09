#!/bin/bash
# Verify API Health and Key Management

API_URL="http://localhost:4444"

echo "1. Checking Health..."
curl -s "$API_URL/" | grep "HFish API" && echo " [OK]" || echo " [FAIL]"

echo "2. Finding Bootstrap Key..."
# We need to grep the logs for the key since we can't auth without it
# This assumes the container is running and logged the key
BOOTSTRAP_KEY=$(docker logs hfish-sidecar-v2 2>&1 | grep "BOOTSTRAP" | tail -n1 | awk '{print $NF}')

if [ -z "$BOOTSTRAP_KEY" ]; then
    echo " [FAIL] Could not find bootstrap key in logs"
    exit 1
fi
echo " Found Key: $BOOTSTRAP_KEY"

echo "3. Listing Keys..."
curl -s -H "api-key: $BOOTSTRAP_KEY" "$API_URL/api/v1/keys" | grep "status\": 0" && echo " [OK]" || echo " [FAIL]"

echo "4. Creating New Key..."
NEW_KEY_RESP=$(curl -s -X POST -H "Content-Type: application/json" -H "api-key: $BOOTSTRAP_KEY" -d '{"memo":"TestKey"}' "$API_URL/api/v1/keys")
echo " Response: $NEW_KEY_RESP"
NEW_KEY=$(echo $NEW_KEY_RESP | grep -oP '"key": "\K[^"]+')

if [ -z "$NEW_KEY" ]; then
     echo " [FAIL] Could not create key"
     exit 1
fi
echo " Created Key: $NEW_KEY"

echo "5. Verifying New Key Access..."
curl -s -H "api-key: $NEW_KEY" "$API_URL/api/v1/keys" | grep "status\": 0" && echo " [OK]" || echo " [FAIL]"

echo "6. Deleting New Key..."
# Get ID first? The create response doesn't return ID directly in my code?
# Ah, I need to fetch list to get ID
KEYS_LIST=$(curl -s -H "api-key: $BOOTSTRAP_KEY" "$API_URL/api/v1/keys")
KEY_ID=$(echo $KEYS_LIST | grep -oP "\"id\": \d+, \"access_key\": \"$NEW_KEY\"" | grep -oP '"id": \K\d+')
echo " Key ID: $KEY_ID"

if [ -n "$KEY_ID" ]; then
    curl -s -X DELETE -H "api-key: $BOOTSTRAP_KEY" "$API_URL/api/v1/keys/$KEY_ID" | grep "deleted" && echo " [OK]" || echo " [FAIL]"
else
    echo " [FAIL] Could not find ID for new key"
fi

echo "Done."
