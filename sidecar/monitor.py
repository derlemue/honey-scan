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
DB_USER = os.getenv("DB_USER", "hfish") # User Request (Made configurable)
DB_PASSWORD = os.getenv("DB_PASSWORD", "password") # Default password for hfish
DB_NAME = os.getenv("DB_NAME", "hfish")

# Threat Intelligence Bridge Config
THREAT_BRIDGE_WEBHOOK_URL = os.getenv("THREAT_BRIDGE_WEBHOOK_URL")

# Legacy/SQLite Path
DB_PATH = "/hfish_ro/database/hfish.db"

SCANS_DIR = "/app/scans"
FEED_DIR = "/app/feed"
ASSETS_DIR = "/app/assets"
BANNED_IPS_FILE = os.path.join(FEED_DIR, "banned_ips.txt")
INDEX_FILE = os.path.join(FEED_DIR, "index.html")
LIVE_THREATS_FILE = os.path.join(ASSETS_DIR, "live_threats.json")
STATS_FILE = os.path.join(ASSETS_DIR, "stats.json")
REPORT_DIR = SCANS_DIR
scanning_ips = set() # Track IPs currently in queue or being scanned


MAX_WORKERS = 16  # Optimized concurrency (User Request: 16)

# Setup Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("HoneySidecar")

def is_loopback(ip):
    """Check if the IP is a loopback address."""
    return ip in ("127.0.0.1", "::1", "localhost")

def signal_handler(sig, frame):
    logger.info("Exiting...")
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

# Passwords
DEFAULT_PASS_HASH_OLD = "$2a$04$9PBC6S/jB8w4jUZcMkbSs.8TkraTZxUU8ZCk2HIXW1l2Q1dEH84gu" # HFish2021
DEFAULT_PASS_HASH_NEW = "$2y$04$qxgj8E6W/BhtiMmf4GO1t.2FsMD/96WYblQmGxaIko6P.0a9hIZsm" # HoneyScan2024!

def get_db_connection():
    try:
        if DB_TYPE.lower() in ("mysql", "mariadb"):
            # logger.info(f"Connecting with user={DB_USER}") # Reduce log noise
            return pymysql.connect(
                host=DB_HOST,
                port=DB_PORT,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_NAME,
                cursorclass=pymysql.cursors.DictCursor,
                connect_timeout=10,
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
    conn = None
    try:
        conn = get_db_connection()
        if not conn: 
            logger.warning("Skipping schema migration - no DB connection")
            return
        cursor = conn.cursor()
        cursor.execute("DESCRIBE nodes")
        columns = [row['Field'] for row in cursor.fetchall()]
        alter_cmds = []
        if 'lat' not in columns: alter_cmds.append("ADD COLUMN lat FLOAT DEFAULT 0.0")
        if 'lng' not in columns: alter_cmds.append("ADD COLUMN lng FLOAT DEFAULT 0.0")
        if 'city' not in columns: alter_cmds.append("ADD COLUMN city VARCHAR(64) DEFAULT ''")
        if 'country' not in columns: alter_cmds.append("ADD COLUMN country VARCHAR(64) DEFAULT ''")
        for cmd in alter_cmds:
            logger.info(f"Migrating DB (nodes): {cmd}")
            cursor.execute(f"ALTER TABLE nodes {cmd}")
        
        # Check ipaddress table for pushed_to_bridge column
        cursor.execute("DESCRIBE ipaddress")
        ip_columns = [row['Field'] for row in cursor.fetchall()]
        if 'pushed_to_bridge' not in ip_columns:
            logger.info("Migrating DB (ipaddress): ADD COLUMN pushed_to_bridge")
            cursor.execute("ALTER TABLE ipaddress ADD COLUMN pushed_to_bridge TINYINT DEFAULT 0")
            cursor.execute("CREATE INDEX idx_pushed_to_bridge ON ipaddress(pushed_to_bridge)")

        # Fix "Data too long" for region
        try:
             cursor.execute("ALTER TABLE ipaddress MODIFY region VARCHAR(128) DEFAULT ''")
        except Exception as e:
             pass
            
        logger.info("Schema migration completed successfully")
    except Exception as e:
        logger.warning(f"Schema migration skipped due to error: {e}")
        # Non-fatal - allow monitor to continue
    finally:
        if conn: 
            try: 
                conn.close()
            except: 
                pass

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
                'country': f"{geo.get('city')}, {geo.get('country')}"
            }
        else:
            logger.warning(f"Geo API failed for {ip}: {geo.get('message')}")
    except Exception as e:
        logger.error(f"Geolocation fetch failed: {e}")
    return None

