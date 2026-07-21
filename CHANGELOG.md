# Changelog

All notable changes to Mping are documented here.
Versioning: `v0.x.0` = feature milestone · `v0.x.y` = bug fix · `v1.0.0` = first commercial release

---

## v0.7.2 — 2026-07-18

### Updates

**Download and install from inside the app**
- The update alert now offers **Download & Install**: Mping downloads the release itself (with a progress sheet and a working Cancel), mounts it, and Finder opens the familiar window showing Mping.app beside an Applications alias to drag it across
- Mping then offers to quit so the running copy can be replaced, since an app can't cleanly overwrite itself while running
- Releases ship a `.dmg` alongside the `.zip`; the updater prefers the DMG and falls back to revealing the zip in Finder for releases published before DMGs existed
- Downloads land in the app's own container, so no additional permissions are required

---

## v0.7.1 — 2026-07-18

### Alerting

**Fibre alerts latch until acknowledged**
- A fibre link that degrades and then recovers on its own — or is repaired mid-show — previously auto-resolved, erasing the alert before anyone necessarily saw it
- Fibre alerts now stay active after the condition clears, still showing the dB value that triggered them, and resolve only once the operator acknowledges them
- Canvas link labels and the inspector's fibre list remain live throughout — only the alert row latches, so you can watch a repair take effect while the alert stands as the record of what happened
- Other categories (disconnect, ping, temperature) still auto-resolve on recovery

**Fibre alert clicks switch to the correct network plane**
- Fibre alerts route through `focusFibreLinkFromAlert`, not `focusDevice`, so they never received the Primary/Secondary tab-switching fix — clicking a secondary-network fibre alert panned the primary plane, where that link isn't drawn, and appeared to do nothing
- Tab switching is now a single shared helper used by every focus path (device, fibre-from-alert, fibre-by-id), so no future path can miss it

### Updates

- The update alert brings Mping to the front before appearing — an automatic check fires ~12s after launch, and the alert previously sat invisible behind other windows if the user had switched away

### Release tooling

- Release zips are built with `zip -X` instead of `ditto`: macOS re-applies `com.apple.provenance` to the executable, so ditto always wrote `._` AppleDouble sidecars into the archive, making the `.app` look missing or damaged when expanded (signature verified intact with the new method)
- Removed `restart-netadapter.bat`, a Windows batch file swept in from another project

---

## v0.7.0 — 2026-07-10

### Alerting

**macOS notifications and Dock bounce**
- When a new alert fires while Mping is in the background, the Dock icon bounces (critically — until the app is activated) and a macOS notification is posted with the category, device, detail, and location
- Clicking the notification activates Mping and pans the canvas to the alerting device
- Fed by the same deduplicated, verification-gated alert pipeline as the sidebar — one condition produces one notification, and false offlines can't reach the Dock; notification permission is requested on the first background alert

**Inspector alerts box**
- Selecting a device now shows its full alert history (active, acknowledged, and recovered) in the inspector — the answer to "why is this tile pulsing yellow" is one click away
- Styled to match the sidebar's History box (state dots, timestamps, category icons, row tints); the border glows yellow while alerts are active

**Alert state resets on workspace switch**
- Opening or creating a workspace clears alert rows, acknowledgements, and caches — alerts never reference devices from a previous workspace; undo/redo deliberately preserves history

### Updates & Distribution

**In-app update checker**
- Mping polls this repository's latest GitHub release on launch and daily; a major/minor version change alerts with a View & Download button, patch releases stay silent but appear via the new **Mping → Check for Updates…** menu item
- Remind Me Later and Skip This Version supported; the check is a single anonymous request to GitHub's public API (adds the app's first direct-network entitlement)

**One-command releases**
- `release.sh` builds a Release archive, verifies the version, zips signature-preserving, extracts the changelog section as release notes, and publishes the GitHub release (with `--dry-run` and `--notarize` modes) — see `Docs/RELEASING.md`
- App category declared for future notarization; README gained an Installing & Updating section and dropped the stale "disable App Sandbox" build note

### Network Routing

**Static routes survive Wi-Fi toggles, sleep, and reboots**
- The routing tool now attaches routes to the network service via `networksetup -setadditionalroutes` instead of raw `route add` — kernel routes were silently flushed by configd on every network transition (Wi-Fi on/off, DHCP renewal, wake), dropping both show networks at once
- Service names are resolved from BSD device names at run time; apply pre-cleans any kernel routes left by the old approach

