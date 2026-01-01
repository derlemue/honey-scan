import pymysql
import os

DB_HOST = "127.0.0.1"
DB_PORT = 3307
DB_USER = "hfish"
DB_PASSWORD = "password"
DB_NAME = "hfish"

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
    
    print("--- NODES Table Schema ---")
    cursor.execute("DESCRIBE nodes")
    for row in cursor.fetchall():
        print(row)
        
    print("\n--- NODES Data ---")
    cursor.execute("SELECT * FROM nodes LIMIT 1")
    for row in cursor.fetchall():
        print(row)

    conn.close()
except Exception as e:
    print(f"Error: {e}")
