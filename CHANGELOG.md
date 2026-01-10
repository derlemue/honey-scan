## [7.7.1] - 2026-01-10

### Changed
- 🛠️ **Scripts**: Changed Fail2Ban configuration target to `/etc/fail2ban/jail.local` (highest priority) to guarantee `nftables-allports` override works on all systems.

## [7.7.0] - 2026-01-10

### Added
- 🛡️ **Scripts**: Automatically configures Fail2Ban (`/etc/fail2ban/jail.d/99-honey-scan.conf`) to block **ALL ports** (TCP & UDP) for the `sshd` jail using `nftables-allports`.

## [7.6.0] - 2026-01-10

### Changed
- 🛠️ **Scripts**: Refactored `client_banned_ips.sh` and `client_banned_ips_no_update.sh` to remove all `nftables` dependencies.
- 🛡️ **Fail2Ban**: Scripts now use `fail2ban` exclusively for blocking IPs (configuring `bantime` dynamically for the `sshd` jail).

## [7.5.0] - 2026-01-10

### Added
- 🔄 **Dual Push**: Sidecar now pushes Intelligence to **multiple** targets simultaneously (e.g., Localhost for Dashboard + Remote for Central Cloud), configured via comma-separated `THREAT_BRIDGE_WEBHOOK_URL`.
- 🛡️ **Auto-Jailing**: `client_banned_ips.sh` now automatically creates missing Fail2Ban jail configurations (e.g., `recidive`, `bedrock`, `apache-auth`) on the fly to ensure protection is always active.
- 📊 **Feed Balancing**: Implemented a **3-Way Bucket Strategy** in the Sidecar SQL query to prevent high-volume sources (Fail2Ban) from drowning out other signals.
    - Fail2Ban: Max 50
    - Bridge Sync (Cloud): Max 50
    - Native (VNC, etc): Max 80 (Guaranteed visibility)

### Fixed
- 🕒 **Timezone**: Corrected `BRIDGE_SYNC` ("Honey Cloud") entries to be treated as Local Time (no +1h shift), ensuring they align perfectly with live creation time on the Dashboard.
- 🔧 **Scripts**: Added `bedrock` (Minecraft) filter creation logic to `client_banned_ips.sh`.

## [7.4.0] - 2026-01-09

### Fixed
- 🐛 **Database**: Resolved "Data too long" error for `region` and `city` columns in `monitor.py` by implementing schema migration (VARCHAR 128) and data truncation.

### Changed
- 🚨 **Rebranding**: Replaced "HFish Honeypot" string with "**Honey Cloud**" in Dashboard and Feed location mapping.
- ✅ **Verification**: Verified concurrent execution protection for `client_banned_ips.sh`.

## [7.3.0] - 2026-01-09

### Added
- 🔌 **API**: Added `/webhook` endpoint to the local sidecar API to handle intelligence pushes and return IP status.
- 🐍 **Sidecar**: Enhanced `push_intelligence` with a local status fallback. Emojis ("✅ New IP" and "🔄 Updated") are now reliably logged regardless of the remote bridge's response format.

### Fixed
- 🐛 **Logging**: Resolved issue where extended logging indicators (emojis) were missing in live systems.
- 🔧 **Networking**: Optimized `THREAT_BRIDGE_WEBHOOK_URL` to point to the secure Reverse Proxy domain.

## [7.2.0] - 2026-01-09

### Added
- 🔗 **Documentation**: Added reference to `lemueIO/honey-api` (Threat Intelligence Bridge).
- 🔐 **Security**: Implemented auto-fix for insecure default password (`HFish2021` -> `HoneyScan2024!`) on startup in `monitor.py`.

### Changed
- 📘 **Documentation**: Updated installation steps to explicitly require copying `.env`, `.env.apikeys`, and `config/hfish.toml`.
- 🔐 **Security**: Updated default password in documentation to `HoneyScan2024!`.

## [7.1.0] - 2026-01-08

### Added
- 🛡️ **Client Shield**: Added `hfish-client.sh` script for reporting attacks back to HFish from client servers.
- 📘 **Documentation**: Added "Active Reporting" (Fail2Ban Action) guide to all READMEs.

## [7.0.0] - 2026-01-08

### Added
- 🔌 **API**: Full Python-based API replacement (`hfish-sidecar-v2`) integrated into the sidecar container.
- 🔌 **API**: New endpoint `/api/v1/config/black_list/add` for manual IP banning (Fail2Ban integration).
- 🔌 **API**: Added `Header` support for API Key authentication (`api_key` and `api-key`).