---

## v0.6.2 — 2026-07-10

### About

- About card now links to the source repository (github.com/therealjackiewelles/Mping)
- Footer tagline removed from the About card

---

## v0.6.1 — 2026-07-09

### Performance

**Alerting fibre link no longer re-renders the window every frame**
- An alerting fibre link started a SwiftUI `repeatForever` opacity pulse, which forced the entire window's display list to re-render at display refresh rate for as long as the alert persisted (~45% CPU on an otherwise idle workspace, any build, whenever the window was visible)
- Removed — alerting links already pulse via their CA dash layers on the render server at zero app CPU, and keep the orange threshold tint
- Example workspace now pins fibre-loss (4.0 dB), ping (100 ms), and jitter (2.0 ms) thresholds alongside the temperature pins, and its fabricated DDM optics were retuned to 0.4–0.6 dB loss (healthy short-run values) — so neither leftover thresholds nor a strict user-set fibre budget (operators go as low as 1 dB) can put demo links into alert

**Splash window leak**
- The launch splash window was hidden with `orderOut` but never closed, leaving its TimelineView and ping-ripple animation rendering every display frame into an invisible window (~40% CPU) — the window is now fully torn down on dismissal

**Demo animator cadence**
- The example workspace animator was updating temperatures, temperature history, and all fibre-port bandwidth values every ping cycle; it now matches real monitoring cadence (RTT/pulse per cycle, bandwidth ~15s, temperature ~30s), so the demo renders no more often than a live workspace

**Compositor load from continuous animations**
- Fibre dash flow now animates as discrete keyframes (~30 steps/s) on a shared clock with a frame-rate hint, instead of continuously interpolating — WindowServer no longer recomposites the canvas at full display refresh (measured ~17–20 → ~6–9 points of WindowServer CPU); alert pulses and the tile pulsing border are capped the same way

### Launch & Splash

**Missing main window fixed**
- Presenting the splash window from `MpingApp.init` (before `NSApplicationMain`) made SwiftUI skip creating the WindowGroup's main window entirely — the app launched with no workspace window until the Dock icon was clicked. The splash now presents from `applicationDidFinishLaunching` via an app delegate, sweeping any already-created windows into hiding
- Handoff hardening: the workspace raises above other apps even when macOS refuses cooperative activation, window registration retries instead of silently giving up, readiness detects unregistered windows, and dismissal raises all app windows as a fallback
- Splash window keeps its exact frame (hosting view wrapped in a container — NSHostingView was shrinking the borderless window off-centre) and the fade-in includes the app name above the tagline and version
- Demo bandwidth labels survive engine restarts (re-seeded on SNMP start; the animator regenerates missing keys)

### Licensing & About

- Proprietary LICENSE.md added (© 2026 Morgan Beecher / MB Technical, all rights reserved) with matching README section and `NSHumanReadableCopyright` in the app bundle
- Clicking the Mping logo or name in the sidebar opens an About card — chromeless rounded window with version, copyright, licence summary, and copyable support contacts; dismisses when clicking anywhere outside it

### Window Management

**Red traffic light quits the app**
- Previously it performed a window close, leaving Mping running headless (still monitoring, still burning CPU) with no window to reclaim — closing the single window now quits; working state is saved on every change so nothing is lost

---

## v0.6.0 — 2026-07-07

### Example Workspace (first launch)

**Demo system with live-looking telemetry**
- First launch now opens a fully populated "Example Workspace": 4 Netgear switches (FOH root bridge, Stage Left/Right, Delay Node) each with a redundant secondary counterpart, plus 3 ping-only access points inside location boxes laid out in audience view (Stage Right left of screen, Stage Left right)
- Fibre topology: FOH → Stage Left, two Stage Left → Stage Right links (one RSTP-blocked redundant path carrying only kbps control-plane traffic), FOH → Delay Node — all with fabricated DDM (≈1 dB loss, SFP temps), LLDP neighbours, STP state, and live bandwidth labels
- New `isDemo` device flag: demo devices are skipped by the ping, SNMP, and bandwidth engines; their telemetry persists inside the `.mpw` instead of being wiped on boot; a demo animator on the ping cycle jitters RTT/temperatures/bandwidth and pulses tiles so everything looks actively monitored without any real network traffic
- Example workspace pins its temperature thresholds at 85°C switch / 90°C SFP so demo telemetry never tints or alerts

### Launch Animation

