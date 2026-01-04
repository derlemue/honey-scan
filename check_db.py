
import os
import pymysql
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "mariadb")
DB_PORT = int(os.getenv("DB_PORT") or 3306)
DB_USER = os.getenv("DB_USER", "hfish")
DB_PASSWORD = os.getenv("DB_PASSWORD", "HoneyScan_DB_Pass_2025!")
DB_NAME = os.getenv("DB_NAME", "hfish")

def check_counts():
    try:
        conn = pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            cursorclass=pymysql.cursors.DictCursor
        )
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) as count FROM infos")
        infos_count = cursor.fetchone()['count']
        
        cursor.execute("SELECT COUNT(*) as count FROM ipaddress")
        ip_count = cursor.fetchone()['count']
        
        print(f"Attack Logs (infos): {infos_count}")
        print(f"IP Addresses (ipaddress): {ip_count}")
        
        if infos_count > 0:
            cursor.execute("SELECT * FROM infos ORDER BY id DESC LIMIT 5")
            print("Recent Entries:")
            for row in cursor.fetchall():
                print(row)
                
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_counts()
