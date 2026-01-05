#!/usr/bin/env python3
import os
import sys
import hashlib
import urllib.request
import subprocess
import logging
import fcntl
import sqlite3
import time
from collections import Counter

# ==========================================
#  lemueIO Active Intelligence Feed - Client Shield (Python Variant)
# ==========================================
#  Version: 5.3.1
#  Description: Fetches malicious IPs, bans them on remote hosts, and cleans up Fail2Ban jails.
# ==========================================

# --- CONFIGURATION ---
UPDATE_URL = "https://feed.sec.lemue.org/scripts/client_banned_ips.sh"
IP_FEED_URL = "https://feed.sec.lemue.org/banned_ips.txt"
DATA_DIR = "./data"
HFISH_DB_PATH = os.path.join(DATA_DIR, "hfish.db")
TARGET_JAIL = "sshd"
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

def fetch_ips_from_db():
    """Fetches unique IPs from the local HFish SQLite database."""
    if not os.path.exists(HFISH_DB_PATH):
        return []
    
    logger.info(f"Fetching IPs from local DB {HFISH_DB_PATH}...")
    try:
        conn = sqlite3.connect(f"file:{HFISH_DB_PATH}?mode=ro", uri=True)
        cursor = conn.cursor()
        # Querying the 'infos' table for source_ip, similar to monitor.py
        cursor.execute("SELECT DISTINCT source_ip FROM infos")
        ips = [row[0] for row in cursor.fetchall() if row[0]]
        conn.close()
        logger.info(f"Fetched {len(ips)} IPs from local DB.")
        return ips
    except Exception as e:
        logger.error(f"Failed to fetch IPs from DB: {e}")
        return []


def get_already_banned_list(host):
    """Fetches all currently banned IPs from the host as a list (to detect duplicates)."""
    h_clean = host.strip().lower()
    is_local = h_clean in ["localhost", "127.0.0.1", "::1"]
    
    if is_local:
        check_cmd = ["sudo", "fail2ban-client", "status", TARGET_JAIL]
    else:
        check_cmd = [
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
            host, f"sudo fail2ban-client status {TARGET_JAIL}"
        ]
        
    try:
        result = subprocess.run(check_cmd, capture_output=True, text=True, check=True)
        stdout = result.stdout
        if "Banned IP list:" in stdout:
            _, ip_part = stdout.split("Banned IP list:", 1)
            # We return a list instead of a set to detect duplicates
            ips = [ip.strip().strip(',') for ip in ip_part.replace('\n', ' ').split() if ip.strip()]
            return ips
    except Exception as e:
        logger.error(f"Failed to fetch ban list from {host}: {e}")
    return []

def unban_ip_remote(ip, host):
    """Unbans IP on a specific host."""
    h_clean = host.strip().lower()
    if h_clean in ["localhost", "127.0.0.1", "::1"]:
        cmd = ["sudo", "fail2ban-client", "set", TARGET_JAIL, "unbanip", ip]
    else:
        cmd = [
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
            host, f"sudo fail2ban-client set {TARGET_JAIL} unbanip {ip}"
        ]
    try:
        subprocess.run(cmd, capture_output=True, text=True, check=True)
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to unban {ip} on {host}: {e.stderr.strip() if e.stderr else e}")
    return False

def cleanup_jail(host):
    """Checks the jail for duplicates and cleans it up by unbanning/re-banning."""
    logger.info(f"Performing jail cleanup on {host}...")
    banned_list = get_already_banned_list(host)
    if not banned_list:
        return

    counts = Counter(banned_list)
    duplicates = [ip for ip, count in counts.items() if count > 1]

    if not duplicates:
        logger.info(f"No duplicates found in jail on {host}.")
        return

    logger.info(f"Found {len(duplicates)} duplicate IPs in jail on {host}. Cleaning up...")
    for ip in duplicates:
        logger.info(f"Resolving duplicate for {ip}...")
        if unban_ip_remote(ip, host):
            ban_ip_remote(ip, host)
    
    logger.info(f"Cleanup finished for {host}.")

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
    lock_path = "/tmp/client_banned_ips.lock"
    try:
        lock_file = open(lock_path, "w")
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except (IOError, OSError):
        logger.warning("Another instance of the script is already running. Exiting.")
        sys.exit(0)

    try:
        logger.info("=" * 60)
        logger.info("lemueIO Active Intelligence Feed - Client Shield v5.3.1")
        logger.info("Starting execution (Cron mode)...")
        logger.info("=" * 60)
        
        self_update()

        # 1. Fetch IPs from multiple sources
        all_ips = set(fetch_ips_from_feed())
        all_ips.update(fetch_ips_from_db())
        
        if not all_ips:
            logger.info("No IPs found from any source. Exiting.")
            return

        # 2. Process per host (Cleanup + Banning)
        for host in REMOTE_HOSTS:
            logger.info(f"--- Processing host: {host} ---")
            
            # Feature: Jail Cleanup
            cleanup_jail(host)
            
            if not all_ips:
                continue

            # Feature: Fresh Ban List
            currently_banned = set(get_already_banned_list(host))
            logger.info(f"Current ban count on {host}: {len(currently_banned)}")

            ips_to_ban = [ip for ip in all_ips if ip not in currently_banned and len(ip) >= 7]
            
            if not ips_to_ban:
                logger.info("All IPs are already banned on this host.")
                continue

            logger.info(f"Found {len(ips_to_ban)} NEW IPs to ban on {host}.")
            
            ban_count = 0
            for ip in ips_to_ban:
                if ban_ip_remote(ip, host):
                    ban_count += 1
                    if ban_count % 100 == 0:
                        logger.info(f"Banned {ban_count}/{len(ips_to_ban)} IPs on {host}...")

            logger.info(f"Summary for {host}: Banned {ban_count} IPs.")

        logger.info("=" * 60)
        logger.info("Execution finished successfully.")
        logger.info("=" * 60)
    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}")
    finally:
        lock_file.close()
        if os.path.exists(lock_path):
            try: os.remove(lock_path)
            except: pass

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logger.info("Stopping script...")
        sys.exit(0)

