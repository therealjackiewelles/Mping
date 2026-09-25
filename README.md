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

## v0.8.24 — 2026-09-25

**Features added**
- AVB Streams view: the switches say who is sending streams — each Netgear's MSRP reservation table names every stream and its talker's MAC — and the switches' address tables say which port each talker is on, so on the Streams view a port-box cell whose device is sending streams turns gold and reads "name · n streams"; its own tier (30 s) in the Telemetry Polling window
- Holding Option shows MAC addresses in the port boxes too, as it already did on the tiles: the neighbour's MAC on a switch port, the amp's on an amp row
- MAC search accepts every form a pasted address can take — dots and spaces between the pairs, a trailing newline — not only colons and dashes
- An application log, beside the console log: one line per thing that happens to the app — launch (version, macOS, Mac, each launch step's time), sleep and wake, front and back, thermal and low-power changes, a five-minute heartbeat (the app's own CPU, memory, threads, open descriptors, devices online/offline), the main thread stalling, the quit path; a run that dies is noticed at the next launch (a history note names its log), macOS's crash reports are collected, and all of it goes into Export All Logs (#143, first cut)
- Help ▸ Export All Logs… now includes every Nemo meter's full power history too: one CSV per meter in a "Power Graphs" folder, every reading held, not just whatever window a graph happened to be showing (#141 follow-up)
- Help ▸ Export All Logs… now includes every Netgear switch's own log: one CSV per switch in a "Switch Logs" folder (every line held, MVRP chatter marked rather than dropped), plus one file combining all of them sorted by when Mping read each line — the switches' own clocks can be hours apart on this rig (#141)
- One address, one adapter, one device: typing an address another device already has through the same NIC turns the IP and Ping NIC boxes red with the other device's name, and the change is refused — in the Inspector, the Device Manager, Group Edit and Network ▸ Adapters; an address shared across two NICs is allowed but never gets a pinned route; a double that gets in anyway (a pasted copy, an old showfile) is greyed out on the canvas, reads "Duplicate IP", and is neither pinged nor polled until its address or NIC changes
- Network ▸ Adapters starts with every adapter collapsed (click anywhere on a header to open it), stripes the device rows, shows VLANs by their name and tag, marks the time server's adapters with an NTP Server badge, hides unused adapters with nothing plugged in, and re-reads the Mac's adapters every two seconds while the window is open
- Network ▸ Adapters is laid out by adapter: each has a header with its name, address, mask and MAC, and beneath it a table of the devices using it with a per-device adapter picker; the head of that column moves the whole table to another adapter (Move all to…, then Apply); adapters only the showfile knows get the same block in red, and devices on Auto have one too
- A showfile from a computer with different network adapters is handled: nothing is added to the Mac for adapters it doesn't have, the opening splash shows red crosses, a box says the adapters don't match (the time server only if one is set up) with a button into Network ▸ Adapters, and there each missing adapter's devices move onto one of this Mac's adapters in one step
- The opening splash names the workspace that is opening and ticks off what Mping does to get ready: workspace loaded, host routes added, the time server's address put on, monitoring started; it holds until the last tick shows
- A closing sequence mirrors the opening: "Closing application", the M un-drawing, and three lines ticking off as Mping saves the workspace, removes the host routes it pinned and takes the time server's address off the rig adapters
- With the helper approved, the host routes the rig needs (only addresses two adapters could both reach) go on at launch and come off at quit, and the helper clears them if the app dies
- First launch asks once for the permission that lets Mping manage the time server's address: Allow opens the one switch in System Settings, the panel watches for it and closes itself, and it never asks again
- The privileged helper is now built into the app: approved once in System Settings, it puts the time server's address on the rig NICs when Mping starts and takes it off when Mping quits, so the switches keep time without a Terminal command after every reboot (#136)

**Changes**
- The workspace background image is removed (Workspace ▸ Background Image); a showfile that carries one still opens, and the image leaves the file at its next save (#81)
- The Zone field is gone from every device: no field in the Inspector or Group Edit, no colour strip on the tile; old showfiles still open
- The LS10 Inspector no longer shows a Temperature card: an LS10 reports no temperature of its own (amp temperatures are unchanged)
- The Network window's sections each open with a header for legends and notes; Adapters shows the outline legend (green up with an address, red no address or no connection, dashed virtual) and the row of summary tags is gone

**Fixes**
- The helper no longer retries the refused system network-database write every 30 s: it remembers the refusal, uses kernel routes from then on, and a re-add keeps the whole pin list (helper 4)
- Mping no longer crashes when a network adapter drops off the Mac (a failing USB hub, an unplugged dongle): a failed SNMP socket was closed twice, and the second close could land on another connection's descriptor and kill the app; the bug dates from 7 Aug
- Unplugging and replugging the network adapters no longer kills one side of the switch management network: the routes Mping pinned were the wrong kind, and on whichever adapter came up first every packet to its switches went nowhere (#136)
- The time server's address goes back on by itself within half a minute of an adapter being replugged or the Mac waking; before, it stayed off until the next launch and the switches lost their time server
- A switch whose clock matches the Mac no longer reads "14400.1 s behind this Mac" while it is re-locking to the time server, and its Time row says it is asking this Mac and when it was last heard; a switch reading "not synchronised" is re-read every ten seconds, not every ten minutes, until it locks
- The NTP status tier no longer starves: finding its switch busy cost it a full minute each time, and after a launch it could go minutes without one read; a slow tier now comes back for the same switch in three seconds
## v0.8.23 — 2026-09-17

**Features added**
- AVB clock master alert: when a leg's agreed grandmaster changes from what the session first saw, and stays changed for two sweeps, one alert names the old and new master (#22)
- Spanning tree topology changes raise an alert in the Links box, read from the switch's own log within a lap: the port, the neighbour on it and the bridge the change came from; the row clears after two quiet minutes. Only a change on a port that leads to a device in the workspace alerts; a change on a port with nothing monitored on it, on an access point's port (a client roaming), or one merely received from another bridge goes into the history as a note (#21)

**Fixes**
- The in-app alert banners (top right) appear only while Mping is in the background; in front, the sidebar has them
## v0.8.22 — 2026-09-17

**Features added**
- "Open full log…" under the Switch log rows opens a window with every line held for that switch, newest at the top: time, severity, component and message, with a filter, a Show MVRP chatter toggle and Copy (#139)
- The switch's own log, read from the switch over SNMP with no syslog host to configure: the Switch log rows at the foot of the Inspector fill from it, with the switch's own timestamps; one small read per lap, lines only when there are new ones; MVRP chatter hidden; its own tier in the Telemetry Polling window (#139)
- The search field finds MAC addresses, whole or in part ("1b:92", "001b92"): a device's own MAC, an amp's, and any MAC a switch port has learned or heard over LLDP, lighting the tile and the port
- A CPU graph for each Netgear switch in the Inspector: the switch's own load over a rolling half hour, with min, average, max and memory used; its own Switch CPU tier in the Telemetry Polling window (15 s default)
- Nemo meter polling runs from half a second to five seconds (was 2 to 60); the power graphs' windows are by time, so a faster meter never shortens them
- The power graphs' window is a slider, from a rolling minute to three hours with hour marks, on the canvas card and in the Inspector (was four fixed chips)
- Silence alerts per device: a toggle under Mute link lines in the Inspector and in Group Edit; while on, the device raises no alert, notification or pulse, its rows leave the boxes, and a struck-through bell sits in the tile's lower right; switching it off shows anything still live at once (#137)
- Netgear switches wear the hops-to-grandmaster chip and the gPTP GM badge in the AVB clock view like the LS10s, and join the wrong-clock-network check: the M4250's steps-removed and grandmaster identity are read beside the timing tables (#116)
- A privileged helper (MpingHelper) puts the time server's addresses on the NICs and takes them off when Mping quits, so nothing lingers on a Mac that is not running it; approved once in System Settings, no Terminal paste; the app's side is in place and the helper's target is added in Xcode (Docs/PRIVILEGED-HELPER.md) — until then the Terminal flow stands (#136)
- Power graphs: each phase readout (L1, L2, L3, N) is a button that hides its line and the axis fits the lines left, so a neutral far above the lives no longer flattens them; the readout stays, dimmed, and the hover panel keeps every phase; saved per graph kind with the device (#138)
- The Inspector gains a Device info section at its foot, just above "Last checked", unboxed: make and model as its heading, firmware and serial, the management and chassis MACs, where a switch takes its time from (with "this Mac" marked) and its own clock against this Mac's, and the last syslog lines it sent here; a plain device shows its learned MAC
- The NTP & Syslog pane is tidied: one row per side with a state word, Apply under the table, and the status as one short line per thing
- Right-click a device to copy the MAC address learned for it; the item is greyed until one has been learned, and the greyed Open Web Interface / Open CLI items now stay grey instead of lighting up
- The NTP & Syslog pane takes a primary and a secondary side, each with its own NIC and address, so the time server can be reached from both switch fabrics; "already carries" is judged per NIC, so an address held by one dongle can still be added to the other; Apply pastes one command for both; the status names each side and refreshes when an adapter changes; the console says which address each NTP client asked (#112)

**Bug fixes**
- AVB link labels wear their own end's gPTP reading; since 9 Sep each chip had been showing the far end's, so a sync timeout on Delay Node North P27 appeared on the P43 chip at the Roof Centre Node
- A switch that is not synchronised no longer writes its NUL-padded NTP source name into the console file

**Fixes**
- The "Mping X is ready" update panel shows what's new: the release notes from the feed, as a list under the version (it said "ready" and nothing else)
- False Link Down on every copper leg of the Roof (16 Sep 22:28): SNMP replies were crossing between polls sharing a switch's socket, so a sweep read a late port-poll reply as its own, its LLDP walk stopped early and 13 links went "missing". Replies are now matched to their request and exchanges on one switch run one at a time; a sweep whose chassis-ID walk returned nothing keeps the last neighbour table; and a link LLDP has lost while both ports still read Up never alerts
- The Inspector's Time row fills within a minute of a launch: the NTP status tier's first lap runs at a few seconds per switch, then settles to its interval (was up to ten minutes of "not read yet")
- The full log window holds every line: the first read takes the switch's whole 200-line buffer and the app keeps up to 2,000 per switch after that; the header says how many are hidden by the MVRP filter
- gPTP raw dumps are no longer cut at 8,000 characters on the way to the console log, so the hops and grandmaster values reach the file and replay (#116)
- The Inspector's Switch log rows follow new lines as they arrive (they read the same log the full window reads) and run newest first
- Exported CSVs (alert history, Device Manager, power history, Export All Logs) open correctly in Excel: they now carry a UTF-8 byte-order mark, so "·", "Ø" and dashes no longer show as "¬∑", "√ò" and "‚Äî"; replay accepts such a file
- The time server's addresses are NTP only: they no longer appear in the device NIC pickers, and a device still sending from one goes back to Auto Routing (noted in the console)
- Open Web Interface works on LS10s from the right-click menu (plain HTTP at the root; was greyed out)

**[Full changelog →](CHANGELOG.md)** — every release since v0.3.0.

<!-- CHANGELOG:END -->
