import sqlite3
import pymysql
import time
import subprocess
import os
import signal
import sys
import logging
from concurrent.futures import ThreadPoolExecutor

# Configuration
DB_TYPE = os.getenv("DB_TYPE", "sqlite")
DB_HOST = os.getenv("DB_HOST", "mariadb")
DB_PORT = int(os.getenv("DB_PORT", 3306))
DB_USER = os.getenv("DB_USER", "hfish")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
DB_NAME = os.getenv("DB_NAME", "hfish")

# Legacy/SQLite Path
DB_PATH = "/hfish_ro/database/hfish.db"

SCANS_DIR = "/app/scans"
FEED_DIR = "/app/feed"
BANNED_IPS_FILE = os.path.join(FEED_DIR, "banned_ips.txt")
INDEX_FILE = os.path.join(FEED_DIR, "index.html")
MAX_WORKERS = 5 

# Setup Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("HoneySidecar")

def signal_handler(sig, frame):
    logger.info("Exiting...")
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

def init_env():
    if not os.path.exists(SCANS_DIR):
        os.makedirs(SCANS_DIR)
    if not os.path.exists(FEED_DIR):
        os.makedirs(FEED_DIR)
    update_index()

def get_db_connection():
    """Establishes connection to SQLite or MariaDB based on DB_TYPE."""
    try:
        if DB_TYPE == "mysql":
            return pymysql.connect(
                host=DB_HOST,
                port=DB_PORT,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_NAME,
                cursorclass=pymysql.cursors.DictCursor,
                connect_timeout=5
            )
        else:
            # Connect in read-only mode to minimize locking
            return sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return None

def get_new_attackers():
    """Fetch unique source IPs from infos table that haven't been scanned."""
    conn = get_db_connection()
    if not conn:
        return []

    ips = []
    try:
        cursor = conn.cursor()
        # Query compatibility: Assume 'infos' table and 'source_ip', 'create_time' exist in both
        query = "SELECT DISTINCT source_ip FROM infos ORDER BY create_time DESC LIMIT 100"
        
        cursor.execute(query)
        rows = cursor.fetchall()
        
        for row in rows:
            # DictCursor returns dict, sqlite3 returns tuple
            if isinstance(row, dict):
                ips.append(row['source_ip'])
            else:
                ips.append(row[0])
                
        conn.close()
    except Exception as e:
        logger.error(f"Error fetching attackers: {e}")
        if conn:
            try: conn.close()
            except: pass
    return ips

def scan_ip(ip):
    """Run nmap scan on IP."""
    report_path = os.path.join(SCANS_DIR, f"{ip}.txt")
    if os.path.exists(report_path):
        return None # Already scanned

    logger.info(f"Scanning {ip}...")
    try:
        command = ["nmap", "-A", "-T4", "-Pn", ip] 
        result = subprocess.run(command, capture_output=True, text=True, timeout=300)
        
        with open(report_path, "w") as f:
            f.write(f"Scan Time: {time.ctime()}\n")
            f.write(f"Target: {ip}\n")
            f.write("-" * 40 + "\n")
            f.write(result.stdout)
            if result.stderr:
                f.write("\nErrors:\n")
                f.write(result.stderr)
        return ip
    except subprocess.TimeoutExpired:
        logger.warning(f"Scan for {ip} timed out.")
        with open(report_path, "w") as f:
            f.write(f"Scan Time: {time.ctime()}\n")
            f.write(f"Target: {ip}\n")
            f.write("Error: Scan timed out after 300s.")
        return ip
    except Exception as e:
        logger.error(f"Error scanning {ip}: {e}")
        return None

def update_banned_list(ips):
    """Update banned_ips.txt with unique IPs."""
    current_banned = set()
    if os.path.exists(BANNED_IPS_FILE):
        with open(BANNED_IPS_FILE, "r") as f:
            current_banned = set(line.strip() for line in f if line.strip())
    
    new_ips = set(ips) - current_banned
    if new_ips:
        with open(BANNED_IPS_FILE, "a") as f:
            for ip in new_ips:
                f.write(f"{ip}\n")
        logger.info(f"Added {len(new_ips)} IPs to ban list.")

def update_index():
    """Generate simple index.html."""
    try:
        scanned_files = sorted([f for f in os.listdir(SCANS_DIR) if f.endswith(".txt")])
        
        html = """
<!DOCTYPE html>
<html>
<head>
    <title>lemue.org SecMonitor</title>
    <style>
        body { font-family: monospace; padding: 20px; background: #f0f0f0; }
        h1 { color: #333; }
        .list { background: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .item { padding: 5px 0; border-bottom: 1px solid #eee; }
        a { text-decoration: none; color: #0066cc; }
        a:hover { text-decoration: underline; }
        .meta { font-size: 0.8em; color: #666; margin-left: 10px; }
    </style>
</head>
<body>
    <h1>lemue.org SecMonitor</h1>
    <div class="list">
        <h3>Resources</h3>
        <div class="item">
            <a href="feed/banned_ips.txt" target="_blank">banned_ips.txt</a>
            <span class="meta">List of unique attacker IPs</span>
        </div>
    </div>
    <br>
    <div class="list">
        <h3>Scan Reports</h3>
"""
        for f in scanned_files:
            safe_f = os.path.basename(f)
            html += f'        <div class="item"><a href="scans/{safe_f}" target="_blank">{safe_f}</a></div>\n'
            
        html += """
    </div>
</body>
</html>
"""
        with open(INDEX_FILE, "w") as f:
            f.write(html)
    except Exception as e:
        logger.error(f"Error updating index: {e}")

def main():
    init_env()
    logger.info(f"Monitor started (DB_TYPE={DB_TYPE}).")
    logger.info("Waiting 30s for DB to be ready...")
    time.sleep(30) # Delay start to allow MariaDB to initialize

    executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)

    try:
        while True:
            try:
                attackers = get_new_attackers()
                
                futures = []
                for ip in attackers:
                    if len(ip) < 7: continue
                    futures.append(executor.submit(scan_ip, ip))
                
                # Wait for scans to complete to update index correctly? 
                # No, fire and forget roughly, but update lists
                
                # Check results periodically or just proceed
                # For simplicity, we just check completion in next loops or assume done
                
                if attackers:
                    update_banned_list(attackers)
                
                # Update index regardless to show new files
                update_index()
                    
            except Exception as e:
                logger.error(f"Loop error: {e}")
            
            time.sleep(10)
            
    finally:
        executor.shutdown(wait=False)

if __name__ == "__main__":
    main()
