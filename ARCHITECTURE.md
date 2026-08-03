# Mping — Architecture Board

A working map of what runs where, when, and why. Diagrams render natively on GitHub.

> Written 2026-08-03, against `a83223b`/`2577a5d`. When behaviour changes, change this file in the same commit — a stale map is worse than none.

---

## 1. The whole system at a glance

```mermaid
flowchart TB
    subgraph UI["UI — SwiftUI + AppKit bridging"]
        App["MpingApp.swift<br/>@main entry"]
        Content["ContentView<br/>sidebar · canvas · inspector"]
        Planes["WorkspacePlaneCoordinator<br/>Overview · STP · Temperatures"]
        Canvas["WorkspaceView<br/>tiles, links, port boxes"]
        Inspector["InspectorView"]
        Debug["Debugging.swift<br/>password-gated windows"]
    end

    subgraph Store["Single source of truth"]
        DS["DeviceStore<br/>@MainActor ObservableObject"]
    end

    subgraph Engines["Monitoring engines — run off the main actor"]
        Ping["PingEngine<br/>+ ICMPPinger"]
        Verify["PingVerificationEngine"]
        SNMP["SNMPEngine"]
        Fibre["FibreLinkEngine"]
        LS10["LS10Engine<br/>HTTP, GET-only"]
        Modules["Modules/<br/>TelemetryModule · PortStateModule"]
    end

    subgraph Out["Side effects"]
        Alerts["Alerting + AlertNotifier"]
        Console["ConsoleOutputBuffer<br/>always-on ring"]
        Disk["Persistence"]
    end

    App --> Content --> Planes --> Canvas
    Content --> Inspector
    Content -.reads.-> DS
    Canvas -.reads.-> DS
    Inspector -.reads.-> DS
    Debug -.reads.-> DS

    DS -->|"schedules"| Ping
    DS -->|"schedules"| SNMP
    DS -->|"schedules"| Modules
    Ping --> Verify
    SNMP --> Fibre
    DS --> LS10

    Ping -->|"PingResult"| DS
    Modules -->|"merge"| DS
    SNMP -->|"SwitchTelemetry"| DS
    Fibre -->|"FibreLossResult"| DS

    DS --> Alerts
    Ping -.logs.-> Console
    SNMP -.logs.-> Console
    Modules -.logs.-> Console
    DS --> Disk
```

**The one rule that shapes everything:** every mutation goes through `DeviceStore`. Engines never write to each other, and views never write to engines. `DeviceStore` is `@MainActor`; engines run off it and return values.

---

## 2. What runs when — the timing board

```mermaid
flowchart LR
    subgraph Fast["Seconds"]
        P["Ping<br/>2s per device"]
        L["Port up/down<br/>5s per switch"]
    end
    subgraph Mid["Tens of seconds"]
        BW["Port bandwidth<br/>15s"]
        SIG["SFP signal<br/>20s"]
        ST["Switch temp<br/>30s"]
        SFT["SFP temp<br/>30s"]
        D["Dropped packets<br/>30s"]
    end
    subgraph Slow["Minutes"]
        DISC["Discovery and inventory<br/>60s"]
    end

    DISC ==>|"establishes rows and links"| Fast
    DISC ==>|"establishes rows and links"| Mid
```

| Loop | Interval | Owns | Round-robin? |
|---|---:|---|---|
| Ping | **2s** | ICMP echo per device | per-device tasks |
| Port up/down | **5s** | `ifOperStatus`, `ifAdminStatus` | ✅ one switch per wake |
| Port bandwidth | **15s** | `ifHCInOctets/OutOctets` | ❌ all switches |
| SFP signal | **20s** | DDM cols 5, 6 (+1) | ✅ |
| SFP temperature | **30s** | DDM col 2 (+1) | ✅ |
| Switch temperature | **30s** | 3 Netgear sensor OIDs | ✅ |
| Dropped packets | **30s** | `ifInDiscards`, `ifOutDiscards` | ✅ |
| Discovery & inventory | **60s** | port list, LLDP, STP, FDB, ARP, SFP inventory, fans | ❌ **still bursts** |
| Working-state save | 0.4s debounce | `.mpingstate` | — |

> **Known gap:** the discovery pass still sweeps every switch back-to-back. On a rig with unreachable switches that sweep is the dominant CPU burst (median 1.2%, p90 27.6% measured). Tracked in issue #65.

---

## 3. Ping path and false-offline prevention

The highest-stakes path in the app. Priority order is *monitoring reliability first* — a false offline alert mid-show is worse than a slow one.

