# Changelog

All notable changes to Mping are documented here.
Versioning: `v0.x.0` = feature milestone · `v0.x.y` = bug fix · `v1.0.0` = first commercial release

---

## v0.8.2 — 2026-08-20

**Bug fixes**
- Standby amps read as "standby" on the AVB power face, not FAULT — an amp told to stand by has its power supply off by design, and the amp's own state word now wins before any electrical judgment

---

## v0.8.1 — 2026-08-20

**Features added**
- Nemo graph box is resizable: drag the bottom-right grip (up to 780×560, size remembered per device) — the graph absorbs all the extra room, and a wider box draws more points, so expanding genuinely shows more detail
- Nemo graph box exports its complete recorded history as CSV — every series, ISO timestamps — via the CSV button in its header
- Nemo graph box hover readout moved beside the card: the graph itself is never covered, and only a thin guideline marks the hovered moment

**Bug fixes**
- Jitter alerts require persistence: one RTT spike used to hold the rolling average over the limit for minutes and fire a "sustained" alert — the alert now forgives the single worst sample, so only repeated spikes register (displayed jitter unchanged)
- Nemo graph scale stops snapping every tick: bounds round outward to a clean grid step and the long-window sample thinning is anchored to the newest data, so the line holds still while values drift
- Nemo box resizing tracks the cursor instead of lagging and jittering, and click-dragging on the box no longer starts the canvas selection band underneath it

---

## v0.8.0 — 2026-08-19

