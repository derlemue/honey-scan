#### Quick Start

After deploying the HFish Management Server, you only need to understand and perform the following three steps to start observing threats.

> **1. Add/Delete Nodes**

After installing the Management Server, a default node named **"Built-in Node"** is automatically created on the server itself to sense attacks.

You can also deploy new nodes on other machines to expand your observation range.

> **2. Add/Delete Honeypots**

The relationship between Honeypots, Nodes, and the Management Server is like Headquarters, Retail Stores, and Goods.
- **Headquarters (Management Server)**: Manages stores and supplies goods.
- **Retail Stores (Nodes)**: Receive goods (honeypot services) from HQ and put them on shelves (deploy services) for customers (attackers).

Nodes actively communicate with the Management Server. Once you configure a honeypot via the Web Interface, the Node receives the instruction and builds the specific service on the host.

*A single node can run up to 10 honeypot services simultaneously.*

> **3. View Attack Details**

HFish provides four different views to analyze attack details: **Attack List**, **Scan Sensing**, **Attack Source**, and **Account Assets**.
