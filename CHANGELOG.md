## [8.13.0] - 2026-01-13

### 🚀 Minor Release: Expanded Monitoring & Sidecar Reliability
- **Stable Milestone**: Updated project version to `8.13.0`.
- **Client Shield (v4.1.0)**:
  - 👁️ **Omniscient Monitoring**: `banned_ips.sh` now automatically detects and monitors logs from:
    - **Nginx Proxy Manager** (Docker): Standard `/data/logs/` paths.
    - **FRPS** (Native): `/var/log/frps.log`.
    - **Nginx** (Docker): Standard access logs.
  - 📊 **Dynamic Reporting**: The status summary now dynamically lists ALL active Fail2Ban jails (including default `sshd`, `honey-frps`, `honey-npm`, etc.) with perfect column alignment.
  - 🎨 **UX**: Improved CLI output with `printf` alignment for a cleaner status report.
- **Sidecar (Reliability)**:
  - 💾 **Offline Caching**: Implemented a robust "Store-and-Forward" queue mechanism. If the Remote API or Webhook is down, threat data is saved to disk (`./queue`) with a 72h TTL.
  - 🔄 **Auto-Retry**: The Sidecar automatically processes the offline queue when connectivity is restored, ensuring zero data loss during outages.
  - 🛡️ **Flood Protection**: Added throttling to the retry mechanism to prevent API swamping after downtime.

## [8.12.0] - 2026-01-11

### 🚀 Minor Release: Strict Whitelist & Logic Refinement
- **Beta Release**: Updated project version to `v8.12.0 beta`.
- **Core Logic**:
  - 🛡️ **Strict Port Whitelist**: Implemented comprehensive "Zero-Action" policy for whitelisted ports (2222, 4435, 8888). IPs solely targeting these ports now bypass **all** actions: no Nmap scan, no Geolocation, no Traceroute, and no database enrichment. They are completely ignored.
  - 🧠 **Smart Banning**: Refined `monitor.py` logic to distinguish between "Internal Bridge Sync" (Sidecar/Agent noise) and real "Global Threats" (Bridge Sync).
  - 🚫 **Fail2Ban Enforcement**: Hardened logic to ensuring IPs labeled as `FAIL2BAN` or `BRIDGE_SYNC` (External) are banned immediately even if no granular scan data exists yet.
- **Client Script**:
  - 📦 **Versioning**: Bumped `banned_ips.sh` to version `2.9.5`.
  - 🐜 **Fix**: Resolved loophole where known administrative IPs could be banned due to lack of scan data ("Unknown" state).
  - 🔧 **Hotfix**: Restored missing database connection function in `monitor.py` preventing crash loop.
  - 🏳️ **Feed Fix**: Added missing flag mapping for South Korea (KR).

## [8.11.0] - 2026-01-11

### 🚀 Minor Release: Search Engine & Roadmap Expansion
- **Stable Milestone**: Updated project version to `8.11.0`.
- **Search Engine**:
  - ⚡ **Performance**: Implemented client-side caching and search, offloading logic from the backend.
  - ⌨️ **UX**: Search now triggers on **Enter** (removing laggy live-typing).
  - 🧩 **Wildcards**: Added support for `*` wildcards (e.g., `192.168.*`) for flexible IP filtering.
  - 🔧 **Compatibility**: Removed `mb_convert_encoding` dependency in favor of `html_entity_decode`.
- **Roadmap**:
  - 🗺️ **New Goals**: Added 5 major strategic pillars to `ROADMAP.md`:
    - 🐬 Flipper Zero Integration (Companion App & Sync).
    - 🔄 Bidirectional API Synchronization.
    - 🔬 Internal Node Consistency Checks.
    - 🍓 Portable Raspberry Pi Edition (Mobile UI).
    - 🥚 Community Easter Egg (CTF/Puzzle).

## [8.10.0] - 2026-01-11

