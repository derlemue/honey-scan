#### Threat Detection (Yara)

**Overview:**
HFish includes a Threat Detection Engine that uses rules to analyze attack logs and web requests.

You can add custom **Yara Rules** to detect specific attack patterns (e.g., Log4j payloads, specific webshell uploads, or 0-day exploits).

**Data Sources:**
- Web Honeypot URL/UA/Body
- High-Interaction Commands (SSH/Telnet)
- General Honeypot Logs

**Usage:**
1. Click **[New Detection Rule]**.
2. Write your Yara Rule.
3. Test the rule against existing logs.

![new_rule](http://img.threatbook.cn/hfish/image-20220525180831991.png)

**Viewing Alerts:**
Matches will appear in the Attack List with the "Threat Name" corresponding to your rule.
