**Attribution Support Version: 3.1.4+**

### What is Attribution?

Attribution (or Active Defense) in this context refers to identifying the attacker's identity (virtual or physical) through technical means during an interaction.

HFish provides defensive capabilities that, within legal and ethical boundaries, can collect information about the attacker when they scan, attack, or connect to specific honeypots.

### Can we attribute in a pure Intranet?

**Business Perspective:**
Attribution is less critical in an intranet because IP assignment (DHCP/CMDB) usually identifies the device/user immediately.

**Technical Perspective:**
HFish supports three methods.
1. **MySQL Counter-measure**: Reads arbitrary files from the attacker's machine (mysql client).
2. **Vendor VPN Counter-measure**: Can acquire WeChat info or screenshots from Windows machines (requires attacker to run a binary).
3. **Web Honeypot Attribution**: (Internet only) Identifies source IP and potentially social media accounts via JSONP (historical vulnerability).

### Implementation Principles

#### 1. MySQL Counter-measure (Intranet Support)

Utilizes the `LOAD DATA LOCAL INFILE` feature/vulnerability in MySQL clients (typically < 8.0). When an attacker connects to the HFish MySQL honeypot using a vulnerable client, HFish can request to read a file from the attacker's machine.

*Note:*
- Requires the attacker to use a vulnerable command-line client or compatible tool.
- You can configure the specific file path to read in Node Management.

![mysql_config](http://img.threatbook.cn/hfish/image-20220807141822892.png)

#### 2. VPN Honeypot Counter-measure (Intranet Support)

This simulates a VPN login page that prompts the user to download a plugin/client. If the attacker downloads and runs it, it can capture system info.

*Note: For testing, this data is local and not uploaded to the cloud.*

#### 3. Web & Java Honeypot Attribution (Internet Only)

These methods use techniques common in "JSONP Hijacking" or specific Java Deserialization chains to identify the attacker's environment or identities (if logged into specific Chinese social platforms).

*Disclaimer: These features rely on specific browser or tool vulnerabilities and may be patched over time.*

### Viewing Trace Information

Go to **[Attack Source]** and click the **[Trace Info]** button on an IP.

![trace_info](http://img.threatbook.cn/hfish/image-20220807123404778.png)

### Traceable Honeypot List

| Type | Service | Port | Description |
| :--- | :--- | :--- | :--- |
| MySQL Counter | MySQL | TCP/3306 | Arbitrary file read capable. |
| VPN Counter | Sangfor VPN | TCP/9091 | Fake VPN portal + binary download. |
| Java Counter | RMI Registry | TCP/1099 | Java Deserialization tracing. |
| Web Trace | Synology NAS | TCP/9194 | Web tracing. |
| Web Trace | Cisco VPN | TCP/9299 | Web tracing. |
| Web Trace | Coremail | TCP/9094 | Web tracing. |
| ... | ... | ... | Many other Web honeypots support basic tracing. |

*Note: The effectiveness of tracing depends heavily on the attacker's tools and environment.*