**Features added**
- IME Nemo 96HD power analyzers (#46): mains power on the map — the meter's full reading set in the inspector, fresh measurements every 5 seconds on a dedicated loop, spoken over the module's own web protocol (its embedded server speaks broken HTTP; Mping now speaks it back), with a Module Password field on the device
- Nemo graphs: phase voltages, line-to-line voltages, phase and neutral currents, per-phase power, power factor, and voltage/current THD — in the inspector, and in a draggable graph box that pops out of the tile with 15m/30m/1h/3h windows; console replays draw them too
- Amplifiers alert panel: session-gated (hidden until amps are detected on the rig), carrying the first two amp alerts — media-clock unlock and stream loss against the session's high-water mark — evaluated identically live and in replay
- AVB clock view animates the clock tree outward from the grandmaster, placed on real rig hop numbers
- Streams view grows a detail rail: locks, faults, errors, format
- Clock faces wear lock glyphs with resolved grandmaster names; an unlocked amp prints its own status word, never a guessed master
- AVB temperature cells read degrees and humidity, state only when hot
- Power faces surface the 15V rail errors and the amp's fault message
- Small LS10 racks (three amps or fewer) fold their port box into the tile itself; LS10 tiles drop the temperature badge — the hardware provides none
- Alert rows wear the P/S network badge beside the device name
- Sharp canvas text at any zoom — supersampled glyphs, same layout — on tiles and port boxes alike (#55)
- The launch map fills as data lands instead of waiting for a full polling lap
- Console: the complete rig in one log, a tick-box filter tree (device type, then poll category), and tape playback that streams rows on the tape's own clock

**Bug fixes**
- Ping RTT no longer counts the app's own scheduling — values match terminal ping
- AVB rack cards share one font size fitted to a common worst case, the ID column stays constant, and cells read as a table: fixed ID column, hairline rule, data
- Amp validation counts physical units, resolves each leg's parent by subnet rather than label, and reports genuinely ambiguous legs as unplaced instead of guessing
- Replay validation understands sub-devices, and legacy LS10 labels migrate without minting false SNMP folders
- Bandwidth labels never vanish one-sided — a quiet direction says 0
- Links and alerts wear the same name the tile does
- LA7.16 Amp Vitals console dumps no longer truncate

---

## v0.7.49 — 2026-08-17

**Bug fixes**
- gPTP grandmaster badge sits on the actual grandmaster — hop counts are 1-indexed, so "1 hop" is the GM itself
- Switch-to-switch links: a switch's word about its own ports now beats its neighbour's guess, so the constant "port 1" every LS10 broadcasts can no longer mislabel a link that really rides port 2
- A link that drops and returns under a different port identity no longer leaves a permanent red ghost on the map
- Link bandwidth comes from the Netgear octet counters only — total measured traffic, not AVB reservations; the LS10 figure (also being read 1000× too large) is deliberately dropped
- A legitimate zero on one end of a link no longer hides the other end's measured traffic
- Netgear-to-Netgear trunks always draw as fibre, including where the SFP offers no diagnostics
- Selected tiles no longer go jagged when zoomed in
- Missing 24V aux input is no longer a fault — that input is optional kit
- Port box cells are sized for a worst-case IP address, so addresses always show whole
- Phantom dual links: VID text can no longer mint a far port number, and idle RSTP earns no root crown
- Paired tiles can be dragged again

**Features added**
- AVB view: five live per-amp tabs — Power, Streams, Clock, Temperature, Errors — mirrored in Device Debug
- Everything polled now reaches the console log and replays from a tape: amp vitals, raw LS10 responses, and a port-resolution trail explaining every switch-to-switch link
- Rig Replay opens without a password
- Rack editor: drop a port onto an occupied unit to swap them, with motion
- Port boxes: own close button, amp IPs in Device IP style, steadier cell fonts, quieter card colour
- Amp identity requests authenticate before an amp is trusted
- NIC picker names the Mac's own adapters

**Prep work started**
- Sharp tile text at any zoom: re-render the canvas at the settled zoom level instead of stretching the 1× picture

---

## v0.7.48 — 2026-08-15

**Bug fixes**
- Stripped LS10 fan/temperature readings the hardware never actually provided
- Redundant rigs: links match by chassis identity before name — duplicated names across networks no longer block link drawing
- Link labels stay at the port they describe and no longer vanish between close tiles
- Port status boxes never overlap device tiles
- Tile badges (ROOT, gPTP GM, data chips) ride the tile edge instead of crowding the name row
- Port box tether is quieter and fades away as the box docks
- Clock-flow animation never runs along an STP-blocked path

**Features added**
- Rig replay transport in the sidebar: play, stop, ±1 minute, timeline, open tape, exit
- AVB view: gPTP grandmaster tags, clock flow from the grandmaster toward listeners, four sub-views (stream locks / amp temps / clock / streams)
- Amplifier monitoring — read-only and identity-gated: nothing is ever polled unless LLDP already shows a known L-Acoustics amp there, and an imposter locks the port out
- Amp vitals in the port racks, every AVB view reading "number - model - data"
- Left-edge toolbars glide open on hover to name their buttons
- LS10 port-error view ("err N")
- Amplifier polling master switch in Preferences (default off)

**Prep work started**
- Amp channel-fault flags and stream-unlock alerts

---

## v0.7.47 — 2026-08-13

L-Acoustics LS10 switches become first-class citizens, and spanning-tree rendering gets materially more honest on every rig.

**Full LS10 monitoring — no SNMP required.** LS10s are polled entirely over their own HTTP interface, read-only: port status boxes, link-state at the same fast cadence as the Netgears, device temperature into the graphs and alerts, per-port bandwidth on the link labels, fan readings, and full topology participation — links to Netgears and between LS10s, chassis-identity matched, with root badge, blocked-path dashes and flow direction. Discovery uses the unit's engineer-set name. The SNMP pollers no longer waste timeouts asking LS10s questions they'll never answer, so the console stays quiet.

**Blocked links can no longer masquerade as live ones.** Whether a link is STP-blocked is now judged from both ends — only the blocking side ever reports it, so depending on polling order a blocked redundant path could previously render as a live flowing link. Flow animations are also properly torn down when a link's direction changes or stops: after an STP failover and recovery, the re-blocked alternate now sits correctly still.

**Copper links restyled** (with a partially colourblind eye doing the tuning): a quieter grey line that no longer outshines live fibre, a legible port label, and flow dashes that actually read against the line.

**Device Manager: pasting into a cell you're editing** now fills from that row with the clicked cell carrying its value — previously the pasted-into cell ended up blank.

**Console CSV export always writes the complete log**, regardless of the device filter — the filter is a view, not a scope. Twice a filtered export silently discarded the diagnostic data it was taken for.

**Steadier link identities on slow rigs:** a poll that fails to read a switch's chassis identity no longer wipes the stored one, which was quietly degrading link matching on rigs with tight SNMP timeouts.

---

## v0.7.46 — 2026-08-11

Showfile-prep quality of life: redundant devices in bulk, spreadsheet pastes that land where aimed, and planning a new show while the current one stays monitored.

**Device Manager: pastes follow the table you clicked.** Pasting a spreadsheet block into the secondary table used to overwrite the primary rows: keyboard shortcuts were claimed by whichever table sat higher in the window, and clicking the secondary table's Linked To column didn't move focus. Cmd-V now pastes into the focused table starting at the clicked row, the secondary section has its own Paste from Spreadsheet button (row-aligned with the primary table), and clicking anywhere on a secondary row selects it.

**Redundancy in bulk.** Multi-select rows and one checkbox click marks them all redundant. The secondary list always mirrors the primary order — tick, untick and re-tick in any sequence and the rows stay aligned for pasting.

**Planning windows.** File > New Workspace opens a separate window with a blank workspace and monitoring off — build next week's file while the current gig stays monitored in its own window. Menus act on whichever window is focused. Closing a planning window tears down its engines completely.

**File > Save restored.** The multi-window scene change silently dropped Save, Save As and Cmd-S from the File menu; they're re-anchored to a menu position that survives it.

**Port-box guard.** A truncated SNMP walk (short timeout, busy switch) can no longer shrink a switch's port table — fewer rows than the switch's fixed port count means a bad walk, and the previous table is kept.

---

## v0.7.45 — 2026-08-11

Completes v0.7.44's topology-matching overhaul — update straight to this one.

**Links are now matched by chassis identity first.** LLDP's own identity primitive — the chassis MAC each switch advertises — is now the primary match key, compared against the chassis identity Mping already reads live from every switch. Switch-to-switch rows that advertise no system name (standard on many uplinks) resolve by protocol identity instead of depending on the far end's name row. The ARP-learned MAC remains a second exact key for endpoints whose chassis ID is simply their NIC address, and name rules drop to what they should always have been: a fallback, used only when nothing exact exists, refusing to bind when ambiguous.

**Auto-named devices contribute no typed name to matching.** With name source set to Auto, the LLDP-discovered name is the maintained identity — the typed name underneath (possibly stale, possibly mispasted, invisible on screen) no longer participates in link matching at all. Under manual naming the typed name remains a legitimate identity, as it should be.

Together with v0.7.44's exact-first tiers and LLDP table guard, this closes the phantom-link investigation: wrong-device links can no longer be minted by hidden stale names, and the map's identity model now leans on the protocol, not on strings.

---

## v0.7.44 — 2026-08-11

Three fixes, all traced on a live two-machine rig — including the end of a phantom-link mystery that had survived reboots, updates and a rebuilt workspace.

**Topology matching: exact identity now beats fuzzy guessing.** A workspace was found carrying user names accidentally scrambled against the physical switches (a shifted paste from an older version, invisible because tiles display the automatic LLDP names — which were all correct). The link matcher's substring rules, running per candidate in list order, let the wrong device's user name steal LLDP rows from the right device's exact name — drawing live, unclearable phantom links between switches that were never connected. The matcher is now tiered: exact matches (LLDP name, user name, IP, chassis MAC) are checked across every candidate first and win outright; substring heuristics only apply when nothing exact exists; and an ambiguous fuzzy match refuses to bind at all. A link drawn to the wrong switch is worse than a link missing until better evidence arrives — the same honesty rule the flow arrows follow.

**LLDP tables survive truncated sweeps.** On a machine with a tight SNMP timeout, a sweep whose neighbour walk timed out erased the switch's LLDP table outright — links flapped, alerts churned, and switches sat at "no neighbours" despite healthy cabling. The neighbour table now keeps its last data when a walk returns empty, the same protection port and SFP tables already had.

**Rig replay: capture recordings now play back fully.** Raw capture-mode walks log at info level and the tape loader was filtering them out, so bandwidth never replayed. One-line fix; capture tapes now drive the complete pipeline.

If a workspace was built with an affected earlier version, correcting (or simply blanking) the user names in Device Manager clears phantom links immediately — the automatic names carry the truth.

---

## v0.7.43 — 2026-08-10

Two fixes, both found and confirmed on a live rig.

**A disconnected unit's temperature no longer pretends to be alive.** When a device goes offline, its tile shows the last known temperature in red — visible, but unmistakably history — and its rolling temperature graph freezes at the final real sample and slides into the past, instead of painting edge-to-edge as if data were still arriving. Both recover the moment the device reconnects.

**Acknowledged alerts survive undo.** Pressing ⌘Z after acknowledging an alert brought it back live and re-notified you — undo's workspace restore made every live condition look like it had recovered and re-fired. Undo now carries the entire alert state across untouched: acknowledgements, armed links and jitter streaks all survive, because undo is for workspace edits, not for alert history.

---

## v0.7.42 — 2026-08-10

**SFP alerts point at the module that is hot.** An SFP over-temperature alert now pulses the affected module's own link label yellow instead of the whole parent switch tile — the tile keeps its pulse for things genuinely about the switch (offline, RTT, jitter, its own sensors). Same latching, same acknowledge behaviour, same zero-cost render-server pulse.

**Fibre link labels redesigned — clearer and quieter at once.** The port number now sits in a chip carrying the link-state colour (muted when healthy, saturating on caution), replacing the old 2.5pt edge sliver, and one value leads beside it: signal loss on the Overview, SFP temperature on the Temperatures plane — each plane answers its own question, never both at once. Zoomed out, labels collapse to the chip alone, following the tiles' progressive disclosure.

**Readable without relying on colour.** Built with partially colourblind eyes on the team: value digits run near-white at medium weight, caution states embolden as well as colour, and the label background keeps a minimum opacity so the animated link dashes behind it can never wash out the numbers.

---

## v0.7.41 — 2026-08-09

**Crash fix — update recommended.** Reading the Mac's own ARP table (a local command that feeds MAC learning and port-box IP labels) used a file-reading call that raises an uncatchable error if the command's pipe tears down at exactly the wrong moment. The result was a silent whole-app crash from a background task — rare, but the read runs every polling lap, so a long session could hit it. It is the same crash class the ping engine was hardened against previously; this was the one remaining call site of the unsafe API, now fixed the same way. A failed read simply means the ARP table skips one cycle.

---

## v0.7.40 — 2026-08-09

**The STP plane is gone — on purpose.** The map itself has always told the spanning-tree story: the root bridge wears its gold badge, blocked redundant paths draw as amber dashes, and traffic-flow arrows animate toward the root. The dedicated STP plane was a second copy of that same truth, and second copies grow their own bugs — it was found showing the secondary network's switches while the Primary tab was selected (#84). Removed rather than repaired: the plane switcher now offers Overview and Temperatures, and STP state lives in exactly one place.

**The example workspace demonstrates flow direction properly.** Its fabricated spanning-tree data lacked the designated-bridge votes real switches report, so the Stage Left ↔ Stage Right link — the only active link not touching the root — could not prove a direction, and the app (correctly) refused to animate a guess. The example now seeds the same votes a real rig would, and every active link animates toward the root. Existing example workspaces regenerate on first launch of a fresh install.

Also: the project README now carries a full illustrated feature tour for AV engineers, shot entirely from the example workspace.

---

## v0.7.39 — 2026-08-09

Two live-monitoring fixes and a major new capability — and the new capability found one of the fixes.

**New: Rig Replay (issue #82).** Debugging > Rig Replay (password-gated) loads a Console Output CSV export and drives the whole app from it — pings, topology, port states, temperatures, SFP signal, STP, alerts — through the same pipeline live polling uses. The tape is validated against the open workspace by IP before it can start, playback runs at 1×/10×/30×, and the workspace carries a REPLAY watermark for the entire session so a recording can never be mistaken for the live rig. A ten-minute console export now stands in for the rig at a desk; the same tape replayed twice gives identical conditions, which live hardware never does. Recordings made with capture mode (`MPING_CAPTURE=1`, also new) additionally replay port bandwidth and complete STP detail.

**Fixed: three readings were being delivered at a third of their configured rate.** A 23-minute rig capture showed switch temperature, SFP temperature and dropped packets arriving every ~90s instead of every 30s — the cause of the recurring "reading has stopped updating" warnings. The three same-interval polling loops started together, stepped through the device list in lockstep, collided on the same switch every turn, and forfeited a whole lap per collision. Loops now start staggered and retry a busy switch in place, and SFP readings skip switches with no optical modules fitted. (Verification on the rig is issue #83.)

**Fixed: phantom links.** When an LLDP row carried no remote-port information and the far switch's table had not arrived yet, the link builder guessed the far port by assuming symmetric numbering — fabricating links between port pairs that do not exist, which then died red and fired Link Down alerts. This fired live during every topology assembly and was caught by replaying a real tape. An unknown far port now skips the pass; the next sweep supplies the true reciprocal row. No more inventions.

Also in this release: every SNMP walk and get can be recorded in full raw form with `MPING_CAPTURE=1` for replay tapes, the STP tier logs its complete table (designated bridges, port roles, root identity), and fan speeds are logged parseably.

---

## v0.7.38 — 2026-08-09

**Ping times are now measured by the kernel, not the app.** Round-trip figures were reading 1–9ms for devices that terminal ping showed steadily under a millisecond. The cause: the RTT was stamped after the app's low-priority ping thread got rescheduled, so with a whole cycle's pings fired at once, forty threads woke together and the last in line inherited the queue as "latency". The kernel now records the exact arrival moment of each reply at the socket, so the number is immune to the app's own scheduling — verified on a live rig, where readings match terminal ping. A side benefit: jitter alerts lose their biggest source of false variation, since that noise fed directly into the jitter maths. No thread priorities were raised; the low-power design is unchanged.

**New: workspace background image** (issue #81, first release). Devices > Background Image > Set Image… places a venue plan, stage plot or rack elevation behind the tiles — PNG, JPEG, TIFF, HEIC or a PDF's first page. It is downsampled at import and stored inside the .mpw, so the workspace stays one portable file. The image arrives unlocked for placement (drag to move, corner handle for aspect-locked resize), then Lock in Place makes it invisible to input — clicks and the selection box pass straight through. Smart Invert is on by default: black-on-white plans render as light lines on the dark canvas while coloured zones keep their colour; toggle it off for photographs. The image is processed once into a cached bitmap and rendered as a static layer, so it costs nothing while monitoring runs.

---

## v0.7.37 — 2026-08-09

Monitoring efficiency and honesty, plus a round of workflow polish.

**Ping response is now a prerequisite for SNMP polling.** A switch that ping has confirmed offline cannot answer an SNMP walk either — every attempt just burned a full timeout inside the polling rotation, slowing the lap for every switch that was answering. All automatic SNMP paths now skip confirmed-offline devices and resume by themselves the moment ping sees the device again. On a partially powered rig this makes polling of the live switches noticeably more even. (New in this build — worth watching on first run.)

**The map fills fast at launch.** Topology starts from nothing every boot by design, but waiting a minute-plus for the rotation to paint it was wrong. Two full discovery rounds now run up front — still throttled three-at-a-time — so the map fills in tens of seconds. Link alerts arm only after a link has been seen up on two consecutive passes, so the assembly no longer fires a storm of false "link down" alerts while it builds.

**Flow arrows only when the data proves a direction.** Some links showed animations flowing the wrong way — stably. When the two ends' spanning-tree votes tie and neither side can see the root, the app previously picked a direction arbitrarily and stuck with it. It now draws no arrow rather than a guessed one.

**Fibre classification held, duplicate walks removed.** SFP temperature was being read twice per lap; now once. TX/RX stays in the discovery sweep deliberately — optical power is how fibre is told from copper, proven the hard way when removing it turned every fibre link copper on the live rig (caught and reverted within minutes, never released).

**A reading that stops updating now leaves a trail.** The inspector's stale-reading warning was ephemeral — nothing to investigate afterwards. Every crossing into stale and every recovery is now logged to the console with age and threshold, so an exported CSV shows exactly which reading went quiet, when, and why. Offline devices are exempt: their silence is expected and already covered by the offline alert.

**Workflow polish**
- Hold **Option** to flip every tile's address line from IP to its learned MAC address (session-learned from the host ARP table; "MAC unknown" until the device has actually been seen).
- Console Output window resizes freely in both directions and remembers its size.
- Inspector: Name and IP share a row; the device type picker gets the full width so long type names stop truncating. The name-source checkbox now reads "Auto".

---

## v0.7.36 — 2026-08-08

One fix: the jitter quieting in v0.7.35 did not hold — sixteen alerts within seconds of launch. Two holes, both now closed.

- **Jitter needs a real sample base.** It was computed from as few as two pings, and the first pings of a session land during the startup storm, when every switch is being swept at once. No jitter figure exists now until nine samples (~16 seconds) — variation measured from two points is not a statistic.
- **"Three consecutive cycles" now means cycles.** The breach counter advanced on every alert evaluation, and evaluations run from several places — one ping cycle could pass the gate in milliseconds. The counter now only advances when a genuinely new ping sample exists.

Expected behaviour after this: silence for the first ~16 seconds after launch while a base is measured, then jitter alerts only for breaches that persist across three real ping cycles.

---

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

---

## v0.7.34 — 2026-08-08

Two fixes, both found in the field the same day.

### Opening a recent workspace works again

Clicking an entry in File → Open Recent closed the menu and did nothing. macOS forgets an app's file permissions between launches, and only the last-used workspace kept a stored permission — every other recent was unreadable, and the failure was silent.

Every recent now keeps its own stored permission and opens on click, across restarts. Entries saved by older versions ask once, with the file already selected in the dialog — one click re-grants access for good. A file that genuinely cannot be read now says so instead of doing nothing.

### The console no longer drowns in "Unmatched neighbour"

Running a workspace that monitors only the switches — a handover copy on a second machine did exactly this — flooded the console with error lines: every amplifier the switches could see was reported as an unmatched LLDP neighbour, on every topology rebuild, a few seconds apart. 1,950 error lines in 100 seconds, all saying the same fifty things.

A neighbour that is not a monitored device is information, not a fault. It is now reported once per session, at info level, in plain words.

---

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

---

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

---

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

---

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

---

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

---

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

---

## v0.7.27 — 2026-08-04

Tested by taking a redundant link down on a live show network and watching what the app did, frame by frame. It turned up several ways a failed link could go unnoticed.

### A failed link is now visible

- **A copper link between two switches no longer disappears when it fails.** Previously it was simply forgotten and vanished from the map — the redundant leg you would never notice failing by any other means. It now stays put and turns red. Copper links to endpoints like laptops and access points still come and go as before
- **A dead link shows red even when spanning tree had it blocked.** The blocked colour was winning, so a failure on a redundant leg looked exactly like normal operation
- **Two links between the same pair of switches now sit side by side.** They were being drawn exactly on top of one another, so the second link was invisible underneath the first
- **Link failures show up in seconds again.** A change in v0.7.26 let the slow background scan monopolise polling, so a dropped link could take the best part of a minute to appear. Each switch is now polled independently

### Fixes

- Fibre labels no longer swap in front of and behind each other every few seconds
- A link that recovers is picked up sooner — the switch it belongs to is re-read straight away rather than waiting its turn
- Temperature graphs, the console log and device naming fixes from v0.7.26 carried forward

---

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

---

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

---

## v0.7.24 — 2026-08-03

### Mping runs on macOS 13 Ventura again

**If Mping refused to install on your Mac, this is the release to get.**

Previous builds were accidentally marked as requiring the very newest macOS, so they would not install on anything older — even though Mping has always been documented as running on Ventura or later. That was a packaging mistake, not a real requirement.

- **Minimum is now macOS 13 Ventura**, as documented
- Nothing else changes — no features were removed to achieve it

One small difference on Ventura: in the workspace search box, Tab no longer arms reverse-cycling through results. Enter still cycles forward as normal.

---

## v0.7.23 — 2026-08-03

### Adding devices

- **A name is no longer required** to start monitoring. It is a label for you, not something the network cares about — only an IP address and a Ping NIC are needed now
- **Setup completes when you click away**, not only when you press Enter. Moving from one field straight to another used to leave the change uncommitted
- **New devices no longer land on top of each other.** Adding several in a row lays them out in a row instead of stacking them in one spot where the ones underneath couldn't be seen or clicked
- Setup starts with the IP field focused, since that is what it actually needs
- Choosing the Ping NIC now completes setup immediately — it is usually the last step

### Under the hood

- Whether a device is ready to monitor is now decided in one place. The rule was written out twice, which is why setup behaved differently depending on how you left the field
- The pulsing highlight on unfilled fields is created and destroyed as you type; it now cleans up after itself properly

---

## v0.7.22 — 2026-08-03

### Temperature graphs

- **The scale now fits the readings.** The graph used a fixed 15–70°C axis, so a switch moving 43°C to 46°C barely registered. It now scales to the temperatures actually on screen, plus 5°C either side — a few degrees of movement is immediately obvious, and two sensors drifting apart is easy to see
- **A steady sensor still looks steady.** The 5°C padding keeps the axis at least 10°C tall, so normal fluctuation reads as small rather than filling the plot
- **Curved lines** instead of straight segments, so a trend reads as a trend. Every reading is still plotted exactly — nothing is smoothed away
- **30 minute window** by default instead of an hour, switchable between 15m, 30m and 1h from buttons on the left of the workspace
- Fan speeds keep their fixed scale — they sit behind the temperature lines as context, and rescaling them would make idle fan noise swing across the graph

### Telemetry

- **Fixed SFP signal readings on the faster optical poll.** Optical power is reported in thousandths of a dBm; it was being read as hundredths, which would have shown healthy links at around −61 dBm and marked them as failed. Found and corrected against live hardware
- **Individual readings can no longer be switched off** — the polling controls now set how often each one refreshes, not whether it happens. Switch temperature and dropped packets refresh every 30s, SFP signal every 20s, SFP temperature every 30s, port state every 5s

---

## v0.7.21 — 2026-08-01

### Link failures show up in seconds

- **A dead link turns red on the map almost immediately** instead of waiting for the next full telemetry pass. Link state is now read on its own quick schedule, separate from the heavier data that only needs occasional refreshing
- **A pulled cable and a fibre that has lost light look the same**, because operationally they are — the link is down either way
- **Copper links finally report properly.** They carry no optical telemetry, so port state is the only liveness signal they have; they now use it
- **Port boxes track ports coming up and going down** at the same quick cadence

### Under the hood

- Individual readings — switch temperature, SFP temperature, SFP signal, port state, dropped packets — can each be polled on their own schedule instead of all arriving together on one slow pass. Reading a single value now asks the switch only for that value
- A missed or timed-out response is never mistaken for a failure: the previous reading stands until the switch answers again

---

## v0.7.20 — 2026-07-31

### Performance & Heat

This release is a CPU pass, driven by profiling an optimised build against a full live rig.

- **SNMP polling costs a fraction of what it did** — parsing switch telemetry, not talking to the switches, turned out to be the app's biggest CPU cost. Reading each value ran a freshly-built regular expression, and every line was searched up to nine times over. Both are gone, along with the allocations behind them; the parsers were checked against real switch output to be certain nothing reads differently
- **Device tiles no longer redraw on every ping** — a tile's name, IP, and type row were being re-laid-out (including their shrink-to-fit text sizing) each time any ping result landed, for every tile on the canvas. Only the latency badge and heartbeat update now
- **The debug console no longer runs when it isn't open** — every ping and every telemetry poll was assembling and storing log entries, including full raw switch output, whether or not anyone was looking at them
- **Animations pause only when the window genuinely can't be seen** — minimised, hidden, covered, or on another Space. Mping left visible on a second monitor keeps animating while you work in another app

### Devices

- **Open CLI** — right-click a switch to open its command-line interface (port 4444) in your browser, alongside Open Web Interface

### Fixes

- Dead (red) fibre links no longer show flowing traffic animation

---

## v0.7.19 — 2026-07-24

### Port Status Boxes

- **Layouts persist properly** — box visibility, rack columns, placed ports, and label style now save and restore with the workspace; switching a box to Grid and back no longer discards the rack
- **Racks appear on open, red until verified** — a reopened workspace shows every configured rack immediately with its labels, each cell red ("remembered") until the first SNMP poll confirms the port, then green (up) or dark (down)
- **Redundant pairs share box geometry** — configure a switch's box and its redundant peer mirrors position, size, and mode (each keeps its own port arrangement)
- **Search dims non-matching cells** so the amp you're looking for stands out in the rack
- **Cell text auto-sizes** to the largest that fits each box's longest label — bigger and readable when zoomed out, never truncated
- **Global label toolbar** on the workspace's left edge sets every box to LLDP Name / Device IP / Drops at once
- **Editor multi-drag** — ⌘-select several ports and drag them into the rack together

### Devices

- **Amp IPs resolve on site** via the switch's LLDP management-address table; phantom (logical) ports filtered out so switches show only real ports

### Performance

- **Tile dragging is smooth** — moving a tile no longer re-renders the inspector, port boxes, and every fibre link each frame

### Alerting

- Offline alerts only fire for devices that were online this session

---

## v0.7.18 — 2026-07-24

### Fixes

- **Port status boxes now persist** — box visibility, layout, rack columns, placed slots, and label style were being stripped when a workspace was reopened; they now save and restore fully with the .mpw
- **Rack layouts survive mode switches** — flipping a box to Grid and back no longer discards the amp-rack arrangement

### Rendering

- **Sharper zoomed-in canvas** — tiles drop their shadows past 1:1 zoom so text re-renders crisply instead of magnifying a bitmap, and the heartbeat, alert-pulse, and fibre-dash graphics now re-render at the zoomed resolution

---

## v0.7.17 — 2026-07-24

### Port Status Boxes

- **Dropped-packet view** — cells can show each port's discard counters as ↓in ↑out, so a link that's dropping packets stands out at a glance
- **Cycle button** beside the port-box reveal button steps each cell through LLDP Name → Device IP → Drops without opening the editor

---

## v0.7.16 — 2026-07-24

### Port Status Boxes

- **Phantom ports gone** — switches list logical interfaces (link-aggregation groups, VLANs, CPU) in their IF-MIB alongside real ports, which were showing as extra ports; only physical Ethernet ports appear now
- **Editor**: ⌘-click several tray ports and place them in one go, plus an **Auto-fill** button that drops every unplaced port into the rack in order
- **Wider cells** so full IP addresses show on the face instead of truncating

### Rendering

- **Sharper on all displays** — the fibre-link, ping-pulse, and alert-border graphics now render at the screen's native resolution (they were drawing at half-resolution on Retina), and tile dimensions and font sizes are pixel-aligned so text and edges stay crisp, especially on standard (non-Retina) monitors

---

## v0.7.15 — 2026-07-24

### Port Status Box Editor

- **Multi-select placement**: ⌘-click several ports in the tray, then click a rack slot to drop the whole run in order — no more placing them one at a time
- **Auto-fill**: one button drops every unplaced port into the empty slots in port order, building a full rack instantly

### Port Status Box

- **Wider cells** so full IP addresses show on the face instead of truncating

---

## v0.7.14 — 2026-07-24

### Port Status Boxes

- **Phantom ports removed** — switches list link-aggregation groups, VLAN interfaces, and a CPU/management interface in their IF-MIB alongside real ports; these logical interfaces were showing as ports (indices up to 74 on a 30-port switch). Only physical Ethernet ports appear now

---

## v0.7.13 — 2026-07-24

### Port Status Boxes

- **Amp IP labels now resolve on site** — endpoints that advertise a management IP over LLDP (L-Acoustics amplifiers do) are read directly from the switch's LLDP table as a port → IP mapping, no ARP dependency. Also adds the modern RFC 4293 ARP table for switches that don't implement the legacy one. Fixes empty "Device IP" labels against real Netgear M4250 rigs

---

## v0.7.12 — 2026-07-23

### Devices

- **LS10 polling now uses the switch's built-in HTTP interface** — read-only monitoring with no configuration needed on the switch; port link state, speed, and duplex feed the same port boxes, Device Ports view, and search as Netgear switches. Mping only ever reads — it cannot change any device setting

### Inspector

- **Protocols strip**: a compact status line under the monitoring toggles showing per-transport health at a glance — ICMP for every device, SNMP and LLDP for Netgear switches, HTTP for LS10s — green OK, red N/R, grey when monitoring is off

---

## v0.7.11 — 2026-07-23

### Devices

- **New device type: L-Acoustics LS10** — user-selectable in the TYPE picker; renders and behaves identically to a Netgear switch (tile, port status boxes, Device Ports, inspector, links). Polls the LS10's standard SNMP (ports + LLDP; enable SNMP on the switch first — the GigaCore fixed "Public" community and web interface defaults are set automatically). HTTP API support to follow.

### Performance

- **Canvas FPS restored**: the adaptive theme's colour tokens defeated SwiftUI's change detection, forcing the whole canvas to re-layout every frame while panning — tokens are now memoised and the workspace is smooth again
- Port-box label resolution is cached off the render path instead of rebuilding lookup tables every frame

---

## v0.7.10 — 2026-07-23

### Search

- **Network-wide search**: the sidebar search now also matches switch ports — by LLDP neighbour name or the endpoint IP resolved from the switch's learned-MAC/ARP tables — so typing an amplifier's IP finds the port it's plugged into
- **Results list** (capped at 10) under the search field: click to jump-and-highlight, Enter cycles forwards, Tab + Enter cycles backwards; port results auto-show the switch's port status box and flash the exact port cell
- Rapid cycling is clean: only the current result highlights, and the canvas/tab return-to-view fires once at the end of a burst

### Alerting

- **Offline alerts only fire for devices that were online this session** — opening a show file at home or before the rig is powered no longer floods the history; never-seen devices simply show "Never Seen"

### Port Status Boxes

- Toggle button moved above the tile: springs out of its own tile on hover, hides half a second after the pointer leaves, and can never be obscured by fibre labels
- The tether line runs tile-edge to box-edge in high-contrast adaptive ink instead of crossing the cards

### Fixes

- Device Ports window no longer shows a duplicated "Device" label

---

## v0.7.9 — 2026-07-23

### Port Status Boxes (LLDP)

- **Per-switch port status box**: right-click a switch (or hover it and click the new tile-side button) for a draggable companion box showing every port — grid mode mimics a switch faceplate; **Rack Columns mode replicates a physical amp rack**: per-column heights, an unplaced-ports tray, drag-and-drop placement, and units butted flush with dotted separators like gear in a bay
- **Cell labels**: LLDP neighbour name or the connected device's IP — resolved via the switch's own learned-MAC table and ARP table over SNMP, so un-pinged, LLDP-less endpoints (amplifiers) still label with their IP
- Boxes snap to the grid, refuse to overlap their own tile (auto-relocating if a layout edit grows them into it), and are edited in a dedicated Port Status Box Editor

### Appearance

- **Light mode**: full dual-theme support via Preferences → Appearance — adaptive colour system across every surface, with status-tinted pastel tiles, solid readout chips, and per-surface tuning; dark remains the default and is pixel-identical to before

### Inspector

- **SFP-centric Fibre Optics section**: one card per transceiver on the selected device — port chip, module type, rx-status dot, TX/RX/temperature/voltage/bias readings, vendor and serial — including modules in ports with no drawn link

### UI Polish (beta-readiness pass)

- Audit-driven cleanup across the app: unified status colours (caution is yellow app-wide), consistent typography and spacing, tooltips and hover states, standardised labels, Escape closes sheets and dialogs
- Zoomed-out canvas switches to big centred device names (legible status map instead of shrunken tiles); detail sheds progressively with zoom
- Device names cap at 20 characters and shrink-to-fit before truncating
- Rubber-band selection matches real tile footprints; port boxes can't hide behind tiles
- **File → Open Recent** lists the last eight workspaces
- About window gains a red close button; Mping-styled update download panel

---

## v0.7.8 — 2026-07-22

### Updater

- The download progress panel now matches Mping's style — logo, dark rounded card, green progress bar — instead of a plain system window

---

## v0.7.7 — 2026-07-22

### Updater

- **Download dialog fixed properly** — the 0.7.5 fix didn't hold: a modal progress alert's run loop never services the queued "download finished" work at all, so the dialog still hung until Cancel was clicked. The progress dialog is now a regular floating panel, so it closes itself the moment the download completes — and Mping stays usable while downloading

---

## v0.7.6 — 2026-07-22

### Licensing

- **Licensing removed** — the licence key system introduced in v0.7.4/v0.7.5 has been withdrawn while it is rethought: no more activation, licence checks, or unlicensed banner, and monitoring is never gated. The About window slims down to version, copyright, and support details

---

## v0.7.5 — 2026-07-22

### Licensing

**Floating keys, Licence Studio & revocation**
- **Licence Studio** (Debugging menu, password-gated, ⌘⌥L): a full GUI for issuing keys — load the private signing key once (remembered), fill in licensee/type/expiry, and mint; every key is copied to the clipboard and recorded in a ledger with per-row copy, revoke, and delete
- **Floating keys**: leave the machine ID blank and the key works on whichever single machine activates it — mint batches ahead of time (quantity stepper auto-numbers licensees) without asking anyone for their machine ID; machine-bound keys remain available when the ID is known
- **Per-key revocation**: every key carries a unique key ID; revoking a ledger row rewrites `revoked.json` for publishing to the public repo, and any online copy using that key disables itself at next launch ("disabled by the publisher" shown in About) — offline copies remain bounded by their expiry date
- **Enforcement is now ON**: the real public key is embedded and the Debug bypass is removed, so unlicensed copies soft-gate monitoring (ping and SNMP/LLDP both stop; the example workspace stays live) exactly as shipped builds do

### Updater

- **Patch releases now notify**: automatic checks previously only alerted on major/minor version changes, which under a patch-first release policy silenced every update — any newer version now alerts ("Skip This Version" still respected)
- **Download dialog no longer hangs**: the progress alert never dismissed itself because its completion ran on a queue the modal loop never serviced — it now closes the moment the download completes and the installer opens; also hardened the download against a temp-file race

---

## v0.7.4 — 2026-07-22

### Licensing

**Offline licence keys**
- Licences are now issued as pasteable **keys** rather than files: a signed token carrying the licensee, type, expiry, and machine binding, verified entirely offline against the app's embedded public key — no server, no internet
- **About window** (click the logo) is the licence home: shows the current licensee, type, and expiry when activated; when not, shows the machine ID and a paste-key field with **Activate** (a file install remains as a fallback)
- The sidebar licence box is gone; unlicensed, a compact **"Mping not licensed — click here to add licence"** banner sits under the workspace name and opens the About window
- Unlicensed machines still open the app and run the example workspace, but **real-network monitoring is disabled and greyed** until activated
- Developer tooling: `make-key.swift` mints keys and records each in a local ledger; `list-keys.swift` lists everything issued with live active/expired status; licences carry a free-text type (perpetual, annual, beta, …) and a per-key expiry

All licensing remains dormant until enforcement is enabled on a signed private-source build; Debug builds always bypass it.

---

## v0.7.3 — 2026-07-21

### Temperatures Plane

**Graph sub-view (#53)**
- A Details / Graph bar above the plane switcher (temperatures plane only, remembered across visits and launches) switches every tile to a 1-hour rolling plot of both temperature sensors and all four fans
- Six colour-coded series — temperatures warm and solid, fans cool, dotted, and at half opacity so temperature always reads on top; a shared key sits on the canvas
- Fixed default scales (15–70 °C, 0–18,500 RPM) that expand only when a reading falls outside, so a small wobble reads as small
- Hover shows a crosshair, per-series dots, and a timestamped readout of every value — rendered below the tile and raised above other layers, so the graph itself is never obscured
- Fan speed history is now recorded alongside temperature on each SNMP poll (it previously wasn't stored at all)

### Inspector

**Fibre Optics panel shows raw SFP values (#54)**
- The panel now reports the actual DDM figures each switch provides — for each direction, the transmitting SFP's TX and the receiving SFP's RX, each line naming its port and switch outright — instead of duplicating the calculated loss shown on the workspace links
- New per-module SFP block: temperature, supply voltage, and laser bias, plus module identity — vendor, transceiver type, speed, and serial — read from the Netgear SFP inventory table (ENTITY-MIB only exposes the chassis on M4250s)

**"?" help buttons**
- The Ping and Fibre Optics boxes gained a help affordance (click, or hover for a second): plain-language explanations of RTT, loss, and jitter — and of TX/RX dBm, the connector-loss budget, and the field-order causes of high loss — each reading the workspace's live alert thresholds

### Alerting

**All alerts latch; recovered-but-unacknowledged shown amber**
- Every category now latches like fibre did: a condition that clears before being acknowledged turns amber instead of vanishing, so a mid-show dropout can't erase itself before anyone saw it — red means live, amber means recovered and awaiting acknowledgement
- Applied consistently across the sidebar category boxes, history rows, category popovers (whose Acked column now reads "Ready"), and the inspector; a re-triggering condition returns to red
- The green "Recovered" history row is logged the moment the condition clears, not when it's later acknowledged

### Workspaces

**Auto-reopen only from ~/Documents/Mping**
- At launch the app only restores a workspace whose .mpw actually exists in Documents/Mping — hidden Library state can no longer resurrect an untitled or externally-stored workspace, and clearing Documents/Mping genuinely resets the app to its first-launch example
- Unsaved edits still survive relaunches for Documents-stored workspaces

### Licensing (preparatory)

- Groundwork for per-machine licensing: an Ed25519 signed-licence verifier bound to the hardware UUID, an activation screen, developer tooling, and a licence status line in the sidebar (licensee and expiry, or this machine's copyable ID) — dormant and unenforced in this release

### Project

- Source moved to a private repository; this public repository now hosts the product page, downloads, full changelog, and the issue tracker

---

## v0.7.2 — 2026-07-18

### Updates

**Download and install from inside the app**
- The update alert now offers **Download & Install**: Mping downloads the release itself (with a progress sheet and a working Cancel), mounts it, and Finder opens the familiar window showing Mping.app beside an Applications alias to drag it across
- Mping then offers to quit so the running copy can be replaced, since an app can't cleanly overwrite itself while running
- Releases ship a `.dmg` alongside the `.zip`; the updater prefers the DMG and falls back to revealing the zip in Finder for releases published before DMGs existed
- Downloads land in the app's own container, so no additional permissions are required

---

## v0.7.1 — 2026-07-18

### Alerting

**Fibre alerts latch until acknowledged**
- A fibre link that degrades and then recovers on its own — or is repaired mid-show — previously auto-resolved, erasing the alert before anyone necessarily saw it
- Fibre alerts now stay active after the condition clears, still showing the dB value that triggered them, and resolve only once the operator acknowledges them
- Canvas link labels and the inspector's fibre list remain live throughout — only the alert row latches, so you can watch a repair take effect while the alert stands as the record of what happened
- Other categories (disconnect, ping, temperature) still auto-resolve on recovery

**Fibre alert clicks switch to the correct network plane**
- Fibre alerts route through `focusFibreLinkFromAlert`, not `focusDevice`, so they never received the Primary/Secondary tab-switching fix — clicking a secondary-network fibre alert panned the primary plane, where that link isn't drawn, and appeared to do nothing
- Tab switching is now a single shared helper used by every focus path (device, fibre-from-alert, fibre-by-id), so no future path can miss it

### Updates

- The update alert brings Mping to the front before appearing — an automatic check fires ~12s after launch, and the alert previously sat invisible behind other windows if the user had switched away

### Release tooling

- Release zips are built with `zip -X` instead of `ditto`: macOS re-applies `com.apple.provenance` to the executable, so ditto always wrote `._` AppleDouble sidecars into the archive, making the `.app` look missing or damaged when expanded (signature verified intact with the new method)
- Removed `restart-netadapter.bat`, a Windows batch file swept in from another project

---

## v0.7.0 — 2026-07-10

### Alerting

**macOS notifications and Dock bounce**
- When a new alert fires while Mping is in the background, the Dock icon bounces (critically — until the app is activated) and a macOS notification is posted with the category, device, detail, and location
- Clicking the notification activates Mping and pans the canvas to the alerting device
- Fed by the same deduplicated, verification-gated alert pipeline as the sidebar — one condition produces one notification, and false offlines can't reach the Dock; notification permission is requested on the first background alert

**Inspector alerts box**
- Selecting a device now shows its full alert history (active, acknowledged, and recovered) in the inspector — the answer to "why is this tile pulsing yellow" is one click away
- Styled to match the sidebar's History box (state dots, timestamps, category icons, row tints); the border glows yellow while alerts are active

**Alert state resets on workspace switch**
- Opening or creating a workspace clears alert rows, acknowledgements, and caches — alerts never reference devices from a previous workspace; undo/redo deliberately preserves history

### Updates & Distribution

**In-app update checker**
- Mping polls this repository's latest GitHub release on launch and daily; a major/minor version change alerts with a View & Download button, patch releases stay silent but appear via the new **Mping → Check for Updates…** menu item
- Remind Me Later and Skip This Version supported; the check is a single anonymous request to GitHub's public API (adds the app's first direct-network entitlement)

**One-command releases**
- `release.sh` builds a Release archive, verifies the version, zips signature-preserving, extracts the changelog section as release notes, and publishes the GitHub release (with `--dry-run` and `--notarize` modes) — see `Docs/RELEASING.md`
- App category declared for future notarization; README gained an Installing & Updating section and dropped the stale "disable App Sandbox" build note

### Network Routing

**Static routes survive Wi-Fi toggles, sleep, and reboots**
- The routing tool now attaches routes to the network service via `networksetup -setadditionalroutes` instead of raw `route add` — kernel routes were silently flushed by configd on every network transition (Wi-Fi on/off, DHCP renewal, wake), dropping both show networks at once
- Service names are resolved from BSD device names at run time; apply pre-cleans any kernel routes left by the old approach

---

## v0.6.2 — 2026-07-10

### About

- About card now links to the source repository (github.com/therealjackiewelles/Mping)
- Footer tagline removed from the About card

---

## v0.6.1 — 2026-07-09

### Performance

**Alerting fibre link no longer re-renders the window every frame**
- An alerting fibre link started a SwiftUI `repeatForever` opacity pulse, which forced the entire window's display list to re-render at display refresh rate for as long as the alert persisted (~45% CPU on an otherwise idle workspace, any build, whenever the window was visible)
- Removed — alerting links already pulse via their CA dash layers on the render server at zero app CPU, and keep the orange threshold tint
- Example workspace now pins fibre-loss (4.0 dB), ping (100 ms), and jitter (2.0 ms) thresholds alongside the temperature pins, and its fabricated DDM optics were retuned to 0.4–0.6 dB loss (healthy short-run values) — so neither leftover thresholds nor a strict user-set fibre budget (operators go as low as 1 dB) can put demo links into alert

**Splash window leak**
- The launch splash window was hidden with `orderOut` but never closed, leaving its TimelineView and ping-ripple animation rendering every display frame into an invisible window (~40% CPU) — the window is now fully torn down on dismissal

**Demo animator cadence**
- The example workspace animator was updating temperatures, temperature history, and all fibre-port bandwidth values every ping cycle; it now matches real monitoring cadence (RTT/pulse per cycle, bandwidth ~15s, temperature ~30s), so the demo renders no more often than a live workspace

**Compositor load from continuous animations**
- Fibre dash flow now animates as discrete keyframes (~30 steps/s) on a shared clock with a frame-rate hint, instead of continuously interpolating — WindowServer no longer recomposites the canvas at full display refresh (measured ~17–20 → ~6–9 points of WindowServer CPU); alert pulses and the tile pulsing border are capped the same way

### Launch & Splash

**Missing main window fixed**
- Presenting the splash window from `MpingApp.init` (before `NSApplicationMain`) made SwiftUI skip creating the WindowGroup's main window entirely — the app launched with no workspace window until the Dock icon was clicked. The splash now presents from `applicationDidFinishLaunching` via an app delegate, sweeping any already-created windows into hiding
- Handoff hardening: the workspace raises above other apps even when macOS refuses cooperative activation, window registration retries instead of silently giving up, readiness detects unregistered windows, and dismissal raises all app windows as a fallback
- Splash window keeps its exact frame (hosting view wrapped in a container — NSHostingView was shrinking the borderless window off-centre) and the fade-in includes the app name above the tagline and version
- Demo bandwidth labels survive engine restarts (re-seeded on SNMP start; the animator regenerates missing keys)

### Licensing & About

- Proprietary LICENSE.md added (© 2026 Morgan Beecher / MB Technical, all rights reserved) with matching README section and `NSHumanReadableCopyright` in the app bundle
- Clicking the Mping logo or name in the sidebar opens an About card — chromeless rounded window with version, copyright, licence summary, and copyable support contacts; dismisses when clicking anywhere outside it

### Window Management

**Red traffic light quits the app**
- Previously it performed a window close, leaving Mping running headless (still monitoring, still burning CPU) with no window to reclaim — closing the single window now quits; working state is saved on every change so nothing is lost

---

## v0.6.0 — 2026-07-07

### Example Workspace (first launch)

**Demo system with live-looking telemetry**
- First launch now opens a fully populated "Example Workspace": 4 Netgear switches (FOH root bridge, Stage Left/Right, Delay Node) each with a redundant secondary counterpart, plus 3 ping-only access points inside location boxes laid out in audience view (Stage Right left of screen, Stage Left right)
- Fibre topology: FOH → Stage Left, two Stage Left → Stage Right links (one RSTP-blocked redundant path carrying only kbps control-plane traffic), FOH → Delay Node — all with fabricated DDM (≈1 dB loss, SFP temps), LLDP neighbours, STP state, and live bandwidth labels
- New `isDemo` device flag: demo devices are skipped by the ping, SNMP, and bandwidth engines; their telemetry persists inside the `.mpw` instead of being wiped on boot; a demo animator on the ping cycle jitters RTT/temperatures/bandwidth and pulses tiles so everything looks actively monitored without any real network traffic
- Example workspace pins its temperature thresholds at 85°C switch / 90°C SFP so demo telemetry never tints or alerts

### Launch Animation

**Fibre-link splash before the main window**
- Borderless transparent window, exactly centred, shown before the main app window appears; the main window is intercepted and kept hidden (alpha 0 + ordered out, with become-key/main watchers as a safety net) until the animation completes, then fades in
- Two fixed-length green fibre lines — the canvas link style, white flow dashes riding a green line — snake in from below the logo tile, travel up the M's legs, and come to rest completing the M; the dashes then dissolve into the solid white logo M
- After the M turns white, the green ping dot fades in with a repeating expanding ping ripple (as tiles ping in the app) alongside the tagline and version number
- Cinematic timing (~5.4s); click anywhere to skip; profile/frequency/skip options are constants on `LaunchSplashView`
- The finished frame (dot still pinging) holds until the main window is actually created and configured, so the splash always hands off directly to the app — never to an empty desktop; 10s safety cap

### Workspace Files

**Workspaces move to ~/Documents/Mping**
- An "Mping" folder is created in the user's real Documents folder on launch; all `.mpw` files live there — the first-launch example workspace, Default Workspace, and the Save As / Open panel defaults
- Sandbox: a scoped exception entitlement (`Mping.entitlements`, new) grants read-write to just `Documents/Mping/`; macOS asks the standard Documents permission once and remembers it in Privacy & Security
- Existing `.mpw` files are copied across from Application Support on first run (no overwrites, originals kept); if Documents access is denied, everything falls back to Application Support as before
- Transient state (`.mpingstate`) and `Preferences.json` remain in Application Support

### Alerting

**Secondary-network alert focus fix**
- Clicking an alert for a secondary-network device reliably switches to the Secondary tab before panning — the active network tab moved from view `@State` into `DeviceStore`, and `focusDevice` now switches it atomically; the previous second `onChange` observer raced with the focus reset and intermittently never fired

### UI

- Support box in the sidebar beneath the workspace name ("Need support or have a suggestion?") with selectable, one-click-copyable email and phone
- Redundant network tint defaults changed to red/blue at 50% brightness, 10% opacity
- Minimap feature-gated off (`FeatureFlags.minimapEnabled`) — hidden in all workspaces and its Preferences toggle greyed out until ready
- Sidebar header: "Mping" never wraps — the version badge moves to the next row as a unit when the sidebar is narrow (ViewThatFits); "Network Topology Monitoring" and the workspace name scale smoothly with sidebar width
- Sidebar resize handle no longer drags the whole window (`WindowDragCutoff` behind the handle)

---

## v0.5.13 — 2026-07-04

### UI

**Temperature box alert tinting**
- Temperature boxes (temperature-mode box and overview badge) now tint their background to match the alerting text colour — amber within 5°C of the user threshold, red at or above, plain black when normal
- Tint uses a dark shade of the alert colour so text stays readable; respects the tile editor's box opacity with a 0.45 floor so it remains visible at low opacity settings

### Window Management

**Green traffic light — fullscreen**
- Now expands the window to the full screen bounds with the menu bar and Dock auto-hidden; clicking again restores the previous frame
- Native `toggleFullScreen` requires a titled window and consistently produced a blank fullscreen Space when `.titled` was re-inserted at toggle time, so a faux-fullscreen approach is used instead (no styleMask changes, no separate Space)

**Double-click blank space to maximise**
- Double-clicking any blank draggable area zooms (maximises) the window, mirroring native title-bar behaviour — implemented as a `mouseUp` override in `MpingWindowFixer`'s dynamic window subclass
- The super IMP is captured at class-creation time; resolving it at event time recursed through AppKit/KVO re-subclassing and crashed with a stack overflow

**Window drag limited to the sidebar header**
- Background-drag now works only on the header strip (traffic lights, logo, workspace name); everything south of the workspace name opts out via `WindowDragCutoff` (`mouseDownCanMoveWindow = false`)

### Network Routing

**Static route apply fix**
- Route commands are now joined with `;` instead of `&&` — the pre-clean `route delete` exits non-zero when no route exists yet, which short-circuited the chain and silently skipped the `route add` commands on a first apply

### Security

**Debug password no longer stored in plaintext**
- All five debug window controllers now validate against a single SHA-256 digest (`DebugAccess`, CryptoKit) instead of comparing plaintext string literals — the password is no longer discoverable via `strings` on the binary
- Password rotated from the old 7-digit code to a stronger mixed-character password; plaintext also removed from repo docs

---

## v0.5.12 — 2026-07-04

### Window Management

**Drag the window from anywhere on the background**
- The window can now be moved by dragging any non-interactive background area — `isMovableByWindowBackground` enabled on the custom window subclass
- The dedicated `WindowDragArea` strip next to the traffic lights has been removed; the sidebar header (logo, title, workspace name) moved outside the ScrollView so drags register there
- The workspace canvas explicitly opts out (`mouseDownCanMoveWindow = false` on `WorkspaceEventNSView`) so panning, marquee selection, and tile drags never move the window

**Green traffic light now zooms instead of fullscreen**
- The green window button performs a standard macOS zoom (maximise to screen) rather than entering fullscreen mode

### UI

**Temperature mode tile cleanup**
- IP address and device type rows are hidden on tiles in temperature mode, leaving room for thermal data
- Fan speeds now display all 4 slots in a fixed 2×2 grid (two per row), with `---` shown for slots that return no data — replaces the deduplicated `N× RPM` format

---

## v0.5.11 — 2026-07-03

### Temperature & Fan Monitoring

**Dual-sensor temperature alerting**
- Both temperature sensors are now independently evaluated for over-temperature alerts — sensor 1 fires with detail "Sensor 1 XX°C", sensor 2 fires with "Sensor 2 XX°C", each resolvable independently
- Overview tile badge and temperature history graph now reflect the highest of both sensors rather than always sensor 1

**Temperature colour coding tied to user threshold**
- Overview badge, temperature plane status dot, and per-sensor text colour all now scale relative to the user-set alert threshold (Preferences → Alerting)
- Green below threshold − 5°C · Yellow within 5°C of threshold · Red at or above threshold
- Previously hardcoded at 55°C / 70°C regardless of user setting

**Fan speed monitoring — correct OID**
- Fan speeds now polled from the correct Netgear OID (`1.3.6.1.4.1.4526.10.43.1.6.1.4`) — previous OID (`...1.9.1.3`) returned no data on M4250 hardware
- Values are STRING-encoded RPM (e.g. `"2500"`); parser updated to handle string, integer, and unsigned SNMP types
- All 4 fan slots supported in model (`fanSpeed1`–`fanSpeed4`); temperature tile deduplicates identical speeds into `N× RPM` format
- `SwitchTelemetry` and `SwitchTemperatureResult` extended with `fanSpeed3`/`fanSpeed4`; fully Codable with safe defaults

### Window Management

**Auto-resize on external display disconnect**
- When a connected display is removed, Mping now detects the screen configuration change, shrinks the window if it exceeds the remaining screen's bounds, and repositions it to stay fully visible — animated
- Fixes the window being stranded at a size that can't be reached or resized when the display it was sized for is no longer present
- Implemented via `NSApplicationDidChangeScreenParametersNotification` observer in `WindowTitleBarRemover`'s coordinator

### UI

**Version number and Beta label in sidebar**
- App version and "beta" label now shown next to the Mping title in the top-left sidebar
- Version is read from `CFBundleShortVersionString` — updates automatically whenever the version is bumped in Xcode; no manual sync required

---

## v0.5.10 — 2026-07-01

### New Features

**Live bandwidth labels on fibre link lines**
- SNMP-polled actual throughput now displayed mid-link on the topology canvas — one label per direction, running parallel to the link line
- Polls ifHCInOctets / ifHCOutOctets (64-bit counters) every 15 seconds per switch; falls back to 32-bit ifInOctets / ifOutOctets if HC tables are unavailable
- Rate computed as delta octets × 8 / delta seconds (bps), displayed as Gbps / Mbps / Kbps; labels hidden below 50 Kbps to suppress idle-line noise
- Direction indicators use `─▶` / `◀─` (line-with-arrowhead) rendered in the link's colour at 40% opacity; labels rotate to run parallel to each link segment
- New `PortBandwidth` value type in `Models.swift`; `DeviceStore.portBandwidthBps` dictionary keyed by `deviceID-port`; `startBandwidthMonitoring()` / `stopBandwidthMonitoring()` lifecycle tied to SNMP start/stop

**Fibre topology HUD is now per-network in redundant mode**
- When a redundant pair is configured, the top-left fibre HUD filters link count, LLDP connections, and SFP count to only the devices visible on the currently selected network tab (Primary / Secondary)
- In single-network mode the HUD continues to show totals across all devices

**P/S badges moved to before device name on canvas tiles**
- Primary and Secondary role badges now appear inline before the device name in the tile title row rather than as a trailing overlay
- Badge uses the same colour coding (primary = blue, secondary = orange) with a rounded-rect background

**Copper ports excluded from inspector fibre box**
- The fibre loss section in the device inspector now only shows ports with `linkMedium == .fibre`; copper SFP and RJ45 ports no longer appear in the optical loss list

---

## v0.5.9 — 2026-07-01

### Bug Fix

**Left-click device selection broken after right-click context menu**
- After opening the workspace right-click menu and selecting any item, left-clicking device tiles would fail to register — clicks appeared to fall through to the desktop, sometimes minimising the window
- Root cause: `window.styleMask.remove(.titled)` causes `NSWindow.canBecomeKeyWindow` to return `false`, so every call to `makeKey()` / `makeKeyAndOrderFront()` silently no-ops. After an NSMenu closes, AppKit never restores the window's key status, and SwiftUI silently drops all gesture events (tap, drag) on non-key windows
- Fixed by isa-swizzling the window via `MpingWindowFixer` (added to `ContentView.swift`): immediately after removing `.titled`, a dynamic Objective-C subclass of the window's actual runtime class is created with `objc_allocateClassPair`, overriding `canBecomeKeyWindow` and `canBecomeMainWindow` to return `true`, then applied via `object_setClass`
- Window now correctly regains key status on the next click after any NSMenu interaction — tile selection, canvas taps, and drag selection all work immediately

---

## v0.5.8 — 2026-06-30

### Bug Fix

**Title bar reappearing after context compaction**
- `WindowTitleBarRemover` had reverted to the intermediate cosmetic approach (`titlebarAppearsTransparent + titleVisibility.hidden + fullSizeContentView`) which hides the buttons and text but leaves the chrome bar visible
- Restored correct implementation: `window.styleMask.remove(.titled)` — strips the entire NSThemeFrame and reclaims the height as usable screen space

---

## v0.5.7 — 2026-06-30

### New Icon & UI Overhaul

**New app icon — M lettermark**
- Replaced the previous icon with a new M lettermark design: white geometric M on the workspace canvas background (#0E0E0F) with a green status dot and concentric ping rings, matching the app's visual language
- All 10 AppIcon sizes regenerated (16×16 through 1024×1024); MpingLogo sidebar asset updated at @1x/@2x/@3x; README header updated

**Title bar removed**
- Stripped the macOS title bar entirely via `window.styleMask.remove(.titled)` — reclaims the title bar height as usable screen space
- Custom close / minimise / zoom traffic light buttons embedded at the top of the sidebar, matching native macOS colours and showing action icons on hover
- Window drag strip spans the full width of the traffic light row so the window remains draggable

**Device Tile Editor enhancements**
- Per-type editing: Netgear Switch and Ping Only tiles each have their own settings tab with a live preview panel showing a real `MpingMapDeviceTileView` instance with mock data
- Field reordering: ↑↓ buttons in the Netgear settings reorder the top-section fields (Device Name, IP Address, Device Type); order bakes back to source via the existing regex mechanism
- Ping-only tile: height, latency badge size, IP size, padding, corner radius, and spacing all independently configurable
- Fixed slider snap-to-max bug — `DebugSliderControl` was using `UUID()` as its `id`, regenerating on every render and causing `ForEach` to destroy mid-gesture; changed to use `title` as stable ID

**Temperature plane settings propagation fix**
- Changes in the Device Tile Editor were not reflected in the Temperatures plane because `.equatable()` on `MpingMapDeviceTileView` blocked re-renders when only internal `@ObservedObject` state changed
- Fixed by adding `tileSettingsRevision: Int` as an explicit prop, driven by `.onReceive(DeviceTileEditorSettings.shared.objectWillChange)` in WorkspaceView

---

## v0.5.6 — 2026-06-29

### Bug Fixes & Redundant Network Enhancements

**Location box name overwrite when switching boxes**
- Fixed inspector `ShapeInspector` committing the pending title to the wrong box — `onChange(of: shape.id)` now commits to the *old* box ID before syncing from the newly selected one, preventing box A's name from being written onto box B

**Heartbeat ripple not firing simultaneously across all tiles**
- Added `pingPulseID` to `MpingMapDeviceTileView`'s Equatable check — all tiles now re-render in the same SwiftUI pass when `markDevicesAsPinging` fires, producing a synchronised ripple across the canvas instead of per-tile staggering driven by RTT rounding

**Copper ports showing fibre DDM signal strength**
- Fixed port-index mismatch in Netgear DDM table (`1.3.6.1.4.1.4526.10.43.1.18`) — the table is indexed by SFP slot (1, 2, 3…) not ifIndex; column 1 is now walked first to map slot → real port number, so DDM data (TX/RX dBm, temperature) is assigned to the actual SFP uplink ports and never lands on copper ports

**Secondary device PING NIC not saving**
- `updateDeviceInterface` now sets `pingNICConfigured = true` so NIC changes from Inspector and Device Manager both mark the NIC as configured
- New `checkAndCompleteSetupIfReady` helper auto-clears the setup alert once name, IP, and NIC are all set — works from any entry point, not just the Inspector

**Secondary device tiles now mirror primary position**
- `moveDevice` propagates XY coordinates to the redundant peer when a primary device is dragged, keeping primary/secondary tiles co-located at all times; new pairs are placed at `x: primary.x` instead of offset

### Redundant Network Workspace Tinting

- Primary workspace location boxes receive a configurable red tint; secondary workspace boxes receive a configurable blue tint when redundant pairs exist
- New **Redundant Networks** tab in Preferences with `ColorPicker` (with opacity) for each tint and a Reset to Defaults button
- Tint colours are persisted to the `.mpw` workspace file as RGBA arrays and restored on load
- Tinting uses `store.hasRedundantPairs` (not the non-persisted `redundantModeActive`) so colours appear correctly after relaunch

---

## v0.5.5 — 2026-06-29

### Performance — GPU Animation & CPU Reduction (40% → 5% baseline)

Instruments `sample` trace identified the remaining CPU load. All animation hot paths moved off the CPU onto the Core Animation GPU render server.

**Fibre link dash animation (was: TimelineView + Canvas at 20fps CPU)**
- Replaced with `FibreDashAnimatorView` (`NSViewRepresentable`) — one `CAShapeLayer` per link (outer dark + inner light) each driven by `CABasicAnimation(keyPath: "lineDashPhase")` running indefinitely on the render server
- Zero CPU wakeups per frame; the animation runs entirely in the GPU compositor
- Y-coordinate flip applied in path construction to reconcile CALayer's bottom-left origin with SwiftUI's top-left device position space

**Ping ripple animation (was: `@State pulseScale/pulseOpacity` + `withAnimation`)**
- Replaced with `PingRippleLayerView` (`NSViewRepresentable`) — fires a `CAAnimationGroup` (scale 0.45→1.55, opacity→0, easeOut 0.82s) on the GPU render server when `pingPulseID` changes
- Applied to both `MpingMapDeviceTileView` (canvas tile) and `DeviceTileView` (sidebar/inspector tile)
- Eliminates SwiftUI `@State` mutation and view-graph re-evaluation on every animation frame

**SNMP sequential polling (was: `withTaskGroup` concurrent)**
- Replaced with sequential `for` loop — naturally staggers switch polls without adding artificial delay, preventing all switches from hammering the network simultaneously while keeping the effective per-device interval exactly as configured

**`FibreAutoLinkBuilder.buildResults` offloaded to background**
- Moved topology rebuild off MainActor into `Task.detached(priority: .utility)`, eliminating the ~150% CPU spike every SNMP cycle

**`MiniMapView` rewritten as Canvas**
- Replaced per-device SwiftUI view with a single `Canvas` draw pass — eliminates `N` view allocations and their associated SwiftUI layout overhead

**`FibreLinksLayer` Equatable + single TimelineView**
- Added `Equatable` conformance so `.equatable()` suppresses re-renders when device positions and topology are unchanged
- Was: one 60fps `TimelineView` per link; reduced to a single 20fps loop before being replaced entirely by CALayer

---

## v0.5.4 — 2026-06-29

### Dual-NIC Static Route Management

- New **Network Routing** pane in Preferences for managing static host routes on dual-NIC setups
- Apply and Remove buttons copy the `sudo route` commands to the clipboard and open Terminal — avoids macOS Automation permission blocks on unsigned apps
- Apply always runs a remove pass before adding, so stale routes from prior NIC assignments don't accumulate or conflict
- Orange warning note: remove routes before disconnecting a NIC to prevent connectivity loss
- `devicesWithExplicitNIC()` on DeviceStore supplies the route target list

### LLDP Topology Link Matching

- `matchingDevice` now checks `candidate.discoveredName` (LLDP-polled system name) alongside `candidate.name` — devices using **SNMP/LLDP auto-naming** are now correctly matched by the name the switch actually broadcasts, not the user-entered label
- Added chassis MAC fallback: LLDP neighbours that report no system name are now matched against the device's ARP-resolved MAC address, fixing topology links on switches that omit their LLDP sysName
- Fixed STP flow direction vote: `aToB`/`bToA` assignments for the remote-port designated bridge check were inverted, causing incorrect arrow directions on some fibre links
- Added Console Output diagnostic logging for switches with no stored LLDP neighbours and for unmatched neighbours (shows sysName and chassisID) to assist future debugging
- `PulsingBorderView` hit-test now returns `nil` to prevent the pulsing border overlay from intercepting pointer events

---

## v0.5.3 — 2026-06-29

### Performance — CPU Reduction (60% → near zero baseline)

Instruments Time Profiler identified 39% of CPU being spent in SwiftUI's `ViewGraph.renderDisplayList` — caused by `@State`-driven `repeatForever` animations forcing the entire view graph to re-evaluate at 60fps.

**Animation hot paths eliminated:**
- Alert pulse on device tiles (`alertPulse: Bool`) replaced with `CABasicAnimation` on a `CAShapeLayer` — animation now runs entirely in the render server with zero CPU per frame
- Fibre flow dashes (`dashPhase: CGFloat`) replaced with `TimelineView { Canvas }` — 60fps updates now isolated to the Canvas only, parent view graph is never re-evaluated
- Alert panel pulse and inspector setup pulse converted to the same `CALayer` approach
- `PulsingBorderView` created as a reusable `NSViewRepresentable` for all pulsing border animations

**Ping cycle render suppression:**
- `lastSeenOnline` removed from tile Equatable check — it updates to `Date()` on every successful ping, which was forcing all online tiles to re-render every cycle. The tile only displays it when offline, and `status` (which is compared) triggers the re-render at the moment it matters
- `rebuildAlertCaches()` now guards all three `@Published` assignments with equality checks — previously fired `objectWillChange` every ping cycle even when no alerts changed, causing a spurious SwiftUI render pass after each cycle

**Result:** CPU goes from 60% constant to near-zero baseline with short spikes on ping cycle completion.

### New Device Setup Flow (issue #50 — partial)
- New devices default to `requiresSetup = true` and are excluded from ping cycles until Name, IP, and Ping NIC are all configured
- Inspector shows setup banner and pulses unfilled fields red
- Setup auto-completes on focus loss without requiring Enter
- Ping NIC defaults to "Not configured" for new devices
- Multi-select group edit now includes Ping NIC picker

---

## v0.5.2 — 2026-06-28

### Inspector
- Device info section (Name, IP, Type, Zone, NIC) redesigned as compact stat cards matching the sparkline aesthetic — labels above fields, dark backgrounds, IP and Type side by side in one row
- Delete Device moved to the bottom of the inspector with a two-step confirmation panel — warning icon, device name, consequence text, Cancel and Delete buttons
- Delete requires ⌘⌫ keyboard shortcut (was plain ⌫, too easy to trigger accidentally)
- MAC address lookup removed from the ping monitoring section
- Preferences window now accessible via Mping → Preferences… (⌘,) using the standard macOS Settings scene

### Graphs
- Min/max labels moved outside the graph box — max above, min below — so the line never overlaps them
- Temperature graph min/max now reflects the visible 20-sample window, not all-time history
- Both graphs use the same valueFormatter for label text so units are always consistent

### Alerts
- Alternating row shading in both alert popovers for easier cross-column reading
- Device name and event description bold; time, category, port, and acknowledged columns normal weight

### CPU Optimisation
- Alert cache rebuild deferred with `scheduleAlertCacheRebuild()` — coalesces N per-device rebuilds into 1 per ping cycle via Task scheduling
- `lastRTT` rounded to nearest ms in tile Equatable check — prevents re-renders when RTT fluctuates within a 1ms band on stable connections
- `pingPulseID` removed from Equatable (redundant alongside `lastRTT`)

### Code Annotations
- Non-obvious sections annotated: ping verification burst rationale, STP flow direction voting, alert cache deferral, tile Equatable exclusions, `cleanDeviceForPersistence` field contracts, ping batch coalescing, `PanelInteractionBlocker` registry design

---

## v0.5.1 — 2026-06-28

### Alerting
- Alert history box added to the sidebar below the alerting panel — shows the 10 most recent alerts across all categories with time, device, and description on a single compact line
- Clicking the history box opens a full history popover with all alerts, a Category column, colour-coded rows (red = active, green = recovered, grey = acknowledged), and the same paginated load-more pattern as the per-category popover
- Clicking any alert row in either the per-category popover or the full history popover now focuses the device: the popover closes, the inspector opens, the canvas pans to centre the device, and the tile flickers white for 5 seconds
- Canvas pan on focus correctly accounts for the inspector panel width so the device lands in the centre of the visible canvas area, not behind the inspector — inspector width is stored in DeviceStore and ready for a variable-width inspector in future
- Sidebar click-through fixed — device tiles that have panned underneath the sidebar can no longer be accidentally clicked through it
- Alert descriptions shortened across all categories: Offline, RTT 1423 ms (limit 100 ms), Jitter 2.34 ms (limit 2.0 ms), 74°C, SFP 78°C, 3.2 dB, No Link, Recovered
- Device disconnect icon changed from wifi slash to network.slash
- Full history popover: Category column widened to fit "Device Disconnect" without truncating; Time column left padding increased for breathing room; column alignment fixed

---

## v0.5.0 — 2026-06-28

### Workspace View Switcher
- Plane switcher added at the bottom of the canvas — switch between **Overview** (full canvas) and **STP** view without losing your zoom or pan position
- **STP plane** shows a dedicated read-only view of the spanning tree topology: root bridge highlighted in gold, switches with blocking ports in amber, active links with flow animation, blocking links in orange dashed style
- STP plane includes a legend (Root Bridge / Active Link / Blocking Link) and supports scroll-to-zoom and right-drag-to-pan
- Architecture: one Swift file per plane under `Workspace/Planes/`, coordinated by `WorkspacePlaneCoordinator`

### STP Flow Direction Fixes
- Flow direction now voted from both sides of each link independently — resolves cases where one link was consistently animated the wrong way due to a port-numbering mismatch on one switch
- Flow direction changes are now debounced across 2 consecutive SNMP polls before being committed — eliminates oscillation (back-and-forth animation) during STP reconvergence after a link state change

### Sidebar Cleanup
- Minimap toggle moved to Preferences (was already there — removed duplicate from sidebar)
- Clear Links on Boot moved to Preferences (was already there — removed duplicate from sidebar)
- Zoom slider removed from sidebar
- Snap to Grid controls removed from sidebar
- Fibre Box Opacity slider moved to Fibre Box Editor in Debugging tools
- Fibre box opacity default changed to 100%

---

## v0.4.1 — 2026-06-27

### Inspector
- Temperature history converted to a sparkline graph — matches the ping graph layout exactly
- Temperature graph shows a 20-point sliding window, filling right to left as new samples arrive
- Hover over any data point in the ping or temperature graph to see a tooltip with the exact value and timestamp
- Stat cards updated: Min, Avg, Max shown for both ping and temperature (Current card removed — live value already visible in the section header)
- Temperature values now display to 2 significant figures (e.g. 55°C, 7.8°C)
- Jitter stat card height fixed — now matches the other cards in the same row

### Debugging
- Device Debug: "Root Bridge ID" renamed — on the root bridge shows "Root Bridge MAC" (correct), on other switches shows "Own Chassis MAC" (accurate — it was always this switch's own MAC, not the root bridge's MAC)

---

## v0.4.0 — 2026-06-27

### STP / RSTP Root Bridge Detection
- Root bridge identified via SNMP — compares LLDP chassis ID against per-port designated bridge MACs across all switches
- The switch where all active ports designate themselves as the upstream bridge is confirmed as root
- Root bridge displays a yellow **ROOT** badge in the top-right corner of its tile
- Fixed: OctetString binary values (MAC addresses, bridge IDs) now correctly decoded as hex by the SNMP client

### Fibre Link Flow Animation
- All active (non-blocking) fibre links now show animated grey rectangular dashes flowing toward the root bridge
- Direction determined per-link using the STP designated bridge MAC for each port — topologically correct for every link
- Grey dashes with black border for clear visibility against the coloured line
- Blocking links retain the dashed orange style with no flow animation
- Fibre link lines made thicker across all signal states

### Bug Fixes
- CSV event log files excluded from Xcode project via `.gitignore` (were causing build errors)
- Binary OctetString SNMP values no longer silently dropped — encoded as colon-separated hex

---

## v0.3.3 — 2026-06-27

### Fibre Topology
- Fibre label tiles now correctly show each switch's own data at its own end of the link (was reversed)
- When devices are moved close together, fibre label tiles slide back along the link toward their device
- When there is not enough room for both label tiles, they hide cleanly rather than snapping to a random position
- Label tiles never overlap device tiles — they disappear when the gap becomes too small

### Ping-Only Device Tiles
- Ping-only devices (amps, computers, etc.) now use a compact half-height tile
- Tile shows device name, ping RTT badge, and IP address — no device type label
- IP address moved next to the RTT badge for a cleaner layout

### Web Interface
- Default URL prefix for Netgear switches changed from `http://` to `https://` (port 49152 requires HTTPS)
- Fixed URL suffix (`webInterfacePath`) not persisting across restarts — was being reset to blank on every boot
- Prefix correctly applied when opening web interface from right-click menu
- Empty prefix fields now fall back to `https://` rather than producing malformed URLs
- Preferences window scaffolding built (disabled for now — browser security blocks URL-embedded credentials)

### Infrastructure
- `KeychainHelper` added for future secure credential storage (macOS Keychain integration)
- `PreferencesView` built with General and Switch Credentials tabs (disabled pending auto-login solution)

---

## v0.3.2 — 2026-06-26

### UI Polish
- Devices with active unacknowledged alerts pulse with a yellow border on the workspace canvas
- Pulse matches the alerting sidebar timing (1.4s ease-in-out)
- Yellow border fades out in 0.3s when alerts are acknowledged
- Workspace background pulse removed in favour of per-device indication

---

## v0.3.1 — 2026-06-26

### UI Polish
- Workspace background pulses red when any alert is active, matching the alerting sidebar panel
- Pulse fades out smoothly when all alerts are acknowledged

---

## v0.3.0 — 2026-06-26

### Monitoring
- Packet loss % tracked per ping cycle with colour-coded display in inspector
- Jitter measurement (average RTT variance) with AVB/Milan-aware thresholds and alert integration
- Uptime counter tracking continuous online duration since last recovery
- Jitter alert fires through the Ping RTT alert box with configurable threshold (default 2.0 ms)
- Per-device ping monitoring toggle — exclude specific devices from all ping cycles
- Per-device SNMP/LLDP monitoring toggle — exclude specific Netgear switches from telemetry polling
- Monitoring and Minimap toggles now persist across boots

### STP / RSTP
- RSTP blocking links detected via FASTPATH CST port role OID on Netgear switches
- Blocked inter-switch links rendered as dashed orange lines on the topology canvas
- STP polling added to SNMP cycle — 4 dead legacy OID calls removed after investigation
- Root bridge detection deferred pending a reliable distinguishing OID (tracked in issue #44)

### Inspector
- RTT sparkline graph showing last 60 samples with min/max labels
- MAC address display with on-demand ARP lookup
- Zone name field for device grouping
- Packet loss %, jitter, uptime and sample count stat cards
- Monitoring controls (Ping / SNMP toggles) at top of inspector
- Switch SNMP section removed — data available in Device Debug
- Inspector now renders as a permanent overlay — eliminated 500ms tap delay caused by `refreshNetworkInterfaces()` on appear

### Workspace
- Zone colour system — coloured left-strip indicator on tiles, colour derived from zone name
- Search bar in sidebar filtering by name, IP or zone — non-matching tiles dim
- Right-click on device tiles shows device-specific context menu: Open Web Interface, Select, Copy, Cut, Duplicate, Paste, Delete
- Right-click on empty canvas shows workspace menu (unchanged)
- Clicking a selected device deselects it
- Double-tap to open web interface removed (was causing 500ms tap delay)
- Inspector rendered as permanent overlay — no layout shift on tile selection

### Device Manager
- Rebuilt as NSTableView with resizable and reorderable columns
- Column order and widths saved to AppPreferences and persist across boots
- Auto-scales to screen size with horizontal and vertical scrollbars
- URL Prefix column added (e.g. `http://` or `https://` per device)
- SNMP Community column added
- Web UI Path renamed to URL Suffix
- Editable fields render with rounded bezel so user knows they're interactive
- Name field locks when SNMP/LLDP auto-naming is enabled

### Group Edit
- Select multiple devices to bulk-set zone, device type, SNMP community, ping and SNMP monitoring
- Only fields the user edits are applied — blank fields are ignored

### Debugging
- Device Debug window (password protected) showing internal monitoring state per device
- Event log CSV export from Console Output window
- Console Output: Export CSV button added

### Bug Fixes
- Last Seen resets to nil on boot, shows "Never Seen" for devices not yet online
- Fixed "Timeout" showing on offline tiles — bug was in `MpingMapDeviceTileView` not `DeviceTileView`
- Tile Equatable conformance updated to include `lastSeenOnline` and `verificationState`
- Alerting box no longer resizes during pulse animation
- False "no optical signal" alert suppressed on boot for stale remembered links
- Stale topology links not replaced by live LLDP links — fixed via canonical endpoint matching
- Duplicate topology links accumulating on each boot — fixed
- Sidebar content no longer overlaps when window is resized small

### Performance
- Ping results batched into a single SwiftUI render pass per cycle (was one pass per device)
- Removed `pingRTTHistory` array from tile Equatable check — eliminated O(120) comparison per tile per ping
- Removed `ifConnectorPresent` SNMP walk — returned unmappable data
- Removed 23 `print()` calls from SNMP probes
- Removed 4 dead STP OID calls per switch per poll confirmed as always returning empty data

---

## v0.2.0 — Earlier 2026

### Stable
- ICMP ping monitoring with verification engine
- Workspace canvas with drag-and-drop devices and location boxes
- SNMP/LLDP telemetry for Netgear AV switches
- Fibre link visualisation with SFP DDM loss and temperature
- Inspector panel
- Minimap
- Alerting framework (Fibre Loss, Ping RTT, Device Disconnect, Over Temperature)
- Device Ports view
- Workspace persistence (`.mpw` + `.mpingstate`)
- Console Output debug window

---