def update_node_location():
    # check_cloud_connectivity() removed 
    data = get_geolocation()
    if not data:
        logger.warning("Could not determine dynamic location.")
        return
    logger.info(f"Detected Public IP: {data['ip']}, Location: {data['country']} ({data['lat']}, {data['lng']})")
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
            cursor.execute(query, (data['country'], data['lat'], data['lng'], data['city'], data['country']))
            if cursor.rowcount > 0: logger.info(f"Updated {cursor.rowcount} node(s) location.")
        conn.close()
    except Exception as e:
        logger.error(f"Database update failed: {e}")
        if conn: conn.close()

def push_intelligence(ip, is_new_hint=None):
    if not THREAT_BRIDGE_WEBHOOK_URL:
        return False

    urls = [u.strip() for u in THREAT_BRIDGE_WEBHOOK_URL.split(',') if u.strip()]
    if not urls:
        return False
        
    success_count = 0
    for url in urls:
        try:
            # Prepare payload
            payload = {"attack_ip": ip}
            
            # Simple logging for first url only if hint provided? No, log per URL.
            # But avoid spam.
            
            resp = requests.post(url, json=payload, timeout=5)
            if resp.status_code == 200:
                logger.info(f"✅ Synced {ip} to {url}")
                success_count += 1
            else:
                logger.error(f"❌ Failed to sync {ip} to {url}: HTTP {resp.status_code}")
        except Exception as e:
            logger.error(f"❌ Error syncing {ip} to {url}: {e}")
            
    return success_count > 0

def sync_to_bridge():
    """Sync unsynced IPs to the bridge with a 50ms delay."""
    if not THREAT_BRIDGE_WEBHOOK_URL:
        return
    
    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
        # Fetch a batch of unsynced IPs
        cursor.execute("SELECT ip FROM ipaddress WHERE pushed_to_bridge = 0 AND ip NOT IN ('::1', '127.0.0.1', 'localhost') LIMIT 100")
        rows = cursor.fetchall()
        if not rows:
            return

        logger.info(f"Syncing {len(rows)} IPs to bridge...")
        for row in rows:
            ip = row['ip']
            # During full sync, they are technically 'new' for the bridge status check
            if push_intelligence(ip, is_new_hint=True):
                # Update status in DB
                cursor.execute("UPDATE ipaddress SET pushed_to_bridge = 1 WHERE ip = %s", (ip,))
            
            # Respect the 50ms delay requested by the user
            time.sleep(0.05)
            
        conn.commit()
    except Exception as e:
        logger.error(f"Sync to bridge failed: {e}")
    finally:
        if conn: conn.close()

# query_threatbook_ip removed

