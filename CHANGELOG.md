# Changelog

All notable changes to this project will be documented in this file.

## [3.5.5] - 2025-12-31

### Fixed
- 🐛 **UI**: Fixed Login Button color to "Cyber Green" (`#4ade80`).
- 🎨 **Assets**: Replaced Bear Logo with user-provided transparent version (via `logo_bear.png`).

## [3.5.4] - 2025-12-31

### Fixed
- 🐛 **UI Hotfix**: Resolved a critical issue where the branding script interfered with the dashboard rendering (White Screen/No Code). Implemented safer DOM manipulation using `MutationObserver`.

## [3.5.3] - 2025-12-31

### Changed
- 🎨 **Branding**: Major UI overhaul for the Login Screen.
    - Replaced the Trident character with the **Honey-Scan Bear** logo.
    - Updated Title to "**Honey Scan Active Defense**" (Green).
- 📝 **Documentation**: Synchronized all README languages (EN/DE/UA) with the new logo and versioning.

## [3.5.2] - 2025-12-31

### Fixed
- 🚑 **Critical**: Fixed HFish crash loop by externalizing `config.toml` and explicitly setting database host to `127.0.0.1` (Host Networking fix).
- ⚙️ **Config**: Added `config/hfish.toml` to repository for persistent configuration management.

## [3.5.1] - 2025-12-31

### Fixed
- 🐛 **Configuration**: Fixed HFish crash in Host Mode by injecting `DB_HOST=127.0.0.1` (Container -> Host -> DB).
- 🐛 **Visuals**: Fixed missing Belgium flag (`?`) in attack list.
- 🎨 **UI**: Updated project logo and location data (Germany/Falkenstein) for built-in nodes.

## [3.5.0] - 2025-12-31

### Changed
- 🌐 **Networking**: Switched `hfish` container to `network_mode: "host"` to enable real Source IP detection.
- ⚙️ **DNS**: Enforced global DNS servers (`1.1.1.1`, `1.0.0.1`) for all containers to prevent resolution issues.
- 🕒 **Timezone**: Standardized all containers to `Europe/Amsterdam`.

## [3.4.1] - 2025-12-30

### Fixed
- 🌐 **Frontend**: Fixed missing country flags regarding the "Attack" list (Injected custom SVG).
- 🎨 **Branding**: Aggressively patched "XX Company" text to "lemueIO SecMonitor".
- 🗺️ **Map**: Fixed incorrect "Built-in Nodes" location (Moved to Falkenstein, Sachsen).
- 🕒 **Timezone**: Changed Docker timezone to `Europe/Amsterdam`.

## [3.4.0] - 2025-12-30

### Changed
- 🔧 **System**: Hardening and stability improvements.

## [3.3.0] - 2025-12-30

### Changed
- 🔧 **Internal**: General housekeeping and internal configuration cleanup.

## [3.2.0] - 2025-12-30

### Changed
- 🛡️ **Client Shield**: Completely overhauled `client_banned_ips.sh`.
    - Automatically checks for Fail2Ban (ASCII warning + install prompt).
    - Starts Fail2Ban daemon if inactive.
    - Bans IPs directly into the `sshd` jail.

## [3.1.0] - 2025-12-30

### Fixed
- 🐛 **Branding**: Permanently patched HFish Dashboard title to "**lemueIO SecMonitor**" via frontend injection.
- 🐛 **Feed**: Verified Feed title is "**lemueIO Active Intelligence Feed**".

## [3.0.0] - 2025-12-30

### Added
- 🌍 **Localization**: Added German (`README_DE.md`) and Ukrainian (`README_UA.md`) documentation.
- 🏳️ **Navigation**: Added language flags to README.

### Changed
- 🚨 **Rebranding**: Renamed feed to "**lemueIO Active Intelligence Feed**" with updated personalization.
- 🆙 **Major Release**: Version bump to 3.0.0 marking stable multi-language support and system resilience.

## [2.1.1] - 2025-12-30

### Changed
- 🚨 **Rebranding**: Updated name to "**lemueIO SecMonitor**".

## [2.1.0] - 2025-12-30

### Changed
- 🚨 **Rebranding**: Rebranded "XX Company Threat Monitor" to "**lemue.org SecMonitor**".
- 📸 **Visuals**: Updated screenshots for Login and Dashboard with **IP obfuscation** to protect privacy.
- 📖 **Documentation**: Updated README header with a new design.

## [2.0.1] - 2025-12-30

### Fixed
- 🐛 **Documentation**: Fixed broken image links in README by moving screenshots to `docs/img/`.
- 📸 **Visuals**: Added internal HFish dashboard screenshots (Screen & Stats) to README.

## [2.0.0] - 2025-12-30

### Changed
- 🚨 **Rebranding**: Renamed dashboards and feeds to **lemue.org Threat Live Monitoring**.
- 📸 **Documentation**: Added screenshots for Login and Dashboard to README.
- 🆙 **Major Release**: Consolidated all recent architecture changes (MariaDB, Sidecar v2, Named Volumes) into a stable 2.0.0 release.

## [1.5.0] - 2025-12-30

### Added
- ✨ **Database**: Added embedded **MariaDB** service for scalable data storage.
- 🔄 **Sidecar**: Updated `sidecar` to support MySQL/MariaDB connections for attacker monitoring.

## [1.4.6] - 2025-12-30

### Changed
- 🧹 **Cleanup**: Removed obsolete `version:` top-level key from `docker-compose.yml`.

## [1.4.5] - 2025-12-30

### Fixed
- 🐛 **Networking**: Moved HFish SSH honeypot port to `2223` as Host SSH is blocking Port `22` (Setup script issue or no reboot).

## [1.4.4] - 2025-12-30

### Fixed
- 🐛 **Deployment**: Fixed HFish Admin 404 error. Changed storage from Host Bind Mount to Docker Named Volume (`hfish_data`) to prevent overwriting web application files in the container.

## [1.4.3] - 2025-12-30

### Fixed
- 🐛 **Networking**: Changed HFish SSH honeypot port to `22` (Host) since `2222` is now used by the real Host SSH.

## [1.4.2] - 2025-12-30

### Fixed
- 🐛 **Deployment**: Fixed Docker mount error by creating placeholder `feed/index.html` and unignoring it in `.gitignore`.

## [1.4.1] - 2025-12-30

### Changed
- 🛠️ **Refactor**: Replaced deprecated `docker-compose` command with modern `docker compose` CLI in documentation.

## [1.4.0] - 2025-12-30

### Added
- 🛠️ **Automation**: Added `scripts/setup_host.sh` for one-click Debian 13 initialization.
- 🔐 **Security**: Setup script now changes SSH port to `2222` to reserve Port 22 for the honeypot.

## [1.3.4] - 2025-12-30

### Added
- 📚 **Docs**: Added "Prerequisites" section to README with copy-paste commands for Debian 13 setup.

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
