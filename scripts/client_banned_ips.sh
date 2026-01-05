#!/usr/bin/env python3
import os
import sys
import time
import sqlite3
import hashlib
import urllib.request
import subprocess
import logging

# ==========================================
#  lemueIO Active Intelligence Feed - Client Shield (Python Variant)
# ==========================================
#  Version: 4.0.0 (Python Rewrite)
#  Description: Fetches malicious IPs from honey-scan DB, runs reconnaissance, and bans them via Fail2Ban on remote hosts.
# ==========================================

# --- CONFIGURATION ---
UPDATE_URL = "https://feed.sec.lemue.org/scripts/client_banned_ips.sh"
IP_FEED_URL = "https://feed.sec.lemue.org/feed/banned_ips.txt"
DB_PATH = "./data/hfish.db"
PROCESSED_FILE = "processed_ips.txt"
SCANS_DIR = "./scans"
TARGET_JAIL = "sshd"
# WICHTIG: Auf den Ziel-Hosts muss in der jail.local für dieses Jail 'banaction = iptables-allports' und 'port = anyport' konfiguriert sein, damit der Block systemweit greift.
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

def get_processed_ips():
    if not os.path.exists(PROCESSED_FILE):
        return set()
    with open(PROCESSED_FILE, 'r') as f:
        return set(line.strip() for line in f if line.strip())

def save_processed_ip(ip):
    with open(PROCESSED_FILE, 'a') as f:
        f.write(f"{ip}\n")

def fetch_new_ips(processed_ips):
    """Fetches unique IPs from the database that haven't been processed."""
    if not os.path.exists(DB_PATH):
        logger.error(f"Database not found at {DB_PATH}")
        return []
    
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        # Assuming table hfish_attack and column source_ip based on request
        cursor.execute("SELECT DISTINCT source_ip FROM hfish_attack")
        rows = cursor.fetchall()
        conn.close()

        new_ips = []
        for row in rows:
            ip = row[0]
            if ip and ip not in processed_ips:
                new_ips.append(ip)
        return new_ips
    except sqlite3.Error as e:
        logger.error(f"Database error: {e}")
        return []

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

def run_nmap(ip):
    """Runs Nmap scan for the given IP."""
    if not os.path.exists(SCANS_DIR):
        os.makedirs(SCANS_DIR)
    
    output_file = os.path.join(SCANS_DIR, f"{ip}.txt")
    cmd = ["nmap", "-A", "-T4", ip, "-oN", output_file]
    logger.info(f"Starting Nmap scan for {ip}...")
    try:
        subprocess.run(cmd, check=True, timeout=300) # 5 min timeout
        logger.info(f"Nmap scan completed for {ip}.")
    except subprocess.TimeoutExpired:
        logger.error(f"Nmap scan for {ip} timed out.")
    except subprocess.SubprocessError as e:
        logger.error(f"Nmap scan failed for {ip}: {e}")

def ban_ip_remote(ip):
    """Bans IP on all remote hosts."""
    for host in REMOTE_HOSTS:
        logger.info(f"Banning {ip} on {host}...")
        # Command: ssh {host} 'sudo fail2ban-client set {TARGET_JAIL} banip {ip}'
        ssh_cmd = [
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
            host, 
            f"sudo fail2ban-client set {TARGET_JAIL} banip {ip}"
        ]
        
        try:
            result = subprocess.run(ssh_cmd, capture_output=True, text=True, check=True)
            logger.info(f"Successfully banned {ip} on {host}.")
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to ban {ip} on {host}. Error: {e.stderr.strip()}")

def main():
    logger.info("Starting execution (Cron mode)...")
    
    # 1. Self Update
    self_update()

    # 2. Get Processed IPs
    processed_ips = get_processed_ips()

    # 3. Fetch New IPs (DB + Feed)
    db_ips = fetch_new_ips(processed_ips) # Returns IPs not in processed_ips
    feed_ips = fetch_ips_from_feed()
    
    # Filter feed IPs against processed_ips
    new_feed_ips = [ip for ip in feed_ips if ip not in processed_ips]

    # Combine and Deduplicate
    all_new_ips = list(set(db_ips + new_feed_ips))
    
    logger.info(f"Found {len(all_new_ips)} new IPs to process (DB: {len(db_ips)}, Feed: {len(new_feed_ips)}).")

    for ip in all_new_ips:
        # 4. Reconnaissance
        run_nmap(ip)

        # 5. Ban Action
        ban_ip_remote(ip)

        # 6. Mark as processed
        save_processed_ip(ip)

    logger.info("Execution finished.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logger.info("Stopping script...")
        sys.exit(0)
