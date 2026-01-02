import sqlite3
import pymysql
import time
import subprocess
import os
import signal
import sys
import logging
import requests
import json
from concurrent.futures import ThreadPoolExecutor

# Configuration
# Version: 1.3 (Force Rebuild)
DB_TYPE = os.getenv("DB_TYPE", "mysql")
DB_HOST = os.getenv("DB_HOST", "mariadb")
DB_PORT = int(os.getenv("DB_PORT") or 3306)
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

def fix_missing_severity():
    """Populate empty severity columns in ipaddress table."""
    conn = get_db_connection()
    if not conn:
        return

    try:
        cursor = conn.cursor()
        if DB_TYPE == "mysql":
            # Update severity to 'Low' where it is empty or NULL or 'Unknown'
            # Also ensure threat_level is consistent if needed, but primary fix is severity column.
            query = "UPDATE ipaddress SET severity = 'Low' WHERE severity IS NULL OR severity = ''"
            cursor.execute(query)
            affected = cursor.rowcount
            if affected > 0:
                logger.info(f"Fixed missing severity for {affected} IPs.")
            conn.commit()
    except Exception as e:
        logger.error(f"Error fixing severity: {e}")
    finally:
        if conn: conn.close()

def restore_chinese_names():
    """Restore Chinese strings in DB to ensure flags work, relying on frontend translation."""
    conn = get_db_connection()
    if not conn: return

    try:
        cursor = conn.cursor()
        if DB_TYPE == "mysql":
            # 1. Restore Country Names (English -> Chinese)
            # We map English back to Chinese because HFish flags depend on Chinese keys OR codes derived from them?
            # Actually, standard HFish puts Chinese in DB. 
            # We need to revert our previous "United States" -> "美国" changes.
            translations = {
                "United States": "美国",
                "Netherlands": "荷兰",
                "Localhost": "本机地址",
                "China": "中国",
                "Russia": "俄罗斯",
                "Germany": "德国",
                "United Kingdom": "英国",
                "France": "法国",
                "LAN": "局域网",
                "Unknown": "未知",
                "Iran": "伊朗",
                "Canada": "加拿大",
                "Czechia": "捷克",
                "Europe": "欧洲地区",
                "Belgium": "比利时",
                "Spain": "西班牙",
                "Japan": "日本",
                "South Korea": "韩国",
                "Brazil": "巴西",
                "India": "印度",
                "Italy": "意大利",
                "Australia": "澳大利亚",
                "Poland": "波兰",
                "Finland": "芬兰",
                "Sweden": "瑞典",
                "Norway": "挪威",
                "Switzerland": "瑞士",
                "Ukraine": "乌克兰",
                "Vietnam": "越南",
                "North Korea": "朝鲜",
                "Thailand": "泰国",
                "Singapore": "新加坡",
                "Indonesia": "印尼",
                "Philippines": "菲律宾",
                "Argentina": "阿根廷",
                "Chile": "智利",
                "Colombia": "哥伦比亚",
                "Mexico": "墨西哥",
                "Egypt": "埃及",
                "South Africa": "南非",
                "Turkey": "土耳其",
                "Israel": "以色列",
                "Saudi Arabia": "沙特"
            }
            for en, cn in translations.items():
                cursor.execute("UPDATE ipaddress SET country = %s WHERE country = %s", (cn, en))
                # Also restore region if it looks like the country
                cursor.execute("UPDATE ipaddress SET region = %s WHERE region = %s", (cn, en))
                
                # Restore in other tables
                for table in ['scans', 'scanners', 'infos']:
                      try:
                           cursor.execute(f"UPDATE {table} SET source_ip_country = %s WHERE source_ip_country = %s", (cn, en))
                      except:
                           pass

            conn.commit()
    except Exception as e:
        logger.error(f"Error restoring DB names: {e}")
    finally:
        if conn: conn.close()

def get_db_connection():
    """Establishes connection to SQLite or MariaDB based on DB_TYPE."""
    try:
        if DB_TYPE.lower() in ("mysql", "mariadb"):
            return pymysql.connect(
                host=DB_HOST,
                port=DB_PORT,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_NAME,
                cursorclass=pymysql.cursors.DictCursor,
                connect_timeout=5,
                autocommit=True,
                charset='utf8mb4'
            )
        else:
            return sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return None

def ensure_db_schema():
    """Ensure nodes table has lat/lng/city/country columns."""
    if DB_TYPE.lower() not in ("mysql", "mariadb"):
        return

    conn = get_db_connection()
    if not conn: return

    try:
        cursor = conn.cursor()
        # Check existing columns
        cursor.execute("DESCRIBE nodes")
        columns = [row['Field'] for row in cursor.fetchall()]

        alter_cmds = []
        if 'lat' not in columns: alter_cmds.append("ADD COLUMN lat FLOAT DEFAULT 0.0")
        if 'lng' not in columns: alter_cmds.append("ADD COLUMN lng FLOAT DEFAULT 0.0")
        if 'city' not in columns: alter_cmds.append("ADD COLUMN city VARCHAR(64) DEFAULT ''")
        if 'country' not in columns: alter_cmds.append("ADD COLUMN country VARCHAR(64) DEFAULT ''")

        for cmd in alter_cmds:
            logger.info(f"Migrating DB: {cmd}")
            cursor.execute(f"ALTER TABLE nodes {cmd}")
        
        conn.close()
    except Exception as e:
        logger.error(f"Schema migration failed: {e}")
        if conn: conn.close()

