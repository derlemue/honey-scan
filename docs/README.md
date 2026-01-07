#### Design Concept

HFish is a free, community-driven honeypot platform designed for enterprise security. It focuses on three core scenarios: **Intranet Breach Detection**, **Internet Threat Awareness**, and **Threat Intelligence Generation**. HFish provides safe, agile, and reliable low-to-medium interaction honeypots tailored to enhance your security posture.

#### Contact Us

HFish is developed by **ThreatBook (Beijing Weibu Online Technology Co., Ltd)**.

![joinus](../images/joinus.png)

HFish supports over 90 types of honeypot services, including basic network services, OA systems, CRM systems, NAS, Web servers, IT ops platforms, security products, wireless APs, switches/routers, email systems, and IoT devices.

**Key Features:**
- **Custom Web Honeypots**: Create your own web-based decoys.
- **Cloud Honeynet**: Support for traffic redirection to a free cloud honeynet.
- **Port Scanning Detection**: Toggleable all-port scan detection.
- **Custom Lures**: Configure custom honey-tokens and baits.
- **One-Click Deployment**: Easy installation across platforms (Linux x32/x64/ARM, Windows x32/x64) and CPU architectures (Intel/AMD, Loongson, Hygon, Phytium, Kunpeng, etc.).
- **Low Resource Usage**: Extremely efficient performance.
- **Unified Alerting**: Supports Email, Syslog, Webhook, WeCom, DingTalk, and Lark.

**Download & Deploy:**

- [Linux AMD64 Management Server](https://hfish.net/#/en/2-2-linux)
- [Linux ARM64 Management Server](https://hfish.net/#/en/2-2-linux)
- [Windows Management Server](https://hfish.net/#/en/2-3-windows)
- [Docker Image](https://hfish.net/#/en/2-1-docker)

For enterprise deployment documentation, visit the [HFish Documentation](https://hfish.net/#/docs).

#### Why Choose HFish?

> **Free, Simple, Safe**

A honeypot is defined by its lightweight detection capabilities and low false-positive rates. It is a high-quality source of local threat intelligence. HFish helps small and medium-sized enterprises avoid alert fatigue while enhancing threat detection at low cost. Considering the power of the open-source community, HFish is constantly evolving to implement the best practices in deception defense.

> **Agile Threat Perception**

HFish is widely used to detect lateral movement in office intranets, production environments, and clouds. It effectively identifies compromised hosts, leaked employee credentials, scanning/probing behaviors, and generates private intelligence. It is also excellent for internal red-teaming and security awareness training.

#### Architecture

HFish adopts a **B/S (Browser/Server) architecture**, consisting of a **Management Server** and **Nodes**.
- **Management Server**: Generates and manages nodes; receives, analyzes, and displays data from nodes.
- **Nodes**: Controlled by the server to host the actual honeypot services.

In HFish, the **Management Server** is responsible for **data analysis and visualization**, while **Nodes** run the **virtual honeypots** that directly **interact with attackers**.

**Module Relationship Diagram:**

![architecture](../images/20210616174908.png)

#### Our Story

- **August 7, 2019**: First release of open-source HFish. In 16 months, it garnered 2.6k stars on GitHub and became a Top 5 GVP security project on Gitee.
- **February 9, 2021**: Incorporating 2 years of community feedback, we launched **HFish v2**—a completely redesigned threat capture and deception system, free for all users.