### Changed
- 🆙 **Major Release**: Version 7.0.0 marks the transition to a fully custom Python API backend, replacing the broken/missing HFish native API.
- 🔧 **Architecture**: API moved to Port **4444** (Sidecar) to coexist with HFish internal services.
- 📘 **Documentation**: Added API Reference to all READMEs.

### Fixed
- 🐛 **API**: Resolved 404/502 errors by routing Nginx `/api/` traffic to the new Python service.
- 🐛 **Scripts**: Updated `client_banned_ips.sh` to use the new robust blacklist endpoint.
- 🖼️ **Docs**: Fixed broken logo link in README.

## [6.1.0] - 2026-01-08

### Added
- 🚀 **Sidecar Evolution**: Significant upgrades to the `hfish-sidecar-v2` component for professional reconnaissance.
    - **Retroactive Scanning**: Implemented `FORCE_RESCAN` mode to automatically scan the entire historical database of attacker IPs.
    - **Nmap Optimization**: Migrated from slow `-A` scans to high-speed SYN scans (`-sS -sV -F`) with a robust 120s timeout.
    - **Persistence**: Fixed volume mounts and pathing to ensure reports are persistently saved in the `scans/` directory for web visibility.

### Changed
- 🔧 **Infrastructure**: Migrated MariaDB to Port **3307** internally and externally to eliminate conflicts with Honeypot services on Port 3306.
- 🔧 **Networking**: Optimized Sidecar to use Docker Bridge networking (`mariadb:3307`), resolving persistent PyMySQL connection timeouts.

## [6.0.0] - 2026-01-08

### Added
- 📸 **Visuals**: Updated "lemueIO Statistics" screenshot in documentation with the new v6 Dashboard layout.
- 🎨 **Layout**: Complete overhaul of the "Threat Intelligence from the Cloud" widget on the dashboard.
    - **Optimized Columns**: Redistributed column widths (IP 25%, Loc 24%, Type 23%, Risk 14%, Time 14%) for perfect readability.
    - **Robust Rendering**: Enforced Flexbox layout to prevent overflows and scrollbars on parent containers.
    - **Capacity**: Optimized for exactly 26 items per page without vertical scrolling.
    - **Styling**: Restored row separators and refined padding (5px margins).

### Changed
- 🆙 **Major Release**: Version bump to 6.0.0 marking the finalization of the dashboard layout and stability fixes.

## [5.2.0] - 2026-01-05

### Added
- 🛡️ **Active Defense**: Major upgrade to `client_banned_ips.sh` (Python).
    - **SQLite Integration**: Automatically fetches malicious IPs from the local `hfish.db`.
    - **Nmap Reconnaissance**: New IPs are now automatically scanned with Nmap (`-A -T4 -Pn`), results saved to `scans/`.
    - **Deduplication**: Persistent tracking via `processed_ips.txt` to prevent redundant scans and API calls.
    - **Jail Cleanup**: Added feature to check Fail2Ban jails for duplicates and "refresh" them (unban/re-ban) to ensure a clean state.
    - **Robustness**: Improved error handling, lock file management, and logging.

## [4.2.1] - 2026-01-04

### Security
- 🛡️ **Cleanup**: Removed `fix_credentials.sql` and ensured no sensitive credentials are in the repository.

### Maintenance
- 🧹 **Cleanup**: Removed temporary files and abandoned scripts (`README_en_temp.md`, `check_db.py`, `app_debug.js`, `analyze_js.py`, `login_native.html`, `index.html.bak`).
- 🧹 **Assets**: Removed temporary asset dumps (`logo_bear_b64.txt`, `logo_bear_head.b64`).

## [4.2.0] - 2026-01-04

### Added
- Added "Simple German" translation README_DE2.md.

### Fixed
- Fixed mobile login page scrolling issues on small screens.
- Fixed footer overlap on mobile login page.
- Removed duplicate footer injection on login page.
- Updated desktop login footer layout to match mobile (static position under content).

# Changelog

## [4.1.1] - 2026-01-04

### Fixed
- 📱 **Mobile UI**: Fixed Login page scrolling on mobile devices (Footer overlap issue).
- 📱 **Mobile UI**: Converted Login page layout to Flex Column for better responsiveness on small screens.

## [4.1.0] - 2026-01-04