**Fibre-link splash before the main window**
- Borderless transparent window, exactly centred, shown before the main app window appears; the main window is intercepted and kept hidden (alpha 0 + ordered out, with become-key/main watchers as a safety net) until the animation completes, then fades in
- Two fixed-length green fibre lines — the canvas link style, white flow dashes riding a green line — snake in from below the logo tile, travel up the M's legs, and come to rest completing the M; the dashes then dissolve into the solid white logo M
- After the M turns white, the green ping dot fades in with a repeating expanding ping ripple (as tiles ping in the app) alongside the tagline and version number
- Cinematic timing (~5.4s); click anywhere to skip; profile/frequency/skip options are constants on `LaunchSplashView`
- The finished frame (dot still pinging) holds until the main window is actually created and configured, so the splash always hands off directly to the app — never to an empty desktop; 10s safety cap

### Workspace Files

**Workspaces move to ~/Documents/Mping**
- An "Mping" folder is created in the user's real Documents folder on launch; all `.mpw` files live there — the first-launch example workspace, Default Workspace, and the Save As / Open panel defaults
- Sandbox: a scoped exception entitlement (`Mping.entitlements`, new) grants read-write to just `Documents/Mping/`; macOS asks the standard Documents permission once and remembers it in Privacy & Security
- Existing `.mpw` files are copied across from Application Support on first run (no overwrites, originals kept); if Documents access is denied, everything falls back to Application Support as before
- Transient state (`.mpingstate`) and `Preferences.json` remain in Application Support

### Alerting

**Secondary-network alert focus fix**
- Clicking an alert for a secondary-network device reliably switches to the Secondary tab before panning — the active network tab moved from view `@State` into `DeviceStore`, and `focusDevice` now switches it atomically; the previous second `onChange` observer raced with the focus reset and intermittently never fired

### UI

- Support box in the sidebar beneath the workspace name ("Need support or have a suggestion?") with selectable, one-click-copyable email and phone
- Redundant network tint defaults changed to red/blue at 50% brightness, 10% opacity
- Minimap feature-gated off (`FeatureFlags.minimapEnabled`) — hidden in all workspaces and its Preferences toggle greyed out until ready
- Sidebar header: "Mping" never wraps — the version badge moves to the next row as a unit when the sidebar is narrow (ViewThatFits); "Network Topology Monitoring" and the workspace name scale smoothly with sidebar width
- Sidebar resize handle no longer drags the whole window (`WindowDragCutoff` behind the handle)

---

## v0.5.13 — 2026-07-04

### UI

**Temperature box alert tinting**
- Temperature boxes (temperature-mode box and overview badge) now tint their background to match the alerting text colour — amber within 5°C of the user threshold, red at or above, plain black when normal
- Tint uses a dark shade of the alert colour so text stays readable; respects the tile editor's box opacity with a 0.45 floor so it remains visible at low opacity settings

### Window Management

**Green traffic light — fullscreen**
- Now expands the window to the full screen bounds with the menu bar and Dock auto-hidden; clicking again restores the previous frame
- Native `toggleFullScreen` requires a titled window and consistently produced a blank fullscreen Space when `.titled` was re-inserted at toggle time, so a faux-fullscreen approach is used instead (no styleMask changes, no separate Space)

**Double-click blank space to maximise**
- Double-clicking any blank draggable area zooms (maximises) the window, mirroring native title-bar behaviour — implemented as a `mouseUp` override in `MpingWindowFixer`'s dynamic window subclass
- The super IMP is captured at class-creation time; resolving it at event time recursed through AppKit/KVO re-subclassing and crashed with a stack overflow

**Window drag limited to the sidebar header**
- Background-drag now works only on the header strip (traffic lights, logo, workspace name); everything south of the workspace name opts out via `WindowDragCutoff` (`mouseDownCanMoveWindow = false`)

### Network Routing

**Static route apply fix**
- Route commands are now joined with `;` instead of `&&` — the pre-clean `route delete` exits non-zero when no route exists yet, which short-circuited the chain and silently skipped the `route add` commands on a first apply

### Security

**Debug password no longer stored in plaintext**
- All five debug window controllers now validate against a single SHA-256 digest (`DebugAccess`, CryptoKit) instead of comparing plaintext string literals — the password is no longer discoverable via `strings` on the binary
- Password rotated from the old 7-digit code to a stronger mixed-character password; plaintext also removed from repo docs

---

## v0.5.12 — 2026-07-04

