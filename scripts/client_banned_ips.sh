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
import re
import socket
from collections import Counter

# ==========================================
#  lemueIO Active Intelligence Feed - Client Shield (Python Variant)
# ==========================================
#  Version: 5.3.3
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
        # Filter for recent (last 14 days) IPs to match server-side policy
        cursor.execute("SELECT DISTINCT source_ip FROM infos WHERE create_time >= datetime('now', '-14 days')")
        ips = [row[0] for row in cursor.fetchall() if row[0]]
        conn.close()
        logger.info(f"Fetched {len(ips)} IPs from local DB (last 14 days).")
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

def get_open_ports(host):
    """Detects open TCP/UDP ports on the target host using `ss`."""
    # We want listening TCP/UDP ports, numeric output
    # Command: ss -tuln
    h_clean = host.strip().lower()
    if h_clean in ["localhost", "127.0.0.1", "::1"]:
        cmd = ["sudo", "ss", "-tulnH"] # H to suppress header
    else:
        cmd = [
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
            host, "sudo ss -tulnH"
        ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        # Parse output. Example line: "UDP UNCONN 0 0 0.0.0.0:68 0.0.0.0:*" or "tcp LISTEN 0 128 *:22 *:* "
        # We need the local port.
        ports = set()
        for line in result.stdout.splitlines():
            parts = line.split()
            if len(parts) >= 4:
                # Local address is usually the 5th column (index 4)
                # But sometimes state is missing for UDP? "UDP UNCONN..." -> state is UNCONN (idx 1)
                # ss output format varies slightly by version, but usually:
                # Netid State Recv-Q Send-Q Local_Address:Port Peer_Address:Port
                # TCP   LISTEN 0      128    0.0.0.0:22         0.0.0.0:*
                
                # Let's simple regex for IP:Port patterns
                # We are looking for the Local Address column which has the port.
                # It's typically the 4th/5th token.
                
                # A robust way: find all tokens that look like address:port
                # and take the port if it's a listening/bound port.
                # Since we used -l, all are listening (or bound UDP).
                
                # Let's iterate tokens and look for the LAST colon
                local_addr = parts[4] # Standard ss -tuln output has local addr at index 4
                if ':' in local_addr:
                    port_str = local_addr.rsplit(':', 1)[1]
                    if port_str.isdigit():
                        ports.add(port_str)
                        
        if not ports:
            # Fallback or empty? Return default ssh port if nothing found to avoid breaking configuration
            logger.warning(f"No open ports detected on {host}. Defaulting to 22.")
            return "22"
            
        sorted_ports = sorted(list(ports), key=int)
        return ",".join(sorted_ports)
        
    except Exception as e:
        logger.error(f"Failed to detect open ports on {host}: {e}")
        return "22" # Safe fallback

def configure_jail(host, jail, ports, bantime=1209600): # 14 days default
    """Configures the jail with a 14-day bantime and updates monitored ports."""
    h_clean = host.strip().lower()
    prefix = []
    if h_clean not in ["localhost", "127.0.0.1", "::1"]:
        prefix = ["ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes", host]
        
    base_cmd = prefix + ["sudo", "fail2ban-client", "set", jail]
    
    # 1. Set Bantime
    try:
        subprocess.run(base_cmd + ["bantime", str(bantime)], capture_output=True, check=True)
        logger.info(f"Updated bantime to {bantime}s for {jail} on {host}.")
    except Exception as e:
        logger.error(f"Failed to set bantime on {host}: {e}")

    # 2. update ports for all actions
    # First, get list of actions
    try:
        # 'fail2ban-client get JAIL actions' returns a list of actions
        # The output format is a bit tricky to parse from CLI: "The actions are: \n iptables-multiport \n ..."
        get_actions_cmd = prefix + ["sudo", "fail2ban-client", "get", jail, "actions"]
        res = subprocess.run(get_actions_cmd, capture_output=True, text=True, check=True)
        # Parse output - assuming simplistic output structure
        # Typical output: "The actions are:\n\t iptables-multiport\n\t other-action"
        actions = [line.strip() for line in res.stdout.splitlines() if line.strip() and "The actions are" not in line]
        
        for action in actions:
            # Setting port: fail2ban-client set JAIL action ACTION port PORTS
            set_port_cmd = base_cmd + ["action", action, "port", ports]
            subprocess.run(set_port_cmd, capture_output=True, check=True)
            logger.info(f"Updated ports for action '{action}' in {jail} on {host} to: {ports}")
            
    except Exception as e:
        logger.error(f"Failed to configure jail actions on {host}: {e}")

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
        logger.info("lemueIO Active Intelligence Feed - Client Shield v5.3.3")
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
            
            # Feature: Dynamic Jail Configuration
            open_ports = get_open_ports(host)
            
            # Resolve ports to service names for better logging
            service_map = []
            for p in open_ports.split(','):
                try:
                    p_int = int(p)
                    service_name = socket.getservbyport(p_int)
                    service_map.append(f"{service_name.upper()}/{p}")
                except:
                    service_map.append(f"UNKNOWN/{p}")
            
            services_str = ", ".join(service_map)
            logger.info(f"Detected active services on {host}: {services_str}")
            
            configure_jail(host, TARGET_JAIL, open_ports, bantime=1209600) # 14 days
            logger.info(f"Protected services on {host} (Jail: {TARGET_JAIL}) -> {services_str}")

            # Feature: Jail Cleanup (with updated config)
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

