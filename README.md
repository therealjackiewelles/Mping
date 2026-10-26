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

## v0.8.33 — 2026-10-26

**Enhancements**
- A device left on Auto with no name of its own (a ping device) takes the unit's name from the switch port it sits on, matched by IP address, for the units amp monitoring verifies (for example "P1 250" instead of "New Device"); a name you typed is never changed, and it follows the unit if it is renamed
- A device that has never answered since Mping started now raises its Offline alert once the adapter it is pinned to is online (up, with a link and its address), about 15 seconds after start-up for an adapter that was already online and a minute for one that comes online while Mping is running, so gear not yet switched on at the morning's start-up is flagged; while the adapter is away or has no link, it stays quiet as before, and a device that answered earlier still alerts the moment it stops
- New Settings option "Two-finger scroll pans the map, pinch zooms" (off by default): two fingers on a trackpad pan the map at half the speed of the fingers, in the direction the Mac's Natural scrolling setting gives, pinching zooms, and ⌘-scroll zooms; a mouse wheel always zooms
- Every box where an IP address is typed (a device's IP in the Inspector, the Device Manager column, a virtual network's address, the NTP address) now only takes digits and dots in the shape ###.###.###.###: anything else does not appear, a number over 255 is refused, and the dot is added after each finished number (a typed dot is taken where it makes sense); pasting still works
- A showfile now keeps the names you gave its network adapters in System Settings, so the adapter alerts, the "adapters don't match" panel and the Network reconciliation window say "Switch Management SEC" instead of en7, even on a computer that has never had that adapter (and on Windows)
- Cmd+A on the map selects every device (a hidden group is left out); in a text box it still selects the text
- The meter's side button now reads "Show/Hide meter graphs" instead of "Show/Hide port status box"
- The launch splash: the lines that start the M now begin solid green and dashed like a link line (fully opaque, already two or three dashes long) and turn into the solid white M, instead of fading in and then through white-grey and plain green
- A new LS10's port box shows ports 8, 9 and 10 (not 1 to 3), and the Port Status Box Editor offers all ten of an LS10's ports from the start, before the first poll

**Bug fixes**
- Telemetry Polling: Reset Defaults now also resets Fan speed (30 s) and Spanning tree (20 s); it left those two as they were
- Rig Replay: a Netgear switch's Temperatures graph now draws during a replay (the window followed the wall clock, so the tape's samples sat off the left edge and the plot was blank)
- An offline ping-only tile's chip reads "Last Seen 21:04:12" in full, and the address beside it is left out while it does (there is no room for both); it read "Last Seen…" with the time cut off
- The thermometer dot on the Temperatures plane (Details view) sits in the same corner spot as the ping dot on the other faces; it sat 11 pt in and down
- Cmd+A selects all the text in a text field again (the Edit menu had lost Select All)
- The adapter alerts are one short line each, in the name System Settings gives the adapter ("Switch Management SEC", not en7): "Adapter not found on this computer", "No Link/Cable Unplugged" or "No valid IP address", once per adapter and once per virtual network in use; they are History rows only (no Offline tag, no sound or banner), glowing red while true and yellow once cleared but unacknowledged
- The ping dot on each tile is now exactly centred in the dark disc behind it; it sat a fraction of a point low and to the right
- Rig Replay: a backward seek, a rewind or leaving the replay no longer leaves the Streams view's gold cells from the position you came from; they follow the tape — https://github.com/therealjackiewelles/Mping/issues/146
## v0.8.32 — 2026-10-23

**Enhancements**
- View Master buttons light green while the item is shown and go dark when it is hidden, and hiding link lines hides their labels too
- Device groups: make up to nine in the sidebar's Groups section, each with a name and its own one of nine colours (1 brown to 9 white, one group per colour), and tick devices into them in the Inspector (several groups per device); the colours run as a strip down the left edge of the tile, and the View Master can hide a group's tiles and link lines without touching its monitoring or alerts — https://github.com/therealjackiewelles/Mping/issues/164
- When a switch or device goes offline, or a link between switches goes down, the switches around it are asked for their spanning-tree and port states straight away (once per switch per ten seconds, two-second timeout) and the map is redrawn, instead of waiting for their next turn — https://github.com/therealjackiewelles/Mping/issues/58
- Showfiles (.mpw) carry Mping's icon in the Finder, and a double-click, a drop on the Dock icon or Open With opens one in Mping, asking first if the current showfile has unsaved changes — https://github.com/therealjackiewelles/Mping/issues/165
- An amplifier or LS10 that refuses the HTTP login is left alone for 30 seconds, then asked once more, doubling to ten minutes, instead of being asked again by every poll; a changed user name or password ends the wait at once

