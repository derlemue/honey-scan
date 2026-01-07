#### Custom Data Integration (Custom Honeypot)

The "Custom Honeypot" feature in HFish is primarily an **interface to receive data** from external sources or other honeypot platforms. Its purpose is central management—aggregating all alerts into HFish.

#### Usage

> **1. Get API Key**

Go to the HFish Management Page for the Custom Honeypot service. View the configuration to find the `apikey`.

![api_key](../images/image-20221031222131166.png)

> **2. Report Data**

Use the API Key to POST data to the HFish Management Server.

- **Method**: `POST`
- **URL**: `https://[server_ip]:8989/api/v1/report` (Default Management Port + API path)
- **Body**: Form-data
  - `apikey`: [Your Key]
  - `info`: [JSON String or Text of the alert data]

**Example:**

![post_example](../images/image-20211027205827645.png)

**Result in Dashboard:**

![result](../images/image-20211027205939646.png)
