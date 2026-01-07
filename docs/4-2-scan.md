#### Scan Sensing

This page displays TCP, UDP, and ICMP scan attempts detected by HFish Nodes.

![scan_sensing](../images/20210730154357.png)

Even if a port is closed, HFish can record the scan attempt.

**Recorded Data:**
- Scanner IP
- Threat Intelligence
- Target Node & Port
- Scan Type (SYN, Connect, etc.)

> **Note for Windows Nodes**: Requires **WinPcap** for full scan sensing functionality.
[Download WinPcap 4.1.3](https://www.winpcap.org/install/bin/WinPcap_4_1_3.exe)

#### Common False Positives

Since HFish Nodes monitor all traffic, if you deploy a node on a laptop or machine performing regular business tasks, you may see "self-generated" alerts (e.g., visiting websites triggering port 445 checks etc.).

**Recommendation**: Deploy nodes on dedicated servers or idle VMs.
