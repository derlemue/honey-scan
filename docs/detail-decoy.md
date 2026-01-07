#### Breach Sensing (Decoys)

The **Breach Sensing** page allows you to generate and manage **Honey Baits (Decoys)** to detect host compromise.

#### What is a Decoy?

A decoy is a fake high-value file (e.g., config file, password list) placed on a business server to lure attackers.

#### Usage Scenario

HFish decoys provide **Precise Breach Detection**. Each decoy is **unique**.
If an attacker steals a decoy from Host A and uses it to attack the HFish node, HFish alerts you that **Host A is compromised**, because that specific decoy file existed *only* on Host A.

#### Modules

HFish Breach Sensing consists of **Decoy Customization**, **Distribution Interface**, and **Alerts**.

##### 1. Decoy Customization

Customize your own baits in **[Breach Sensing]** -> **[Decoy Management]**.

![decoy_custom](../images/image-20211116212624793.png)

**Variables:**
- `$username$`: Account name (defaults to 'root' if empty).
- `$password$`: Auto-generated password.
- `$honeypot$`: Target IP/Port (auto-filled by HFish).

**Preview:**

![preview](../images/2811635164463_.pic_hd.jpg)

##### 2. Distribution Interface

Runs on HFish Nodes (Default TCP/7878).
Enable it in **[Node Management]**.

![distribution](../images/image-20211116213058329.png)

Download command:
`http://[Node_IP]:7878/api/v1/payload/[Token]`

Run the command on the target server to plant the decoy.

##### 3. Alerts

When the decoy is touched or used:
1. **Touch Alert**: Attacker accessed the bait URL (for Honey Markers).
2. **Login Alert**: Attacker used the bait credentials (for Honey Baits) to log into a honeypot.

The alert will clearly show the **Source of Breach**.

![alert_example](../images/image-20211116213801346.png)