### Changed
- 🎨 **Feed**: Restored functionality with a new **Cyberpunk UI** matching the platform's theme.
- 🖼️ **Assets**: Added new circular "Honey Scan" logo to Feed header.
- 📸 **Documentation**: Updated "Live Threat Feed" screenshot and refined README captions.
- 🐛 **Fix**: Corrected resource paths in `monitor.py` to fix missing Logo and `banned_ips.txt` link on the Feed page.

## [4.0.0] - 2026-01-04

### Added
- 🎉 **Major Release**: Version 4.0.0 marks the complete transition to the **Active Defense Ecosystem**.
- 🌟 **Feature**: Fully Native Login Page (`/web/login`) integrated directly into the HFish core.
    - **Design**: "Honey Scan" Dark Mode Cyberpunk aesthetics.
    - **Security**: Server-side Captcha Validation (`/v1/captcha`).
    - **UX**: Rotation animations, Loading states, and forgotten password modal.
    - **Integration**: Direct API calls to `/v1/login` bypassing legacy routing issues.

### Changed
- 🚨 **Rebranding**: Complete branding overhaul for Login and Dashboard.
- 📸 **Documentation**: Updated all README screenshots, placing the new Login Interface at the top.
- 📦 **Badges**: Added "Forked from hfish/hfish" badge to READMEs.

## [3.8.16] - 2026-01-04

### Fixed
- 🎨 **UI**: Removed unsightly scrollbars from dashboard panels using global CSS override.
- 📊 **Data**: Populated "The recent suspicious CS" panel with mock active defense data (C2/Mining IPs) to demonstrate capabilities.


## [3.8.15] - 2026-01-04

### Fixed
- 🚩 **UI**: Fixed incorrect flag rendering for "Britain" (showing US flag) by adding missing mapping to the Ticker's internal country map.
- 🌍 **Geography**: Added comprehensive country mapping to `web/index.html` to prevent future missing flags.

## [3.8.14] - 2026-01-03

### Fixed
- 🎨 **Layout**: Refined right sidebar overlap fix with a smarter child-count heuristic to correctly identify and constrain the "Recent active hackers" list.
- 🚩 **UI**: Broadened Ticker Flag fix to target all SVGs with potential `fill` attributes, ensuring visibility of color flags in all dashboard components.

## [3.8.13] - 2026-01-03

### Fixed
- 🚩 **UI**: Fixed invisible flags in "Recent Attacks" ticker by removing monochromatic `fill` attribute from SVGs.
- 🎨 **Layout**: Fixed "Cloud Intelligence" overlap on right sidebar by limiting the height of the "Recent active hackers" list.

## [3.8.12] - 2026-01-03

### Changed
- 🎨 **Dashboard**: Reverted dashboard UI to original HFish layout (restored "Cloud Intelligence", Language switch, and original styling) while maintaining critical bug fixes.
- 🎨 **Login**: Preserved custom "lemueIO" login page styling.

## [3.8.11] - 2026-01-02

### Fixed
- 🐛 **Critical**: Fixed syntax error in `index.html` (duplicate function declaration) that prevented UI patches from running.
- 🐛 **Geolocation**: Added **Hardcoded IP Force** for node `23.88.40.46` to guarantee "Falkenstein" location.
- 🐛 **UI**: Expanded "Cloud Intelligence" hiding selector to ensure it is removed.

## [3.8.10] - 2026-01-02

### Fixed
- 🐛 **UI**: Hardened "Cloud Intelligence" hiding script (expanded selector).
- 🐛 **Geolocation**: Refined Node detection logic in frontend patch to specifically target "Germany" nodes and force "Falkenstein".

## [3.8.9] - 2026-01-02

### Fixed
- 🌍 **Geolocation**: Enforced "Active Defense" location (Falkenstein, DE) via generic frontend patch (independent of Node IP).
- 🌍 **Geolocation**: Updated `sidecar` to fetch precise City-level location and refresh it every 10 minutes.
- 🎨 **UI**: Hidden broken "Cloud Intelligence" section from Dashboard.

## [3.8.8] - 2026-01-01

### Fixed
- 🌍 **Geolocation**: Simplified geolocation logic in `monitor.py` to use "Country" (e.g., "Germany") to prevent HFish map mismatches caused by specific city names.
- 🕒 **Timezone**: Corrected frontend time patch from +2h to +1h to resolve the reported -1h mismatch.
- 🚩 **UI**: Expanded country flag mapping to include 50+ additional countries.

## [3.8.7] - 2026-01-01

