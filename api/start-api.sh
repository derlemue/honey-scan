#!/bin/bash
# Start HFish API service alongside HFish server

# Install Python dependencies if not already installed
if [ ! -f /tmp/api_deps_installed ]; then
    pip3 install --no-cache-dir fastapi==0.115.0 uvicorn[standard]==0.32.0 mysql-connector-python==9.1.0 python-dotenv==1.0.1
    touch /tmp/api_deps_installed
fi

# Start API server in background
cd /opt/hfish/api
uvicorn main:app --host 0.0.0.0 --port 4434 --workers 2 &

# Keep script running
wait
