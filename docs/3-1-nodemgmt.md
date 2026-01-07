#### Manage Nodes

#### Built-in Node

After installing the HFish Management Server, a default node is automatically created on the server to detect attacks. This node is named **Built-in Node**.

This node enables several services by default, including FTP, SSH, Telnet, Zabbix Monitor, Nginx, MySQL, Redis, HTTP Proxy, ElasticSearch, and generic TCP listeners.

`Note: The Built-in Node cannot be deleted, but it can be paused.`

![builtin_node](../images/image-20210902210912371.png)

#### Add New Node

> **Step 1: Go to [Node Management] page and click [Add Node]**

![add_node](../images/image-20210902172749029.png)

> **Step 2: Select the installation package and callback address**

Choose the package corresponding to your node's operating system.

![select_os](../images/image-20210902172832815.png)

> **Step 3: Configure Callback Address**

HFish automatically detects the current server IP. However, in cloud environments or complex networks, this might be an internal IP. **You must ensure the configured callback address (IP and Port) is accessible by all nodes.**

![callback_addr](../images/image-20210902172916191.png)

> **Step 4: Execute Command**

Copy the generated command or download the installer and run it on the node machine to complete the deployment.

#### Delete Node

> **Go to [Node Management], find the node, and click [Delete].**

HFish requires a secondary confirmation (Admin password) to prevent accidental deletions.

Once deleted, the node process will automatically exit. However, the program files will remain in the installation directory and must be manually removed if desired. All historical attack data collected from this node will be retained and remains viewable in the Management Server.
