#!/bin/bash
set -e

# Dependencies are now in the Docker image!

echo "Starting API server on port 4444..."
cd /app/api
uvicorn main:app --host 0.0.0.0 --port 4444 --workers 2 &
API_PID=$!
echo "API started with PID $API_PID"

echo "Starting monitor..."
cd /app
exec python monitor.py
