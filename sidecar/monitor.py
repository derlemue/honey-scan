import sqlite3
import time
import subprocess
import os
import signal
import sys
from concurrent.futures import ThreadPoolExecutor

# Configuration
DB_PATH = "/hfish_ro/database/hfish.db"
SCANS_DIR = "/app/scans"
FEED_DIR = "/app/feed"
BANNED_IPS_FILE = os.path.join(FEED_DIR, "banned_ips.txt")
INDEX_FILE = os.path.join(FEED_DIR, "index.html")
MAX_WORKERS = 5 # Number of concurrent scans

def signal_handler(sig, frame):
    print("Exiting...")
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

def init_env():
    if not os.path.exists(SCANS_DIR):
        os.makedirs(SCANS_DIR)
    if not os.path.exists(FEED_DIR):
        os.makedirs(FEED_DIR)
    
    # Ensure index.html exists
    update_index()

def get_new_attackers():
    """Fetch unique source IPs from infos table that haven't been scanned."""
    try:
        # Connect in read-only mode to minimize locking
        conn = sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
        cursor = conn.cursor()
        
        # Get recent attackers
        cursor.execute("SELECT DISTINCT source_ip FROM infos ORDER BY create_time DESC LIMIT 100")
        ips = [row[0] for row in cursor.fetchall()]
        conn.close()
        return ips
    except sqlite3.OperationalError:
        # DB might be locked or not ready yet, just return empty list
        return []
    except Exception as e:
        print(f"Error fetching attackers: {e}")
        return []

def scan_ip(ip):
    """Run nmap scan on IP."""
    report_path = os.path.join(SCANS_DIR, f"{ip}.txt")
    if os.path.exists(report_path):
        return None # Already scanned

    print(f"Scanning {ip}...")
    try:
        # Using -Pn to assume host is up, as attackers might block ping
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
        print(f"Scan for {ip} timed out.")
        with open(report_path, "w") as f:
            f.write(f"Scan Time: {time.ctime()}\n")
            f.write(f"Target: {ip}\n")
            f.write("Error: Scan timed out after 300s.")
        return ip # Considered scanned/attempted
    except Exception as e:
        print(f"Error scanning {ip}: {e}")
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
        print(f"Added {len(new_ips)} IPs to ban list.")

def update_index():
    """Generate simple index.html."""
    try:
        scanned_files = sorted([f for f in os.listdir(SCANS_DIR) if f.endswith(".txt")])
        
        html = """
<!DOCTYPE html>
<html>
<head>
    <title>HFish Active Defense Dashboard</title>
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
    <h1>Active Defense Feed</h1>
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
            # Basic sanitization
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
        print(f"Error updating index: {e}")

def main():
    init_env()
    print("Monitor started.")
    
    executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)

    try:
        while True:
            try:
                attackers = get_new_attackers()
                
                futures = []
                for ip in attackers:
                    # Basic IP validation (skip empty or weird strings)
                    if len(ip) < 7: continue
                    
                    futures.append(executor.submit(scan_ip, ip))
                
                # Collect results
                scanned_ips = []
                for future in futures:
                    result = future.result()
                    if result:
                        scanned_ips.append(result)
                
                if attackers:
                    update_banned_list(attackers) # Ban everyone we see
                
                if scanned_ips:
                    update_index()
                    
            except Exception as e:
                print(f"Loop error: {e}")
            
            time.sleep(10) # Poll every 10 seconds
            
    finally:
        executor.shutdown(wait=False)

if __name__ == "__main__":
    main()
