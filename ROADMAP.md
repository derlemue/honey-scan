# 🗺️ Project Roadmap

This document serves as a collection of planned features, improvements, and architectural ideas for Honey Scan.

## 🚀 Future Enhancements

### 📡 Enhanced Webhook Payload (Sidecar)
**Status**: 📝 Proposed
**Priority**: Medium

**Description**
Currently, the Sidecar sends a minimal payload to the Threat Bridge Webhook:
```json
{
  "attack_ip": "1.2.3.4"
}
```
The goal is to enrich this payload with the geolocation data that the Sidecar has already resolved.

**Proposed Payload**
```json
{
  "attack_ip": "1.2.3.4",
  "geolocation": {
    "country": "Germany",
    "city": "Frankfurt",
    "lat": 50.1109,
    "lng": 8.6821
  },
  "source": "sidecar-v2"
}
```

**Benefits**
- **Efficiency**: Prevents the API server from performing a redundant geolocation lookup.
- **Consistency**: Ensures the API DB and Sidecar DB have identical location data.
- **Speed**: Faster processing of threat signals on the API side.

### 🔑 API Key Identity Source
**Status**: 📝 Idea
**Priority**: Low

**Description**
Allow linking individual names/identities to API keys within the `.env` file (e.g., `API_KEY_1_NAME=Sidecar-Sec`, `API_KEY_2_NAME=Sidecar-Cloud`). This would allow the API to log the exact source name instead of just validating the key, providing better granularity in audit logs.


---

## ✅ Completed

### 🛡️ Scanning Optimization (v2.1)
**Status**: Done
**Description**
Separation of `ipscan` and `geoscan` statuses to allow independent tracking of network scans vs. geolocation resolution.
- **IP Scan**: Tracks Nmap/Traceroute execution.
- **Geo Scan**: Tracks IP-API resolution.
- **Optimization**: Skips redundant scans if a report exists and location is valid.