def update_threat_feed():
    logger.info("Updating Threat Feed...")
    conn = get_db_connection()
    if not conn: return
    recent_hackers = []
    suspicious_cs = []
    try:
        cursor = conn.cursor()
        # Pre-fetch known Fail2Ban IPs from the last 14 days to prioritize their metadata
        # preventing "Bridge Sync" from overriding the "Fail2Ban" status.
        f2b_ips = set()
        try:
            f2b_query = "SELECT DISTINCT source_ip FROM infos WHERE service = 'FAIL2BAN' AND create_time >= DATE_SUB(NOW(), INTERVAL 14 DAY)"
            cursor.execute(f2b_query)
            f2b_rows = cursor.fetchall()
            for r in f2b_rows:
                f2b_ip = r['source_ip'] if isinstance(r, dict) else r[0]
                f2b_ips.add(f2b_ip)
            logger.info(f"Loaded {len(f2b_ips)} Fail2Ban IPs for metadata prioritization.")
        except Exception as e:
            logger.warning(f"Failed to pre-fetch Fail2Ban IPs: {e}")

        # Flood Protection: Use 3-Way UNION to guarantee representation of all event types:
        # 1. Fail2Ban (Local) - Capped at 50
        # 2. Bridge Sync (Cloud) - Capped at 50 
        # 3. Native (VNC etc) - Capped at 80 (Guaranteed visibility)
        query = """
            SELECT *,
                CASE 
                    WHEN service IN ('FAIL2BAN', 'API_MANUAL', 'BRIDGE_SYNC') THEN create_time 
                    ELSE DATE_ADD(create_time, INTERVAL 1 HOUR) 
                END as normalized_time
            FROM (
                (SELECT source_ip, source_ip_country, service, create_time 
                 FROM infos 
                 WHERE service IN ('FAIL2BAN', 'API_MANUAL') 
                 ORDER BY create_time DESC LIMIT 50)
                UNION ALL
                (SELECT source_ip, source_ip_country, service, create_time 
                 FROM infos 
                 WHERE service = 'BRIDGE_SYNC' 
                 ORDER BY create_time DESC LIMIT 50)
                UNION ALL
                (SELECT source_ip, source_ip_country, service, create_time 
                 FROM infos 
                 WHERE service NOT IN ('FAIL2BAN', 'API_MANUAL', 'BRIDGE_SYNC') 
                 ORDER BY create_time DESC LIMIT 80)
            ) as combined_feeds
            ORDER BY normalized_time DESC
            LIMIT 180
        """
        logger.info(f"Executing Query: {query}")
        cursor.execute(query)
        rows = cursor.fetchall()
        logger.info(f"Fetched {len(rows)} rows from DB")
        for row in rows:
            ip = row['source_ip'] if isinstance(row, dict) else row[0]
            country = row.get('source_ip_country', 'Unknown') if isinstance(row, dict) else "Unknown"
            service_actual = row.get('service', '') if isinstance(row, dict) else ""
            service = service_actual
            
            # Metadata Override: If IP is a known Fail2Ban jail, force context
            if ip in f2b_ips:
                service = 'FAIL2BAN'
            
            # Formatting for Fail2Ban entries
            threat_type = "Port Scanner"
            threat_risk = "Medium"
            location_disp = get_english_name(country)
            
            if service == 'FAIL2BAN':
                threat_type = "Fail2Ban"
                threat_risk = "Low"
                location_disp = "FAIL2BAN"
            elif service == 'BRIDGE_SYNC':
                threat_type = "Global Threat"
                threat_risk = "High"
                location_disp = "Honey Cloud"

            # Time Adjustment: normalized_time is Unified Local (T).
            # Frontend (UTC+1) expects UTC (T-1).
            # So we shift -1h.
            raw_time = row.get('normalized_time')
            if isinstance(raw_time, datetime):
                adjusted_time = raw_time - timedelta(hours=1)
            else:
                adjusted_time = raw_time

            if len(recent_hackers) < 135:
                recent_hackers.append({
                    "ip": ip,
                    "location": location_disp,
                    "time": str(adjusted_time if adjusted_time else 'Just now'),
                    "flag": get_english_name(country) if service != 'FAIL2BAN' else "Unknown",
                    "count": 1
                })
            if len(suspicious_cs) < 130:
                suspicious_cs.append({
                        "ip": ip,
                        "location": location_disp,
                        "type": threat_type,
                        "risk": threat_risk,
                        "time": str(adjusted_time if adjusted_time else 'Just now'),
                        "flag": get_english_name(country) if service != 'FAIL2BAN' else "Unknown",
                        "count": 1
                    })

        # Enforce reasonable limit for performance (20 items)
        recent_hackers = recent_hackers[:20]
        suspicious_cs = suspicious_cs[:20]

        output = {"hackers": recent_hackers, "cs": suspicious_cs, "api_active": False}
        
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
        # Filter for recent (last 14 days/336h) IPs to align with banned list policy and avoid reprocessing old IPs
        if DB_TYPE.lower() in ("mysql", "mariadb"):
            query = "SELECT DISTINCT ip FROM ipaddress WHERE create_time >= DATE_SUB(NOW(), INTERVAL 336 HOUR) ORDER BY create_time DESC LIMIT 7500"
        else:
            query = "SELECT DISTINCT ip FROM ipaddress WHERE create_time >= datetime('now', '-336 hours') ORDER BY create_time DESC LIMIT 7500"
        
        cursor.execute(query)
        rows = cursor.fetchall()
        for row in rows:
            ips.append(row['ip'] if isinstance(row, dict) else row[0])
        conn.close()
    except Exception as e:
        logger.error(f"Error fetching attackers: {e}")
        if conn: conn.close()
    
    # Check if force rescan is enabled
    force_rescan = os.getenv('FORCE_RESCAN', 'false').lower() == 'true'
    
    if force_rescan:
        # Skip ban check - scan everything without reports
        new_ips = []
        for ip in ips:
            if len(ip) < 7 or ip in scanning_ips or is_loopback(ip):
                continue
            report_path = os.path.join(REPORT_DIR, f"{ip}.txt")
            if not os.path.exists(report_path):
                new_ips.append(ip)
        if new_ips:
            logger.info(f"FORCE RESCAN: Found {len(new_ips)} IPs without reports (out of {len(ips)} total)")
        return new_ips
    
    # Normal mode: Filter out IPs already in banned list or currently scanning
    current_banned = set()
    if os.path.exists(BANNED_IPS_FILE):
        try:
            with open(BANNED_IPS_FILE, "r") as f:
                current_banned = set(line.strip() for line in f if line.strip())
        except Exception as e:
            logger.error(f"Error reading banned IPs: {e}")
    
    new_ips = [ip for ip in ips if ip not in current_banned and ip not in scanning_ips and len(ip) >= 7 and not is_loopback(ip)]
    if new_ips:
        logger.info(f"Found {len(new_ips)} new attacker IPs to process")
    return new_ips

