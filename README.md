# 🍯 Honey-Scan: Active Defense Ecosystem
### Powered by HFish | Version: **1.3.2**

> [!WARNING]
> **⚠️ DISCLAIMER: HIGH RISK TOOL ⚠️**
>
> This tool performs **ACTIVE RECONNAISSANCE** (Nmap scans) against IP addresses that connect to your honeypot.
> *   **Legal Risk**: Scanning systems without permission may be illegal in your jurisdiction.
> *   **Retaliation**: Aggressively scanning attackers may provoke stronger attacks (DDoS) or expose your infrastructure.
> *   **Usage**: Use strictly for educational purposes or within controlled environments where you accept all liability. **The authors are not responsible for any misuse or legal consequences.**

---

## 📖 Overview

**Honey-Scan** transforms a passive HFish honeypot into an **Active Defense System**. Instead of just logging attacks, it bites back (informatively).

When an attacker touches your honeypot, Honey-Scan automatically:
1.  **🕵️ Detects** the intrusion via the HFish database.
2.  **🔍 Scans** the attacker immediately using `nmap`.
3.  **📢 Publishes** the intelligence to a local feed.
4.  **🛡️ Blocks** the attacker on your production infrastructure (via client scripts).

## 🚀 Key Features

*   **⚡ Real-Time Reaction**: Python sidecar monitors `hfish.db` and triggers scans within seconds of an attack.
*   **📊 Automated Intel**: Generates detailed `.txt` reports for every unique attacker IP.
*   **🚫 Network Shield**: Serves a dynamic `banned_ips.txt` list that your other servers can consume to preemptively block threats.
*   **🔒 Secure Access**: Includes Nginx Proxy Manager for easy HTTPS SSL termination for all dashboards.
*   **🖥️ Dashboard**: Simple web interface to browse scan reports and ban lists.

## 🏗️ Architecture

The system runs as a set of Docker containers extension to the core HFish binary:

| Service | Type | Description |
| :--- | :--- | :--- |
| **HFish** | 🍯 Core | The base honeypot platform (Management & Nodes). (Standard ports `80`/`443`) |
| **Sidecar** | 🐍 Python | The brain. Watches DB, orchestrates Nmap, updates feeds. |
| **Feed** | 🌐 Nginx | Serves reports and banlists on port `8888`. |
| **NPM** | 🔐 Proxy | Nginx Proxy Manager (Ports `8000`/`4430`). |

```mermaid
graph LR
    A[👹 Attacker] -- 1. Hacks --> B(🍯 HFish)
    B -- 2. Logs --> C[(💽 DB)]
    D[🐍 Sidecar] -- 3. Watches --> C
    D -- 4. Nmap Scan --> A
    D -- 5. Updates --> E[📂 Feed]
    F[💻 Dashboard] -- Reads --> E
    G[🛡️ Prod Server] -- 6. Feeds & Blocks --> E
    H[🔐 NPM] -- HTTPS Proxy --> E
    H -- HTTPS Proxy --> B
```

## 🛠️ Installation

### 1. Start the Server
clone the repo and launch the stack:

```bash
git clone https://github.com/derlemue/honey-scan.git
cd honey-scan
docker-compose up -d --build
```

### 2. Access Dashboards
*   **Nginx Proxy Manager**: `http://localhost:81` (Default: `admin@example.com` / `changeme`)
*   **Active Defense Feed**: `http://localhost:8888`
*   **HFish Admin**: `https://localhost:4433` (Default: `admin` / `HFish2021`)

### 3. Configure HTTPS (Recommended)
Login to NPM (`http://localhost:81`) and create Proxy Hosts.
*Note: Since NPM is on port 8000/4430, you will need to point your DNS or load balancer accordingly if you want valid SSL certificates via HTTP-01 challenge, or use DNS-01 challenge.*

1.  **HFish Admin**: Domain `hfish.yourdomain.com` -> Forward to `https://hfish:4433` (Scheme: HTTPS)
2.  **Defense Feed**: Domain `scan.yourdomain.com` -> Forward to `http://feed:80` (Scheme: HTTP)

### 3. Deploy Client Shield
Protect your *other* servers by automatically banning IPs detected by this honeypot.

Run this on your production servers:
```bash
# Download the script (Point to your Honey-Scan server IP)
wget http://<HONEY-SCAN-IP>:8888/scripts/client_banned_ips.sh

# Make executable
chmod +x client_banned_ips.sh

# Run (Add to Crontab for auto-updates!)
./client_banned_ips.sh
```

## 📜 About Core HFish

This project is built upon [HFish](https://hfish.net), a high-performance community honeypot.
*   **Base Features**: Supports SSH, Redis, Mysql web honeypots, and more.
*   **Visualization**: Beautiful attack maps and statistics in the native HFish admin panel.
*   **Note**: This repository focuses on the *Active Defense* extension. For core HFish documentation, please refer to the [official docs](https://hfish.net/#/docs).

---
*Maintained by the Honey-Scan Community.*