### 🎨 Minor Release: Feed Layout & Mobile Polish
- **Stable Milestone**: Updated project version to `8.10.0`.
- **Feed UI**:
  - 📏 **Desktop**: Enforced explicit `1fr 2.5fr` grid layout and equal height for "Active Scans" and "Top 10" boxes.
  - 📱 **Mobile**: Implemented responsive stacking (single column) for analytics boxes and country lists to prevent overlap.
  - 🔠 **Typography**: Adjusted responsive font sizes for the main counter to prevent overflow on small screens.
  - 🚩 **Flags**: Added support for **Reunion (RE)** flag.

## [8.9.1] - 2026-01-11

### 🔧 Fix: Dashboard Caching
- **Web**: Disabled server-side caching for the main Feed dashboard (`index.php`) to ensure real-time updates and immediate visibility of code changes. Static assets remain optimized via `.htaccess`.

## [8.9.0] - 2026-01-11

### 🚀 Minor Release: UX & Performance Polish
- **Stable Milestone**: Consolidated all recent Feed enhancements into a stable minor release.
- **UI Finalization**: Active Scans counter is now supersized (**4.5rem**) and perfectly centered.
- **Search Experience**: Smart grouping logic (triggers at 2 octets) and comprehensive flag support (200+ countries).
- **Core Optimization**: Enabled Apache-level caching and compression for maximum performance.

## [8.8.5] - 2026-01-11

### 🎨 UI Refinement: Active Scans Size
- **Feed**: Increased the "Active Scans" font size by another 50% (to **4.5rem**) for even greater visibility.
- **Feed**: Corrected a CSS typo in the analytics card styles.

## [8.8.4] - 2026-01-11

### 🎨 UI Refinement: Active Scans
- **Feed**: The "Active Scans" analytics box is now perfectly centered (vertically and horizontally) and the count font size has been **doubled** (3rem) for better visibility.

## [8.8.3] - 2026-01-11

### ⚡ Performance: Caching Engine
- **Web**: Explicitly enabled `mod_deflate`, `mod_expires`, and `mod_headers` in the Feed container. This ensures that the `.htaccess` rules for Gzip compression and browser caching are correctly enforced, significantly reducing load times for assets.
- **Search**: Refined search grouping trigger to **2 octets** (e.g., `47.107` now groups by country).

## [8.8.2] - 2026-01-11

### 🔧 Fix: Search Grouping Trigger
- **Web**: Grouping by country in search results now only triggers after entering at least **3 octets** (e.g., `47.107.166`). Searching by only one or two octets (e.g., `47.`) now provides a plain, non-grouped list as requested.

## [8.8.1] - 2026-01-11

### 🔧 Fix: Dynamic Flags & Permissions
- **Web**: Resolved "Permission denied" error for report metadata caching.
- **Web**: Added comprehensive support for **200+ country flags** using Regional Indicator symbols.
- **Web**: Improved "The Netherlands" mapping and other regional identification.

## [8.8.0] - 2026-01-11

### 🚀 Minor Release: Feed Analytics & UX Overhaul
- **Stable Milestone**: Updated project version to `8.8.0`.
- **Features**:
  - 📊 **Deep Analytics**: Expanded Top 3 to **Top 10** threats in the feed, with improved percentage tracking and grid layout.
  - 🌍 **Categorized Search**: Reports are now automatically grouped by country when searching (3+ characters), featuring flag emojis for each origin.
  - ⚡ **Performance Engine**: Implemented server-side metadata caching and web server optimization via `.htaccess` (Gzip, Expires headers).
  - 🚩 **Global Flags**: Comprehensive country-to-emoji mapping for real-time visibility.

### 🛡️ Banning Client v2.9.1
- **Proactive Whitelisting**: The client script now automatically removes (unbans) IPs from the Fail2Ban jail if they are no longer present in the remote threat feed. This ensures immediate propagation of whitelisting decisions to all standalone nodes like `lemue-io`.

## [8.7.1] - 2026-01-11

