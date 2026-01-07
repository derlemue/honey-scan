#### QQ Mail (SMTP) Configuration

> **1. Login to QQ Mail Settings**

Go to [https://mail.qq.com](https://mail.qq.com/), Login -> **Settings**.

![qq_1](images/20220103194402.png)

> **2. Enable SMTP & Get App Password**

Under **POP3/IMAP/SMTP/Exchange/CardDAV/CalDAV Service**:
1. Enable **POP3/SMTP Service**.
2. Click **Generate Authorization Code** (App Password). You will need to verify via SMS.

![qq_2](images/20211231163518.png)

> **3. Configure HFish**

Go to **[Alert Configuration]** -> **[Notification Config]** -> **[Email Server]**.

- **SMTP Host**: `smtp.qq.com`
- **Port**: `465` (SSL) or `587`
- **Account**: Your QQ Email
- **Password**: **The Authorization Code** (NOT your login password)

Click **[Test]**. You should receive a test email.

![qq_3](images/20211231163415.png)
