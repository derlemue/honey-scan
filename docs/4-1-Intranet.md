#### Intranet Breach Detection

According to HFish team research, Intranet Breach Detection is the most practical and commonly used scenario reported by commercial users. Compared to internet deployment, local intranet deployment allows for precise detection of lateral movement and scanning behaviors from compromised internal hosts. This provides higher fidelity alerts and enables stronger closed-loop responses.

![intranet_scenario](../images/202311081253175.png)

> **Pain Points**

Internal office networks and servers are vulnerable due to various factors: unsecured USB devices, illegal software downloads, client vulnerabilities, stolen VPN credentials, or malicious insiders. Once inside, attackers or worms move laterally with abandon. The challenge is: **How to timely detect these critical security events already happening within the intranet?**

> **Recommended Deployment**

![deployment_diagram](../images/20210616174930.png)

This is the **most common** use case for honeypots in enterprise environments. It focuses on **agile and accurate** detection of compromised hosts, ransomware, and malicious behaviors.

**1. Office Network Scenario**
Honeypots are deployed in the office network zone to **detect compromised workstations, ransomware scanning, or insider probing**.
*Template Recommendation*: Listen on TCP/135, TCP/139, TCP/445, and TCP/3389.

**2. Server Zone Scenario**
Honeypots are deployed in the server zone to **detect server compromise and lateral movement**.
*Template Recommendation*: Simulate Web, MySQL, Redis, Elasticsearch, SSH, Telnet services.

> **Deployment Notes**

1. **Density**: Higher coverage is better. We recommend deploying at least two nodes per subnet (one at the start and one at the end of the IP range).
2. **Network**: VLANs don't fundamentally matter, as long as an attacker scanning the subnet from a compromised machine is likely to hit a node.
3. **Firewall**: Ensure the honeypot service ports are open and accessible to potential attackers within the network.

> **Key Monitoring Pages**

1. **[Attack List](detail-attack.md)**
   View all attacks against the honeypots.

2. **[Scan Sensing](4-2-scan.md)**
   When enabled, HFish observes connections to *any* port on the node host.
   *Recommendation*: Strongly recommended if the node is a dedicated machine (running only HFish).
   *Note*: If the node shares a server with business apps, this may generate massive false positives. Use specific "TCP Port Listening Honeypots" instead.

3. **[Breach Sensing](detail-decoy.md)**
   This leverages **Honey Tokens (Decoys)** to passively detect host compromise. You can generate decoys here and monitor their usage.

4. **[Alert Configuration](detail-alarm.md)**
   Configure real-time notifications to security operation centers or personnel when high-fidelity alerts occur.
