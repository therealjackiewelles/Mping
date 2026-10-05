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

## Features

*Every screenshot below is Mping's built-in example workspace — a redundant four-switch fibre rig with access points — exactly as the app draws it.*

### The whole rig on one canvas

<img src="docs/screenshots/topology.png" alt="Live topology canvas: four zones, fibre links with loss and bandwidth, an RSTP-blocked redundant path" width="100%" />

Every switch, amplifier and access point is a live tile — round-trip time, temperature and status readable from across the room. Fibre links are discovered automatically over LLDP and drawn with **per-end optical loss in dB** and **live per-port bandwidth**. Traffic direction animates toward the root bridge, and a blocked redundant path is drawn as exactly that — an orange dashed line, not a healthy link. Zone boxes group the rig the way it is racked, tiles drag freely, and a venue plan can sit behind everything (PNG, JPEG or PDF, with smart invert so black-on-white drawings read correctly on the dark canvas).

<table>
<tr>
<td width="55%" valign="top">

### Ping you can trust

A device is **never marked offline until a verification burst confirms it** — one lost packet on a busy network does not page you. Round-trip times are stamped by the kernel at packet arrival, so the numbers match `ping` in a terminal instead of inheriting the app's scheduling noise. Loss %, jitter and uptime are tracked per device, and jitter alerts only fire on a breach sustained across consecutive real cycles.

</td>
<td width="45%" valign="top">
<img src="docs/screenshots/device-tile.png" alt="Device tile with RTT, temperature, root bridge badge and port status box" width="100%" />
</td>
</tr>
<tr>
<td width="55%" valign="top">

### Fibre and SFP optics, per module

Optical TX/RX power, temperature, voltage and laser bias for every SFP, read over DDM. Link labels carry the measured **loss of each direction** of every span, with alerts on your dB threshold — and a link whose light disappears goes red immediately. Copper SFPs are told apart from optical automatically, so the map never claims fibre where there is none.

</td>
<td width="45%" valign="top">
<img src="docs/screenshots/fibre-links.png" alt="Fibre links with per-end dB loss, bandwidth labels, and an STP-blocked dashed path" width="100%" />
</td>
</tr>
<tr>
<td width="55%" valign="top">

### Spanning tree, drawn honestly

STP state lives right on the map: the root bridge wears a gold badge, blocked redundant paths draw as dashed amber, and traffic-flow arrows animate toward the root — computed from the switches' own designated-bridge votes. If the data cannot prove a direction, Mping draws **no arrow rather than a guessed one**.

</td>
<td width="45%" valign="top">
<img src="docs/screenshots/stp-detail.png" alt="Root bridge badge, dashed blocked path, and flow arrows on the topology map" width="100%" />
</td>
</tr>
<tr>
<td width="55%" valign="top">

### Redundant networks are first-class

Primary and secondary planes as two tabs of one workspace. Devices pair with their redundant twins, share canvas position and port-box layout, and wear P/S badges. Each plane keeps its own topology, its own link map and its own alert focus — clicking a secondary alert takes you to the secondary plane.

</td>
<td width="45%" valign="top">
<img src="docs/screenshots/redundant.png" alt="Secondary network plane with blue-tinted zones and paired switches" width="100%" />
</td>
</tr>
<tr>
<td width="55%" valign="top">

### Heat, before it becomes a problem

Both temperature sensors and all four fans of every switch, polled continuously with configurable alert thresholds. The Temperatures plane turns every tile into a **rolling one-hour graph** of sensors and fans, with hover readouts — a quiet rack at load-in and a hot one at showtime are one glance apart.

</td>
<td width="45%" valign="top">
<img src="docs/screenshots/temperatures.png" alt="Temperatures plane: per-switch rolling graphs of sensors and fans" width="100%" />
</td>
</tr>
<tr>
<td width="55%" valign="top">

### Search that knows your patch

Search matches devices — and **switch ports**, by LLDP neighbour name or by the endpoint IP resolved from the switch's own learned-MAC and ARP tables. Type an device's IP and Mping finds the port it is plugged into, opens that switch's port box, and flashes the exact cell.

</td>
<td width="45%" valign="top">
<img src="docs/screenshots/search.png" alt="Sidebar search returning devices and the switch ports they are plugged into" width="100%" />
</td>
</tr>
<tr>
<td width="55%" valign="top">

### One click, whole story

The inspector shows a device's live RTT sparkline, loss, jitter and uptime, temperature history, and a card per SFP — TX/RX, temperature, voltage, bias, vendor and serial. Per-device toggles for ping and SNMP monitoring, and a protocols strip showing per-transport health at a glance.

</td>
<td width="45%" valign="top">
<img src="docs/screenshots/inspector.png" alt="Device inspector: ping statistics, temperature history and fibre optics per SFP" width="100%" />
</td>
</tr>
<tr>
<td width="55%" valign="top">

### Set up a rig in minutes

