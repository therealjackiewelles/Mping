<p align="center">
  <img src="docs/icon.png" width="128" alt="Mping" />
</p>

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

![Mping monitoring a live show network](docs/mping-demo.gif)

## What is Mping?

Network monitoring built for show engineers, not IT departments. Everything on one canvas, readable at a glance from the FOH position.

- Know the instant a device drops — with **no false alerts**
- Your whole network as an interactive topology map
- The numbers that matter: RTT, jitter, packet loss, fibre loss, SFP temperature and signal
- Built around **Netgear AV**, **AVB/Milan**, **L-Acoustics** and fibre rigs

![Mping monitoring a live show network](docs/mping-demo.gif)

---

## Install

1. Download **`Mping-x.y.z.dmg`** from the [**latest release**](https://github.com/therealjackiewelles/Mping/releases/latest)
2. Open it and drag **Mping** into Applications
3. **First launch: right-click Mping → Open**, then click Open again

> **Step 3 is not optional.** Mping is not yet notarised by Apple, so double-clicking it the first time shows a warning and refuses to launch. Right-click → Open is the way past it, and macOS only asks once. If macOS says the app is *"damaged"*, that is the same thing — the file is fine.

Workspaces are stored in `~/Documents/Mping`, never inside the app, so updates never touch your data.

**Updates:** Mping checks GitHub on launch and once a day. Feature releases offer to download and install themselves; patch releases are quiet — check any time via **Mping → Check for Updates…**. It is one anonymous request to GitHub. No account, no tracking.

---

## Setting up Netgear AV switches

Mping reads switch telemetry over SNMP — port status, temperatures, SFP levels, LLDP neighbours and STP state. The switch needs a read-only community string before any of that appears.

### 1. Create an SNMP community on the switch

In the switch's **main web UI** (not the AV UI), find the SNMP section — on M4250/M4300 it is under **System → SNMP → Community Configuration**.

- **Community string** — a name of your choosing, e.g. `mping`. This is effectively a password, so avoid `public` on a show network
- **Access mode** — **read-only**. Mping never writes to a switch, and read-write access is not needed
- **Client address** — restrict it to the Mac running Mping if your switch supports it, or leave open on a closed show network
- Make sure the community is **enabled**, and that SNMP itself is enabled on the switch

### 2. Add the switch in Mping

Right-click the canvas → **Add Device**, then in the inspector set:

- **IP address** of the switch
- **Type** → *Netgear Switch*
- **SNMP community** → the string you just created
- **Ping NIC** → the interface that reaches this switch

Telemetry appears on the next poll. If nothing arrives, open **Debugging → Console Output** and filter by subsystem to see exactly which OIDs were asked for and what came back.

### 3. What Mping does and does not do

Mping is **read-only by design**. It issues SNMP GET and WALK requests only, and never SET. It cannot change a switch's configuration, and the L-Acoustics HTTP integration is likewise GET-only.

---

## Redundant networks and dual NICs

A redundant rig usually means two physically separate networks — primary and secondary — often using **the same subnet on both**. That is where macOS gets in the way.

### The problem

With two NICs on overlapping subnets, macOS decides which interface to use from its routing table, not from which cable you meant. Replies arriving on the "wrong" interface are dropped by reverse-path filtering, so devices appear offline even though they are reachable.

### The fix — static host routes

Mping generates the routes for you. In **Preferences → Dual-NIC Static Routes**:

1. Set a specific **Ping NIC** on each device in the inspector — not *Auto Routing*. Only devices with an explicit NIC can be routed
2. Open the Dual-NIC Static Routes panel and press **Apply**
3. The commands are copied to your clipboard and Terminal opens — press **⌘V** then **Return**, and enter your admin password

This tells macOS exactly which interface to use for each device, so replies are accepted on the right one.

> **Remove the routes before you disconnect a NIC.** A static route pointing at an interface that is no longer there will black-hole all traffic to those devices until it is removed. The same panel has a **Remove** button.

### Primary and secondary

Once devices are paired, the **Primary / Secondary** tabs at the top of the canvas switch the whole view between the two networks. A secondary device sits in the same position as its primary, so the layout stays identical as you flip between them.

---

## Requirements

- macOS 13 Ventura or later
- Netgear AV switches for SNMP telemetry (any pingable device works for basic monitoring)
- A network route to the devices you want to monitor

---

## Ideas, questions and problems

- **Ideas & feature requests:** [Discussions](https://github.com/therealjackiewelles/Mping/discussions) — tell me what Mping should do. What you would use it for on a rig matters more than how it should work
- **Questions:** [Q&A](https://github.com/therealjackiewelles/Mping/discussions/categories/q-a)
- **Bugs:** [Issues](https://github.com/therealjackiewelles/Mping/issues)
- **Email:** mping@mb-technical.com · **Phone:** +44 7548 773053

[**How it works →**](ARCHITECTURE.md) — the system board: what runs when, and why.

---

## Trademarks & affiliation

Mping is an independent product. It is not affiliated with, endorsed by, or supported by NETGEAR or L-Acoustics. All trademarks belong to their respective owners.

## Licence

Proprietary — Copyright © 2026 Morgan Beecher / MB Technical. All rights reserved. See [LICENSE.md](LICENSE.md).

The application source is maintained in a private repository; this repository hosts releases, documentation, and the issue tracker.

---

## Recent releases

<!-- CHANGELOG:START -->

## v0.7.26 — 2026-08-04

Tested against a live show network, which turned up several things that only appear when real switches are answering.

### Monitoring is now as fast as you set it

- **Poll intervals were running two to three times slower than configured.** Readings rotate through your switches one at a time, but the gap between them didn't account for how long each reading actually takes — so a five second setting behaved more like fifteen on a large rig. The numbers in Telemetry Polling now mean what they say
- **Reading a switch's temperature was quietly fetching everything else too** — port tables, neighbours, fibre levels, spanning tree and fan speeds — every thirty seconds per switch. Temperature now reads the temperature. SNMP traffic is down to about a quarter of what it was
- **Nothing is fetched twice.** Each reading is now the only thing asking for its data

### Fixes

- **Port boxes no longer blank out** when the slower discovery pass runs
- **Temperature graphs no longer zig-zag** between two sensors — the graph follows the hottest sensor consistently
- **Fibre link matching is much faster**, which on a large rig was the single heaviest thing the app did
- Console Output: device names no longer flip between your name for a device and the name it reports over LLDP, and the log no longer empties and refills as it updates

### Quality of life

- **The last workspace reopens on launch, wherever you keep it** — including the Desktop or a USB stick, not just the app's own folder
- **A reading that stops updating now says so** in the inspector, with how long ago the last value arrived, rather than quietly showing a stale number as though it were current
## v0.7.25 — 2026-08-03

### When a switch won't report

- **The inspector now tells you why.** A switch that answers pings but gives back no SNMP used to show nothing but empty fields — no ports, no temperatures, no explanation. It now says what has happened and lists the three usual causes: SNMP turned off on the switch, a community string that doesn't match, or the switch only accepting SNMP from certain addresses
- **The SNMP community can be set in the inspector**, where you actually look when a switch isn't reporting. It was only in Device Manager before. There's a "?" beside it explaining what a community string is and how to create one on a Netgear switch
- Changing the community clears the previous failure message, so an old error doesn't sit there looking like the new setting is wrong

### Smoother while monitoring

- **The main telemetry sweep is spread across its interval** instead of hammering every switch at once and then going quiet. Each switch is checked exactly as often as before — the work is simply spread out, so the app no longer surges every cycle. On a rig where some switches are slow to answer, the difference is large
- **Port boxes stop redrawing when nothing about them has changed**, which they were doing on every poll

### Zoom

- The status and temperature dots stay sharp when you zoom right in; they were being flattened into an image beforehand
## v0.7.24 — 2026-08-03

### Mping runs on macOS 13 Ventura again

**If Mping refused to install on your Mac, this is the release to get.**

Previous builds were accidentally marked as requiring the very newest macOS, so they would not install on anything older — even though Mping has always been documented as running on Ventura or later. That was a packaging mistake, not a real requirement.

- **Minimum is now macOS 13 Ventura**, as documented
- Nothing else changes — no features were removed to achieve it

One small difference on Ventura: in the workspace search box, Tab no longer arms reverse-cycling through results. Enter still cycles forward as normal.

**[Full changelog →](CHANGELOG.md)** — every release since v0.3.0.

<!-- CHANGELOG:END -->