def scan_ip(ip):
    report_path = os.path.join(REPORT_DIR, f"{ip}.txt")
    if os.path.exists(report_path): return None
    logger.info(f"Scanning {ip}...")
    try:
        command = ["nmap", "-A", "-T4", "-Pn", ip]  # Comprehensive scan: includes OS detection, version, scripts, and traceroute
        result = subprocess.run(command, capture_output=True, text=True, timeout=120)
        with open(report_path, "w") as f:
            f.write(f"Scan Time: {time.ctime()}\n")
            f.write(f"Target: {ip}\n")
            f.write("-" * 40 + "\n")
            f.write(result.stdout)
        return ip
    except Exception as e:
        logger.error(f"Error scanning {ip}: {e}")
        return None
    finally:
        if ip in scanning_ips:
            scanning_ips.remove(ip)

def update_banned_list():
    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
        # Regenerate banned list from DB (infos table) for the last 14 days (336 hours)
        # This ensures the list serves as a 14-day rolling window blocklist
        if DB_TYPE.lower() in ("mysql", "mariadb"):
            query = "SELECT DISTINCT source_ip FROM infos WHERE create_time >= DATE_SUB(NOW(), INTERVAL 336 HOUR)"
        else:
            query = "SELECT DISTINCT source_ip FROM infos WHERE create_time >= datetime('now', '-336 hours')"
            
        cursor.execute(query)
        rows = cursor.fetchall()
        
        banned_ips = set()
        for row in rows:
            ip = row['source_ip'] if isinstance(row, dict) else row[0]
            if not is_loopback(ip):
                banned_ips.add(ip)

        with open(BANNED_IPS_FILE, "w") as f:
            for ip in sorted(banned_ips):
                f.write(f"{ip}\n")
        logger.info(f"Updated banned list from DB (last 14 days). Total active: {len(banned_ips)}")
        
    except Exception as e:
        logger.error(f"Error updating banned list: {e}")
    finally:
        if conn: conn.close()


    
    # update_index() call removed (Generated by PHP now)



def fix_missing_severity():
    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
        if DB_TYPE == "mysql":
            # Fix empty severity and set threat_level=2 (Suspicious) for Low risk entries
            # This ensures HFish UI displays a badge instead of [Unk]
            # Catch level 0 and 1
            query = "UPDATE ipaddress SET severity = 'Low', threat_level = 2 WHERE severity IS NULL OR severity = '' OR threat_level <= 1"
            cursor.execute(query)
            if cursor.rowcount > 0: logger.info(f"Fixed missing severity/level for {cursor.rowcount} IPs.")
            conn.commit()
    except Exception as e:
        logger.error(f"Error fixing severity: {e}")
    finally:
        if conn: conn.close()



