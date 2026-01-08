FROM python:3.9-slim

# Install Nmap and sqlite3
RUN apt-get update && apt-get install -y nmap sqlite3 && \
    pip install pymysql requests fastapi==0.115.0 uvicorn[standard]==0.32.0 mysql-connector-python==9.1.0 python-dotenv==1.0.1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the monitor script
COPY monitor.py .

# Run the monitor script
CMD ["python", "monitor.py"]