### Window Management

**Drag the window from anywhere on the background**
- The window can now be moved by dragging any non-interactive background area — `isMovableByWindowBackground` enabled on the custom window subclass
- The dedicated `WindowDragArea` strip next to the traffic lights has been removed; the sidebar header (logo, title, workspace name) moved outside the ScrollView so drags register there
- The workspace canvas explicitly opts out (`mouseDownCanMoveWindow = false` on `WorkspaceEventNSView`) so panning, marquee selection, and tile drags never move the window

**Green traffic light now zooms instead of fullscreen**
- The green window button performs a standard macOS zoom (maximise to screen) rather than entering fullscreen mode

### UI

**Temperature mode tile cleanup**
- IP address and device type rows are hidden on tiles in temperature mode, leaving room for thermal data
- Fan speeds now display all 4 slots in a fixed 2×2 grid (two per row), with `---` shown for slots that return no data — replaces the deduplicated `N× RPM` format

---

## v0.5.11 — 2026-07-03

### Temperature & Fan Monitoring

**Dual-sensor temperature alerting**
- Both temperature sensors are now independently evaluated for over-temperature alerts — sensor 1 fires with detail "Sensor 1 XX°C", sensor 2 fires with "Sensor 2 XX°C", each resolvable independently
- Overview tile badge and temperature history graph now reflect the highest of both sensors rather than always sensor 1

**Temperature colour coding tied to user threshold**
- Overview badge, temperature plane status dot, and per-sensor text colour all now scale relative to the user-set alert threshold (Preferences → Alerting)
- Green below threshold − 5°C · Yellow within 5°C of threshold · Red at or above threshold
- Previously hardcoded at 55°C / 70°C regardless of user setting

**Fan speed monitoring — correct OID**
- Fan speeds now polled from the correct Netgear OID (`1.3.6.1.4.1.4526.10.43.1.6.1.4`) — previous OID (`...1.9.1.3`) returned no data on M4250 hardware
- Values are STRING-encoded RPM (e.g. `"2500"`); parser updated to handle string, integer, and unsigned SNMP types
- All 4 fan slots supported in model (`fanSpeed1`–`fanSpeed4`); temperature tile deduplicates identical speeds into `N× RPM` format
- `SwitchTelemetry` and `SwitchTemperatureResult` extended with `fanSpeed3`/`fanSpeed4`; fully Codable with safe defaults

### Window Management

**Auto-resize on external display disconnect**
- When a connected display is removed, Mping now detects the screen configuration change, shrinks the window if it exceeds the remaining screen's bounds, and repositions it to stay fully visible — animated
- Fixes the window being stranded at a size that can't be reached or resized when the display it was sized for is no longer present
- Implemented via `NSApplicationDidChangeScreenParametersNotification` observer in `WindowTitleBarRemover`'s coordinator

### UI

**Version number and Beta label in sidebar**
- App version and "beta" label now shown next to the Mping title in the top-left sidebar
- Version is read from `CFBundleShortVersionString` — updates automatically whenever the version is bumped in Xcode; no manual sync required

---

## v0.5.10 — 2026-07-01

### New Features

**Live bandwidth labels on fibre link lines**
- SNMP-polled actual throughput now displayed mid-link on the topology canvas — one label per direction, running parallel to the link line
- Polls ifHCInOctets / ifHCOutOctets (64-bit counters) every 15 seconds per switch; falls back to 32-bit ifInOctets / ifOutOctets if HC tables are unavailable
- Rate computed as delta octets × 8 / delta seconds (bps), displayed as Gbps / Mbps / Kbps; labels hidden below 50 Kbps to suppress idle-line noise
- Direction indicators use `─▶` / `◀─` (line-with-arrowhead) rendered in the link's colour at 40% opacity; labels rotate to run parallel to each link segment
- New `PortBandwidth` value type in `Models.swift`; `DeviceStore.portBandwidthBps` dictionary keyed by `deviceID-port`; `startBandwidthMonitoring()` / `stopBandwidthMonitoring()` lifecycle tied to SNMP start/stop

**Fibre topology HUD is now per-network in redundant mode**
- When a redundant pair is configured, the top-left fibre HUD filters link count, LLDP connections, and SFP count to only the devices visible on the currently selected network tab (Primary / Secondary)
- In single-network mode the HUD continues to show totals across all devices