def fix_default_password():
    """Checks for default insecure password and updates it to new secure default."""
    if DB_TYPE.lower() not in ("mysql", "mariadb"):
        return

    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
        # Check known weak hash
        query = "SELECT id, password FROM users WHERE username = 'admin'"
        cursor.execute(query)
        row = cursor.fetchone()
        
        if row:
            current_hash = row['password'] if isinstance(row, dict) else row[1].decode() if isinstance(row[1], bytes) else row[1]
            # Verify if it matches the known insecure hash
            if current_hash == DEFAULT_PASS_HASH_OLD:
                logger.warning("Detected insecure default password (HFish2021). Updating to HoneyScan2024!...")
                update_query = "UPDATE users SET password = %s WHERE username = 'admin'"
                cursor.execute(update_query, (DEFAULT_PASS_HASH_NEW,))
                conn.commit()
                logger.info("Admin password updated successfully.")
            elif current_hash == DEFAULT_PASS_HASH_NEW:
                # logger.info("Admin password is secure (HoneyScan2024!).")
                pass
            else:
                pass # User has set a custom password, do nothing
                
    except Exception as e:
        logger.error(f"Error checking default password: {e}")
    finally:
        if conn: conn.close()

# Translation Dictionary (Chinese -> English)
TRANSLATIONS = {
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
    "刚果共和国": "Republic of the Congo",
    "刚果民主共和国": "DR Congo",
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
    "危地马拉": "Guatemala",
    "欧洲地区": "Europe Region",
    "亚太地区": "Asia-Pacific Region",
    "非洲地区": "Africa Region",
    "北美地区": "North America Region",
    "拉美地区": "Latin America Region",
    "保加利亚": "Bulgaria",
    "摩洛哥": "Morocco",
    "爱沙尼亚": "Estonia",
    "伊朗": "Iran",
    "伊拉克": "Iraq",
    "立陶宛": "Lithuania",
    "哈萨克斯坦": "Kazakhstan",
    "阿塞拜疆": "Azerbaijan",
    "突尼斯": "Tunisia",
    "乌兹别克斯坦": "Uzbekistan",
    "孟加拉": "Bangladesh",
    "波斯尼亚和黑塞哥维那": "Bosnia and Herzegovina",
    "委内瑞拉": "Venezuela",
    "塞内加尔": "Senegal",
    "埃塞俄比亚": "Ethiopia",
    "白俄罗斯": "Belarus",
    "安哥拉": "Angola",
    "摩尔多瓦": "Moldova",
    "老挝": "Laos",
    "格鲁吉亚": "Georgia",
    "玻利维亚": "Bolivia",
    "洪都拉斯": "Honduras",
    "斯洛伐克": "Slovakia",
    "斯里兰卡": "Sri Lanka",
    "尼泊尔": "Nepal",
    "索马里": "Somalia",
    "巴拉圭": "Paraguay",
    "卡塔尔": "Qatar",
    "塞尔维亚": "Serbia",
    "阿曼": "Oman",
    "阿尔及利亚": "Algeria",
    "约旦": "Jordan",
    "吉尔吉斯斯坦": "Kyrgyzstan",
    "秘鲁": "Peru",
    "加蓬": "Gabon",
    "厄瓜多尔": "Ecuador",
    "喀麦隆": "Cameroon",
    "局域网": "LAN",
    "科威特": "Kuwait",
    "利比亚": "Libya",
    "北马其顿": "North Macedonia",
    "拉脱维亚": "Latvia",
    "圭亚那": "Guyana",
    "斯洛文尼亚": "Slovenia",
    "多哥": "Togo",
    "科特迪瓦": "Ivory Coast",
    "卢森堡": "Luxembourg",
    "科索沃": "Kosovo",
    "乌拉圭": "Uruguay",
    "缅甸": "Myanmar",
    "津巴布韦": "Zimbabwe",
    "特立尼达和多巴哥": "Trinidad and Tobago",
    "柬埔寨": "Cambodia",
    "蒙古": "Mongolia",
    "加纳": "Ghana",
    "牙买加": "Jamaica",
    "亚美尼亚": "Armenia",
    "黎巴嫩": "Lebanon",
    "阿尔巴尼亚": "Albania",
    "克罗地亚": "Croatia",
    "坦桑尼亚": "Tanzania",
    "莫桑比克": "Mozambique",
    "哥斯达黎加": "Costa Rica",
    "巴拿马": "Panama",
    "赞比亚": "Zambia",
    "苏里南": "Suriname",
    "乌干达": "Uganda",
    "巴林": "Bahrain",
    "叙利亚": "Syria",
    "吉布提": "Djibouti",
    "冰岛": "Iceland",
    "也门": "Yemen",
    "多米尼加": "Dominican Republic",
    "塞浦路斯": "Cyprus",
    "莱索托": "Lesotho",
    "博茨瓦纳": "Botswana",
    "根西岛": "Guernsey",
    "本机地址": "Localhost",
    "未知": "Unknown",
    "HFish Honeypot": "Honey Cloud",
    "hfish honeypot": "Honey Cloud"
}

