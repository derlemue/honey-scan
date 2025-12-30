# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2025-12-30

### Changed
- ⚙️ **Configuration**: Updated `docker-compose.yml` with comprehensive port mappings for 40+ honeypot services.
- 🕒 **Timezone**: Set HFish container timezone to `Europe/Berlin`.
- 🔄 **Reliability**: Changed restart policy to `unless-stopped` for all services.
- 💾 **Resources**: Increased memory limit to 4GB.

## [1.1.0] - 2025-12-30

### Changed
- 📝 **Documentation Overhaul**: Rewrote README.md to focus on Active Defense capabilities.
- 🎨 **Style**: Added emojis, headers, and better formatting.
- ⚠️ **Disclaimer**: Added prominent usage warning.
- 🧹 **Cleanup**: Removed broken images and excessive HFish legacy text.

## [1.0.0] - 2025-12-30

### Added
- 🎉 **Initial Release**: Forked HFish and implemented Active Defense ecosystem.
- 🐍 **Sidecar**: Added Python monitoring service (`sidecar/monitor.py`).
- 📡 **Feed**: Added Nginx feed service (`feed/`).
- 🛡️ **Scripts**: Added client-side protection script (`scripts/client_banned_ips.sh`).
- 🐳 **Docker**: Integrated services via `docker-compose.yml`.
