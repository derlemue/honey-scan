#### JSONP Attribution

This page explains the default JSONP attribution capability in HFish Web Honeypots.

#### What is JSONP?

JSONP (JSON with Padding) is a technique for requesting data from a server in a different domain (Cross-Origin).

#### How it works in HFish

HFish Web Honeypots include a script (`portrait.js`) that utilizes JSONP to attempt to identify the attacker. It tries to fetch public profile information from various social platforms if the attacker is currently logged in.

*Disclaimer: This relies on specific browser behaviors (e.g., Chrome < v80) and social platform interfaces. It may be flagged by antivirus software.*

**Customization:**
You can remove the `portrait.js` reference from `index.html` if you wish to disable this aggressive attribution feature.
