# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Build

There is no CLI build system. All builds are done in **Xcode** by the developer. There are no tests, no linting commands, and no CI pipeline. When code changes are made, the developer builds locally and reports any compiler errors back for fixing.

> **Never tell the developer to manually edit code.** Always produce complete replacement files. If multiple files change, produce all of them. The developer replaces files manually and builds in Xcode.

---

## Architecture

### Single-Process macOS SwiftUI App

Mping is a single-window macOS application written entirely in Swift/SwiftUI with AppKit bridging where needed. There is one entry point: `MpingApp.swift`.

### Central Store: `DeviceStore`

`DeviceStore` (`Workspace/DeviceStore.swift`) is a `@MainActor`-bound `ObservableObject` and is the single source of truth for the entire application. It owns:

- `devices: [MonitoredDevice]` — all monitored devices
- `shapes: [WorkspaceShape]` — location box shapes on the canvas
- All alert events, fibre results, temperature history, selection state, workspace scale/offset, undo/redo stacks, and all alert thresholds

Every update to device data goes through `DeviceStore.updateDeviceRuntime(id:update:)` — a private mutating helper that locates the device by ID and applies a closure. All public `updateDevice*` functions call this internally.

### Data Model: `Models.swift`

`MonitoredDevice` is a `Codable` value type (`struct`) with a large number of fields spanning identity, ping state, telemetry, and user preferences. Key design decisions:

- **Runtime fields** (ping history, lastSeen, MAC, currentOnlineSince, loss history) are reset on boot via `cleanDeviceForRuntime(_:)` in DeviceStore
- **User fields** (name, IP, zone, deviceType, snmpCommunity, webInterfacePrefix, webInterfacePath, pingMonitoringEnabled, snmpMonitoringEnabled) persist across saves
- `MonitoredDevice` has a manual `CodingKeys` enum and manual `init(from decoder:)` — all new fields must be added to both, using `decodeIfPresent` with a safe default

`SwitchTelemetry` is a nested struct (manual Codable) storing SNMP/LLDP data. `WorkspaceShape` is a simpler codable struct for the canvas location boxes.

### Persistence

Two separate files are written to `~/Library/Application Support/Mping/`:

1. **`Default Workspace.mpw`** (or user-named) — the workspace JSON (`PersistedWorkspace`), containing devices and shapes. Saved on every meaningful change via `markWorkspaceDirty()` → debounced write.
2. **`Working Workspace.mpingstate`** — a transient state file (`PersistedWorkingState`) capturing the current unsaved state on every change, used to restore exactly where the user left off on next launch.

User preferences (sidebar width, column orders/widths for Device Ports and Device Manager, port filter state) live in `Preferences.json` via `AppPreferences` (singleton `@MainActor` class, `User Prefs/AppPreferences.swift`). Simple booleans (monitoring toggle, minimap toggle) use `UserDefaults` / `@AppStorage` directly.

Alert thresholds are stored in `UserDefaults` directly on `DeviceStore` via `persistedAlertThreshold(key:defaultValue:)`.

### Monitoring Engines

**Ping loop** (`startPingCycleWithoutBlockingTimer()`):  
Runs on a `Task` with a configurable interval. Filters devices by `pingMonitoringEnabled && !isPinging && no active verification task`. Dispatches one `PingEngine.ping()` call per device concurrently. Results return on `MainActor`.

**Verification** (`PingVerificationEngine.swift`):  
When a ping fails (potential offline), a verification burst fires (4 pings by default). If all fail → confirmed offline. If any succeed → device recovers. This prevents false offline alerts. The UI must never show "Timeout" — only RTT or Last Seen.

**SNMP/LLDP** (`SNMPEngine.swift`, `FibreLinkEngine.swift`):  
Polls Netgear switches at a configurable interval. Filters by `snmpMonitoringEnabled`. Reads temperature, port telemetry, fibre DDM (SFP), and LLDP neighbour data. Results are written back to `devices[index].switchTelemetry`.

### Right-Click / Context Menu

All right-mouse events in the workspace are intercepted by `WorkspaceEventNSView` (inside `WorkspaceEventCatcher` in `WorkspaceView.swift`) via `NSEvent.addLocalMonitorForEvents`. This returns `nil` for all right-mouse events, preventing SwiftUI's `.contextMenu` from ever firing. The NSMenu is built manually in `showWorkspaceMenu(for:)`, which calls `deviceAt(swiftUIPoint)` to determine whether a device was clicked and routes to `showDeviceMenu` or `showCanvasMenu` accordingly.

### Inspector Panel

`InspectorView.swift` is always present in the layout (not conditionally rendered). When nothing is selected, its container frame is `width: 0` in the `ZStack` overlay in `ContentView`. It tracks `lastDeviceID`/`lastShapeID` via `onChange` to keep `DeviceInspector` alive between selections, avoiding cold-start creation cost.

`DeviceInspector.onAppear` does **not** call `store.refreshNetworkInterfaces()` — that call was the source of a 500ms delay. The NIC Refresh button in the NIC picker section handles that on demand.

### Debugging Tools (Password: `4512360`)

`Debugging.swift` contains all developer debug windows:
- `DeviceTileEditorWindowController` — live tile layout editor with bake-to-source feature
- `FibreBoxEditorWindowController` — fibre label styling
- `TelemetryPollingDebugWindowController` — SNMP poll interval controls
- `ConsoleOutputWindowController` — live ping/SNMP command trace with CSV export
- `DeviceDebugWindowController` — per-device snapshot of internal monitoring state

`ConsoleOutputStore` is a singleton that aggregates all engine log calls via `ConsoleOutputStore.log(subsystem:direction:...)`.

### Panel Interaction Blocking

`PanelInteractionBlocker` (`PanelInteractionBlocker.swift`) is an `NSViewRepresentable` that registers its window-space rect with `PanelInteractionRegistry`. `WorkspaceEventNSView` checks this registry before processing right-click events, so sidebar and inspector right-clicks are not intercepted by the workspace event handler.

### Device Tile Rendering

Two tile types exist:
- `MpingMapDeviceTileView` (in `WorkspaceView.swift`) — the actual tile rendered on the canvas. Conforms to `Equatable` for `.equatable()` performance opt. Zone colour strips are rendered as a left-edge overlay.
- `DeviceTileView` (`DeviceTileView.swift`) — an older/alternate tile. The canvas uses `MpingMapDeviceTileView`.

Tile ping badge display rule: **never show "Timeout"**. Show RTT when online, "Last Seen HH:mm:ss" when confirmed offline, "Never Seen" if the device has never been online this session.

---

## Priority Order

When making changes, always respect:

1. Monitoring reliability (ping accuracy, false-offline prevention)
2. Stability
3. Performance
4. Clean architecture
5. User experience
6. New features

---

## Sensitive Components — Create a Git Checkpoint Before Modifying

- `PingEngine.swift` / `PingVerificationEngine.swift`
- `DeviceStore.swift` (ping loop, verification callbacks, persistence)
- `SNMPEngine.swift` / `FibreLinkEngine.swift`
- `Alerting.swift`
- `Models.swift` (Codable changes require `decodeIfPresent` with safe defaults)
