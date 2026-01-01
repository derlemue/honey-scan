# Changelog

All notable changes to this project will be documented in this file.

## [3.6.20] - 2026-01-01

### Changed
- 🚀 **Auto-Deploy**: Automated release via protocol.

## [3.6.19] - 2026-01-01

### Changed
- 🚀 **Auto-Deploy**: Automated release via protocol.

## [3.6.18] - 2026-01-01

### Changed
- 🚀 **Auto-Deploy**: Automated release via protocol.

## [3.6.17] - 2026-01-01

### Changed
- 🚀 **Auto-Deploy**: Automated release via protocol.

## [3.6.16] - 2025-12-31

### Fixed
- 🐛 **Branding**: Enforced universal text replacement for "XX Company" branding on all pages (Dashboard & Login).
- 🐛 **UI**: Added `MutationObserver` independent logic to catch and replace branding text that bypasses initial checks.


### Changed
- 🐛 **UI**: **Route-Specific Branding**. Scoped the aggressive Login styles to `/login` only.
- 🎨 **Dashboard**: Restored original dashboard UI (Header, Light/Default Mode) by removing injections when not on login page.
- 🐛 **UI**: Fixed issue where "Header Menu" disappeared on dashboard.

## [3.6.14] - 2025-12-31

### Changed
- 🎨 **UI**: Reduced **Top Spacing to 0px**. Link Bar is now flush with the top-right corner.
- 🎨 **Logo**: Added `15px` padding to the Bear Logo to prevent container clipping (Original image has inherent cutoff).
- 🐛 **Docs**: Verified logo source file limitations.

## [3.6.13] - 2025-12-31

### Changed
- 🗑️ **UI**: **Replaced SVG Branding** with HTML. Browser verification showed "HFish" was an SVG (`#hfish-hfish-logo-en`), not text.
- 🎨 **UI**: Injected "Honey Scan" (Green) and "Active Defense Platform" (Pill) as pure HTML elements.
- 🐛 **Fix**: Resolved issue where text replacement scripts failed due to SVG usage.

## [3.6.12] - 2025-12-31

### Changed
- 🗑️ **UI**: Removed Detached Title (conflicting text).
- 🔄 **Rebranding**: Replaced "HFish" (Red) with "**Honey Scan**" (Green) in-place.
- 🔄 **Rebranding**: Replaced "Honeypot Platform" with "**Active Defense Platform**" (Grey Pill style retained).
- 🐛 **Fix**: Restored visibility of login container (`.right-wrapper`) while keeping header hidden.

## [3.6.11] - 2025-12-31

### Changed
- 🗑️ **UI**: Completely Removed Original Header Bar (using `display: none`).
- ✨ **UI**: Injected Detached Title directly into `body` for clean positioning.
- 🔗 **Link**: Updated "Banned IPs" link to full URL `https://feed.sec.lemue.org/feed/banned_ips.txt`.

## [3.6.10] - 2025-12-31

### Changed
- 🐛 **Fix**: Masked Header with Dark Background (#0f172a) to eliminate white bar.
- 🎨 **UI**: Reduced Spacing to 25px (matching button gap).
- 🔗 **Link**: Verified Feed Link.

## [3.6.9] - 2025-12-31

### Changed
- 🐛 **Fix**: Nuclear Option for White Header Bar (Forced Dark Body Background).
- 🎨 **UI**: Aggressive Transparency on all header children.

## [3.6.8] - 2025-12-31

### Changed
- 🐛 **Fix**: Hardened CSS for Header Transparency and Title Centering.
- 🎨 **UI**: Reduced Title Font Size to 24px.
- 🎨 **UI**: Forced `display: block` on title elements to ensure correct rendering.

## [3.6.7] - 2025-12-31

### Changed
- 🎨 **UI**: Refined Header Styles (Aggressive Transparency, Smaller Title Font 26px).
- 🎨 **UI**: Adjusted Spacing to align title with inputs.
- 🔗 **Link**: Updated Feed Link to `https://feed.sec.lemue.org/`.

## [3.6.6] - 2025-12-31

### Changed
- 🎨 **UI**: Increased Title Font Size to **42px** (with Glow Effect).
- 🎨 **UI**: Attempted to remove White Header Background (Transparency Fix).
- 🐛 **Fix**: Fixed missing Favicons in Feed (`monitor.py` update) and Dashboard (Docker Mounts).

## [3.6.5] - 2025-12-31

### Changed
- 🎨 **UI**: Added "Transparency Link Bar" to Top-Right Header (GitHub, Feed, Banned IPs, Web).
- 🎨 **UI**: Added "for you by lemue.org ♥️" Footer.
- ✨ **Feed**: Added Favicons to Feed Page.
- 🐛 **Fix**: Fixed Header White Border and increased Title Font Size (36px).

## [3.6.4] - 2025-12-31

### Changed
- 🎨 **UI**: Refined Title Spacing & Logo.
    - Added spacing between the "Honey Scan" title and input fields.
    - Enforced `aspect-ratio: 1/1` on Bear Logo to prevent clipping and ensuring a perfect circle.

## [3.6.3] - 2025-12-31

### Changed
- 🎨 **UI**: Fixed Logo clipping issues.
    - Added `padding` and `box-sizing` to the Bear Logo.
- ✨ **Assets**: Added custom Favicons (generated from Bear Logo) for Dashboard and Feed.

## [3.6.2] - 2025-12-31

### Changed
- 🎨 **UI**: Refined Title and Footer visuals.
    - Increased Title "Honey Scan Active Defense" font size to **28px** and added spacing.
    - Updated "IPv6" footer button text to **White** and **Bold**.
- 📝 **Documentation**: Updated README with production domains (`sec.lemue.org`).

## [3.6.1] - 2025-12-31

### Changed
- 🎨 **UI**: Refined visual weighting.
    - Increased Bear Logo width to 80% (max 350px).
    - Fixed "IPv6" Footer Button having a red border (forced to Green).

## [3.6.0] - 2025-12-31

### Changed
- 🎨 **UI**: Refined Login Screen aesthetics.
    - Resized Bear Logo to 60% with centered alignment.
    - Increased "Honey Scan Active Defense" title font size and adjusted spacing.
    - Updated "IPv6" footer button to Cyber Green (`#4ade80`).

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