def get_geolocation():
    """Fetch public IP and detailed geolocation."""
    try:
        # Get Public IP with retry
        ip = None
        for url in ["https://api.ipify.org?format=json", "https://api.myip.com"]:
            try:
                ip_resp = requests.get(url, timeout=5).json()
                ip = ip_resp.get('ip')
                if ip: break
            except:
                continue

        if not ip: 
            logger.error("Could not determine public IP after retries.")
            return None
        
        # Get Geo Info (free endpoint)
        # ip-api.com returns: lat, lon, city, country
        geo = requests.get(f"http://ip-api.com/json/{ip}", timeout=10).json()
        
        if geo.get('status') == 'success':
            return {
                'ip': ip,
                'lat': geo.get('lat', 0.0),
                'lng': geo.get('lon', 0.0), # API uses 'lon'
                'city': geo.get('city', 'Unknown'),
                'country': geo.get('country', 'Unknown'),
                'location_str': f"{geo.get('city')}, {geo.get('country')}"
            }
        else:
            logger.warning(f"Geo API failed for {ip}: {geo.get('message')}")
            
    except Exception as e:
        logger.error(f"Geolocation fetch failed: {e}")
    return None

def check_cloud_connectivity():
    """Check connectivity to ThreatBook/HFish Cloud."""
    try:
        # ThreatBook API endpoint often used by HFish
        resp = requests.get("https://api.threatbook.cn/v3/scene/ip_reputation", timeout=5)
        if resp.status_code == 404 or resp.status_code == 200: 
            # 404 is expected if no auth, but proves connectivity.
            logger.info("Cloud Intelligence Connectivity: OK (ThreatBook API reachable)")
        else:
            logger.warning(f"Cloud Intelligence Connectivity: Unexpected status {resp.status_code}")
    except Exception as e:
        logger.error(f"Cloud Intelligence Connectivity: FAILED - {e}")

def update_node_location():
    """Update valid node location in database and side-channel JSON."""
    check_cloud_connectivity() # Run diagnostics

    data = get_geolocation()
    if not data:
        logger.warning("Could not determine dynamic location.")
        return

    logger.info(f"Detected Public IP: {data['ip']}, Location: {data['location_str']} ({data['lat']}, {data['lng']})")
    
    # === SIDE CHANNEL WRITE ===
    # Write this data to a JSON file that the frontend can fetch
    try:
        json_path = "/app/assets/location.json"
        
        # Ensure the directory exists (it should via volume mount, but being safe)
        if not os.path.exists(os.path.dirname(json_path)):
            os.makedirs(os.path.dirname(json_path), exist_ok=True)
            
        with open(json_path, 'w') as f:
            json.dump(data, f)
        logger.info(f"Updated side-channel location file: {json_path}")
    except Exception as e:
        logger.error(f"Failed to write side-channel location file: {e}")
    
    # === DB UPDATE ===
    conn = get_db_connection()
    if not conn: return

    try:
        cursor = conn.cursor()
        # Find ALL active nodes (HFish often has just one, but we should be robust)
        if DB_TYPE == "mysql":
            # Update ALL nodes to the current location to ensure the map is correct
            # We update both the legacy 'location' string and the new specific columns
            query = """
                UPDATE nodes 
                SET location = %s, lat = %s, lng = %s, city = %s, country = %s
            """
            cursor.execute(query, (data['location_str'], data['lat'], data['lng'], data['city'], data['country']))
            
            affected = cursor.rowcount
            if affected > 0:
                logger.info(f"Updated {affected} node(s) location.")
            else:
                # If no rows affected, maybe the table is empty or location is same.
                cursor.execute("SELECT count(*) as count FROM nodes")
                res = cursor.fetchone()
                if res and res['count'] > 0:
                     logger.info("Node location presumably already up to date.")
                else:
                     logger.warning("No nodes found in DB to update.")
        else:
             logger.info("Skipping DB update (SQLite / Read-Only mode)")
        conn.close()
    except Exception as e:
        logger.error(f"Database update failed: {e}")
        if conn: conn.close()

def get_new_attackers():
    """Fetch unique source IPs from infos table that haven't been scanned."""
    conn = get_db_connection()
    if not conn:
        return []

    ips = []
    try:
        cursor = conn.cursor()
        query = "SELECT DISTINCT source_ip FROM infos ORDER BY create_time DESC LIMIT 100"
        cursor.execute(query)
        rows = cursor.fetchall()
        
        for row in rows:
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
    <title>lemueIO Active Intelligence Feed</title>
    <link rel="icon" href="/assets/favicon.ico">
    <link rel="icon" sizes="32x32" href="/assets/favicon-32x32.png">
    <link rel="icon" sizes="16x16" href="/assets/favicon-16x16.png">
    <link rel="apple-touch-icon" href="/assets/apple-touch-icon.png">
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
    <h1>lemueIO Active Intelligence Feed</h1>
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
    time.sleep(30) 
    
    # Run Schema Migration
    ensure_db_schema()
    
    # Run dynamic geolocation UPDATE
    update_node_location()

    executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)

    try:
        while True:
            try:
                attackers = get_new_attackers()
                
                futures = []
                for ip in attackers:
                    if len(ip) < 7: continue
                    futures.append(executor.submit(scan_ip, ip))
                
                if attackers:
                    update_banned_list(attackers)
                
                fix_missing_severity()
                restore_chinese_names()
                update_index()
                
                # Periodic Location Update (Every ~10 mins -> 60 loops * 10s)
                # We use a simple timestamp check or counter
                if int(time.time()) % 600 < 15: # Run roughly every 10 mins
                     update_node_location()
                    
            except Exception as e:
                logger.error(f"Loop error: {e}")
            
            time.sleep(10)
            
    finally:
        executor.shutdown(wait=False)

if __name__ == "__main__":
    main()
