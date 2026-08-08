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

## v0.7.35 — 2026-08-08

Three changes, all shaped by a day of two machines watching the same live rig.

### The map starts honest, every launch

Topology memory is now session-only, by design: **every boot starts from nothing and draws only what the switches prove over live LLDP.** Previously, remembered links and right-click deletions persisted per machine — so the map was partly yesterday's assumptions, two computers could show the same rig differently, and there was no way to tell observation from assumption. That ambiguity is exactly what made a field report of wrong-looking links undiagnosable after the fact.

Within a session nothing changes: a link that dies stays visible and red and raises its alert, because this session saw it up.

Expect on first launch: any link you had deleted that the switches still advertise will reappear — including real cross-plane interconnects. The map shows what is cabled and advertised, full stop.

### Jitter alerts need a sustained breach

A jitter alert now requires **three consecutive ping cycles over the limit** (about six seconds at default settings) instead of one. Eight devices alerting within the same seven seconds is the signature of the measuring Mac stalling for a moment — a compile, a spotlight index, anything — not of eight network paths degrading at once. Real jitter persists and still alerts quickly; a machine hiccup no longer pages you. The alert text says "sustained" so the rule is visible.

### Spreadsheet paste lands on the rows you see

In a redundant-mode workspace, pasting wrote to the store's internal device order rather than the filtered, reorderable table on screen — names and addresses could land on an interleaved mix of primary and secondary devices, and a workspace rebuilt that way drew wildly wrong topology because tiles were, by address, different switches than their labels claimed. Every paste path now maps through the exact row order of the table it happens in, drag-reordering included.

If you rebuilt a workspace with paste on an earlier build and the map looks wrong: check Device Manager's SNMP/LLDP Name column against your row names, then re-paste names and addresses on this build.
## v0.7.34 — 2026-08-08

Two fixes, both found in the field the same day.

### Opening a recent workspace works again

Clicking an entry in File → Open Recent closed the menu and did nothing. macOS forgets an app's file permissions between launches, and only the last-used workspace kept a stored permission — every other recent was unreadable, and the failure was silent.

Every recent now keeps its own stored permission and opens on click, across restarts. Entries saved by older versions ask once, with the file already selected in the dialog — one click re-grants access for good. A file that genuinely cannot be read now says so instead of doing nothing.

### The console no longer drowns in "Unmatched neighbour"

Running a workspace that monitors only the switches — a handover copy on a second machine did exactly this — flooded the console with error lines: every amplifier the switches could see was reported as an unmatched LLDP neighbour, on every topology rebuild, a few seconds apart. 1,950 error lines in 100 seconds, all saying the same fifty things.

A neighbour that is not a monitored device is information, not a fault. It is now reported once per session, at info level, in plain words.
## v0.7.33 — 2026-08-08

Quality-of-life release for building a workspace, plus a menu fix. Every item below was found and verified on the machine during a live working session.

### Spreadsheet paste that actually behaves

Copy device names — or names and addresses — from a spreadsheet and press ⌘V in Device Manager:

- **The rows fill the moment the paste lands.** No pressing Enter, no clicking away. Previously the data applied but stayed invisible until the edit ended — three separate faults stacked on that one symptom, all found by tracing on the machine.
- **It fills from the row you have selected**, so a paste can start anywhere in the list, not just at the top.
- **Works from any state** — mid-edit with the cursor blinking, a row selected, or nothing focused at all.
- Excel-style line endings handled; more rows than devices creates the devices needed.

### Editing device fields

- **One click puts the cursor in a cell.** Previously the first click selected the row and the second was held while macOS decided whether you were starting a drag — measured at over a second on the redundant-mode tables, and on a live rig the table could refresh between the two clicks and undo the first one. The trade: rows can no longer be dragged to reorder *by their text fields* — the checkbox column and row padding still drag.
- **A refresh can no longer destroy an edit in progress.** Typing in one table while the other refreshed could tear the cursor out mid-word.

### Menus

- **File → Open Recent no longer flickers away under the pointer.** The menu bar was being rebuilt four times a second by telemetry updates — macOS closes an open submenu whenever its items are replaced. The menu bar now only rebuilds when something it actually displays changes.

### Under the hood

- **Devices still awaiting setup are no longer SNMP-polled.** A workspace of freshly created devices was being polled continuously at placeholder addresses — pure timeout churn, for nothing.

**[Full changelog →](CHANGELOG.md)** — every release since v0.3.0.

<!-- CHANGELOG:END -->