Add a show's worth of devices in one action, then **paste names and IPs straight from a spreadsheet** — the table fills live as you paste. Bulk-edit zone, type, community and monitoring state across a selection. In redundant mode the manager pairs both networks side by side.

</td>
<td width="45%" valign="top">
<img src="docs/screenshots/device-manager.png" alt="Device Manager: redundant-mode table with spreadsheet paste" width="100%" />
</td>
</tr>
</table>

### And for the engineer who reads spec sheets

- **Port status boxes** — a draggable companion per switch that replicates the physical racks with your kit in: per-column heights, drag-in placement, cells labelled with LLDP name, endpoint IP or drop counters, red-until-verified on reopen
- **Alerts that latch** — offline, RTT, jitter, fibre loss and temperature alerts stand until acknowledged, with full history; recovered-but-unacknowledged shows amber, and macOS notifications reach you when Mping is in the background
- **Hold ⌥ Option** to flip every tile's IP to its MAC address, learned live from the network
- **Honest by design** — topology memory is session-only: every launch draws only what the switches prove now, never yesterday's assumptions
- **One portable file** — a workspace is a single `.mpw` including the venue plan; open it on another Mac and the whole rig comes with it
- **Multi-NIC aware** — ping and SNMP bind to the interface you choose per device, built for FOH Macs riding two networks at once
- **Show-safe footprint** — engineered for low CPU and few wake-ups so the Monitoring Mac stays cool and silent; read-only throughout: Mping never writes a single setting to any device

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

## v0.8.27 — 2026-10-04

**Performance**
- Panning, zooming and switching views are smoother: the map is one canvas for all three views and switches without a fade, and its background redraw waits until you let go
- Sitting idle uses less CPU: port-box labels are rebuilt only when something they show has changed, not on every ping lap and every poll result

**Fixes**
- Holding Option over a Netgear switch shows its chassis MAC, the one on its label, instead of its management MAC; a MAC search finds either
- Searching for any of a Netgear switch's own MAC addresses now lights the switch itself, not just the switches that learned that address
- Searching for a whole MAC flashes a gold border round the exact device that owns it, a tile or its cell in a port box; the results list shows only that device, and nothing if it is not in the workspace
- AVB: the "Pdelay timeouts" face and the counter alert read the wrong column of the switch and always showed 0; they now show the pdelay timeouts as the switch's own 802.1AS page does, and the alert fires on them
- Older console records are kept up to a 4 GB budget (up to 40 runs) and the newest earlier one is never deleted, so a burst of relaunches no longer pushes a show day's records out; each launch notes what it removed in the app log
- The Console window lets go of its rows when it is closed instead of re-filtering them in the background

**Features added**
- The console record warns below 5 GB of free disk, stops growing below 1 GB (the Console window keeps working) and resumes above 2 GB, all noted in the app log; a failed write or a record file that would not open is reported instead of silently dropping rows, and the heartbeat line shows free disk space
- The spacebar flips the map between the Primary and Secondary networks, whichever is up; the keys 1, 2 and 3 switch it to Overview, Temperatures and AVB
- The AVB "FIBRE TILES" rail is always on the left edge, even with the View Master's gPTP-on-links chip off; choosing a face (or pressing Shift+Tab) switches the readings back on
- Tab steps down the left rail (port-box labels on the Overview; Power, Streams, Clock and the rest on AVB); Shift+Tab steps through the AVB fibre tile faces
- Esc in the search box clears it and leaves the box, so the map keys work again at once
- AVB link faces: a new "Announce discards" face and a "Pdelay lost" face (a port dropping out of the clock), in the order of the switch's own statistics page
## v0.8.26 — 2026-09-30

**Features added**
- Jumbo frames: Edit… on a virtual interface can fix a size above 1500 where the adapter can carry it; Mping holds it, tests it with a large packet on that leg, and says so if the leg isn't carrying it
- The Network window keeps each section's long explanations behind a "?" at the right-hand end of its heading

**Changes**
- A new virtual interface is made at 1496 with no frame-size choice; Edit… keeps it, and "leave as found" now really leaves the interface alone
- The Network ▸ Virtual Interfaces description is one line, and its status reads "adopted from System Settings" or "adopted from Mping"
- A Netgear switch's Inspector shows the hotter of its two temperature sensors, the same number as its tile
- The About card (click the Mping logo) now carries the credits: created by Morgan Beecher, and the ideators

**Fixes**
- The helper's launch description is now in the form Apple documents — on one Mac the helper never started, so routes, the time server address and virtual interfaces did nothing
## v0.8.25 — 2026-09-28

