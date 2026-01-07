#### Linux One-Click Installation (Recommended)

> **Recommended System**: CentOS is the primary development and testing environment for HFish. We recommend using CentOS for the Management Server.

If your Linux environment has internet access, we strongly recommend using the one-click deployment script.

**Prerequisites**:
If the honeypot node is exposed to the internet, you might encounter TCP connection limits (default 1024). You may need to manually increase the maximum open file descriptors. [Reference](https://www.cnblogs.com/lemon-flm/p/7975812.html)

> **Step 1: Configure Firewall**
Open TCP ports 4433 and 4434.

```bash
firewall-cmd --add-port=4433/tcp --permanent   # Web Interface
firewall-cmd --add-port=4434/tcp --permanent   # Node Communication
firewall-cmd --reload
```
*If you need to open other ports for specific honeypot services later, use the same commands.*

> **Step 2: Run Installation Script** (Root required)

```bash
bash <(curl -sS -L https://hfish.net/webinstall.sh)
```

> **Step 3: Login**

```bash
URL: https://[server_ip]:4433/web/
Default User: admin
Default Password: HFish2021
```
*Note: You must include the `/web/` path in the URL.*

Successful installation will show the default node in the "Node Management" page:
![node_mgmt](images/image-20210914113134975.png)

#### Linux Manual Installation (Offline)

If your environment cannot access the internet, use the manual installation method.

> **Step 1: Download Installation Package**

- [Linux AMD x86-64](https://hfish.cn-bj.ufileos.com/hfish-3.3.5-linux-amd64.tgz)
- [Linux ARM-64](https://hfish.cn-bj.ufileos.com/hfish-3.3.5-linux-arm64.tgz)

*The following steps assume Linux 64-bit system.*

> **Step 2: Prepare Directory**

```bash
mkdir /home/user/hfish
```

> **Step 3: Extract Package**

```bash
tar zxvf hfish-3.3.5-linux-amd64.tgz -C /home/user/hfish
```

> **Step 4: Configure Firewall**

```bash
sudo firewall-cmd --add-port=4433/tcp --permanent
sudo firewall-cmd --add-port=4434/tcp --permanent
sudo firewall-cmd --reload
```

> **Step 5: Run Install Script**

```bash
cd /home/user/hfish
sudo ./install.sh
```

> **Step 6: Login**

```bash
URL: https://[server_ip]:4433/web/
Default User: admin
Default Password: HFish2021
```
