FROM python:3.9-slim

# Install Nmap and sqlite3
RUN apt-get update && apt-get install -y nmap sqlite3 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the monitor script
COPY monitor.py .

# Run the monitor script
CMD ["python", "monitor.py"]
