# HFish Sidecar & Active Defense

This project extends the HFish honeypot with an automated "Active Defense" ecosystem. It monitors the HFish database for new attackers, automatically scans them with Nmap, and publishes a ban list for other servers to consume.

## Architecture

*   **HFish Server**: The core honeypot (Docker).
*   **Sidecar (Python)**: Monitors `hfish.db` (SQLite) for new attacker IPs. Runs `nmap -A -T4` against them.
*   **Feed (Nginx)**: Serves the `banned_ips.txt` list and scan reports via HTTP on port 8888.
*   **Client Script**: `scripts/client_banned_ips.sh` allows other servers to fetch the ban list and add it to Fail2Ban/IPSet.

## Installation

### Server Side (Honeypot + Active Defense)

1.  **Clone the repository**:
    ```bash
    git clone -b honey-scan/active-defense <REPO_URL>
    cd hfish
    ```

2.  **Start the stack**:
    ```bash
    docker-compose up -d --build
    ```

    This will start HFish (admin port 4433, SSH pot 2222), the Sidecar, and the Feed (port 8888).

3.  **Verify**:
    *   Visit `https://<YOUR_IP>:4433` for HFish Admin (Default: `admin` / `HFish2021`).
    *   Visit `http://<YOUR_IP>:8888` for the Active Defense Dashboard.

### Client Side (Protective Shield)

To automatically ban IPs detected by the honeypot on your other servers:

1.  Copy `scripts/client_banned_ips.sh` to the client server.
2.  Edit the script to set your HFish server IP:
    ```bash
    FEED_URL="http://<HFISH_IP>:8888/feed/banned_ips.txt"
    ```
3.  Make it executable and run it (cronjob recommended):
    ```bash
    chmod +x client_banned_ips.sh
    ./client_banned_ips.sh
    ```

## Directory Structure

*   `hfish_data/`: Mapped volume for HFish (contains `database/hfish.db`).
*   `sidecar/`: Python source code for the monitoring module.
*   `feed/`: Stores `banned_ips.txt` and `index.html`.
*   `scans/`: Stores generated Nmap reports (`<IP>.txt`).
*   `scripts/`: Client-side integration scripts.

## Customization

*   **Scan Intensity**: Modify `sidecar/monitor.py` to change Nmap flags (currently `-A -T4`).
*   **Whitelist**: Add logic to `monitor.py` to ignore certain IPs if needed.
