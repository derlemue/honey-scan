#### Quick Deployment

HFish adopts a B/S architecture, consisting of a **Management Server** (Server) and **Nodes** (Client). The Management Server generates and manages nodes, and receives, analyzes, and displays data returned by them. The Nodes receive control instructions from the Management Server and are responsible for hosting the honeypot services.

> **Supported Architecture**

| Component | Windows | Linux x86 |
| :--- | :--- | :--- |
| **Management Server** | Supported (64-bit) | Supported (64-bit) |
| **Node (Client)** | Supported (64-bit/32-bit) | Supported (64-bit/32-bit) |

> **Intranet Deployment Requirements**

Honeypots deployed within an intranet generally have lower performance requirements. Based on past testing, we recommend the following configurations:

| | Management Server | Node |
| :--- | :--- | :--- |
| **Recommended** | 2 Core, 4GB RAM, 200GB Disk | 1 Core, 2GB RAM, 50GB Disk |
| **Minimum** | 1 Core, 2GB RAM, 100GB Disk | 1 Core, 1GB RAM, 50GB Disk |

`Note: Log storage usage is highly dependent on the number of attacks. It is recommended to configure the Management Server with at least 200GB of disk space.`

> **Internet/Extranet Deployment Requirements (MySQL Required)**

Honeypots deployed on the public internet are exposed to significantly more attacks and traffic, thus requiring higher performance. **You must replace the default SQLite database with MySQL.**

| | Management Server | Node |
| :--- | :--- | :--- |
| **Recommended** | 4 Core, 8GB RAM, 200GB Disk | 1 Core, 2GB RAM, 50GB Disk |
| **Minimum** | 2 Core, 4GB RAM, 100GB Disk | 1 Core, 1GB RAM, 50GB Disk |

`Note: Log storage usage is highly dependent on the number of attacks. It is recommended to configure the Management Server with at least 200GB of disk space.`

> **Permission Requirements**

1. **Official Install Script**: If you use the official `install.sh` script, **root privileges are required**. The installation will be placed in the `/opt` directory.
2. **Manual Installation**: If you manually download and run the package with the default SQLite database, root privileges are **not required** for the Management Server. However, if you switch to MySQL, installing and configuring MySQL will require root privileges.
3. **Node Permissions**: Nodes do not strictly require root privileges to run. However, due to OS limitations, **non-root users cannot bind to ports below TCP/1024**.