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
IP_FEED_URL = "https://feed.sec.lemue.org/banned_ips.txt"
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
    if os.path.exists(output_file):
        return

    cmd = ["nmap", "-A", "-T4", ip, "-oN", output_file]
    logger.info(f"Starting Nmap scan for {ip}...")
    try:
        subprocess.run(cmd, check=True, timeout=300) # 5 min timeout
        logger.info(f"Nmap scan completed for {ip}.")
    except subprocess.TimeoutExpired:
        logger.error(f"Nmap scan for {ip} timed out.")
    except subprocess.SubprocessError as e:
        logger.error(f"Nmap scan failed for {ip}: {e}")

def is_already_banned(ip, host):
    """Checks if the IP is already present in the target Fail2Ban jail on the remote host."""
    check_cmd = [
        "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
        host,
        f"sudo fail2ban-client status {TARGET_JAIL}"
    ]
    try:
        result = subprocess.run(check_cmd, capture_output=True, text=True, check=True)
        # Fail2Ban output usually contains 'Banned IP list: ...'
        if ip in result.stdout:
            return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to check ban status for {ip} on {host}. Error: {e.stderr.strip()}")
    return False

def ban_ip_remote(ip):
    """Bans IP on all remote hosts, skipping if already banned."""
    for host in REMOTE_HOSTS:
        if is_already_banned(ip, host):
            # logger.info(f"IP {ip} already banned on {host}. Skipping.")
            continue
            
        logger.info(f"Banning {ip} on {host}...")
        ssh_cmd = [
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
            host, 
            f"sudo fail2ban-client set {TARGET_JAIL} banip {ip}"
        ]
        
        try:
            subprocess.run(ssh_cmd, capture_output=True, text=True, check=True)
            logger.info(f"Successfully banned {ip} on {host}.")
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to ban {ip} on {host}. Error: {e.stderr.strip()}")

def main():
    logger.info("=" * 40)
    logger.info("lemueIO Active Intelligence Feed - Client Shield")
    logger.info("Starting execution (Cron mode)...")
    logger.info("=" * 40)
    
    # 1. Self Update
    self_update()

    # 2. Fetch IPs from Feed
    feed_ips = fetch_ips_from_feed()
    
    # Unique set
    all_ips = sorted(list(set(feed_ips)))
    
    if not all_ips:
        logger.info("No IPs found in feed. Exiting.")
        return

    logger.info(f"Found {len(all_ips)} IPs to verify.")
    logger.info("-" * 40)

    processed_count = 0
    banned_count = 0

    for ip in all_ips:
        if len(ip) < 7: continue
        
        # We use Fail2Ban as the source of truth for 'processed'
        # To avoid heavy SSH calls, we only log when we ACTION something
        if is_already_banned(ip, "localhost"): # Simple check for local/primary host
            continue
            
        processed_count += 1
        logger.info(f"[{processed_count}] New IP detected: {ip}")
        
        # 3. Reconnaissance
        run_nmap(ip)

        # 4. Ban Action
        ban_ip_remote(ip)
        banned_count += 1

    logger.info("=" * 40)
    logger.info(f"Execution finished. Processed {processed_count} new IPs, Banned {banned_count}.")
    logger.info("=" * 40)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logger.info("Stopping script...")
        sys.exit(0)
