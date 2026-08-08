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

## v0.7.30 — 2026-08-07

Building a workspace is much quicker: add devices in bulk, then paste their names and addresses in from a spreadsheet.

### Building a workspace

- **Add Devices…** in the Devices menu (⌥⌘D) — choose how many of each device type and add them all at once. They lay out across the canvas without overlapping, and the whole batch is a single undo.
- **Paste from Spreadsheet** in Device Manager — copy a column of names, or two columns of names and addresses, and paste them straight in. More rows than devices creates the devices needed, so a workspace can be built from an empty canvas.
- Pasting into a row fills from that row down, so you can top up part of a list.
- Pasting into the address column fills addresses, even when the values do not look like typical addresses.

### Fixed

- **Pasting no longer ruins the device you paste into.** The cell was taking the whole copied block and committing it as that one device's name, leaving every other device correct and that one wrong.

### Worth knowing

Pasting directly into a cell only shows once you finish editing that cell — the table will not refresh mid-edit, because doing so would take the cursor away while you type. The **Paste from Spreadsheet** button updates immediately and needs nothing selected.
## v0.7.29 — 2026-08-07

Tested on a live show rig. The headline is heat: the app now uses less than half the CPU it did this morning, and a fault that made it get steadily worse the longer it ran is fixed.

### Much cooler

Measured on the same rig, same workspace, 16 of 16 links live throughout:

| | CPU |
|---|---|
| v0.7.28 | 79% |
| **v0.7.29** | **35%** |

Three separate causes, found by profiling rather than guesswork:

- **It got worse the longer it ran.** Raising the console log to 50,000 entries in v0.7.28 meant that once the log filled, every single line copied the whole log. Fine on launch, bad after ten minutes. It now trims in blocks. This was a fault introduced in v0.7.28 and is the main reason to update.
- **The map was describing itself to nobody.** Roughly 60% of the work in each canvas redraw was macOS accessibility machinery, rebuilding descriptions of every tile and link on every pass. See the note below.
- **One reading arriving caused several redraws.** A single poll updates fibre results, bandwidth, temperature history and alerts, and each one separately told the screen to redraw. They now share one.

### A link going down is now caught in about 4 seconds

Confirmed on the rig by taking a redundant leg down:

- **An alert is raised even when the link is redundant** and nothing else appears to break — the case where a rig quietly loses its backup path. This had never been seen work before.
- **Detection takes about 4 seconds**, and recovery about 5. Previously both took around 45.

### Fixes

- **SFP temperature and optical readings no longer stop on some switches.** A single failed or timed-out discovery could empty a switch's SFP list, and once empty the readings had nothing to attach to, so that switch stayed blank until a later sweep happened to rediscover it. The list now keeps its contents when a discovery comes back empty. The same protection was added to the per-port list.
- **Selecting several devices works properly.** Dragging a selection box towards the sidebar no longer stops it growing, releasing outside no longer leaves the box stranded on screen, and it selects what it covers.
- **Fibre Box Editor** shows the real fibre label instead of a preview that had drifted a long way from it, and its bold, line spacing and border controls now do something.
- **Undo no longer risks a burst of false Link Down alerts.**

### New

- **Paste device names and addresses straight from a spreadsheet** into Device Manager. Copy the columns, select a row, paste. Two columns are read as name then address; a single column is worked out from what it contains. More rows than devices creates the devices it needs.

### Worth knowing

**The map is no longer reachable by VoiceOver or Voice Control.** That was a deliberate trade for a third of the CPU saving. Everything else — sidebar, inspector, Device Manager, port tables, menus — is unaffected.

**CPU is much better, not solved.** The system compositor still spends a significant amount drawing the canvas, so the machine will still warm up on a large workspace. That work continues.
## v0.7.28 — 2026-08-06

A stability baseline before starting a larger change to how the canvas is zoomed. Mostly performance and interface fixes made away from the rig, so several items still need confirming on live hardware — they are listed at the end.

### The app should be much cooler and quieter

A 30 second profile of a live rig running at 85% CPU found the cost was not the SNMP polling at all — the poller threads were idle over 99% of the time. It was the app redrawing the whole canvas every time any reading arrived, many times a second.

- Redraws are now grouped and capped at four a second. Readings still arrive and are acted on the instant they land; only the picture is paced. Anything you do yourself redraws immediately, so the canvas still feels immediate under the hand.
- Telemetry polls are limited to three at once rather than seven all competing for the same queue.

### Console output

- Every entry is now numbered, like Wireshark, so you can refer to a specific line. The number is kept with the entry, so it stays put when you filter.
- The log keeps 50,000 entries instead of 3,000.
- Scrolling up stops the log following, and a **Jump to latest** button appears. New entries keep arriving underneath rather than shoving what you are reading up the screen.
- The jitter and the occasional blank console are fixed. Auto-scroll was animating towards a target that had already moved.
- Rows are tighter, so about half as many again fit in the window.

### Windows and tables

- Device Manager and Device Ports no longer open wider than the app window and hang off the side of the screen. They size themselves to the window and follow it as you resize.
- Their columns shrink to fit a narrow window before falling back to sideways scrolling. Column widths you have set are remembered and restored — they are never overwritten by the fitting.

### Fibre Box Editor

- The preview now shows the real fibre label rather than a lookalike that had drifted a long way from it, including the copper state it never had.
- Bold text, line spacing and border width were connected to nothing. All three now work.

### Under the hood

- Fan speed and spanning tree are now polled separately on their own intervals, with their own sliders. If either misbehaves, the **Split fan speed and spanning tree** toggle in Telemetry Polling puts them back with no restart.
- Undo could apply an out-of-date topology rebuild, which had the potential to raise a burst of false Link Down alerts and immediately clear them.

### Still to be confirmed on hardware

These are believed right but have not been proven against real switches: the CPU improvement, the poll limit, the link-down alert for redundant links, link detection timing, and the fan/spanning-tree split. Each is tracked on its issue with what to check.

**[Full changelog →](CHANGELOG.md)** — every release since v0.3.0.

<!-- CHANGELOG:END -->