def get_english_name(chinese_name):
    if not chinese_name:
        return "Unknown"
    
    # Clean string and ensure it is unicode
    name = str(chinese_name).strip()
    
    # Specific common patterns using unicode escapes for stability
    # \u53f0\u6e7e = 台湾, \u9999\u6e2f = 香港, \u6fb3\u95e8 = 澳门
    if "\u53f0\u6e7e" in name or "Taiwan" in name:
        return "Taiwan"
    if "\u9999\u6e2f" in name or "Hong Kong" in name:
        return "Hong Kong"
    if "\u6fb3\u95e8" in name or "Macau" in name:
        return "Macau"
        
    # If it contains China (\u4e2d\u56fd) in any form
    if "\u4e2d\u56fd" in name or "china" in name.lower():
        # Try to find a more specific translation for the sub-part if it's a hyphenated string
        if "-" in name:
            parts = name.split("-")
            for part in reversed(parts):
                p = part.strip()
                if p in TRANSLATIONS and p != "\u4e2d\u56fd":
                     return TRANSLATIONS[p]
        return "China"
    
    # Try direct mapping
    if name in TRANSLATIONS:
        return TRANSLATIONS[name]
        
    # Final check for sub-parts of any hyphenated string
    if "-" in name:
        parts = name.split("-")
        for part in reversed(parts):
            p = part.strip()
            if p in TRANSLATIONS:
                return TRANSLATIONS[p]
                
    # Return as-is if no match
    return name

def restore_db_language():
    """Revert English location names to Chinese in DB to fix HFish dashboard"""
    # OPTIMIZATION: Check if there are ANY English names before hammering the DB
    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
        
        # Check for presence of key English country names (Sample check)
        check_query = "SELECT COUNT(*) FROM ipaddress WHERE country IN ('United States', 'China', 'Germany', 'Russia', 'France')"
        cursor.execute(check_query)
        count = cursor.fetchone()[0]
        
        if count == 0:
            # DB seems clean, skip massive update
            return

        logger.info(f"Found {count} English entries. Restoring specific entries to Chinese...")

        if DB_TYPE == "mysql":
            # Create a reverse mapping
            reverse_translations = {v: k for k, v in TRANSLATIONS.items()}
            
            # Find all English names currently in the database to only update what's necessary
            # This avoids looping through 150+ countries every 10 seconds.
            cursor.execute("SELECT DISTINCT country FROM ipaddress WHERE country REGEXP '^[a-zA-Z ]+$'")
            found_countries = [row['country'] for row in cursor.fetchall()]
            
            if not found_countries:
                return

            logger.info(f"Detected English country names: {found_countries}. Restoring to Chinese...")
            
            for en in found_countries:
                if en in reverse_translations:
                    cn = reverse_translations[en]
                    cursor.execute("UPDATE ipaddress SET country = %s WHERE country = %s", (cn, en))
                    
            conn.commit()
            logger.info("Restored DB location names to Chinese")
    except Exception as e:
        logger.warning(f"Restoration error: {e}")
    finally:
        if conn: conn.close()

