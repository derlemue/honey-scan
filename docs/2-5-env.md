#### Active Internet Access Requirements

> **Security Note**

HFish is developed 100% in Golang. It uses low-interaction honeypots locally. All network services are simulated by HFish. While it may appear that an attacker can log into MySQL, Redis, or other services, they are actually interacting with a Golang simulation designed to confuse and trap them.

**You do not need to worry about the HFish simulated services being compromised.**

> **Outbound Connections (Management Server)**

HFish supports both IPv4 and IPv6 and can operate in a completely isolated internal network. However, to maximize threat detection, integrate with cloud honeynets, consume threat intelligence, and perform auto-upgrades, **we strongly recommend allowing the Management Server to access specific internet domains.**

**The Management Server will NEVER actively initiate connections to Nodes.** It generates a configuration, and Nodes attempt to connect to the Management Server every 60 seconds to pull it.

For a balance of security and functionality, we recommend configuring ACLs to allow the HFish Management Server to access only the following:

| IP / Domain | Protocol / Port | Purpose |
| :--- | :--- | :--- |
| `106.75.31.212`, `106.75.71.108`<br>`api.hfish.net` | TCP/443 | **(Recommended)** Upgrades and attack data synchronization. |
| `106.75.5.50`, `106.75.15.34`<br>`zoo.hfish.net` | TCP/22222 (SSH)<br>TCP/22223 (Telnet) | **(Recommended)** Communication with Cloud High-Interaction Honeypots. |
| `43.227.197.203`, `43.227.197.42`<br>`hfish.cn-bj.ufileos.com` | TCP/443 | Downloading installation/upgrade packages. |
| `api.threatbook.cn` | TCP/443 | Threat Intelligence queries (Optional). |
| `open.feishu.cn` | TCP/443 | Lark (Feishu) Alerts (Optional). |
| `oapi.dingtalk.com` | TCP/443 | DingTalk Alerts (Optional). |
| `qyapi.weixin.qq.com` | TCP/443 | WeCom Alerts (Optional). |

`Notes:`
1. For security, **do not** expose the Management Server's Web Interface (TCP/4433) to the public internet.
2. If using Email Alerts, allow access to your SMTP server.
3. HFish supports sending Syslog to up to 5 destinations; ensure network connectivity to your SIEM/Log servers.

> **Outbound Connections (Nodes)**

**HFish Nodes do not actively access any external addresses other than the Management Server.**

#### Security Configuration

> **Management Server Security**

The Management Server should be deployed in a **Secure Zone**. The Web and SSH ports should only be accessible to authorized security personnel and management devices.

- **TCP/4433 (Web)**: Default management port (HTTPS). Can be changed in `config.ini`, though not recommended.
- **TCP/4434 (Node Comm)**: Used for communication between Nodes and the Server. **This port cannot be changed** and must be accessible by all Nodes.

`Security Rules:`
- **TCP/4433** and **TCP/22** should "ONLY" be accessible by management devices in the Secure Zone.
- **TCP/4434** must be accessible by **all Honeypot Nodes**.

> **Node Security**

Honeypot nodes inherently face attackers. We recommend the following:

1. **Isolation**: If you need both Intranet and Internet sensing, we **strongly recommend** deploying two independent HFish instances (separate Management Servers and Nodes) for complete isolation.
2. **DMZ**: If a node must be accessible from the internet, deploy both the Node and Management Server in a DMZ.
3. **Outbound restrictions**: Internet-facing nodes should **only** be allowed to access the Management Server's **TCP/4434**. They should have **NO** access to internal assets.
4. **Inbound restrictions**: Internal nodes should only expose the specific honeypot service ports. No other ports should be accessible.
5. **Maintenance**: Limit SSH access to nodes to a strictly defined set of maintenance hosts.
