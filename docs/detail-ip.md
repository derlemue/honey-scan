#### IP Profile

For every IP captured by honeypots, HFish generates an **IP Profile** for deeper analysis.

**Community Intelligence:** All intelligence captured by HFish is shared with the community (if opted in), creating a collaborative defense network.

> **IP Details**

Click the **[Details]** button in the [Attack Source] page to view the IP Profile.

![ip_profile](images/image-20220526111406301.png)

> **Threat Level**

Combines cloud intelligence and local detection counts to provide an intuitive Threat Level.

![threat_level](images/image-20220526111541932.png)

> **Community Data**

Aggregates **Attribution Intelligence** and **Device Information** from the entire HFish community. If *any* user has captured info on this IP, it is shared.

> **Analysis Dimensions**

1. **Threat Behavior**: Judge intent by attack type.
2. **Targeting**: Is it attacking specific services (e.g., VPN)?
3. **Heatmap**: Is it automated (script) or manual? Time patterns?
4. **Local Attack Chain**: View the full history of this IP against your nodes (up to 30 days history displayed).

![heatmap](images/image-20220526112040812.png)

![attack_chain](images/image-20220526112130356.png)

*If you believe an IP is wrongly tagged as malicious (e.g., your own test IP), please contact honeypot@threatbook.cn.*
