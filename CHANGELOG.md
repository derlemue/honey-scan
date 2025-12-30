# Changelog

All notable changes to this project will be documented in this file.

## [1.3.3] - 2025-12-30

### Removed
- 🗑️ **NPM**: Removed Nginx Proxy Manager integration to simplify architecture and reduce potential conflicts.

## [1.3.2] - 2025-12-30

### Fixed
- 📝 **Documentation**: Corrected logic for NPM Proxy Host configuration (Domain -> Forward).

## [1.3.1] - 2025-12-30

### Changed
- 🔄 **Networking**: Swapped ports back. HFish now listens on standard `80`/`443` for honeypot services.
- 🔐 **NPM**: Nginx Proxy Manager moved to `8000`/`4430`.

## [1.3.0] - 2025-12-30

### Added
- 🔐 **NPM**: Integrated Nginx Proxy Manager for easy HTTPS certificate management.
- ⚙️ **Architecture**: Moved HFish ports to `8000`/`4430` to allow NPM to handle ports `80`/`443`.

## [1.2.2] - 2025-12-30

### Fixed
- 🐛 **Reliability**: Fixed blocking loop in `monitor.py` using `ThreadPoolExecutor`.
- 📂 **Deployment**: Added missing `feed` and `scans` directories to prevent Docker volume errors.
- 🐚 **Scripts**: Updated `client_banned_ips.sh` to support custom server URL argument.

## [1.2.1] - 2025-12-30

### Fixed
- 🐛 **Deployment**: Restored missing `docker-compose.yml` file.

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