### 🚀 Minor Release: Feed Intelligence & Analytics
- **Stable Milestone**: Updated project version to `8.7.0`.
- **Features**:
  - 📊 **Feed Analytics**: Added a new "Real-time Analytics" box to the `/feed` page, showing the Top 3 threat origin countries from the last 30 minutes with counts and percentages.
  - 🛡️ **Status Accuracy**: Improved the "Check My Status" logic in the feed to use exact line matching against `banned_ips.txt`, preventing partial IP match false positives.
  - 🔍 **Audit**: Verified scan and geolocation coverage across sensor nodes (`lemue-sec`, `lemue-sec-2`).

## [8.6.0] - 2026-01-11

### 🚀 Minor Release: Feed & Update Resilience
- **Stable Milestone**: Updated project version to `8.6.0` (Client v2.9.0).
- **Features**:
  - 🔄 **Backup Sources**: Added GitHub repository as a fallback source for both the IP feed and the client script itself, ensuring continuity even if `feed.sec.lemue.org` is unreachable.
  - 🛡️ **Failover Logic**: Intelligently retry-and-fallback logic in `banned_ips.sh` that automatically switches to the backup source after primary failure.
  - 📂 **Repository Feed**: Integrated `feed/banned_ips.txt` into the repository to serve as a high-availability backup source.

## [8.5.0] - 2026-01-11

### 🚀 Minor Release: Sidecar Resilience & Logging Fixes
- **Stable Milestone**: Updated project version to `8.5.0`.
- **Features**:
  - 🛡️ **Sidecar Resilience**: Resolved an infinite re-scan loop by ensuring a report is written even on scan failure/timeout.
  - 🔍 **Logging Restored**: Fixed a critical logging issue where monitor logs were silenced. Restored full visibility for `[SCAN]`, `[SYNC]`, and `[MAINTENANCE]` actions.
  - 🚀 **Performance**: Moved bridge synchronization to an asynchronous background thread pool with concurrency locking to prevent main loop blocking.
  - 🔧 **Git History**: Standardized repository commit history for consistent contributor identity.

## [8.4.0] - 2026-01-11

### 🚀 Minor Release: Enhanced Resilience
- **Stable Milestone**: Updated project version to `8.4.0` (Client v2.8.0).
- **Features**:
  - 🔄 **Retry Logic**: Added robust retry mechanisms (`--retry 3`, `--retry-delay 5`) to `banned_ips.sh` for both feed downloads and auto-updates, significantly improving reliability over unstable connections.
  - 🦊 **Git Identity**: Introduced `.gitaccounts` for managing contributor identities.

## [8.3.0] - 2026-01-11

### 🚀 Minor Release: Reliability & Standardization
- **Stable Milestone**: This release consolidates all recent reliability fixes for the client banning script (`banned_ips.sh` v2.7.0).
- **Features**:
  - 🔄 **Reliable Auto-Update**: Fixed URL mismatches and added timeout/empty-file validation logic.
  - 🎨 **Visuals**: Added periodic logo display and updated branding.
  - 🧹 **Standardization**: Restored canonical filenames and cleaned up deprecated scripts.
  - 🔍 **Debugging**: Enhanced logging capabilities for easier troubleshooting.

## [8.2.7] - 2026-01-11

### Changed
- ♻️ **Refactor**: Renamed `scripts/client_banned_ips.sh` back to the standard `scripts/banned_ips.sh` to match the canonical filename.
- 🐛 **Auto-Update**: Updated `SCRIPT_URL` to correctly point to `banned_ips.sh`.
- ⬆️ **Update**: Bumped client script version to `2.7.0`.

## [8.2.6] - 2026-01-11

### Fixed
- 🐛 **Auto-Update**: Fixed incorrect update URL in `client_banned_ips.sh` (it was pointing to a deprecated file).
- 🧹 **Cleanup**: Deleted obsolete `scripts/banned_ips.sh` to prevent confusion.
- 🔍 **Debugging**: Enabled verbose logging (`DEBUG_UPDATE=true`) for the auto-update process to help diagnose issues.
- ⬆️ **Update**: Bumped client script version to `2.6.9`.

