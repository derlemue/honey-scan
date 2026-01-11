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


### 🐬 Flipper Zero Integration
**Status**: 📝 Planned
**Priority**: Medium

**Description**
Integrate Honey Scan with Flipper Zero to enable portable threat monitoring.
- **Companion App (.fap)**: A native Flipper Zero app to view, search, and manage feed reports on-the-go.
- **Sync Bridge**: A Dockerized PC bridge service that pulls reports from the Honey Scan Feed and synchronizes them to the Flipper via USB, using smart timestamp-based verification to only transfer new data.

### 🥚 Hidden "Easter Egg" Server
**Status**: 📝 Idea
**Priority**: Low

**Description**
Implement a hidden server page (e.g., via Konami code or hidden path) featuring a hacker-themed puzzle or interactive terminal. This serves as a community engagement tool and a "Capture The Flag" (CTF) style educational challenge for users exploring the infrastructure.

### 🔄 Bidirectional API Sync (Full Schema)
**Status**: 📝 Planned
**Priority**: High

**Description**
Upgrade the synchronization engine to support **two-way replication** of all database columns between Honeypot Nodes and the central API Server. This ensures that metadata updates (e.g., geolocation corrections, manual comments) propagate across the entire mesh, maintaining a single source of truth.

### 🔬 Internal Node consistency
**Status**: 📝 Planned
**Priority**: High

**Description**
Implement an internal API reconciliation mechanism for Honeypot Nodes to validate their state against each other or a leader node. This ensures that the local SQLite/MariaDB databases on edge nodes remain consistent with the central API, preventing data drift in distributed deployments.

### 🍓 Raspberry Pi Portable Honeypot
**Status**: 📝 Planned
**Priority**: Medium

**Description**
Develop a specialized deployment configuration and setup script for **Raspbian (Raspberry Pi)**, optimized for:
- **Mobility**: Lightweight configuration for portable usage.
- **Display Support**: Mobile-optimized UI for small touch screens (e.g., 3.5" GPIO or HDMI displays).
- **One-Click Setup**: Automated script to handle Raspbian-specific dependencies and Docker installation.

---

## ✅ Completed

### 🛡️ Scanning Optimization (v2.1)
**Status**: Done
**Description**
Separation of `ipscan` and `geoscan` statuses to allow independent tracking of network scans vs. geolocation resolution.
- **IP Scan**: Tracks Nmap/Traceroute execution.
- **Geo Scan**: Tracks IP-API resolution.
- **Optimization**: Skips redundant scans if a report exists and location is valid.
