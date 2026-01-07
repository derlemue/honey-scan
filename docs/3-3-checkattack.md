#### View Attack Details

HFish provides four pages to view **Attack Details**: **Attack List**, **Scan Sensing**, **Attack Source**, and **Account Assets**.

![attack_overview](../images/image-20210902143712779.png)

These four functions correspond to different data scenarios:

| Feature | Description | Principle |
| :--- | :--- | :--- |
| **Attack List** | Collects all interactions with honeypots. | Once a node deploys a honeypot, **all interaction/attack information** against it is recorded here. |
| **Scan Sensing** | Collects connections to the node's network interfaces. | HFish records **all connection attempts** to the node's NICs, including source IP, destination IP, and port, even for non-honeypot ports. |
| **Attack Source** | Aggregates IP information. | **All IPs** that connected to or attacked a node are aggregated here. If tracing/attribution is successful, that data is also recorded. |
| **Account Assets** | Collects credentials used in brute-force attacks. | HFish records the **username and password** used by attackers during brute-force attempts. You can set **Custom Monitoring Words** (e.g., employee names, company name) to highlight and alert on specific credential usage. |

For detailed information, please see:

- [Attack List](detail-attack.md)
- [Scan Sensing](4-2-scan.md)
- [Attack Source](detail-attack-source.md)
- [Account Assets](detail-damaged-account.md)