## [8.2.5] - 2026-01-11

### Changed
- 🎨 **Visuals**: Implemented periodic logo display in `client_banned_ips.sh` (appears every 50 IPs during banning loop).
- ⬆️ **Update**: Bumped client script version to `2.6.8`.

## [8.2.4] - 2026-01-11

### Security
- 🛡️ **Script**: Implemented validation checks in `client_banned_ips.sh` to reject empty files during feed download and auto-update.
- ⬆️ **Update**: Bumped client script version to `2.6.7`.

## [8.2.3] - 2026-01-11

### Fixed
- 🐛 **Script**: Extended timeout logic to the self-update mechanism in `client_banned_ips.sh` for higher reliability.
- ⬆️ **Update**: Bumped client script version to `2.6.6`.

## [8.2.2] - 2026-01-11

### Fixed
- 🐛 **Script**: Added timeout and improved error handling for feed download in `client_banned_ips.sh` to prevent hanging.
- ⬆️ **Update**: Bumped client script version to `2.6.5`.

## [8.2.1] - 2026-01-11

### Changed
- 🎨 **Visuals**: Updated `client_banned_ips.sh` logo to match the new "Honey Sec" design (Yellow).
- ⬆️ **Update**: Bumped client script version to `2.6.4`.

## [8.2.0] - 2026-01-11

### Added
- 🎨 **Logging**: Enhanced sidecar logging with ANSI colors (`[SCAN]`, `[SYNC]`, `[GEO]`) replacing emojis.
- 💛 **Visuals**: Added yellow "Honey Sec" ASCII logo on startup (`hsec_ascii.logo`).
- 🔇 **Silence**: Silenced verbose SQL query logging in sidecar logic.
- 🚦 **Status**: Added granular status tracking and detailed logs for all major operations.

### Changed
- 🔧 **Git**: Corrected repository commit history author.

## [8.1.0] - 2026-01-11

### Added
- 🌍 **Geolocation**: Sidecar now resolves attacker location (Country, City, Lat/Lng) and embeds it in scan reports.
- 🚦 **Scan Logic**: Separated scan status into `ipscan` and `geoscan` columns for granular tracking.
- ✨ **Optimization**: Intelligent logic to skip redundant scans if a valid report and location already exist.
- 🗂️ **Feed Sorting**: Feed reports are now sorted by date (newest first) for better visibility.
- 📱 **Mobile Layout**: Responsive list view for feed reports on mobile devices.
- 🧹 **Cleanup**: Removed unused legacy scripts and docs to reduce repository size.
- 🗺️ **Roadmap**: Added `ROADMAP.md` to track future ideas.

## [8.0.2] - 2026-01-10

### Changed
- 🎯 **Configuration**: Reverted Fail2Ban configuration target in `banned_ips.sh` back to `/etc/fail2ban/jail.d/defaults-debian.conf` as per user requirement for standard installation compatibility.
- 🧹 **Cleanup**: Added auto-cleanup logic to remove valid but now deprecated `99-honey-scan.conf` to prevent configuration conflicts.
- 📦 **Versioning**: Bumped `banned_ips.sh` to version 2.6.5.

## [8.0.1] - 2026-01-10

### Fixed
- 🐛 **Persistence**: Updated `banned_ips.sh` to write Fail2Ban configuration to `/etc/fail2ban/jail.d/99-honey-scan.conf` instead of `defaults-debian.conf`. This prevents system updates or restarts from resetting the configuration to defaults.
- 📦 **Versioning**: Bumped `banned_ips.sh` to version 2.6.4.

## [8.0.0] - 2026-01-10

