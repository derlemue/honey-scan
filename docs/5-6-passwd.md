#### Forgot Password

If you forget the admin password, you can force a reset using the `tools` binary.

> **Linux**

```bash
cd /opt/hfish
./tools -mode resetpwd
# Pkill or restart process if needed, usually auto-restarts.
# Default Login: admin / HFish2021
```

> **Windows**

```cmd
cd C:\Path\To\HFish
tools.exe -mode resetpwd
# Restart hfish-server process via Task Manager.
# Default Login: admin / HFish2021
```

> **Docker**

```bash
docker exec -it hfish /bin/sh
cd [version_directory]  # e.g., cd 3.3.5
./tools -mode resetpwd
exit
docker restart hfish
# Default Login: admin / HFish2021
```
