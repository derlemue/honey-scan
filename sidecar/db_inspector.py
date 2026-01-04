
import os
import pymysql
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "mariadb")
DB_PORT = int(os.getenv("DB_PORT") or 3306)
DB_USER = os.getenv("DB_USER", "hfish")
DB_PASSWORD = os.getenv("DB_PASSWORD", "HoneyScan_DB_Pass_2025!")
DB_NAME = os.getenv("DB_NAME", "hfish")

def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )

def search_db(term):
    conn = get_connection()
    cursor = conn.cursor()
    
    cursor.execute("SHOW TABLES")
    tables = [list(x.values())[0] for x in cursor.fetchall()]
    
    print(f"Searching for '{term}' in {len(tables)} tables...")
    
    found = False
    for table in tables:
        try:
            # Get columns (text/varchar only to save time)
            cursor.execute(f"DESCRIBE `{table}`")
            columns = [r['Field'] for r in cursor.fetchall() if 'char' in r['Type'] or 'text' in r['Type']]
            
            if not columns: continue
            
            for col in columns:
                query = f"SELECT `{col}` FROM `{table}` WHERE `{col}` LIKE %s LIMIT 1"
                cursor.execute(query, (f"%{term}%",))
                res = cursor.fetchone()
                if res:
                    print(f"[FOUND] Table: {table}, Column: {col}, Value: {res[col]}")
                    found = True
        except Exception as e:
            print(f"Error checking {table}: {e}")
            
    conn.close()
    if not found:
        print("Not found.")

if __name__ == "__main__":
    search_db("第")
    print("-" * 20)
    search_db("美国")
    print("-" * 20)
    search_db("被攻击") # "Be attacked" usually maps to this