### Changed
- 🧹 **Cleanup**: Massive repository cleanup. Removed unused legacy scripts (`client_banned_ips_no_update.sh`, `fix_cache.sh`, `verify_api.sh`), debug tools, and temporary data dumps to ensure a clean distribution.
- 📜 **Documentation**: Updated all README files (EN, DE, UA, DE2) with comprehensive feature lists including Auto-Update configurations, Persistence logic, and Whitelist preservation.
- 🛡️ **Scripts**: `banned_ips.sh` promoted to v2.6.3.
    - **Persistence**: Implemented jail refresh logic to ensure bans stick even after service restarts.
    - **Whitelist**: Added robust whitelist preservation to prevent accidental banning of admin IPs during flush operations.
    - **Auto-Update**: Refined self-update mechanism with version checking and checksum validation.

## [7.8.0] - 2026-01-10

### Changed
- 🚀 **Major Firewall Upgrade**: Replaced default `nftables-allports` action with a custom `honey-nftables` action. This new implementation ensures **TRUE Layer 3 blocking**, effectively stopping both TCP and UDP traffic from banned IPs. This resolves issues where system defaults were silently restricting bans to TCP only.
- 🔄 **Reliability**: Scripts now enforce a full `service fail2ban restart` instead of a reload, ensuring that old configurations (like default `sendmail` actions) are completely cleared from memory.
- 🛠️ **Configuration**: Redundant `banaction` definitions added to `defaults-debian.conf` overrides to prevent Fallback-to-Default behavior on some Debian/Ubuntu versions.

## [7.7.9] - 2026-01-10

### Added
- ✨ **Network**: Introduced custom `honey-nftables` action for Fail2Ban. This replaces the default OS `nftables-allports` action, which was found to restrict bans to TCP only on some systems. The new action enforces Layer 3 blocking (Reject all protocols) for banned IPs, ensuring both UDP and TCP traffic are stopped.

## [7.7.8] - 2026-01-10

### Fixed
- 🔄 **Service**: Switched from `fail2ban-client reload` to `service fail2ban restart` (with systemctl fallback). This ensures that "ghost" actions (like standard `sendmail` configured by distros) are properly cleared from memory and replaced by our custom `nftables-allports` configuration.
- ⚙️ **Config**: Added redundant `banaction = ...` definition to the jail override to ensure Fail2Ban correctly maps the ban logic even if the `action` line is complex.

## [7.7.7] - 2026-01-10

### Fixed
- 🔨 **Compatibility**: Removed parameters from `nftables-allports` action definition. This fixes an issue where some Fail2Ban versions would fail to load the action if `[name=..., port=...]` arguments were passed to an all-ports action, causing it to fall back silently or fail.

## [7.7.6] - 2026-01-10

### Changed
- 🎯 **Configuration**: Switched Fail2Ban override target to `/etc/fail2ban/jail.d/defaults-debian.conf`. This location is user-confirmed to work reliably on target systems.
- 🧹 **Cleanup**: The script now strictly overwrites this file (delete & recreate) to ensure no conflicting legacy configurations remain.

## [7.7.5] - 2026-01-10

### Fixed
- 🐛 **Scripts**: Enhanced `jail.local` detection logic to specifically check for the `action =` definition. If a previous version created an incomplete config, version 2.5.5 will now correctly detect this and apply the full fix, ensuring the firewall (`nftables-allports`) is active.

## [7.7.4] - 2026-01-10

### Changed
- 🧪 **Scripts**: Verification bump to version 2.5.4 to confirm update propagation.

## [7.7.3] - 2026-01-10

### Changed
- 🛠️ **Scripts**: Explicitly define `action = %(action_mwl)s` in `jail.local` (conditionally apending `hfish-client` if available). This ensures that the configured `banaction` (firewall blocking) is always activated, even if external defaults try to disable it.
- ℹ️ **Logs**: Added `Auto-Update` status to script log header.

## [7.7.2] - 2026-01-10

### Changed
- 🛠️ **Scripts**: Updated configuration logic to conditionally add `hfish-client` action to `jail.local` only if the action file `/etc/fail2ban/action.d/hfish-client.conf` is present. This prevents errors on clients that do not have the monitoring extension installed.

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
