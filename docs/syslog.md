### Syslog Field Definitions

#### Threat Alert Fields

**HFish - Threat Alert**

```json
{
  "client": "Node Name",
  "client_ip": "Node IP",
  "attack_type": "scan/attack/signon/hr_signon/compromise", // Type: Scan, Attack, Login, High-Risk Login, Compromise
  "scan_type": "udp/tcp/icmp",
  "scan_port": "Port (or N/A)",
  "type": "Honeypot Name",
  "class": "Honeypot Category",
  "account": "Credentials Used",
  "src_ip": "Attacker IP",
  "labels": "Threat Intel Labels",
  "dst_ip": "Victim IP (Honey IP)",
  "geo": "Attacker Geo-location",
  "time": "Timestamp",
  "threat_name": "Threat Behavior Name",
  "threat_level": "Level (e.g., high)",
  "info": "Details (or N/A)"
}
```

#### System Alert Fields

**HFish - Node Offline**

```json
{
  "title": "HFish - Node Offline Alert",
  "Server_ip": "HFish Server IP",
  "client": "Node Name",
  "client_ip": "Node IP"
}
```

**HFish - Honeypot Offline**

```json
{
  "title": "HFish - Honeypot Offline Alert",
  "Server_ip": "HFish Server IP",
  "client": "Node Name",
  "client_ip": "Node IP",
  "class": "Honeypot Service Name"
}
```