```mermaid
sequenceDiagram
    participant DS as DeviceStore loop
    participant PE as PingEngine
    participant IC as ICMPPinger
    participant PV as PingVerificationEngine

    DS->>PE: ping(ip, timeout, sourceIP, interface)
    PE->>IC: SOCK_DGRAM ICMP echo
    Note over IC: IP_BOUND_IF binds the NIC<br/>bind() sets source address

    alt reply received
        IC-->>PE: RTT
        PE-->>DS: .healthy (or .slow)
    else timeout or unreachable
        IC-->>PE: failure
        PE-->>DS: .offline
        DS->>PV: verifyOffline
        loop up to 4 attempts, 100ms apart
            PV->>PE: ping again
            alt any reply
                PV-->>DS: NOT confirmed — device stays online
            end
        end
        PV-->>DS: confirmed offline → alert
    else socket unavailable / bind / send failed
        IC-->>PE: probe never left the machine
        PE->>PE: fall back to /sbin/ping
    end
```

**Rules encoded here:**

- A timeout is a **real answer** and is never retried by the subprocess path — otherwise a genuinely down device could be reported up by the slower method.
- The fallback fires **only** when the probe never left the machine.
- Offline requires **4 consecutive failures**; online recovery requires **2** (`PingVerificationEngine.Configuration`).
- `IP_BOUND_IF` matters when two NICs advertise the same subnet — the redundant rig case.

---

## 4. Telemetry: discovery vs values

```mermaid
flowchart TB
    subgraph Discovery["Discovery — 60s, authoritative"]
        DISC["SNMPEngine.readSwitchTemperature<br/>+ readInterfacePortSummary"]
        DOUT["Port list · ifType · LLDP neighbours<br/>STP roles · FDB/ARP · SFP inventory · fans"]
    end

    subgraph Values["Value modules — seconds to a minute"]
        PS["PortStateModule"]
        SFP["SFP signal / temperature"]
        TMP["Switch temperature"]
        DIS["Dropped packets"]
    end

    subgraph Model["SwitchTelemetry on MonitoredDevice"]
        ROWS["devicePorts[]"]
        FP["fibrePorts[]"]
        LLDP["lldpNeighbours[]"]
    end

    DISC --> DOUT --> ROWS
    DOUT --> FP
    DOUT --> LLDP
    PS -->|"updates operStatus/adminStatus"| ROWS
    DIS -->|"updates discard counters"| ROWS
    SFP -->|"updates txDbm/rxDbm/temp"| FP
    TMP -->|"updates sensors"| Model

    ROWS --> LINKS["FibreLinkEngine<br/>link status + flow"]
    FP --> LINKS
    LLDP --> LINKS
    LINKS --> MAP["Canvas: green / amber / red links"]
```

**Invariants:**

1. **Discovery owns the row set.** Value modules never add or remove ports or links.
2. **Absence is not a reading.** No response leaves previous state untouched — never "all ports down" or "zero drops".
3. **Value modules idle until discovery has run** for that device (`pollTargets(requiringDiscoveredPorts:)`).
4. **One SNMP unit of work at a time** across all tiers (`isPollingTier`), and everything stands aside for discovery.

> **Not yet true:** discovery still walks the value OIDs too, so some are polled twice. Removing that is the point of issue #65, and it needs live hardware — if a module doesn't fully cover what it claims, a reading silently freezes.

---

## 5. Link liveness — how a dead link turns red

```mermaid
flowchart LR
    LLDPD["LLDP topology<br/>slow, stable"] -->|"which port ↔ which port"| LINK["FibreLossResult"]
    DDM["DDM optical levels<br/>20-30s"] -->|"loss, No Signal"| LINK
    PORT["Port up/down<br/>5s"] -->|"portDown flag"| LINK
    LINK --> RED{"isDeadLink?"}
    RED -->|"yes"| R["Red, no flow animation"]
    RED -->|"no"| G["Coloured by signal status"]
```

A down port at **either** end means the link is dead, whatever the last DDM reading said. Cable-pulled and lost-light render identically — operationally they're the same. This is also the **only** liveness signal copper links have, since they carry no DDM.

---

## 6. State and persistence

```mermaid
flowchart TB
    DS["DeviceStore"]
    DS -->|"markWorkspaceDirty → debounced"| MPW["~/Documents · Default Workspace.mpw<br/>devices + shapes (PersistedWorkspace)"]
    DS -->|"every change, 0.4s debounce"| STATE["Working Workspace.mpingstate<br/>restores exactly where you left off"]
    PREFS["AppPreferences"] --> JSON["Preferences.json<br/>sidebar width, column layouts"]
    UD["UserDefaults"] --> SIMPLE["monitoring toggle, poll intervals,<br/>alert thresholds, appearance"]
```

