<h1 align="center">Mping</h1>

<p align="center">
  <strong>Professional network monitoring for live event production.</strong><br/>
  Built for touring, festival, fixed installation, and live broadcast engineers.
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2013%2B-black" />
  <img alt="Status" src="https://img.shields.io/badge/status-beta-orange" />
  <img alt="Licence" src="https://img.shields.io/badge/licence-proprietary-red" />
  <a href="https://github.com/therealjackiewelles/Mping/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/therealjackiewelles/Mping?label=download" /></a>
</p>

---

## What is Mping?

Traditional network monitoring tools are built for IT infrastructure — powerful, but slow to configure and impossible to read at a glance during a show. Mping is built around the workflows of AV system engineers:

- Know the instant a device goes offline, with **zero false alerts**
- See your entire network topology on a single interactive canvas
- Get the metrics that matter: RTT, jitter, packet loss, fibre loss, SFP temperature, voltage, and bias
- Designed natively for **AVB/Milan**, **L-Acoustics**, **Netgear AV**, and fibre infrastructure

---

## Download & Install

1. Download the latest **`Mping-x.y.z.dmg`** from the [**Releases page**](https://github.com/therealjackiewelles/Mping/releases/latest).
2. Open the DMG and drag **Mping** into your Applications folder.
3. On first launch, right-click Mping → **Open** (macOS asks once, because the app is not yet notarised).

### Staying up to date

Mping checks for new releases itself — on launch and once a day:

- A **feature or fix release** (the major or minor version changes) shows an alert with a **Download & Install** button that fetches the update, mounts it, and opens the drag-to-Applications window.
- **Patch releases** are silent; check any time via **Mping → Check for Updates…**.
- The check is a single anonymous request to GitHub's public releases API — no accounts, no telemetry.

Your workspaces live in `~/Documents/Mping`, never inside the app, so updating never touches your data.

---

## Features

### Real-Time Monitoring
- ICMP ping monitoring with a configurable interval and timeout
- **Offline verification engine** — confirms a failure with a burst of pings before alerting, eliminating false positives
- Per-device **packet loss %**, **jitter**, **uptime**, and an **RTT sparkline** with hover readouts
- Native macOS notifications and a Dock bounce when an alert fires while the app is in the background

### Network Topology Canvas
- Drag-and-drop devices and location boxes onto a freeform canvas, with zoom, pan, and snap-to-grid
- **Live fibre link visualisation** between switches, with optical loss, SFP temperature, and bandwidth labels
- **Redundant network** dual-plane view (Primary / Secondary) and a dedicated STP plane with root-bridge flow animation
- **Zone system** and a search bar to filter and highlight devices

### SNMP & LLDP Telemetry *(Netgear AV)*
- Dual-sensor switch temperature and all four fan speeds, with a **1-hour rolling graph** per switch
- Per-port telemetry: link status, duplex, speed, medium type
- SFP DDM: optical TX/RX levels, loss, temperature, **voltage**, **laser bias**, and module **vendor / serial / type**
- LLDP neighbour discovery for automatic topology mapping

### Alerting
| Category | Default Threshold |
|---|---|
| Device Offline | — |
| Ping RTT | 100 ms |
| Jitter | 2.0 ms *(AVB/Milan aware)* |
| Fibre Loss | 4.0 dB |
| Over Temperature (Switch) | 70 °C |
| Over Temperature (SFP) | 75 °C |

Alerts **latch until acknowledged** — a fault that recovers on its own turns amber rather than vanishing, so nothing that happened during a show erases itself before anyone saw it. Clicking an alert focuses the device on the canvas.

### Device Manager & Inspector
- Table view with resizable, reorderable columns and bulk group-edit
- Per-device inspector: RTT graph, loss, jitter, uptime, MAC, fibre optics (raw SFP levels), and temperature history

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

---

## Philosophy

> Monitoring reliability before features. No false alerts. Built for the pace of a show.

- A device is never marked offline until a verification burst confirms it
- The UI never surfaces transient ping failure states — only confirmed status or last-seen time
- Nothing ships that could destabilise the monitoring core

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history.

---

## Support, suggestions & licensing

- **Email:** mping@mb-technical.com
- **Phone:** +44 7548 773053
- **Issues & feature requests:** [GitHub Issues](https://github.com/therealjackiewelles/Mping/issues)

---

## Licence

Mping is **proprietary software** — Copyright © 2026 Morgan Beecher / MB Technical. All rights reserved. See [LICENSE.md](LICENSE.md).

The application source is maintained in a private repository (`Mping-source`); this repository hosts the public releases, documentation, and issue tracker.
