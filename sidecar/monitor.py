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
from datetime import timedelta, datetime

# Configuration
DB_TYPE = os.getenv("DB_TYPE", "mysql")
DB_HOST = os.getenv("DB_HOST", "mariadb")
DB_PORT = int(os.getenv("DB_PORT") or 3306)
DB_USER = "root" # FORCE ROOT
DB_PASSWORD = os.getenv("DB_PASSWORD", os.getenv("MYSQL_ROOT_PASSWORD"))
DB_NAME = os.getenv("DB_NAME", "hfish")

# ThreatBook API Config
THREATBOOK_API_KEY = os.getenv("THREATBOOK_API_KEY")
THREATBOOK_API_BASE_URL = os.getenv("THREATBOOK_API_BASE_URL", "https://api.threatbook.io/v3")

# Legacy/SQLite Path
DB_PATH = "/hfish_ro/database/hfish.db"

SCANS_DIR = "/app/scans"
FEED_DIR = "/app/feed"
ASSETS_DIR = "/app/assets"
BANNED_IPS_FILE = os.path.join(FEED_DIR, "banned_ips.txt")
INDEX_FILE = os.path.join(FEED_DIR, "index.html")
LIVE_THREATS_FILE = os.path.join(ASSETS_DIR, "live_threats.json")
STATS_FILE = os.path.join(ASSETS_DIR, "stats.json")

MAX_WORKERS = 5 

# Setup Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("HoneySidecar")

def signal_handler(sig, frame):
    logger.info("Exiting...")
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