**On boot:** `cleanDeviceForRuntime` resets runtime fields (ping history, lastSeen, MAC, loss history). User fields persist. `MonitoredDevice` has **manual** `CodingKeys` and `init(from:)` — a new field must be added to the struct, `CodingKeys`, the decoder (with `decodeIfPresent` + safe default), the custom init signature *and* body, and `cleanDeviceForPersistence`. Miss one and the field silently vanishes on save.

---

## 7. Console and debugging

```mermaid
flowchart LR
    E1["PingEngine"] --> BUF
    E2["SNMPEngine"] --> BUF
    E3["Modules"] --> BUF
    BUF["ConsoleOutputBuffer<br/>lock-protected ring, 3000 entries<br/>no actor hop, no publishing"]
    BUF -->|"drained on 0.5s timer<br/>only while window open"| WIN["Console Output window"]
    WIN --> FILT["Filter by subsystem:<br/>Port Up/Down · SFP Signal · SFP Temp<br/>Switch Temp · Dropped Packets · LLDP · STP · Ping"]
```

Capture is **always on** — the window back-fills when opened. Recording is cheap; it was the *publishing* that cost CPU.

Debug windows are password-gated (SHA-256 digest in `DebugAccess`): Device Tile Editor, Fibre Box Editor, Telemetry Polling, Console Output, Device Debug.

---

## 8. File map

| Area | File | Responsibility |
|---|---|---|
| Entry | `Workspace/MpingApp.swift` | `@main`, menus, splash, update check |
| **Store** | `Workspace/DeviceStore.swift` | Single source of truth; all poll loops |
| Model | `Workspace/Models.swift` | `MonitoredDevice`, `SwitchTelemetry`, manual Codable |
| Ping | `Ping Engine/PingEngine.swift` | Facade: native ICMP, `/sbin/ping` fallback |
| Ping | `Ping Engine/ICMPPinger.swift` | Raw ICMP over `SOCK_DGRAM` |
| Ping | `Ping Engine/PingVerificationEngine.swift` | 4-strike offline / 2-strike online |
| SNMP | `SNMP-LLDP/SNMPEngine.swift` | Client, BER, walks, discovery pass |
| SNMP | `SNMP-LLDP/FibreLinkEngine.swift` | DDM parse, link building, canvas link views |
| SNMP | `SNMP-LLDP/LS10Engine.swift` | L-Acoustics HTTP, **GET-only by design** |
| Modules | `SNMP-LLDP/Modules/TelemetryModule.swift` | Protocol, poll target, freshness |
| Modules | `SNMP-LLDP/Modules/PortStateModule.swift` | Port up/down |
| Canvas | `Workspace/WorkspaceView.swift` | Tiles, right-click menu, drag, port boxes |
| Canvas | `Workspace/WorkspacePlaneCoordinator.swift` | Plane switching, left-edge toolbars |
| Canvas | `Workspace/Planes/TemperatureGraphView.swift` | Temperature plots |
| Ports | `Workspace/DevicePortsView.swift` | Port table + `DevicePortTelemetryExtractor` |
| Alerts | `Alerting/*` | Thresholds, notifications, pulsing borders |
| Debug | `Debugging/Debugging.swift` | Console store/buffer, all debug windows |

---

## 9. Rules to work by

Ordered — earlier beats later when they conflict.

1. **Monitoring reliability** — no false offline alerts, ever.
2. **Stability**
3. **Performance**
4. **Clean architecture**
5. **User experience**
6. **New features**

**Checkpoint before touching:** `PingEngine`, `PingVerificationEngine`, `DeviceStore` (loops/persistence), `SNMPEngine`, `FibreLinkEngine`, `Alerting`, `Models` Codable.

**Measurement rules learned the hard way:**

- Profile **Release**, never Debug — Debug inflates hot loops enough to send you chasing the wrong thing.
- Confirm the **live workspace is loaded and Monitoring is ON** before believing a number.
- `ps %cpu` is a **lifetime average**; sample instantaneously to see what a process is doing *now*.
- Check a new OID's real values with `snmpwalk` before trusting a scaling factor inferred from code. SFP power is milli-dBm; assuming centi-dBm would have shown every link at −61 dBm.

---

## 10. Open threads

| Issue | What |
|---|---|
| #65 | Per-subsystem telemetry modules; **OID exclusion needs live hardware** |
| #60 | Native ICMP — implemented, labelled `needs testing`, do not release untested |
| #63 | Alert when a redundant link drops |
| #59 | SNMP poll cycle re-renders the whole canvas |
| #58 | Refresh topology system-wide on failure |
| #61 | Older macOS compatibility |

---

*Mping is not affiliated with, endorsed by, or supported by NETGEAR or L-Acoustics. OIDs referenced here are from published standard and vendor MIBs.*