**P/S badges moved to before device name on canvas tiles**
- Primary and Secondary role badges now appear inline before the device name in the tile title row rather than as a trailing overlay
- Badge uses the same colour coding (primary = blue, secondary = orange) with a rounded-rect background

**Copper ports excluded from inspector fibre box**
- The fibre loss section in the device inspector now only shows ports with `linkMedium == .fibre`; copper SFP and RJ45 ports no longer appear in the optical loss list

---

## v0.5.9 — 2026-07-01

### Bug Fix

**Left-click device selection broken after right-click context menu**
- After opening the workspace right-click menu and selecting any item, left-clicking device tiles would fail to register — clicks appeared to fall through to the desktop, sometimes minimising the window
- Root cause: `window.styleMask.remove(.titled)` causes `NSWindow.canBecomeKeyWindow` to return `false`, so every call to `makeKey()` / `makeKeyAndOrderFront()` silently no-ops. After an NSMenu closes, AppKit never restores the window's key status, and SwiftUI silently drops all gesture events (tap, drag) on non-key windows
- Fixed by isa-swizzling the window via `MpingWindowFixer` (added to `ContentView.swift`): immediately after removing `.titled`, a dynamic Objective-C subclass of the window's actual runtime class is created with `objc_allocateClassPair`, overriding `canBecomeKeyWindow` and `canBecomeMainWindow` to return `true`, then applied via `object_setClass`
- Window now correctly regains key status on the next click after any NSMenu interaction — tile selection, canvas taps, and drag selection all work immediately

---

## v0.5.8 — 2026-06-30

### Bug Fix

**Title bar reappearing after context compaction**
- `WindowTitleBarRemover` had reverted to the intermediate cosmetic approach (`titlebarAppearsTransparent + titleVisibility.hidden + fullSizeContentView`) which hides the buttons and text but leaves the chrome bar visible
- Restored correct implementation: `window.styleMask.remove(.titled)` — strips the entire NSThemeFrame and reclaims the height as usable screen space

---

## v0.5.7 — 2026-06-30

### New Icon & UI Overhaul

