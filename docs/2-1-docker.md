#### Docker Deployment

Docker is one of our recommended deployment methods. The current version offers the following features:

1. **Automatic Upgrade**: Checks for the latest image every hour to upgrade without data loss.
2. **Data Persistence**: Creates a `data` directory under `/usr/share/hfish` on the host to store attack data, and a `logs` directory for logs.

`Note: The current Docker version runs in host mode. If you do not want the Management Server to expose ports other than TCP/4433 and TCP/4434, you can stop the built-in default node on the Management Server.`

#### Default Installation

> **Step 1: Verify Docker is installed and running**

```bash
docker version
```

> **Step 2: Run HFish** (Copy and paste the entire block)

```bash
docker run -itd --name hfish \
-v /usr/share/hfish:/usr/share/hfish \
--network host \
--privileged=true \
threatbook/hfish-server:latest
```

Expected output:
![docker_run_success](images/4351638188574_.pic_hd.jpg)

> **Step 3: Configure Automatic Upgrades** (Copy and paste the entire block)

```bash
docker run -d    \
 --name watchtower \
 --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock  \
  --label=com.centurylinklabs.watchtower.enable=false \
--privileged=true \
  containrrr/watchtower  \
  --cleanup  \
  hfish \
  --interval 3600
```

Expected output:
![watchtower_run_success](images/4381638189986_.pic_hd.jpg)

> **Step 4: Login to HFish**

```
URL: https://[server_ip]:4433/web/
Default User: admin
Default Password: HFish2021
```

#### Docker Upgrade Troubleshooting

If you have configured a Docker image proxy, Watchtower might fail. You can manually upgrade:

```bash
docker pull threatbook/hfish-server:latest
docker stop hfish
docker rm hfish
docker run -itd --name hfish \
-v /usr/share/hfish:/usr/share/hfish \
--network host \
--privileged=true \
threatbook/hfish-server:latest
```

#### Manual Docker Upgrade (Without Auto-Upgrade)

If you haven't configured auto-upgrade, you can perform a one-time manual upgrade:

> **Step 1: Run Watchtower Once**

```bash
docker run -d    \
 --name watchtower \
 --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock  \
  --label=com.centurylinklabs.watchtower.enable=false \
--privileged=true \
  containrrr/watchtower  \
  --cleanup  \
  hfish \
  --interval 10
```

> **Step 2: Verify Upgrade**
Log in to the web interface to check the version.

> **Step 3: Stop Watchtower**

```bash
docker stop watchtower
```

After the initial configuration, you can simply run `docker start watchtower` to upgrade and `docker stop watchtower` to stop it.

#### Modifying Persistence Configuration

To modify the configuration:

> **Step 1: Edit `config.toml`**

Edit the file at `/usr/share/hfish/config.toml`.

> **Step 2: Restart Container**

```bash
docker restart hfish
```