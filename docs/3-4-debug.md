#### Troubleshooting

> **Management Server Web Interface Won't Open**

1. **Check URL**: Ensure you are accessing `https://[server]:4433/web/`. **The `/web/` path is mandatory.**
2. **Check Process & Port**: Access the server via SSH and verify the process is running and the port is open.

```bash
# Check if hfish-server is running
ps ax | grep ./hfish | grep -v grep

# Check if TCP/4433 is open
ss -ntpl
```

3. **Check Firewall**: Ensure the firewall allows TCP/4433.

```bash
# CentOS 7: Check status
systemctl status firewalld

# Check open ports
firewall-cmd --list-ports
```

4. **Check Time**: On Linux, use the `date` command to ensure the system time is accurate.
5. **Check Logs**: If all else fails, check the logs.
    - **Linux**: `/usr/share/hfish/log/server.log`
    - **Windows**: `C:\Users\Public\hfish\log\server.log`

> **Node Status is "Offline" (Red)**

1. **Check Network**: Nodes connect to the Management Server's TCP/4434 every 60 seconds. If no heartbeat is received for 180 seconds, it shows Offline.
    - *Note: Newly deployed nodes or unstable networks may cause temporary offline status.*
    - *Wait 2-3 minutes. If it turns green (Online), services will follow suit.*

2. **Check Process**:
```bash
# Check if client process is running
ps ax | grep -E 'services|./client' | grep -v grep
```
If the process is stuck or abnormal, kill all related processes and restart.

3. **Check Logs**:
    - **Node**: `logs/client.log` inside the installation directory.
    - **Server**: `/usr/share/hfish/log/server.log`

> **Node is Online, but some Honeypots are Offline**

Hover your mouse over the **question mark icon** next to the offline honeypot to see the exact error.

![offline_reason](http://img.threatbook.cn/hfish/image-20220721111203773.png)

> **Common Error: `bind: address already in use`**

The port required by the honeypot is occupied by another process.

*Example*: If you enable the SSH honeypot (Port 22) but haven't moved the server's real SSH service to another port, they will conflict. The honeypot might start briefly but will fail shortly after.

**Solution**:
1. Use `ss -ntpl` to identify the process holding the port.
2. Change the port of the conflicting real service, or change the port of the honeypot service in HFish.

*Note for Windows*: Windows uses ports 135, 139, 445, and 3389 by default. We do not recommend enabling honeypots on these ports on a Windows host unless you have disabled the native services.

> **How to keep the node running after closing SSH?**

Use `nohup` to run it in the background:
```bash
nohup ./client >> nohup.out 2>&1 &
```

> **How to auto-start Node on boot (Linux)?**

Add the command to `/etc/rc.local`:
```bash
echo 'nohup /path/to/client >> /path/to/nohup.out 2>&1 &' >> /etc/rc.local
# Ensure rc.local is executable
chmod +x /etc/rc.local
```

> **How to auto-restart Node using Crontab?**

Add a cron job to check and restart every minute:
```bash
echo '* * * * * nohup /path/to/client >> /path/to/nohup.out 2>&1 &' >> /var/spool/cron/crontabs/root
```
*(Note: The client script usually handles idempotency or you might need a wrapper script to check if it's running first.)*
