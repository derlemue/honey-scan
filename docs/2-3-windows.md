#### Windows Installation (Manual)

Windows environments do not support one-click installation. You must install manually.

> **Step 1: Download Installation Package**

- [HFish-Windows-amd64](https://hfish.cn-bj.ufileos.com/hfish-3.3.5-windows-amd64.tgz)

> **Step 2: Configure Firewall**

Allow **inbound and outbound** traffic for **TCP/4433** and **TCP/4434**.
*If you need to use other honeypot services, ensure their corresponding ports are also open.*

> **Step 3: Install**

Unzip the package. Run `install.bat` located in the `HFish-Windows-amd64` directory.
*Note: `install.bat` installs HFish in the **current directory**. Ensure the directory path is appropriate before running.*

> **Step 4: Login**

```bash
URL: https://[server_ip]:4433/web/
Default User: admin
Default Password: HFish2021
```
*Note: You must include the `/web/` path in the URL.*

Successful installation will show the default node in the "Node Management" page:
![node_mgmt](images/image-20210914113134975.png)

#### Important Notes

1. **Processes**: HFish has two main processes: `hfish` (Management) and `management` (Honeypot/Console). The `hfish` process monitors, launches, and upgrades the main program. **Always run `install.bat` process** (which starts `hfish`). Do not run the management/console executable directly, as it may cause instability or upgrade failures.
2. **Database Location**: On Windows, the default database is stored in `C:\Users\Public\hfish`. After reinstallation, HFish will automatically read configuration and data from this directory.
3. **Troubleshooting**: If you cannot access the web interface, verify that TCP/4433 and TCP/4434 are allowed through the Windows Firewall.
