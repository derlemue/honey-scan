### What are Decoys?

Decoys (or Honey Tokens) are fake high-value files (e.g., VPN config, password lists, architectural diagrams) placed on real systems. Their purpose is to lure attackers away from real assets and into traps.

### Usage Scenarios

HFish Decoys add **Precise Breach Detection**. Each generated decoy file is **unique**. If an attacker steals a file from Host A and uses the credentials inside it to attack Host B (the honeypot), HFish knows exactly which decoy file was used, pinpointing the source of the leak (Host A).

**Example:**
```text
1. Attacker breaches Server A.
2. Finds 'payment_config.ini' (Decoy).
3. Config contains fake DB credentials pointing to HFish.
4. Attacker connects to HFish using these credentials.
5. HFish alerts: "Decoy from Server A triggered".
```

### Honey Baits vs Honey Markers

- **Honey Baits (Static Files)**: Files containing fake info (IP, User, Pass). Can be placed anywhere (Web dir, Desktop, Shared Drive).
- **Honey Markers (Active Docs)**: Special Excel/Word docs. When opened, they silently ping the HFish node.
  *Note: Honey Markers require the target machine to have network connectivity to the HFish node.*

### Configuration

HFish provides **Customization**, **Distribution**, and **Alerting**.

#### 1. Decoy Customization

Go to **[Breach Sensing]** -> **[Decoy Management]** to create new decoys.

![decoy_mgmt](images/image-20220525224243205.png)

![create_decoy](images/image-20220525224216905.png)

**Variables:**
- `$username$`: Defaults to 'root' if no dictionary is provided.
- `$password$`: Auto-generated based on complexity rules.
- `$honeypot$`: Auto-fills IP/Port of your HFish node.

**Preview:**

![decoy_preview](images/2811635164463_.pic_hd.jpg)

#### 2. Distribution

The **Distribution Interface** runs on HFish Nodes (Default TCP/7878).
Enable it in **[Node Management]**.

![dist_enable](images/image-20211116213058329.png)

Once enabled, visit the distribution URL from the target machine (the machine you want to protect) to download a unique decoy.

![download_decoy](images/image-20220525224602527.png)

Run the generated command on the target business server to deploy the decoy.

#### 3. Alerts

When an attacker accesses the bait URL (Honey Marker) or uses the bait credentials (Honey Bait) to log into a honeypot, HFish records it.

![decoy_alert](images/image-20211222095822939.png)

The alert will show the **Source of Breach** (which machine the decoy was stolen from).