**Bug fixes**
- Rig Replay and the golden replay no longer send identity requests or vitals reads to live amplifiers while a tape plays; amp cells come from the tape only, so a replay gives the same result on or off the rig — https://github.com/therealjackiewelles/Mping/issues/156
- A launch that cannot restore the last session no longer writes the example over the working state: it says why, opens the last saved showfile or the example, keeps the file (and a copy from before the launch) until you change something, and logs the reason — https://github.com/therealjackiewelles/Mping/issues/157
- Cut of one half of a redundant pair puts both halves on the clipboard, so Paste makes a new pair instead of a lone half — https://github.com/therealjackiewelles/Mping/issues/154
- Deleting or cutting a selection that holds both halves of a redundant pair asks first, as deleting one half does — https://github.com/therealjackiewelles/Mping/issues/154
- Help › Export All Logs no longer freezes monitoring while the zip is made: the copy and zip of the session's console file (up to 1.4 GB) run in the background, with a console row when the file is ready; the save dialog was never the cause — https://github.com/therealjackiewelles/Mping/issues/144
- With its dongle unplugged, a showfile's virtual interface was listed twice in the Network window (its description, and the Mac's own interface for the same VLAN as a second card); it is one card again
- A saved amplifier password the keychain cannot read (locked, or from another Mac) is no longer replaced by the factory password: no login is sent, the console and Settings say so, and entering the password again repairs it, and Settings says so if the keychain will not keep the new one
- A refused amplifier login reads HTTP 401 in the console (it read "cancelled"); a changed password is now noticed without restarting Mping

**Other**
- The planning window is gone: File › New Workspace asks to save, then clears the one window to an empty map, and a showfile always opens in that one window — https://github.com/therealjackiewelles/Mping/issues/166
## v0.8.31 — 2026-10-21

**Map**
- A tile or location box can no longer be dragged off the edge of the map, where it could not be clicked, selected or dragged back; a group dragged together stops as one at the edge, and a showfile with an item beyond the edge brings it back when opened — https://github.com/therealjackiewelles/Mping/issues/163

**Pop-up windows**
- Pop-up windows (Settings, Network, Fix the Network, the Port Status Box Editor, switch logs, About and the debug windows) stay above the main window while Mping is in front, and cannot be minimised — https://github.com/therealjackiewelles/Mping/issues/159
- Escape closes the front-most pop-up whether or not it has focus; in a text field inside a pop-up the first Escape only leaves the field, and a sheet or help bubble on top keeps its own Escape — https://github.com/therealjackiewelles/Mping/issues/162
- With no pop-up open, Escape clears the search whether or not the search box has focus (a text field being edited elsewhere keeps its own Escape)
- Closing Settings with a changed amplifier username or password asks Apply / Don't Apply / Cancel instead of applying silently, on the close button, Escape, Quit and the update's Relaunch
- Settings is now Mping's own window (⌘, as before)
- The virtual-interface editor and Add Devices ask before Cancel or Escape throws away changes, and a Quit or the update's Relaunch also waits on the virtual-interface editor
- A closed Port Status Box Editor is now let go instead of being kept alive; one left open still costs more the longer it stays open (that issue stays open) — https://github.com/therealjackiewelles/Mping/issues/160

**Link lines**
- Link lines from a switch to its ping-only devices and Nemo meters are routed round other tiles instead of behind them; a device boxed in on all four sides keeps its straight line — https://github.com/therealjackiewelles/Mping/issues/158
- Link lines of different switches are kept off each other's stretches instead of lying on top of each other (they may still cross)
- A link line from a ping device or Nemo meter no longer runs along or hidden under a link between switches, and leaves a busy switch between two links instead of across one; it may still cross one where there is no way round
- Port boxes can sit closer to a ping-only device: the clear space around each tile now uses its real height, not the taller switch height
- When the adapter that reaches a switch is unplugged, every amplifier row behind it goes stale at once (grey, with the time last read) instead of staying green for about four minutes
- When a switch is confirmed offline, its amplifiers are pinged at once and the ones that do not answer go stale within seconds (grey, with the time last read) instead of staying green for about four minutes; no alert is raised for it
- With the adapters unplugged (or a switch silent for 90 seconds), the link lines of the switches that can no longer be read turn red like a link that is down, with no moving dashes, traffic figures or stale readings, instead of looking live (no Link Down alert is raised for them)
- Link lines are drawn twice as thick, in a stronger colour, with longer dashes
- Traffic figures on a link line can sit beside a vertical stretch, with up and down arrows, when no horizontal stretch has room

**Network window**
- Adapters is now split into Physical Interfaces and, at the bottom, Virtual Interfaces; the separate Virtual Interfaces section is gone and everything it held (the showfile's VLAN cards, Add Virtual Interface, the other VLANs on this Mac, remove-at-quit) is in that bottom part; each virtual interface is one card, with the devices set to it behind Show devices

**Under the hood**
- The About window and the console's launch row name the shared core by build number and date only
- The application log notes a Quit held for unapplied changes, and each Escape that closes a pop-up or is passed on, with the reason
- Unused files were removed from the app

**[Full changelog →](CHANGELOG.md)** — every release since v0.3.0.

<!-- CHANGELOG:END -->
