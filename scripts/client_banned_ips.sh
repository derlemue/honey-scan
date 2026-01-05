#!/usr/bin/env python3
import os
import sys
import time
import hashlib
import urllib.request
import subprocess
import logging
from shutil import which

# ==========================================
#  lemueIO Active Intelligence Feed - Client Shield (Python Variant)
# ==========================================
#  Version: 4.1.0
#  Description: Fetches malicious IPs from honey-scan Feed and bans them via Fail2Ban on remote hosts.
# ==========================================

# --- CONFIGURATION ---
UPDATE_URL = "https://feed.sec.lemue.org/scripts/client_banned_ips.sh"
IP_FEED_URL = "https://feed.sec.lemue.org/banned_ips.txt"
SCANS_DIR = "./scans"
TARGET_JAIL = "sshd"
MAX_NEW_SCANS = 10  # Limit Nmap scans per run to avoid hangs
REMOTE_HOSTS = ["localhost"] # TODO: Add your remote hosts here, e.g. ["user@host1", "user@host2"]

# --- LOGGING ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger(__name__)

def self_update():
    """Checks for updates from the feed and restarts the script if updated."""
    logger.info(f"Checking for updates from {UPDATE_URL}...")
    try:
        # Calculate current hash
        pk_path = os.path.abspath(__file__)
        with open(pk_path, 'rb') as f:
            current_hash = hashlib.sha256(f.read()).hexdigest()

        # Download remote file
        with urllib.request.urlopen(UPDATE_URL) as response:
            remote_content = response.read()
            remote_hash = hashlib.sha256(remote_content).hexdigest()

        if current_hash != remote_hash:
            logger.info("New version found. Updating...")
            with open(pk_path, 'wb') as f:
                f.write(remote_content)
            
            # Ensure executable
            st = os.stat(pk_path)
            os.chmod(pk_path, st.st_mode | 0o111)

            logger.info("Update successful. Restarting...")
            os.execv(sys.executable, [sys.executable] + sys.argv)
        else:
            logger.info("No updates found.")

    except Exception as e:
        logger.error(f"Self-update failed: {e}")

def fetch_ips_from_feed():
    """Fetches IPs from the remote text feed."""
    logger.info(f"Fetching IPs from feed {IP_FEED_URL}...")
    try:
        with urllib.request.urlopen(IP_FEED_URL) as response:
            content = response.read().decode('utf-8')
            ips = [line.strip() for line in content.splitlines() if line.strip()]
            logger.info(f"Fetched {len(ips)} IPs from feed.")
            return ips
    except Exception as e:
        logger.error(f"Failed to fetch IP feed: {e}")
        return []

def get_already_banned_batch(host):
    """Fetches all currently banned IPs from the host. Uses direct command for local hosts."""
    logger.info(f"Fetching current ban list from {host}...")
    
    h_clean = host.strip().lower()
    is_local = h_clean in ["localhost", "127.0.0.1", "::1"]
    
    if is_local:
        # Use fail2ban-client directly if local
        check_cmd = ["sudo", "fail2ban-client", "status", TARGET_JAIL]
    else:
        check_cmd = [
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
            host,
            f"sudo fail2ban-client status {TARGET_JAIL}"
        ]
        
    try:
        result = subprocess.run(check_cmd, capture_output=True, text=True, check=True)
        stdout = result.stdout
        if "Banned IP list:" in stdout:
            # Split by the header to get only the IP part
            # Use '1' as maxsplit to get everything after the first match
            _, ip_part = stdout.split("Banned IP list:", 1)
            # Remove existing commas or other separators if present, though F2B usually uses spaces
            # Replace newlines with spaces and split to get clean IPs
            ips = set(ip.strip().strip(',') for ip in ip_part.replace('\n', ' ').split() if ip.strip())
            return ips
    except Exception as e:
        logger.error(f"Failed to fetch ban list from {host}: {e}")
    return set()

def ban_ip_remote(ip, host):
    """Bans IP on a specific host. Uses direct command for local hosts."""
    h_clean = host.strip().lower()
    if h_clean in ["localhost", "127.0.0.1", "::1"]:
        cmd = ["sudo", "fail2ban-client", "set", TARGET_JAIL, "banip", ip]
    else:
        cmd = [
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
            host, 
            f"sudo fail2ban-client set {TARGET_JAIL} banip {ip}"
        ]
    try:
        subprocess.run(cmd, capture_output=True, text=True, check=True)
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to ban {ip} on {host}: {e.stderr.strip() if e.stderr else e}")
    return False

def main():
    logger.info("=" * 40)
    logger.info("lemueIO Active Intelligence Feed - Client Shield")
    logger.info("Starting execution (Cron mode)...")
    logger.info("=" * 40)
    
    self_update()

    # 1. Fetch Feed
    feed_ips = fetch_ips_from_feed()
    if not feed_ips:
        return

    # 2. Process per host
    for host in REMOTE_HOSTS:
        logger.info(f"--- Processing host: {host} ---")
        
        # Batch fetch current banned IPs to avoid sequential SSH calls
        currently_banned = get_already_banned_batch(host)
        logger.info(f"Found {len(currently_banned)} IPs already banned on {host}.")

        new_ips = [ip for ip in feed_ips if ip not in currently_banned and len(ip) >= 7]
        
        if not new_ips:
            logger.info("All IPs from feed are already banned. Skipping.")
            continue

        logger.info(f"Found {len(new_ips)} NEW IPs to ban.")
        
        ban_count = 0

        for ip in new_ips:
            # Ban
            if ban_ip_remote(ip, host):
                ban_count += 1
                if ban_count % 100 == 0:
                    logger.info(f"Banned {ban_count}/{len(new_ips)} IPs...")

        logger.info(f"Summary for {host}: Banned {ban_count} IPs.")

    logger.info("=" * 40)
    logger.info("Execution finished successfully.")
    logger.info("=" * 40)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logger.info("Stopping script...")
        sys.exit(0)

