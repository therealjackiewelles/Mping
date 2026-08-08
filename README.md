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
## v0.7.32 — 2026-08-08

Fibre link direction fixes, a crash fix, network polling that no longer drags the interface, a duplicate SNMP reading removed, and a small improvement to panning.

### A crash, fixed

Away from the rig — where every ping times out and gets forcibly stopped — reading the output of a stopped ping could raise an error of a kind the app cannot intercept, which brought the whole app down. Seen once after about 90 minutes. The read now uses the variant that reports failure as an ordinary, ignorable error: a dead pipe just means no output, which is what a timed-out ping is anyway.

### Network waits no longer drag the interface

All of the app's background work — polling, redrawing, alert evaluation — shares one small pool of worker threads, one per processor core. Pings and SNMP requests were waiting for their replies *on those threads*, and a device that never answers holds its thread for the full timeout. Off the rig, everything times out at maximum, so a normal device list could occupy the entire pool and everything else queued behind it — which is exactly the interface sluggishness reported while polling ran. The waiting now happens on separate threads that the system grows as needed, so a slow or absent device costs patience, not the app's responsiveness.

### Link flow arrows stop reversing

Reported from a live rig: the flow animation on a link would run the wrong way, come right, then go wrong again. Three separate faults were behind it, all of which looked identical on screen.

- **A link had no fixed orientation.** Its identity was already consistent whichever switch reported it, but which end counted as the "start" was simply whichever switch happened to be polled. Seen from the other end, the same unchanged flow was recorded as its opposite — and because the identity matched, the app treated the reversal as a genuine change and committed it. Poll order rotates, so it flipped intermittently. Links now hold one orientation whoever reports them.
- **Link identities did not survive a restart.** They were derived using a value that macOS deliberately randomises for each app launch, so a link got a different identity every time the app started, while saved links kept their old one. The same physical link then existed twice — once live, once remembered — and the two disagreed. Identities are now derived properly and are the same on every launch.
- **Links saved by earlier versions lingered as ghosts.** Anything remembered under the old scheme could never match a live link again, so it stayed on the map until topology links were cleared by hand. Saved links are now matched up on load, so this corrects itself.

### One less SNMP reading per switch

Switch temperature was being fetched twice every cycle — once by the temperature reading and again by the discovery pass. The discovery pass no longer asks for it.

This also fixed something quieter: switches that do not publish a temperature table were falling down a different path that skipped their port and fan readings entirely. Every switch now gets the same treatment.

### Panning

Moving the canvas made the app rebuild its entire view tree on every frame — all forty tiles, the links and the port boxes — to work out what to draw. One of the reasons for that has been removed, which cuts the layout work during a pan by roughly a quarter.

**It does not fix the stutter.** The main cause sits higher up: the zoom and pan position are stored above the canvas, so moving the view rebuilds everything beneath it. Fixing that properly means changing where that position is kept, which touches plane switching, the minimap and zoom-at-cursor, so it is being done deliberately rather than quickly. Tracked as issue #80, along with the profiling behind it and three attempts that did not work.
## v0.7.31 — 2026-08-07

One change, aimed squarely at heat.

### SNMP stops building a network connection for every reading

Profiling a live rig showed the app spending as much effort on *setting up and tearing down* network connections as on anything else. Every time it asked a switch for a reading — and with eight readings rotating across sixteen switches, that is constantly — it built a network flow, worked out a route, installed a handler, then dismantled the lot.

It now uses a plain socket, the same way the ping engine always has.

Measured on a live rig with both versions running side by side against the same switches:

| | CPU | Wake-ups per second |
|---|---|---|
| v0.7.30 | ~39% | 121 |
| **v0.7.31** | **~27%** | **16** |

The wake-up figure matters as much as the CPU one. Every wake-up pulls the processor out of its low-power state, and at 121 a second it never gets to rest — which is what keeps a laptop warm and the fans audible.

Switches see exactly the same requests as before; only the way the app opens its socket has changed.

**[Full changelog →](CHANGELOG.md)** — every release since v0.3.0.

<!-- CHANGELOG:END -->
