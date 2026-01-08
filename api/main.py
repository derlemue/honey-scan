"""
HFish API Replacement Service
Provides REST API endpoints compatible with HFish API documentation
"""

from fastapi import FastAPI, Query, HTTPException, Depends, Body
from fastapi.responses import JSONResponse
from typing import Optional, List, Dict, Any
from pydantic import BaseModel
from datetime import datetime, timedelta
import mysql.connector
from mysql.connector import Error
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="HFish API",
    description="Python-based replacement for HFish API endpoints",
    version="1.0.0"
)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'hfish-db'),
    'port': int(os.getenv('DB_PORT', '3307')),
    'user': os.getenv('DB_USER', 'hfish'),
    'password': os.getenv('DB_PASSWORD', '734f181149acdabc269dacba6faf3be7'),
    'database': os.getenv('DB_NAME', 'hfish'),
    'charset': 'utf8mb4'
}

# API Key validation (simple for now)
VALID_API_KEY = os.getenv('API_KEY', 'nXYzlupNuFFiUZvGRrfaRTySjsIIfYChnpIDnDWIczkvIdMYXhdotcdtLLsBKuMU')


def get_db_connection():
    """Create database connection"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        logger.error(f"Database connection error: {e}")
        raise HTTPException(status_code=500, detail="Database connection failed")


def validate_api_key(api_key: str = Query(..., alias="api_key")):
    """Validate API key from query parameter"""
    if api_key != VALID_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return api_key


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "HFish API",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }


@app.post("/api/v1/attack/ip")
async def get_attack_ips(
    api_key: str = Depends(validate_api_key),
    start_time: Optional[str] = Query(None),
    end_time: Optional[str] = Query(None),
    limit: int = Query(100, le=1000)
):
    """
    Get attack source IPs for a period of time
    
    Returns list of source IPs with attack counts
    """
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        # Build time filter
        time_filter = ""
        params = []
        
        if start_time and end_time:
            time_filter = "WHERE create_time BETWEEN %s AND %s"
            params = [start_time, end_time]
        elif start_time:
            time_filter = "WHERE create_time >= %s"
            params = [start_time]
        elif end_time:
            time_filter = "WHERE create_time <= %s"
            params = [end_time]
        else:
            # Default to last 24 hours
            yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d %H:%M:%S')
            time_filter = "WHERE create_time >= %s"
            params = [yesterday]
        
        query = f"""
            SELECT 
                source_ip,
                source_ip_country as country,
                COUNT(*) as attack_count,
                MAX(create_time) as last_attack,
                GROUP_CONCAT(DISTINCT service) as services
            FROM infos
            {time_filter}
            GROUP BY source_ip, source_ip_country
            ORDER BY attack_count DESC
            LIMIT %s
        """
        params.append(limit)
        
        cursor.execute(query, params)
        results = cursor.fetchall()
        
        # Format response
        data = []
        for row in results:
            data.append({
                "ip": row['source_ip'],
                "country": row['country'] or "Unknown",
                "count": row['attack_count'],
                "last_seen": row['last_attack'].isoformat() if row['last_attack'] else None,
                "services": row['services'].split(',') if row['services'] else []
            })
        
        return {
            "status": 0,
            "msg": "success",
            "data": data,
            "total": len(data)
        }
        
    except Error as e:
        logger.error(f"Database query error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        connection.close()


@app.post("/api/v1/attack/detail")
async def get_attack_details(
    api_key: str = Depends(validate_api_key),
    source_ip: Optional[str] = Query(None),
    start_time: Optional[str] = Query(None),
    end_time: Optional[str] = Query(None),
    limit: int = Query(100, le=1000)
):
    """
    Get detailed attack information for a specific IP or time period
    """
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        # Build filters
        filters = []
        params = []
        
        if source_ip:
            filters.append("source_ip = %s")
            params.append(source_ip)
        
        if start_time and end_time:
            filters.append("create_time BETWEEN %s AND %s")
            params.extend([start_time, end_time])
        elif start_time:
            filters.append("create_time >= %s")
            params.append(start_time)
        elif end_time:
            filters.append("create_time <= %s")
            params.append(end_time)
        
        where_clause = "WHERE " + " AND ".join(filters) if filters else ""
        
        query = f"""
            SELECT 
                info_id,
                client_id,
                service,
                source_ip,
                source_ip_country,
                source_port,
                dest_ip,
                dest_port,
                credentials,
                commands,
                urls,
                info,
                create_time
            FROM infos
            {where_clause}
            ORDER BY create_time DESC
            LIMIT %s
        """
        params.append(limit)
        
        cursor.execute(query, params)
        results = cursor.fetchall()
        
        # Format response
        data = []
        for row in results:
            data.append({
                "id": row['info_id'],
                "client_id": row['client_id'],
                "service": row['service'],
                "source_ip": row['source_ip'],
                "country": row['source_ip_country'] or "Unknown",
                "source_port": row['source_port'],
                "dest_ip": row['dest_ip'],
                "dest_port": row['dest_port'],
                "credentials": row['credentials'],
                "commands": row['commands'],
                "urls": row['urls'],
                "info": row['info'],
                "time": row['create_time'].isoformat() if row['create_time'] else None
            })
        
        return {
            "status": 0,
            "msg": "success",
            "data": data,
            "total": len(data)
        }
        
    except Error as e:
        logger.error(f"Database query error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        connection.close()


@app.post("/api/v1/attack/account")
async def get_attack_accounts(
    api_key: str = Depends(validate_api_key),
    start_time: Optional[str] = Query(None),
    end_time: Optional[str] = Query(None),
    limit: int = Query(100, le=1000)
):
    """
    Get account/credential information from attacks
    """
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        # Build time filter
        time_filter = ""
        params = []
        
        if start_time and end_time:
            time_filter = "WHERE create_time BETWEEN %s AND %s AND credentials IS NOT NULL AND credentials != ''"
            params = [start_time, end_time]
        elif start_time:
            time_filter = "WHERE create_time >= %s AND credentials IS NOT NULL AND credentials != ''"
            params = [start_time]
        elif end_time:
            time_filter = "WHERE create_time <= %s AND credentials IS NOT NULL AND credentials != ''"
            params = [end_time]
        else:
            time_filter = "WHERE credentials IS NOT NULL AND credentials != ''"
        
        query = f"""
            SELECT 
                source_ip,
                source_ip_country,
                service,
                credentials,
                dest_ip,
                dest_port,
                create_time
            FROM infos
            {time_filter}
            ORDER BY create_time DESC
            LIMIT %s
        """
        params.append(limit)
        
        cursor.execute(query, params)
        results = cursor.fetchall()
        
        # Format response
        data = []
        for row in results:
            data.append({
                "ip": row['source_ip'],
                "country": row['source_ip_country'] or "Unknown",
                "service": row['service'],
                "credentials": row['credentials'],
                "target_ip": row['dest_ip'],
                "target_port": row['dest_port'],
                "time": row['create_time'].isoformat() if row['create_time'] else None
            })
        
        return {
            "status": 0,
            "msg": "success",
            "data": data,
            "total": len(data)
        }
        
    except Error as e:
        logger.error(f"Database query error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        connection.close()


@app.get("/api/v1/hfish/sys_info")
async def get_system_info(api_key: str = Depends(validate_api_key)):
    """
    Get system operating status information
    """
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        # Get various statistics
        stats = {}
        
        # Total attacks in last 24h
        cursor.execute("""
            SELECT COUNT(*) as count 
            FROM infos 
            WHERE create_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        """)
        stats['attacks_24h'] = cursor.fetchone()['count']
        
        # Total unique IPs in last 24h
        cursor.execute("""
            SELECT COUNT(DISTINCT source_ip) as count 
            FROM infos 
            WHERE create_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        """)
        stats['unique_ips_24h'] = cursor.fetchone()['count']
        
        # Total attacks all time
        cursor.execute("SELECT COUNT(*) as count FROM infos")
        stats['total_attacks'] = cursor.fetchone()['count']
        
        # Active services
        cursor.execute("""
            SELECT service, COUNT(*) as count 
            FROM infos 
            WHERE create_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
            GROUP BY service
        """)
        services = cursor.fetchall()
        
        return {
            "status": 0,
            "msg": "success",
            "data": {
                "attacks_last_24h": stats['attacks_24h'],
                "unique_ips_last_24h": stats['unique_ips_24h'],
                "total_attacks": stats['total_attacks'],
                "active_services": services,
                "uptime": "running",
                "timestamp": datetime.now().isoformat()
            }
        }
        
    except Error as e:
        logger.error(f"Database query error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        connection.close()


class BlackListRequest(BaseModel):
    ip: str
    memo: Optional[str] = "Manual Blacklist"


@app.post("/api/v1/config/black_list/add")
async def add_black_list(
    request: BlackListRequest,
    api_key: str = Depends(validate_api_key)
):
    """
    Add IP to blacklist (Simulated as an attack from FAIL2BAN service)
    """
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)
    
    try:
        # Check if IP already exists in ipaddress table, if not add it
        cursor.execute("SELECT id FROM ipaddress WHERE ip = %s", (request.ip,))
        if not cursor.fetchone():
            cursor.execute("""
                INSERT INTO ipaddress (ip, create_time, update_time, country, region, city) 
                VALUES (%s, NOW(), NOW(), 'Unknown', 'Unknown', 'Unknown')
            """, (request.ip,))
        
        # Insert simulated attack into infos table
        # This will be picked up by the sidecar monitor and added to banned_ips.txt
        import uuid
        info_id = str(uuid.uuid4())[:20] # Generate unique ID, max 20 chars
        
        query = """
            INSERT INTO infos (
                info_id,
                source_ip, 
                source_ip_country, 
                service, 
                client_id, 
                create_time, 
                dest_port, 
                info
            ) VALUES (
                %s,
                %s, 
                'Unknown', 
                'FAIL2BAN', 
                'manual_api', 
                NOW(), 
                0, 
                %s
            )
        """
        cursor.execute(query, (info_id, request.ip, request.memo))
        connection.commit()
        
        return {
            "status": 0,
            "msg": "success",
            "data": None
        }
        
    except Error as e:
        logger.error(f"Database error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        connection.close()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=4434)
