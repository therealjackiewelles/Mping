# Changelog

All notable changes to Mping are documented here.
Versioning: `v0.x.0` = feature milestone · `v0.x.y` = bug fix · `v1.0.0` = first commercial release

---

## v0.3.3 — 2026-06-27

### Fibre Topology
- Fibre label tiles now correctly show each switch's own data at its own end of the link (was reversed)
- When devices are moved close together, fibre label tiles slide back along the link toward their device
- When there is not enough room for both label tiles, they hide cleanly rather than snapping to a random position
- Label tiles never overlap device tiles — they disappear when the gap becomes too small

### Ping-Only Device Tiles
- Ping-only devices (amps, computers, etc.) now use a compact half-height tile
- Tile shows device name, ping RTT badge, and IP address — no device type label
- IP address moved next to the RTT badge for a cleaner layout

### Web Interface
- Default URL prefix for Netgear switches changed from `http://` to `https://` (port 49152 requires HTTPS)
- Fixed URL suffix (`webInterfacePath`) not persisting across restarts — was being reset to blank on every boot
- Prefix correctly applied when opening web interface from right-click menu
- Empty prefix fields now fall back to `https://` rather than producing malformed URLs
- Preferences window scaffolding built (disabled for now — browser security blocks URL-embedded credentials)

### Infrastructure
- `KeychainHelper` added for future secure credential storage (macOS Keychain integration)
- `PreferencesView` built with General and Switch Credentials tabs (disabled pending auto-login solution)

---

## v0.3.2 — 2026-06-26

### UI Polish
- Devices with active unacknowledged alerts pulse with a yellow border on the workspace canvas
- Pulse matches the alerting sidebar timing (1.4s ease-in-out)
- Yellow border fades out in 0.3s when alerts are acknowledged
- Workspace background pulse removed in favour of per-device indication

---

## v0.3.1 — 2026-06-26

### UI Polish
- Workspace background pulses red when any alert is active, matching the alerting sidebar panel
- Pulse fades out smoothly when all alerts are acknowledged

---

## v0.3.0 — 2026-06-26

### Monitoring
- Packet loss % tracked per ping cycle with colour-coded display in inspector
- Jitter measurement (average RTT variance) with AVB/Milan-aware thresholds and alert integration
- Uptime counter tracking continuous online duration since last recovery
- Jitter alert fires through the Ping RTT alert box with configurable threshold (default 2.0 ms)
- Per-device ping monitoring toggle — exclude specific devices from all ping cycles
- Per-device SNMP/LLDP monitoring toggle — exclude specific Netgear switches from telemetry polling
- Monitoring and Minimap toggles now persist across boots

### STP / RSTP
- RSTP blocking links detected via FASTPATH CST port role OID on Netgear switches
- Blocked inter-switch links rendered as dashed orange lines on the topology canvas
- STP polling added to SNMP cycle — 4 dead legacy OID calls removed after investigation
- Root bridge detection deferred pending a reliable distinguishing OID (tracked in issue #44)

### Inspector
- RTT sparkline graph showing last 60 samples with min/max labels
- MAC address display with on-demand ARP lookup
- Zone name field for device grouping
- Packet loss %, jitter, uptime and sample count stat cards
- Monitoring controls (Ping / SNMP toggles) at top of inspector
- Switch SNMP section removed — data available in Device Debug
- Inspector now renders as a permanent overlay — eliminated 500ms tap delay caused by `refreshNetworkInterfaces()` on appear

### Workspace
- Zone colour system — coloured left-strip indicator on tiles, colour derived from zone name
- Search bar in sidebar filtering by name, IP or zone — non-matching tiles dim
- Right-click on device tiles shows device-specific context menu: Open Web Interface, Select, Copy, Cut, Duplicate, Paste, Delete
- Right-click on empty canvas shows workspace menu (unchanged)
- Clicking a selected device deselects it
- Double-tap to open web interface removed (was causing 500ms tap delay)
- Inspector rendered as permanent overlay — no layout shift on tile selection

### Device Manager
- Rebuilt as NSTableView with resizable and reorderable columns
- Column order and widths saved to AppPreferences and persist across boots
- Auto-scales to screen size with horizontal and vertical scrollbars
- URL Prefix column added (e.g. `http://` or `https://` per device)
- SNMP Community column added
- Web UI Path renamed to URL Suffix
- Editable fields render with rounded bezel so user knows they're interactive
- Name field locks when SNMP/LLDP auto-naming is enabled

### Group Edit
- Select multiple devices to bulk-set zone, device type, SNMP community, ping and SNMP monitoring
- Only fields the user edits are applied — blank fields are ignored

### Debugging
- Device Debug window (password protected) showing internal monitoring state per device
- Event log CSV export from Console Output window
- Console Output: Export CSV button added

### Bug Fixes
- Last Seen resets to nil on boot, shows "Never Seen" for devices not yet online
- Fixed "Timeout" showing on offline tiles — bug was in `MpingMapDeviceTileView` not `DeviceTileView`
- Tile Equatable conformance updated to include `lastSeenOnline` and `verificationState`
- Alerting box no longer resizes during pulse animation
- False "no optical signal" alert suppressed on boot for stale remembered links
- Stale topology links not replaced by live LLDP links — fixed via canonical endpoint matching
- Duplicate topology links accumulating on each boot — fixed
- Sidebar content no longer overlaps when window is resized small

### Performance
- Ping results batched into a single SwiftUI render pass per cycle (was one pass per device)
- Removed `pingRTTHistory` array from tile Equatable check — eliminated O(120) comparison per tile per ping
- Removed `ifConnectorPresent` SNMP walk — returned unmappable data
- Removed 23 `print()` calls from SNMP probes
- Removed 4 dead STP OID calls per switch per poll confirmed as always returning empty data

---

## v0.2.0 — Earlier 2026

### Stable
- ICMP ping monitoring with verification engine
- Workspace canvas with drag-and-drop devices and location boxes
- SNMP/LLDP telemetry for Netgear AV switches
- Fibre link visualisation with SFP DDM loss and temperature
- Inspector panel
- Minimap
- Alerting framework (Fibre Loss, Ping RTT, Device Disconnect, Over Temperature)
- Device Ports view
- Workspace persistence (`.mpw` + `.mpingstate`)
- Console Output debug window

---
