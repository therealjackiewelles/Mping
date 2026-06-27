<p align="center">
  <img src="https://raw.githubusercontent.com/therealjackiewelles/Mping/main/docs/icon.png" width="128" alt="Mping icon" />
</p>

<h1 align="center">Mping</h1>

<p align="center">
  <strong>Professional network monitoring for live event production.</strong><br/>
  Built for touring, festival, fixed installation, and live broadcast engineers.
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/therealjackiewelles/Mping/main/docs/logo.png" width="72" alt="Mping network topology logo" />
</p>

---

## What is Mping?

Traditional network monitoring tools are built for IT infrastructure — powerful, but slow to configure and impossible to read at a glance during a show. Mping is built around the workflows of AV system engineers:

- Know the instant a device goes offline, with **zero false alerts**
- See your entire network topology on a single interactive canvas
- Get the metrics that matter: RTT, jitter, packet loss, fibre loss, SFP temperature
- Designed natively for **AVB/Milan**, **L-Acoustics**, **Netgear AV**, and fibre infrastructure

---

## Features

### Real-Time Monitoring
- ICMP ping monitoring with configurable interval and timeout
- **Offline verification engine** — confirms failures with a burst of pings before alerting, eliminating false positives
- Per-device **packet loss %**, **jitter**, **uptime counter**, and **RTT sparkline graph**
- Last Seen timestamp when a device goes offline; Never Seen for devices not yet reached
- Per-device ping and SNMP monitoring can be toggled independently

### Network Topology Canvas
- Drag-and-drop devices and location boxes onto a freeform canvas
- Zoom, pan, and snap-to-grid
- **Fibre link visualisation** between switches with optical loss and SFP temperature labels
- **Zone system** — colour-code devices by zone with a persistent left-strip indicator on each tile
- Search bar to filter and highlight devices by name, IP, or zone

### SNMP & LLDP Telemetry *(Netgear AV)*
- Switch temperature monitoring with configurable alert thresholds
- Per-port telemetry: link status, duplex, speed, medium type (copper / fibre)
- SFP/fibre port optical loss and temperature via DDM
- LLDP neighbour discovery for automatic topology mapping
- MAC address lookup via ARP

### Alerting
| Category | Default Threshold |
|---|---|
| Device Offline | — |
| Ping RTT | 100 ms |
| Jitter | 2.0 ms *(AVB/Milan aware)* |
| Fibre Loss | 4.0 dB |
| Over Temperature (Switch) | 70 °C |
| Over Temperature (SFP) | 75 °C |

Thresholds are configurable per session. Alerts support per-category acknowledgement and full history.

### Device Manager
- Table view with **resizable and reorderable columns**, saved across sessions
- Fields: Name, IP Address, Device Type, SNMP Community, URL Prefix, URL Suffix, Ping NIC
- **Bulk group-edit** — select multiple devices to set zone, device type, SNMP community, or monitoring state in one action

### Inspector
- Click any device to open its inspector panel
- RTT sparkline graph, packet loss %, jitter, uptime, MAC address
- Zone assignment, Ping Monitoring toggle, SNMP/LLDP toggle
- Fibre loss per port, temperature history for Netgear switches

### Debugging Tools *(password protected)*
- **Device Debug** — live snapshot of internal monitoring state per device
- **Console Output** — full ping and SNMP command trace with CSV export
- **Device Tile Editor** — live tile layout controls with bake-to-source
- **Telemetry Polling** — SNMP poll interval controls

---

## Supported Hardware

| Category | Hardware |
|---|---|
| Amplifiers | L-Acoustics (all networked models) |
| Switches | Netgear AV Line (M4250, M4350 series) |
| Infrastructure | Fibre links with SFP DDM support |
| Protocol | AVB / Milan, standard Ethernet |
| Generic | Any ICMP-reachable device |

---

## Requirements

- macOS 13 Ventura or later
- Xcode 15+ to build from source
- App Sandbox must be **disabled** in the target entitlements for ICMP ping to function

---

## Building

Mping is built in Xcode. There is no package manager or CLI build step.

```
1. Clone the repository
2. Open Mping.xcodeproj
3. Select the Mping target
4. Confirm App Sandbox is disabled in entitlements
5. Build and run (⌘R)
```

---

## Philosophy

> Monitoring reliability before features. No false alerts. Built for the pace of a show.

- A device is never marked offline until a verification burst confirms it
- The UI never surfaces transient ping failure states — only confirmed status or last seen time
- Monitoring engines are kept independent from the UI layer
- Iterative, focused development — nothing ships that could destabilise the monitoring core

---

## Roadmap

- SNMP CPU and memory telemetry
- Historical latency graphs per device
- STP and AVB clock alerting
- Audio alert notifications on device offline
- Remote collector support

---

## Changelog

### v0.4.0 — 2026-06-27
- RSTP root bridge auto-detected via SNMP — ROOT badge on tile
- All active fibre links show animated directional flow toward root bridge
- Fibre link lines thicker with topologically correct arrow direction per link

### v0.3.3 — 2026-06-27
- Fibre label tiles slide back along the link when devices are close, hide when no room
- Fibre labels fixed to show correct data at each end
- Ping-only devices use compact half-height tile (name, RTT, IP)
- Netgear web interface defaults to `https://` and URL suffix now persists correctly

### v0.3.2 — 2026-06-26
- Devices with active alerts pulse with a yellow border on the canvas

### v0.3.1 — 2026-06-26
- Workspace background pulses red when any alert is active (removed in v0.3.2)

### v0.3.0 — 2026-06-26
- **STP / RSTP** — Blocking links detected via SNMP and shown as dashed orange lines on the topology canvas
- **Monitoring** — Packet loss %, jitter, uptime counter, RTT sparkline, per-device monitoring toggles
- **Device Manager** — Rebuilt as native macOS table with resizable/reorderable columns and screen-aware sizing
- **Inspector** — MAC address, zone, sparkline graph, monitoring controls; 500ms tap delay eliminated
- **Workspace** — Zone colour system, sidebar search, right-click context menus, deselect on tap
- **Group Edit** — Bulk-edit zone, device type, SNMP community and monitoring state across multiple devices
- **Performance** — Ping results batched into one render pass per cycle; unnecessary SNMP walks removed
- **Bug Fixes** — Topology link deduplication, Last Seen display, false STP alerts on boot, alerting box resize

### v0.2.0 — Earlier 2026
- ICMP ping monitoring with verification engine
- Workspace canvas, SNMP/LLDP telemetry, fibre link visualisation
- Inspector panel, minimap, alerting framework
- Device Ports view, Console Output debug window
- Workspace persistence

[Full changelog →](CHANGELOG.md)

---

## License

See [LICENSE](LICENSE) for details.