**Features added**
- A full user manual (PDF), plain-language and versioned with the app — every screen and device type, attached to this release as Mping-User-Manual.pdf; screenshots are still placeholders and it isn't linked from inside the app yet
- Fix the Network window (issue 148): the mismatch panel's button now opens one list of everything this Mac lacks for the showfile — named virtual interfaces and devices pinned to a missing adapter — with Point at to move a row onto an adapter that already fits and Use the Mac's address for a VLAN whose address differs; nothing is built from it yet
- Showfile-owned virtual interfaces, second half (issue 147): an interface the showfile describes and this Mac lacks is made by Mping through the helper when the file opens — as vlan100 or above, with the file's address and a safe 1496 frame size — and removed when Mping quits (a checkbox in Network ▸ Virtual Interfaces keeps them up for other software; a crash never removes anything); switching showfiles takes down only what the old file built and the new one does not need, then builds the new file's; one that macOS removes on a dongle replug or a Network-settings Apply is made again within seconds; the section gains Add Virtual Interface…, Edit…, Re-make now and Remove from showfile…, with a live line saying what Mping will do with the description on this Mac
- Showfile-owned virtual interfaces, first half (issue 147): a showfile now describes each VLAN interface it needs — name, dongle by hardware address, tag, address, frame-size rule — and devices point at that description instead of a bare "vlan1"; on open Mping adopts a matching VLAN already on the Mac (never touching it) and says so on the splash and in Network ▸ Virtual Interfaces; an old showfile has its descriptions read off this Mac's live VLANs on open and keeps them at its next save; the NIC pickers list the showfile's virtual interfaces by name; a live VLAN the showfile does not use can be added to it in one click
- Groundwork for showfile-owned virtual interfaces (issue 147): the helper can make and remove temporary VLAN interfaces — vlan100 and above only, never one System Settings defines, never a second tag on a dongle, never a second holder of an address, and a crash never removes one — and the app reads any VLAN's tag and parent from the kernel, so an interface Mping made shows its tag in the Network window and NIC pickers and gets the frame-size check; MPING_VLAN_SELFTEST=en9 proves it on an idle dongle
- Adapter frame size, checked and kept right by the helper: at launch (an "Adapter frame size" line on the splash), after a replug and every half minute, a full-size don't-fragment ping goes to a device on each VLAN adapter; where a 1500-byte frame dies and a 1496-byte one passes, the adapter's MTU is trimmed to 1496 and put back if anything resets it, with a console line and an app-log line each time, and the Network window says so on the adapter — the 25 Sep afternoon of "the LS10s' port tables and the amps' vitals vanished on one leg" was this, an MTU a Settings Apply had put back to 1500

**Changes**
- A device whose adapter is not on this Mac now waits instead of reading offline: its tile says "Waiting for adapter", it is left out of every poll, and one alert per interface replaces dozens of device-offline alerts and the /sbin/ping spawn storm a pulled dongle used to cause; the ping engine itself now reports a missing adapter as "no information" rather than falling back to /sbin/ping (MPING_NO_HOLD=1 turns the hold off only, so those devices are still pinged and read "no information"; the /sbin/ping fallback is gone either way)
- Opening another showfile asks Save / Don't Save / Cancel when the current one has unsaved changes, instead of dropping them silently; Open Recent now runs the adapter check and re-pins the routes like Open… does, and changing one device's adapter re-pins its route at once
- The AVB Power face says one of three things for an amp — "online", "standby", or "fault" with what the fault is ("fault — SMPS off", "fault — 15V ch3", the amp's own error word) — instead of "ok" and a bare "FAULT"
- Amp alerts lead with the unit — "amp 42", or "P1 250" for a processor — with its port and parent LS10 beside it ("P9 · E L1-2 PRI"), instead of the model and number; the History sidebar shows "amp 42 · E L1-2 PRI"
- The clock-stream alert now watches the present, not the amp's memory: a leg that is not locked, an error word, or a fault counter climbing raises it; the amp's "connected / sync" report word — which records a past hiccup and re-appeared on every launch for amps that were locked and passing audio — no longer does. The row reads the two legs side by side with the tiles' red P / blue S chips: "Clock P Locked, S Waiting mclk". The alert table's Time column no longer clips the first digit

**Fixes**
- Route pins now follow the showfile: a pin no longer wanted on an adapter is removed when its set is re-sent (kernel mode used to only add), and a pin that moves from one adapter to another is never deleted from the old one after it has moved
- Switching NTP & Syslog off and on no longer stops the half-minute checks that put the time-server address and the 1496 frame size back
- The app reads the helper's version before using a new verb, so a helper kept alive by another copy of Mping cannot take the whole helper out of service
- Port boxes no longer flicker stale on every switch when the LS10s' port-state call stops answering (25 Sep: all 29 primary-leg units at once): the Netgears and the LS10s now take turns in separate rotations, the LS10s' HTTP reads queue on their own with the fast port-state read in its own lane, and a unit whose port-state call keeps timing out is left alone for 30 s, doubling to two minutes, re-tried off the rotation so its timeout costs the other units nothing — the sweep stops asking it for ports too and keeps the list it has, and while it is held a port with an LLDP neighbour reads as up, so the amp rows stay live instead of red — with a console line each way
- The LS10 log no longer says "connection refused — port 80 closed" for a connection that was blocked or unreachable; it says so

**[Full changelog →](CHANGELOG.md)** — every release since v0.3.0.

<!-- CHANGELOG:END -->
