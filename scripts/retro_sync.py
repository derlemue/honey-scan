import os
import time
import pymysql
import requests
import logging

# Configuration
DB_HOST = os.getenv("DB_HOST", "mariadb")
DB_PORT = int(os.getenv("DB_PORT") or 3306)
DB_USER = os.getenv("DB_USER", "hscan")
DB_PASSWORD = os.getenv("DB_PASSWORD", "734f181149acdabc269dacba6faf3be7")
DB_NAME = os.getenv("DB_NAME", "hscan")
WEBHOOK_URL = os.getenv("THREAT_BRIDGE_WEBHOOK_URL", "https://api.sec.lemue.org/webhook")
DELAY_MS = 500

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("RetroSync")

def get_db_connection():
    try:
        return pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            cursorclass=pymysql.cursors.DictCursor
        )
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return None

def is_loopback(ip):
    return ip in ("127.0.0.1", "::1", "localhost")

def main():
    logger.info("Starting retroactive intelligence sync...")
    conn = get_db_connection()
    if not conn:
        return

    try:
        with conn.cursor() as cursor:
            # Fetch all unique IPs from ipaddress table
            cursor.execute("SELECT DISTINCT ip FROM ipaddress")
            rows = cursor.fetchall()
            ips = [row['ip'] for row in rows if row['ip'] and not is_loopback(row['ip'])]
            
            logger.info(f"Found {len(ips)} unique IPs to sync.")

            for i, ip in enumerate(ips):
                try:
                    logger.info(f"[{i+1}/{len(ips)}] Syncing IP: {ip}")
                    resp = requests.post(WEBHOOK_URL, json={"attack_ip": ip}, timeout=10)
                    if resp.status_code == 200:
                        logger.info(f"Successfully synced {ip}")
                    else:
                        logger.warning(f"Failed to sync {ip}: {resp.status_code}")
                except Exception as e:
                    logger.error(f"Error syncing {ip}: {e}")
                
                # Delay for 500ms
                time.sleep(DELAY_MS / 1000.0)

        logger.info("Retroactive sync completed.")
    except Exception as e:
        logger.error(f"Sync failed: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
