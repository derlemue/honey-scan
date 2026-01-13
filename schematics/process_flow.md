# Honey-Scan Process Schematics

This document details the architecture and data flow of the Honey-Scan Client (v4.x). It describes how the system detects attacks, manages jails, and synchronizes with the central intelligence feed.

## 1. High-Level Architecture

The system operates on a **Split Defense Strategy**:
1.  **Tactical (Local)**: Short-term, aggressive defense against new threats hitting this specific sensor.
2.  **Strategic (Global)**: Long-term defense against known threats reported by the global swarm.

```mermaid
graph TD
    subgraph "External World"
        Attacker[🔴 Attacker]
        FeedServer["🟢 Feed Server (Lemue-Sec)"]
        API["🔵 Report API (Lemue-Sec)"]
    end

    subgraph "Honey-Scan Client"
        subgraph "Sensors (Jails)"
            SSHD[honey-sshd]
            Nginx[honey-nginx]
            DockerNginx[honey-nginx-docker]
        end

        subgraph "Defense Layer"
            F2B[Fail2Ban Server]
            NFT[nftables Firewall]
        end

        subgraph "Logic Layer"
            HoneyClient[honey-client.sh]
            BannedIPs[banned_ips.sh]
            Queue[Queue /var/lib/honey-scan]
        end
    end

    Attacker -- "Attack" --> Sensors
    Sensors -- "Log / Detection" --> F2B
    F2B -- "Ban (1) Filter" --> NFT
    F2B -- "Report (2) Action" --> HoneyClient
    
    HoneyClient -- "Check Dedup" --> NFT
    HoneyClient -- "Report" --> API
    HoneyClient -- "Offline?" --> Queue
    
    FeedServer -- "Banned URLs" --> BannedIPs
    BannedIPs -- "Sync (Silent)" --> F2B
    F2B -- "Long Ban (14d)" --> NFT
```

---

## 2. Process Flows

### A. Tactical Flow (Attack Response)
**Trigger**: An attacker creates a failed login attempt or suspicious request on a local service.

```mermaid
sequenceDiagram
    participant Attacker
    participant Service as Service (SSH/Nginx)
    participant F2B as Fail2Ban
    participant HC as honey-client.sh
    participant NFT as nftables (Honey-Feed)
    participant API as Lemue API

    Attacker->>Service: Failed Login / Exploit Attempt
    Service->>F2B: Log Entry (MaxRetry reached)
    
    rect rgb(200, 150, 150)
    Note right of F2B: ACTION TRIGGERED
    F2B->>NFT: Ban IP (48 Hours)
    F2B->>HC: Execute reporting script
    end

    rect rgb(200, 200, 240)
    Note right of HC: DEDUPLICATION CHECK
    HC->>NFT: Is IP in 'honey-feed' (Global Ban)?
    alt IP is Known (Global Ban)
        NFT-->>HC: Yes
        HC-->>F2B: Exit (Silent - No Report)
    else IP is New
        NFT-->>HC: No
        HC->>API: POST /api/v1/config/black_list/add
        alt API Success
            API-->>HC: 200 OK
            HC->>HC: Flush Queue (if any)
        else API Failure
            API-->>HC: 5xx / Timeout
            HC->>HC: Save to JSON Queue
        end
    end
    end
```

### B. Strategic Flow (Feed Synchronization)
**Trigger**: Cron job (every 15m) or System Boot (`banned_ips.sh`).

```mermaid
flowchart TD
    Start([Start banned_ips.sh]) --> SelfUpdate{Check Update?}
    SelfUpdate -- Yes --> GitHub(Fetch Latest Script)
    SelfUpdate -- No --> InstallDeps[Check/Install Dependencies]
    
    InstallDeps --> CompUpdate[Auto-Heal Components]
    CompUpdate --> CheckLogs{Discover Services}
    
    subgraph "Dynamic Configuration"
        CheckLogs -- "Found: sshd" --> PatchJail[Patch Legacy sshd Jail]
        CheckLogs -- "Found: nginx" --> CreateJail1[Create honey-nginx]
        CheckLogs -- "Found: access.log" --> CreateJail2[Create honey-nginx-docker]
        CreateJail1 & CreateJail2 & PatchJail --> RestartF2B[Restart Fail2Ban]
    end
    
    RestartF2B --> SyncProcess
    
    subgraph "Feed Synchronization"
        SyncProcess[Fetch feed.sec.lemue.org] --> Validate{Valid IPs?}
        Validate -- Yes --> Diff["Calculate Diff (Local vs Remote)"]
        Diff --> ImportLoop["Ban New IPs (Silent / No Report)"]
        ImportLoop --> Cleanup[Unban Stale IPs]
    end
    
    Cleanup --> End([Finish])
```

---

## 3. Component Details

| Component | Responsibility | Action |
| :--- | :--- | :--- |
| **banned_ips.sh** | Manager | Orchestrates setup, updates, feed sync, and service discovery. |
| **honey-client.sh** | Reporter | Handles API communication, deduplication, and offline queuing. |
| **honey-feed** | Jail | Holds the global blacklist (Strategic Defense). **Silent** (does not report back). |
| **honey-*** | Jails | Dynamic "sensors" for local services (e.g. `honey-sshd`). **Loud** (reports to API). |