**New app icon — M lettermark**
- Replaced the previous icon with a new M lettermark design: white geometric M on the workspace canvas background (#0E0E0F) with a green status dot and concentric ping rings, matching the app's visual language
- All 10 AppIcon sizes regenerated (16×16 through 1024×1024); MpingLogo sidebar asset updated at @1x/@2x/@3x; README header updated

**Title bar removed**
- Stripped the macOS title bar entirely via `window.styleMask.remove(.titled)` — reclaims the title bar height as usable screen space
- Custom close / minimise / zoom traffic light buttons embedded at the top of the sidebar, matching native macOS colours and showing action icons on hover
- Window drag strip spans the full width of the traffic light row so the window remains draggable

**Device Tile Editor enhancements**
- Per-type editing: Netgear Switch and Ping Only tiles each have their own settings tab with a live preview panel showing a real `MpingMapDeviceTileView` instance with mock data
- Field reordering: ↑↓ buttons in the Netgear settings reorder the top-section fields (Device Name, IP Address, Device Type); order bakes back to source via the existing regex mechanism
- Ping-only tile: height, latency badge size, IP size, padding, corner radius, and spacing all independently configurable
- Fixed slider snap-to-max bug — `DebugSliderControl` was using `UUID()` as its `id`, regenerating on every render and causing `ForEach` to destroy mid-gesture; changed to use `title` as stable ID

**Temperature plane settings propagation fix**
- Changes in the Device Tile Editor were not reflected in the Temperatures plane because `.equatable()` on `MpingMapDeviceTileView` blocked re-renders when only internal `@ObservedObject` state changed
- Fixed by adding `tileSettingsRevision: Int` as an explicit prop, driven by `.onReceive(DeviceTileEditorSettings.shared.objectWillChange)` in WorkspaceView

---

## v0.5.6 — 2026-06-29

### Bug Fixes & Redundant Network Enhancements

**Location box name overwrite when switching boxes**
- Fixed inspector `ShapeInspector` committing the pending title to the wrong box — `onChange(of: shape.id)` now commits to the *old* box ID before syncing from the newly selected one, preventing box A's name from being written onto box B

**Heartbeat ripple not firing simultaneously across all tiles**
- Added `pingPulseID` to `MpingMapDeviceTileView`'s Equatable check — all tiles now re-render in the same SwiftUI pass when `markDevicesAsPinging` fires, producing a synchronised ripple across the canvas instead of per-tile staggering driven by RTT rounding

**Copper ports showing fibre DDM signal strength**
- Fixed port-index mismatch in Netgear DDM table (`1.3.6.1.4.1.4526.10.43.1.18`) — the table is indexed by SFP slot (1, 2, 3…) not ifIndex; column 1 is now walked first to map slot → real port number, so DDM data (TX/RX dBm, temperature) is assigned to the actual SFP uplink ports and never lands on copper ports

**Secondary device PING NIC not saving**
- `updateDeviceInterface` now sets `pingNICConfigured = true` so NIC changes from Inspector and Device Manager both mark the NIC as configured
- New `checkAndCompleteSetupIfReady` helper auto-clears the setup alert once name, IP, and NIC are all set — works from any entry point, not just the Inspector

**Secondary device tiles now mirror primary position**
- `moveDevice` propagates XY coordinates to the redundant peer when a primary device is dragged, keeping primary/secondary tiles co-located at all times; new pairs are placed at `x: primary.x` instead of offset

### Redundant Network Workspace Tinting

- Primary workspace location boxes receive a configurable red tint; secondary workspace boxes receive a configurable blue tint when redundant pairs exist
- New **Redundant Networks** tab in Preferences with `ColorPicker` (with opacity) for each tint and a Reset to Defaults button
- Tint colours are persisted to the `.mpw` workspace file as RGBA arrays and restored on load
- Tinting uses `store.hasRedundantPairs` (not the non-persisted `redundantModeActive`) so colours appear correctly after relaunch

---

## v0.5.5 — 2026-06-29

### Performance — GPU Animation & CPU Reduction (40% → 5% baseline)

Instruments `sample` trace identified the remaining CPU load. All animation hot paths moved off the CPU onto the Core Animation GPU render server.

**Fibre link dash animation (was: TimelineView + Canvas at 20fps CPU)**
- Replaced with `FibreDashAnimatorView` (`NSViewRepresentable`) — one `CAShapeLayer` per link (outer dark + inner light) each driven by `CABasicAnimation(keyPath: "lineDashPhase")` running indefinitely on the render server
- Zero CPU wakeups per frame; the animation runs entirely in the GPU compositor
- Y-coordinate flip applied in path construction to reconcile CALayer's bottom-left origin with SwiftUI's top-left device position space

**Ping ripple animation (was: `@State pulseScale/pulseOpacity` + `withAnimation`)**
- Replaced with `PingRippleLayerView` (`NSViewRepresentable`) — fires a `CAAnimationGroup` (scale 0.45→1.55, opacity→0, easeOut 0.82s) on the GPU render server when `pingPulseID` changes
- Applied to both `MpingMapDeviceTileView` (canvas tile) and `DeviceTileView` (sidebar/inspector tile)
- Eliminates SwiftUI `@State` mutation and view-graph re-evaluation on every animation frame

**SNMP sequential polling (was: `withTaskGroup` concurrent)**
- Replaced with sequential `for` loop — naturally staggers switch polls without adding artificial delay, preventing all switches from hammering the network simultaneously while keeping the effective per-device interval exactly as configured

**`FibreAutoLinkBuilder.buildResults` offloaded to background**
- Moved topology rebuild off MainActor into `Task.detached(priority: .utility)`, eliminating the ~150% CPU spike every SNMP cycle

**`MiniMapView` rewritten as Canvas**
- Replaced per-device SwiftUI view with a single `Canvas` draw pass — eliminates `N` view allocations and their associated SwiftUI layout overhead

**`FibreLinksLayer` Equatable + single TimelineView**
- Added `Equatable` conformance so `.equatable()` suppresses re-renders when device positions and topology are unchanged
- Was: one 60fps `TimelineView` per link; reduced to a single 20fps loop before being replaced entirely by CALayer

---

## v0.5.4 — 2026-06-29

### Dual-NIC Static Route Management

- New **Network Routing** pane in Preferences for managing static host routes on dual-NIC setups
- Apply and Remove buttons copy the `sudo route` commands to the clipboard and open Terminal — avoids macOS Automation permission blocks on unsigned apps
- Apply always runs a remove pass before adding, so stale routes from prior NIC assignments don't accumulate or conflict
- Orange warning note: remove routes before disconnecting a NIC to prevent connectivity loss
- `devicesWithExplicitNIC()` on DeviceStore supplies the route target list

### LLDP Topology Link Matching

- `matchingDevice` now checks `candidate.discoveredName` (LLDP-polled system name) alongside `candidate.name` — devices using **SNMP/LLDP auto-naming** are now correctly matched by the name the switch actually broadcasts, not the user-entered label
- Added chassis MAC fallback: LLDP neighbours that report no system name are now matched against the device's ARP-resolved MAC address, fixing topology links on switches that omit their LLDP sysName
- Fixed STP flow direction vote: `aToB`/`bToA` assignments for the remote-port designated bridge check were inverted, causing incorrect arrow directions on some fibre links
- Added Console Output diagnostic logging for switches with no stored LLDP neighbours and for unmatched neighbours (shows sysName and chassisID) to assist future debugging
- `PulsingBorderView` hit-test now returns `nil` to prevent the pulsing border overlay from intercepting pointer events

---

## v0.5.3 — 2026-06-29

### Performance — CPU Reduction (60% → near zero baseline)

Instruments Time Profiler identified 39% of CPU being spent in SwiftUI's `ViewGraph.renderDisplayList` — caused by `@State`-driven `repeatForever` animations forcing the entire view graph to re-evaluate at 60fps.

**Animation hot paths eliminated:**
- Alert pulse on device tiles (`alertPulse: Bool`) replaced with `CABasicAnimation` on a `CAShapeLayer` — animation now runs entirely in the render server with zero CPU per frame
- Fibre flow dashes (`dashPhase: CGFloat`) replaced with `TimelineView { Canvas }` — 60fps updates now isolated to the Canvas only, parent view graph is never re-evaluated
- Alert panel pulse and inspector setup pulse converted to the same `CALayer` approach
- `PulsingBorderView` created as a reusable `NSViewRepresentable` for all pulsing border animations

**Ping cycle render suppression:**
- `lastSeenOnline` removed from tile Equatable check — it updates to `Date()` on every successful ping, which was forcing all online tiles to re-render every cycle. The tile only displays it when offline, and `status` (which is compared) triggers the re-render at the moment it matters
- `rebuildAlertCaches()` now guards all three `@Published` assignments with equality checks — previously fired `objectWillChange` every ping cycle even when no alerts changed, causing a spurious SwiftUI render pass after each cycle

**Result:** CPU goes from 60% constant to near-zero baseline with short spikes on ping cycle completion.

### New Device Setup Flow (issue #50 — partial)
- New devices default to `requiresSetup = true` and are excluded from ping cycles until Name, IP, and Ping NIC are all configured
- Inspector shows setup banner and pulses unfilled fields red
- Setup auto-completes on focus loss without requiring Enter
- Ping NIC defaults to "Not configured" for new devices
- Multi-select group edit now includes Ping NIC picker

---

## v0.5.2 — 2026-06-28

### Inspector
- Device info section (Name, IP, Type, Zone, NIC) redesigned as compact stat cards matching the sparkline aesthetic — labels above fields, dark backgrounds, IP and Type side by side in one row
- Delete Device moved to the bottom of the inspector with a two-step confirmation panel — warning icon, device name, consequence text, Cancel and Delete buttons
- Delete requires ⌘⌫ keyboard shortcut (was plain ⌫, too easy to trigger accidentally)
- MAC address lookup removed from the ping monitoring section
- Preferences window now accessible via Mping → Preferences… (⌘,) using the standard macOS Settings scene

### Graphs
- Min/max labels moved outside the graph box — max above, min below — so the line never overlaps them
- Temperature graph min/max now reflects the visible 20-sample window, not all-time history
- Both graphs use the same valueFormatter for label text so units are always consistent

### Alerts
- Alternating row shading in both alert popovers for easier cross-column reading
- Device name and event description bold; time, category, port, and acknowledged columns normal weight

### CPU Optimisation
- Alert cache rebuild deferred with `scheduleAlertCacheRebuild()` — coalesces N per-device rebuilds into 1 per ping cycle via Task scheduling
- `lastRTT` rounded to nearest ms in tile Equatable check — prevents re-renders when RTT fluctuates within a 1ms band on stable connections
- `pingPulseID` removed from Equatable (redundant alongside `lastRTT`)

### Code Annotations
- Non-obvious sections annotated: ping verification burst rationale, STP flow direction voting, alert cache deferral, tile Equatable exclusions, `cleanDeviceForPersistence` field contracts, ping batch coalescing, `PanelInteractionBlocker` registry design

---

## v0.5.1 — 2026-06-28

### Alerting
- Alert history box added to the sidebar below the alerting panel — shows the 10 most recent alerts across all categories with time, device, and description on a single compact line
- Clicking the history box opens a full history popover with all alerts, a Category column, colour-coded rows (red = active, green = recovered, grey = acknowledged), and the same paginated load-more pattern as the per-category popover
- Clicking any alert row in either the per-category popover or the full history popover now focuses the device: the popover closes, the inspector opens, the canvas pans to centre the device, and the tile flickers white for 5 seconds
- Canvas pan on focus correctly accounts for the inspector panel width so the device lands in the centre of the visible canvas area, not behind the inspector — inspector width is stored in DeviceStore and ready for a variable-width inspector in future
- Sidebar click-through fixed — device tiles that have panned underneath the sidebar can no longer be accidentally clicked through it
- Alert descriptions shortened across all categories: Offline, RTT 1423 ms (limit 100 ms), Jitter 2.34 ms (limit 2.0 ms), 74°C, SFP 78°C, 3.2 dB, No Link, Recovered
- Device disconnect icon changed from wifi slash to network.slash
- Full history popover: Category column widened to fit "Device Disconnect" without truncating; Time column left padding increased for breathing room; column alignment fixed

---

## v0.5.0 — 2026-06-28

### Workspace View Switcher
- Plane switcher added at the bottom of the canvas — switch between **Overview** (full canvas) and **STP** view without losing your zoom or pan position
- **STP plane** shows a dedicated read-only view of the spanning tree topology: root bridge highlighted in gold, switches with blocking ports in amber, active links with flow animation, blocking links in orange dashed style
- STP plane includes a legend (Root Bridge / Active Link / Blocking Link) and supports scroll-to-zoom and right-drag-to-pan
- Architecture: one Swift file per plane under `Workspace/Planes/`, coordinated by `WorkspacePlaneCoordinator`

### STP Flow Direction Fixes
- Flow direction now voted from both sides of each link independently — resolves cases where one link was consistently animated the wrong way due to a port-numbering mismatch on one switch
- Flow direction changes are now debounced across 2 consecutive SNMP polls before being committed — eliminates oscillation (back-and-forth animation) during STP reconvergence after a link state change

### Sidebar Cleanup
- Minimap toggle moved to Preferences (was already there — removed duplicate from sidebar)
- Clear Links on Boot moved to Preferences (was already there — removed duplicate from sidebar)
- Zoom slider removed from sidebar
- Snap to Grid controls removed from sidebar
- Fibre Box Opacity slider moved to Fibre Box Editor in Debugging tools
- Fibre box opacity default changed to 100%

---

## v0.4.1 — 2026-06-27

### Inspector
- Temperature history converted to a sparkline graph — matches the ping graph layout exactly
- Temperature graph shows a 20-point sliding window, filling right to left as new samples arrive
- Hover over any data point in the ping or temperature graph to see a tooltip with the exact value and timestamp
- Stat cards updated: Min, Avg, Max shown for both ping and temperature (Current card removed — live value already visible in the section header)
- Temperature values now display to 2 significant figures (e.g. 55°C, 7.8°C)
- Jitter stat card height fixed — now matches the other cards in the same row

### Debugging
- Device Debug: "Root Bridge ID" renamed — on the root bridge shows "Root Bridge MAC" (correct), on other switches shows "Own Chassis MAC" (accurate — it was always this switch's own MAC, not the root bridge's MAC)

---

## v0.4.0 — 2026-06-27

### STP / RSTP Root Bridge Detection
- Root bridge identified via SNMP — compares LLDP chassis ID against per-port designated bridge MACs across all switches
- The switch where all active ports designate themselves as the upstream bridge is confirmed as root
- Root bridge displays a yellow **ROOT** badge in the top-right corner of its tile
- Fixed: OctetString binary values (MAC addresses, bridge IDs) now correctly decoded as hex by the SNMP client

### Fibre Link Flow Animation
- All active (non-blocking) fibre links now show animated grey rectangular dashes flowing toward the root bridge
- Direction determined per-link using the STP designated bridge MAC for each port — topologically correct for every link
- Grey dashes with black border for clear visibility against the coloured line
- Blocking links retain the dashed orange style with no flow animation
- Fibre link lines made thicker across all signal states

### Bug Fixes
- CSV event log files excluded from Xcode project via `.gitignore` (were causing build errors)
- Binary OctetString SNMP values no longer silently dropped — encoded as colon-separated hex

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
