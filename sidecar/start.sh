#!/bin/bash
set -e

echo "Installing API dependencies..."
pip install --no-cache-dir fastapi==0.115.0 uvicorn[standard]==0.32.0 mysql-connector-python==9.1.0 python-dotenv==1.0.1

echo "Starting API server on port 4444..."
cd /app/api
uvicorn main:app --host 0.0.0.0 --port 4444 --workers 2 &
API_PID=$!
echo "API started with PID $API_PID"

echo "Starting monitor..."
cd /app
exec python monitor.py
