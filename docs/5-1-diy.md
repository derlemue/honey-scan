#### Custom Web Honeypot

> **Download Template**

Download the official HFish Custom Web Honeypot template:
[https://hfish.net/service-demo.zip](https://hfish.net/service-demo.zip)

Unzip to get the `index.html` file.

> **index.html Analysis**

- `<form>`: Defines how the login form submits data. See "Creating a New Login Page" below.
- `<script>`: Defines the JSONP calls (used for attacker attribution).

> **portrait.min.js Analysis**

This file utilizes JSONP to attempt to identify the attacker. If the attacker is logged into certain social platforms, this script attempts to retrieve their account info.

*Note: This relies on specific browser behaviors (like Chrome < v80) and may trigger antivirus alerts. You can remove the reference to `portrait.min.js` in `index.html` if you do not want this aggressive attribution feature.*

HFish community welcomes contributions of new vulnerability utilization code for attribution.

#### Creating a New Login Page

You can create a completely custom login page (e.g., mimicking your company's OA system) by modifying the form elements of any HTML page.

Open `index.html` and modify the form elements as shown:

![form_elements](images/20210728213641.png)

#### Packaging and Uploading

> **Create Zip Package**

Package all static files (index.html, js, css, images) into a zip file named `service-xxx.zip`.
- Must start with `service-`.
- Must be `.zip` format.
- Cannot contain "web" or "root" in the custom name part.

![zip_package](images/20210728213740.png)

> **Upload Package**

Go to **[Service Management]** -> **[Custom Service]** and upload your zip file.

![upload_package](images/20210728213815.png)

> **Configure Service**

Once uploaded, you can add this new service to any node or template.

![config_service](images/20210728213852.png)

#### Troubleshooting: "not found index.html"

This usually happens if the zip file has a nested directory structure (e.g., `service-oa.zip/service-oa/index.html`).
**Ensure `index.html` is at the root of the zip file.** Select all files inside your folder and zip them directly.

![zip_fix](images/20220806141310886.png)