def get_db_connection():
    try:
        if DB_TYPE.lower() in ("mysql", "mariadb"):
            logger.info(f"Connecting with user={DB_USER}")
            print(f"!!! DEBUG CONNECT: Connecting as {DB_USER} to {DB_HOST} !!!", flush=True)
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
    if DB_TYPE.lower() not in ("mysql", "mariadb"):
        return
    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
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
    try:
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
        geo = requests.get(f"http://ip-api.com/json/{ip}", timeout=10).json()
        if geo.get('status') == 'success':
            return {
                'ip': ip,
                'lat': geo.get('lat', 0.0),
                'lng': geo.get('lon', 0.0),
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
    try:
        # Check against Community API with a known safe IP
        url = "https://api.threatbook.io/v1/community/ip"
        params = {"apikey": THREATBOOK_API_KEY, "resource": "8.8.8.8"}
        try:
             resp = requests.post(url, data=params, timeout=10)
             if resp.status_code == 200: 
                 logger.info(f"Cloud Intelligence Connectivity: OK ({url})")
             else:
                 logger.warning(f"Cloud Intelligence Connectivity: HTTP {resp.status_code}")
        except Exception as e:
             logger.error(f"Cloud Intelligence Connectivity: FAILED ({url}) - {e}")
    except Exception as e:
        logger.error(f"Cloud Intelligence Connectivity: Critical Error - {e}")

def update_node_location():
    check_cloud_connectivity() 
    data = get_geolocation()
    if not data:
        logger.warning("Could not determine dynamic location.")
        return
    logger.info(f"Detected Public IP: {data['ip']}, Location: {data['location_str']} ({data['lat']}, {data['lng']})")
    try:
        json_path = "/app/assets/location.json"
        if not os.path.exists(os.path.dirname(json_path)):
            os.makedirs(os.path.dirname(json_path), exist_ok=True)
        with open(json_path, 'w') as f:
            json.dump(data, f)
    except Exception as e:
        logger.error(f"Failed to write side-channel location: {e}")
    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
        if DB_TYPE == "mysql":
            query = """UPDATE nodes SET location = %s, lat = %s, lng = %s, city = %s, country = %s"""
            cursor.execute(query, (data['location_str'], data['lat'], data['lng'], data['city'], data['country']))
            if cursor.rowcount > 0: logger.info(f"Updated {cursor.rowcount} node(s) location.")
        conn.close()
    except Exception as e:
        logger.error(f"Database update failed: {e}")
        if conn: conn.close()

def query_threatbook_ip(ip):
    if not THREATBOOK_API_KEY: return None
    # Use the verified Community API endpoint
    url = "https://api.threatbook.io/v1/community/ip"
    # Parameters for POST request
    params = {"apikey": THREATBOOK_API_KEY, "resource": ip}
    
    try:
        # Change to POST request
        resp = requests.post(url, data=params, timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            if data.get("response_code") == 200:
                result = data.get("data", {})
                
                # Extract severity/risk - Community API doesn't have explicit severity field
                # Infer from judgments: if judgments exist -> High/Critical depending on type?
                # For now, default to Medium if judgments exist, Low/Info if not.
                judgments = result.get("summary", {}).get("judgments", [])
                severity = "medium" if judgments else "low"
                
                # Check for specific critical judgments if needed
                if any(j.lower() in ['c2', 'malware', 'botnet', 'zombie'] for j in judgments):
                    severity = "critical"
                
                return {
                    "severity": severity,
                    "judgments": judgments,
                    "scene": "Unknown", # Community API doesn't provide scene context clearly
                    "carrier": result.get("basic", {}).get("carrier", "Unknown"),
                    "location": result.get("basic", {}).get("location", {})
                }
    except Exception as e:
        logger.error(f"ThreatBook API Error for {ip}: {e}")
    return None

def update_threat_feed():
    logger.info("Updating Threat Feed...")
    conn = get_db_connection()
    if not conn: return
    recent_hackers = []
    suspicious_cs = []
    try:
        cursor = conn.cursor()
        query = "SELECT DISTINCT source_ip, source_ip_country, create_time FROM infos ORDER BY create_time DESC LIMIT 200"
        logger.info(f"Executing Query: {query}")
        cursor.execute(query)
        rows = cursor.fetchall()
        logger.info(f"Fetched {len(rows)} rows from DB")
        for row in rows:
            ip = row['source_ip'] if isinstance(row, dict) else row[0]
            country = row.get('source_ip_country', 'Unknown') if isinstance(row, dict) else "Unknown"
            recent_hackers.append({
                "ip": ip,
                "location": country,
                "time": str(row.get('create_time', 'Just now')),
                "flag": country, 
                "count": 1
            })
            if len(suspicious_cs) < 50:
                threat_data = query_threatbook_ip(ip)
                if threat_data:
                    # Location Logic: Default to DB Country (English). Append API City if available.
                    # This avoids the Chinese country name from ThreatBook.
                    city = threat_data['location'].get('city', '')
                    location_str = country
                    if city and city != country:
                         location_str = f"{country} {city}"

                     # Timezone Logic: Add 1 hour to DB time
                    info_time = row.get('create_time')
                    time_display = "Just now"
                    
                    if info_time:
                         try:
                             final_dt = None
                             
                             # 1. If it relies on pymysql's datetime conversion
                             if isinstance(info_time, datetime):
                                 final_dt = info_time
                             
                             # 2. If it's a string (e.g. from sqlite or failed conversion)
                             elif isinstance(info_time, str):
                                 # Try standard format
                                 try:
                                     final_dt = datetime.strptime(info_time, "%Y-%m-%d %H:%M:%S")
                                 except ValueError:
                                     pass
                             
                             # Force conversion to datetime if possible, or just add if it supports it
                             if final_dt:
                                 # Add 2 hours (1h was insufficient, implies DB is UTC-1 or similar lag)
                                 new_time = final_dt + timedelta(hours=2)
                                 time_display = str(new_time)
                             else:
                                 time_display = str(info_time)
                                 # logger.warning(f"DEBUG TIME: Failed to parse {info_time}")

                         except Exception as e:
                             logger.error(f"Time parsing error: {e}")
                             time_display = str(info_time)

                    suspicious_cs.append({
                        "ip": ip,
                        "location": location_str,
                        "type": threat_data['judgments'][0] if threat_data['judgments'] else "Scanner",
                        "risk": threat_data['severity'].capitalize(),
                        "time": time_display
                    })
                else:
                     suspicious_cs.append({
                        "ip": ip,
                        "location": country,
                        "type": "Port Scanner",
                        "risk": "Medium",
                        "time": str(row.get('create_time', '')) if 'create_time' in row else "Just now"
                    })
        output = {"hackers": recent_hackers, "cs": suspicious_cs, "api_active": bool(THREATBOOK_API_KEY)}
        output = {"hackers": recent_hackers, "cs": suspicious_cs, "api_active": bool(THREATBOOK_API_KEY)}
        
        # Direct write to preserve inode for Docker bind mount
        with open(LIVE_THREATS_FILE, "w") as f:
            json.dump(output, f)
            f.flush()
            os.fsync(f.fileno())

        # Generate General Stats
        stats = {
            "total_attacks": 0,
            "today_attacks": 0,
            "top_country": "Unknown"
        }
        try:
             # Total
             cursor.execute("SELECT COUNT(*) FROM infos")
             row = cursor.fetchone()
             stats["total_attacks"] = row['COUNT(*)'] if isinstance(row, dict) else row[0]

             # Today (Approximation, assume timestamps are standard)
             # MariaDB/MySQL specific syntax
             cursor.execute("SELECT COUNT(*) FROM infos WHERE create_time >= CURDATE()")
             row = cursor.fetchone()
             stats["today_attacks"] = row['COUNT(*)'] if isinstance(row, dict) else row[0]

             # Top Country
             cursor.execute("SELECT country, COUNT(*) as c FROM ipaddress GROUP BY country ORDER BY c DESC LIMIT 1")
             row = cursor.fetchone()
             if row:
                 stats["top_country"] = row['country'] if isinstance(row, dict) else row[0]
        except Exception as e:
            logger.warning(f"Stats calculation partial failure: {e}")

        # Direct write for stats
        with open(STATS_FILE, "w") as f:
            json.dump(stats, f)
            f.flush()
            os.fsync(f.fileno())

    except Exception as e:
        logger.error(f"Error updating threat feed: {e}")
    finally:
        if conn: conn.close()

def get_new_attackers():
    conn = get_db_connection()
    if not conn: return []
    ips = []
    try:
        cursor = conn.cursor()
        query = "SELECT DISTINCT source_ip FROM infos ORDER BY create_time DESC LIMIT 100"
        cursor.execute(query)
        rows = cursor.fetchall()
        for row in rows:
            ips.append(row['source_ip'] if isinstance(row, dict) else row[0])
        conn.close()
    except Exception as e:
        logger.error(f"Error fetching attackers: {e}")
        if conn: conn.close()
    
    # Filter out IPs already in banned list
    current_banned = set()
    if os.path.exists(BANNED_IPS_FILE):
        try:
            with open(BANNED_IPS_FILE, "r") as f:
                current_banned = set(line.strip() for line in f if line.strip())
        except Exception as e:
            logger.error(f"Error reading banned IPs: {e}")
    
    new_ips = [ip for ip in ips if ip not in current_banned and len(ip) >= 7]
    if new_ips:
        logger.info(f"Found {len(new_ips)} new attacker IPs to process")
    return new_ips

def scan_ip(ip):
    report_path = os.path.join(SCANS_DIR, f"{ip}.txt")
    if os.path.exists(report_path): return None
    logger.info(f"Scanning {ip}...")
    try:
        command = ["nmap", "-A", "-T4", "-Pn", ip] 
        result = subprocess.run(command, capture_output=True, text=True, timeout=300)
        with open(report_path, "w") as f:
            f.write(f"Scan Time: {time.ctime()}\n")
            f.write(f"Target: {ip}\n")
            f.write("-" * 40 + "\n")
            f.write(result.stdout)
        return ip
    except Exception as e:
        logger.error(f"Error scanning {ip}: {e}")
        return None

def update_banned_list(ips):
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


    
    # update_index() call removed (Generated by PHP now)



def fix_missing_severity():
    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
        if DB_TYPE == "mysql":
            query = "UPDATE ipaddress SET severity = 'Low' WHERE severity IS NULL OR severity = ''"
            cursor.execute(query)
            if cursor.rowcount > 0: logger.info(f"Fixed missing severity for {cursor.rowcount} IPs.")
            conn.commit()
    except Exception as e:
        logger.error(f"Error fixing severity: {e}")
    finally:
        if conn: conn.close()

def translate_to_english():
    """Translate Chinese location names to English"""
    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
        if DB_TYPE == "mysql":
            # Comprehensive Chinese to English translation dictionary
            translations = {
                "美国": "United States",
                "中国": "China",
                "俄罗斯": "Russia",
                "德国": "Germany",
                "英国": "United Kingdom",
                "法国": "France",
                "日本": "Japan",
                "韩国": "South Korea",
                "印度": "India",
                "巴西": "Brazil",
                "加拿大": "Canada",
                "澳大利亚": "Australia",
                "意大利": "Italy",
                "西班牙": "Spain",
                "荷兰": "Netherlands",
                "瑞士": "Switzerland",
                "瑞典": "Sweden",
                "挪威": "Norway",
                "丹麦": "Denmark",
                "芬兰": "Finland",
                "波兰": "Poland",
                "土耳其": "Turkey",
                "以色列": "Israel",
                "沙特阿拉伯": "Saudi Arabia",
                "阿联酋": "United Arab Emirates",
                "新加坡": "Singapore",
                "马来西亚": "Malaysia",
                "泰国": "Thailand",
                "越南": "Vietnam",
                "印度尼西亚": "Indonesia",
                "菲律宾": "Philippines",
                "巴基斯坦": "Pakistan",
                "孟加拉国": "Bangladesh",
                "墨西哥": "Mexico",
                "阿根廷": "Argentina",
                "智利": "Chile",
                "哥伦比亚": "Colombia",
                "南非": "South Africa",
                "埃及": "Egypt",
                "尼日利亚": "Nigeria",
                "肯尼亚": "Kenya",
                "乌克兰": "Ukraine",
                "罗马尼亚": "Romania",
                "捷克": "Czech Republic",
                "匈牙利": "Hungary",
                "奥地利": "Austria",
                "比利时": "Belgium",
                "葡萄牙": "Portugal",
                "希腊": "Greece",
                "爱尔兰": "Ireland",
                "新西兰": "New Zealand",
                "香港": "Hong Kong",
                "台湾": "Taiwan",
                "未知": "Unknown"
            }
            for cn, en in translations.items():
                cursor.execute("UPDATE ipaddress SET country = %s WHERE country = %s", (en, cn))
                cursor.execute("UPDATE ipaddress SET region = %s WHERE region = %s", (en, cn))
                cursor.execute("UPDATE infos SET source_ip_country = %s WHERE source_ip_country = %s", (en, cn))
            conn.commit()
            logger.info("Translated Chinese location names to English")
    except Exception as e:
        logger.warning(f"Translation error: {e}")
    finally:
        if conn: conn.close()

def init_env():
    if not os.path.exists(SCANS_DIR): os.makedirs(SCANS_DIR)
    if not os.path.exists(FEED_DIR): os.makedirs(FEED_DIR)
    if not os.path.exists(ASSETS_DIR): os.makedirs(ASSETS_DIR)
    # update_index() removed

def main():
    init_env()
    logger.info(f"Monitor started (DB_TYPE={DB_TYPE}).")
    logger.info(f"DEBUG: DB_USER={DB_USER}, DB_HOST={DB_HOST}, DB_NAME={DB_NAME}")
    logger.info("Waiting 30s for DB to be ready...")
    time.sleep(30) 
    ensure_db_schema()
    update_node_location()
    executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)
    try:
        while True:
            try:
                attackers = get_new_attackers()
                if attackers:
                    logger.info(f"Processing {len(attackers)} new attacker IPs...")
                    for ip in attackers:
                        executor.submit(scan_ip, ip)
                    update_banned_list(attackers)
                fix_missing_severity()
                translate_to_english()  # Translate Chinese to English
                # update_index() removed
                update_threat_feed()
                if int(time.time()) % 600 < 15: update_node_location()
            except Exception as e:
                logger.error(f"Loop error: {e}")
            time.sleep(10)
    finally:
        executor.shutdown(wait=False)

if __name__ == "__main__":
    main()
