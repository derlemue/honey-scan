### Add Node

1. Click **[Add Node]**.
2. Select the **Opearting System** for your node.

![add_node](../images/20210616171500.png)

**Deployment Options:**

- **Linux**:
  1. **One-liner Script**: Copy and run directly on the node.
  2. **Binary Download**: Download, upload to node, and run.

- **Windows**:
  1. **Binary Download**: Download, upload to node, and run.

![node_deploy_linux](../images/20210616172029.png)

### Select Service Template

> Expand the node in the list and select a template from the dropdown.

*Recommendation for Windows Users: Temporarily disable antivirus software if it interferes with installation.*

![select_template](../images/20210616173018.png)

> **Status Transitions:**
> 1. **Enabled**: Configuration pushed.
> 2. **Online**: Service successfully started.
> 3. **Offline**: Service failed to start. Check logs or troubleshooting guide.

![status_enabled](../images/20210616173055.png)

### Host Breach Detection (Decoy Injection)

This feature deploys "Honey Baits" (Decoys) onto the node host itself. These are fake files (e.g., config files with fake credentials) designed to detect if the host itself has been compromised.

When the command is run on the host, it generates a unique "backup file" containing fake credentials. If an attacker finds this file and tries to use the credentials, HFish detects the breach.

![breach_detection](../images/20210812135104.png)

### Delete Node

If you delete a node:
- The node process will exit automatically.
- Program files remain and must be manually deleted.
- **Historical attack data is retained** and can still be viewed.
