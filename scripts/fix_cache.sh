#!/bin/bash
echo "[+] Requesting Nginx Reload to clear stale cache..."
sudo systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "[+] SUCCESS: Cache cleared. Please refresh your browser."
else
    echo "[-] FAILED: Could not reload Nginx. Please try: sudo killall -HUP nginx"
fi
