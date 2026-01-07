#### Threat Intelligence

Integrate with **ThreatBook** intelligence to enhance detection.

> **Why Integrate?**

Cloud intelligence provides context (e.g., "This IP is a known scanner" or "This IP is a botnet C&C"). This helps in accurate judgment and response.

![why_intel](../images/image-20210806093718827.png)

When enabled, queried intelligence is cached locally for 3 days to save quota.

> **Configuration**

Enter your ThreatBook API Key. (Supports TIP commercial integration).

![tip_config](../images/image-20210806093916207.png)

#### Local Whitelist

To prevent false alarms from internal scanners or known safe IPs, add them to the **Whitelist**.
- One IP per line.
- Whitelisted IPs will **not** generate alerts.
- You can also quick-add IPs to the whitelist from the [Attack List] page.
