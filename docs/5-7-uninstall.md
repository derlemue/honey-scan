#### Uninstall HFish

### Uninstall Linux Server

1. **Remove Crontab Task**:
   `crontab -e` and remove lines containing `hfish`.

2. **Kill Processes**:
   ```bash
   ps ax | grep ./hfish
   kill -9 [PID]
   ```

3. **Delete Directory**:
   `rm -rf /opt/hfish`

4. **Clean Global Configs**:
   `rm -rf /usr/share/hfish`

5. **Clean Database** (If using local MySQL):
   `DROP DATABASE hfish;`

6. **Revert SSH/Firewall**:
   - Check `/etc/ssh/sshd_config` for AllowUsers changes.
   - Remove opened firewall ports.

### Uninstall Linux Node

1. **Remove Crontab**: Remove `hfish` lines.
2. **Kill Process**: Kill `client`.
3. **Delete Directory**: Remove the installation folder.

### Uninstall Windows

1. **Stop Tasks**: Remove HFish from Task Scheduler.
2. **Kill Processes**: Stop `hfish.exe` / `client.exe` in Task Manager.
3. **Delete Directory**: Delete the HFish folder.
