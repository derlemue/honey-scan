#### Cloud Environment Risk Awareness

By deploying honeypots in the cloud, you **attract attacks** away from real business assets. Defenders can perceive the **intensity and methods of cloud threats**, avoiding blindness to the security landscape. Finally, through the **HFish API** and integrations with **SIEM/SOC**, defenders can achieve **unified management**.

> **Pain Points**

Due to the nature of cloud environments, there is a **scarcity** of traffic-based security products. Furthermore, defenders often have to toggle frequently between local security device alerts and limited cloud alerts.

> **Recommended Deployment**

Register a deceptive subdomain or use an abandoned subdomain. Deploy a honeypot to sense attack intensity and behaviors.

> **Deployment Notes**

1. **White-listing**: This scenario will capture a **massive amount of real attack traffic**. Suggest adding the honeypot IP to your network detection equipment's whitelist to avoid false alarms.
2. **Compliance**: Some industries require reporting internet-facing assets to regulators. Ensure you register the honeypot address if required.
