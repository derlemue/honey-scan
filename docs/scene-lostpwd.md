#### Account Credential Loss Awareness

> **Pain Points**

The loss of employee account/password assets is a **fatal hidden danger** for most enterprises. Sensing such threats has effectively been a blind spot for security teams.

> **Recommended Deployment**

Deploy a honeypot that mimics common external services, such as `vpn.company.com` or `hr.company.com` (using deceptive domains). By monitoring login attempts, you can identify if **internal employee credentials** are being tested/used. HFish can notify the security team and the employee immediately to change their password.

> **Deployment Notes**

1. **White-listing**: This scenario will capture a **massive amount of real attack traffic**. Suggest adding the honeypot IP to your network detection equipment's whitelist to avoid false alarms.
2. **Compliance**: Some industries require reporting internet-facing assets to regulators. Ensure you register the honeypot address if required.