def fix_unknown_countries():
    """Resolves 'Unknown' countries for IPs in the DB using background GeoIP lookup."""
    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
        # Fetch a few IPs with Unknown country
        cursor.execute("SELECT DISTINCT ip FROM ipaddress WHERE country = 'Unknown' AND ip NOT IN ('::1', '127.0.0.1', 'localhost') LIMIT 2")
        rows = cursor.fetchall()
        
        if not rows: return

        for row in rows:
            ip = row['ip'] if isinstance(row, dict) else row[0]
            logger.info(f"Resolving location for {ip}...")
            
            try:
                geo = requests.get(f"http://ip-api.com/json/{ip}", timeout=5).json()
                if geo.get('status') == 'success':
                    country = geo.get('country', 'Unknown')
                    city = geo.get('city', 'Unknown')
                    region = geo.get('regionName', '')

                    # Truncate to avoid "Data too long" errors
                    country = country[:64]
                    city = city[:64]
                    region = region[:128]
                    
                    # Update ipaddress table
                    cursor.execute("UPDATE ipaddress SET country = %s, city = %s, region = %s WHERE ip = %s", 
                                   (country, city, region, ip))
                                   
                    # Update infos table for historical accuracy in feed
                    cursor.execute("UPDATE infos SET source_ip_country = %s WHERE source_ip = %s AND source_ip_country = 'Unknown'", 
                                   (country, ip))
                    
                    logger.info(f"Resolved {ip} -> {country}")
                else:
                    pass
            except Exception as e:
                logger.warning(f"Geo lookup failed for {ip}: {e}")
            
            # Respect rate limit (45/min -> ~1.3s per req). 
            time.sleep(1.5)
            
        conn.commit()
    except Exception as e:
        logger.error(f"Error fixing unknown countries: {e}")
    finally:
        if conn: conn.close()

def init_env():
    if not os.path.exists(SCANS_DIR): os.makedirs(SCANS_DIR)
    if not os.path.exists(FEED_DIR): os.makedirs(FEED_DIR)
    if not os.path.exists(ASSETS_DIR): os.makedirs(ASSETS_DIR)
    # update_index() removed

def reset_sync_status():
    """Reset pushed_to_bridge status for all IPs on startup."""
    conn = get_db_connection()
    if not conn: return
    try:
        cursor = conn.cursor()
        logger.info("Resetting sync status for all IPs...")
        cursor.execute("UPDATE ipaddress SET pushed_to_bridge = 0")
        logger.info(f"Reset sync status for {cursor.rowcount} rows.")
        conn.commit()
    except Exception as e:
        logger.error(f"Failed to reset sync status: {e}")
    finally:
        if conn: conn.close()


def main():
    init_env()
    logger.info(f"Monitor started (DB_TYPE={DB_TYPE}).")
    logger.info(f"DEBUG: DB_USER={DB_USER}, DB_HOST={DB_HOST}, DB_NAME={DB_NAME}")

    if THREAT_BRIDGE_WEBHOOK_URL:
        logger.info(f"Threat Intelligence Bridge ENABLED. Target: {THREAT_BRIDGE_WEBHOOK_URL}")
    else:
        logger.warning("Threat Intelligence Bridge DISABLED (URL not set).")

    logger.info("Waiting 30s for DB to be ready...")
    time.sleep(30) 
    ensure_db_schema()
    # update_node_location()
    logger.info("Schema migration completed - proceeding to main loop")
    
    # Reset sync status on startup (REMOVED: Causes flooding/stagnation)
    # reset_sync_status()
    
    # Fix insecure default password
    fix_default_password()
    
    executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)
    
    last_maintenance = 0
    
    try:
        while True:
            try:
                attackers = get_new_attackers()
                if attackers:
                    logger.info(f"Processing {len(attackers)} new attacker IPs...")
                    for ip in attackers:
                        scanning_ips.add(ip)
                        executor.submit(scan_ip, ip)
                        # Push to Threat Intelligence Bridge
                        # Check if it was already synced to decide on the hint
                        executor.submit(push_intelligence, ip, is_new_hint=True)
                
                # Optimization: Run heavy tasks roughly every 60s
                # Using timestamp check is more robust than modulo 0 against loop drift
                if time.time() - last_maintenance > 60:
                    update_banned_list()
                    fix_missing_severity()
                    last_maintenance = time.time()

                # Run background tasks
                fix_unknown_countries()
                restore_db_language()
                update_threat_feed()
                if int(time.time()) % 600 < 15: 
                    try:
                        update_node_location()
                    except Exception as e:
                        logger.warning(f"Node location update failed: {e}")
                
                # Run sync to bridge in the main loop
                sync_to_bridge()

            except Exception as e:
                logger.error(f"Loop error: {e}")
            time.sleep(10)
    finally:
        executor.shutdown(wait=False)

if __name__ == "__main__":
    main()