### Fixed
- 🌍 **Geolocation**: Manually updated DB node record to "Germany" to resolve map displacement.
- 🕒 **Timezone**: Adjusted frontend time patch offset to +2 Hours (CET) to fix persistent -1h mismatch.
- 🚩 **UI**: Fixed flag detection logic to correctly identify country names from sibling elements.
- 🎨 **Docs**: Implemented strict `div align="center"` for all README images and captions.

## [3.8.6] - 2026-01-01

### Fixed
- 🌍 **Geolocation**: Simplified geolocation logic in `monitor.py` to use "Country" (e.g., "Germany") to prevent HFish map mismatches caused by specific city names.
- 🕒 **Timezone**: Injected frontend patch to correct "Recent Attacks" time by +1 Hour (UTC -> CET).
- 🚩 **UI**: Fixed missing country flags in dashboard lists via frontend mapping injection.
- 🎨 **Docs**: Refined image caption alignment in READMEs.

## [3.8.5] - 2026-01-01

### Fixed
- 🐛 **Docs**: Removed duplicate headings in the "Visuals" section of all README files.
- 🎨 **Docs**: Enforced centered alignment for all image captions in documentation.

## [3.8.4] - 2026-01-01

### Security
- 🔒 **Credentials**: Remedied security violation by removing `config/hfish.toml` from git tracking (contained DB password).
- 🔒 **Configuration**: Added `config/hfish.toml.example` with sanitized credentials.
- ⚙️ **Git**: Updated `.gitignore` to exclude sensitive configuration files.

## [3.8.3] - 2026-01-01

### Added
- 📜 **Protocol**: Added `REGO.md` - The "Project Antigravity" System Operating Rules.
- ⚙️ **Workflow**: Formalized automated DevOps workflow for versioning, documentation, and security.

## [3.8.2] - 2026-01-01

### Changed
- 🔧 **Infrastructure**: Moved MariaDB to Host Port **3307** to resolve conflict with Honeypot MySQL service on Port 3306.
- 🔧 **Configuration**: Updated `hfish.toml` to connect to database via `127.0.0.1:3307`.

### Fixed
- 🌍 **Geolocation**: Enhanced Sidecar Monitor (`monitor.py`) with robust public IP fetching (Retries) and fixed Map Geolocation updates.
- ☁️ **Diagnostics**: Added connectivity check for Cloud Intelligence (ThreatBook API) to logs.

## [3.8.1] - 2026-01-01

### Fixed
- 🚑 **Critical**: Fixed blank screen issue on Dashboard/Monitor. Refined `patchBrandingAggressive` script to use safe `innerText` replacement on leaf nodes only, preventing destruction of DOM elements and Event Listeners (React/Vue bindings).

## [3.8.0] - 2026-01-01

### Added
- 📸 **Visuals**: Updated all project screenshots (Feed, SecMonitor, Statistics, Login) with clean, high-quality captures (removed blue borders).
- 📝 **Docs**: Added horizontal rules (`---`) to READMEs for better readability between sections.

### Changed
- 🚨 **Rebranding**: Renamed "HFish Attack Map" to "**lemueIO SecMonitor** (Internal)" in documentation.
- 🚨 **Rebranding**: Renamed "HFish Statistics" to "**lemueIO Statistics** (Internal)" in documentation.
- 🆙 **Minor Release**: Version bump to 3.8.0 reflecting documentation overhaul.

## [3.7.2] - 2026-01-01

### Fixed
- 🎨 **UI**: Removed legacy `mix-blend-mode` from Logo CSS which caused rendering issues with transparency.
- 📝 **Docs**: Fine-tuned README spacing (removed excess top break) for perfect symmetry.

## [3.7.1] - 2026-01-01

### Fixed
- 🎨 **Assets**: Refined Bear Logo with a circular transparency mask to remove black corners.
- 📝 **Docs**: Adjusted README spacing for perfect symmetry around the logo.

## [3.7.0] - 2026-01-01

### Changed
- 🎨 **Branding**: Updated Bear Logo with a new high-quality, sharp version.
- ✨ **Assets**: Regenerated all favicons and documentation images with the new logo.
- 🦸 **Credits**: Huge thanks to **Parameterized7** (he/him) for providing the refined logo assets!

## [3.6.17] - 2026-01-01

### Added
- 📜 **Rules**: Added `PROJECT_RULES.md` containing the "Project Antigravity" system operating rules.
- ⚙️ **Process**: Adopted automated deployment and versioning workflow as per new rules.

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
