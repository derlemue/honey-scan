#### Manage Honeypots

Every honeypot service (e.g., MySQL, Redis) must be built on a Node. Therefore, you must add a node first before configuring services for it. HFish provides two ways to configure services.

#### Direct Configuration (Single Node)

This method is for quickly modifying services on a specific node.

> **Click on a node in the list to directly Add or Delete services.**

![direct_manage](images/image-20210914120052175.png)

#### Template Configuration (Batch Management)

Honeypot Templates allow you to manage multiple nodes simultaneously by applying a standard set of services to them.

> **Step 1: Create Template**

Go to **[Template Management]**, click **[New Template]**. Enter a name, select the desired honeypot services, add a description, and click **[Confirm]**.

![create_template](images/image-20210914115931102.png)

> **Step 2: Apply Template**

Go to **[Node Management]**, expand the specific node, and select the template you created.

![apply_template](images/20210616173018.png)

> **Step 3: Check Status**

After applying the template, the service status will briefly show as **[Enabled]**. This means the configuration is pushed but deployment varies.
The service is only fully functional when the status turns to **[Online]** (Green).

![status_online](images/20210616173055.png)

> **Troubleshooting Offline Status**

If the status shows **[Offline]** (Red), the service failed to start. Hover your mouse over the question mark icon to see the error message, or refer to the **[Troubleshooting]** section.

![status_offline](images/20210616173129.png)
