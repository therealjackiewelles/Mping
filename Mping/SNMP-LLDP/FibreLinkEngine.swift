import Foundation
import SwiftUI

// MARK: - Fibre Box Baked Defaults

enum FibreBoxStyleDefaults {
    static let textSize: CGFloat = 10.0
    static let textBold: Bool = true
    static let lineSpacing: CGFloat = 1.0
    static let horizontalPadding: CGFloat = 10.0
    static let verticalPadding: CGFloat = 5.0
    static let minimumWidth: CGFloat = 62.0
    static let cornerRadius: CGFloat = 7.0
    static let borderWidth: CGFloat = 1.0
    static let opacity: CGFloat = 0.5
}


struct FibrePortTelemetry: Identifiable, Codable, Equatable, Hashable, Sendable {
    let deviceID: UUID
    let port: Int
    var temperatureCelsius: Double?
    var voltage: Double?
    var biasCurrentMilliAmps: Double?
    var txDbm: Double?
    var rxDbm: Double?
    var txFaultText: String?
    var losText: String?
    var faultStatusText: String?

    var id: String { "\(deviceID.uuidString)-\(port)" }

    var hasOpticalPower: Bool {
        txDbm != nil || rxDbm != nil
    }

    var hasExplicitLOS: Bool {
        guard let losText else { return false }
        let text = losText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return false }

        // Be deliberately conservative here. Some Netgear DDM tables report
        // numeric/enum values that earlier code translated to the word "LOS",
        // but those have produced false "No optical signal" alerts on live links.
        // Only raise a no-signal condition from an explicit human-readable fault
        // string, not from a bare numeric value or the short enum label "LOS".
        if text == "ok" || text == "normal" || text == "none" || text == "0" || text == "1" || text == "2" || text == "los" {
            return false
        }

        return text.contains("loss of signal") || text.contains("no optical signal") || text.contains("signal lost") || text.contains("los detected") || text.contains("los asserted")
    }

    var rxStatus: FibreSignalStatus {
        // Only the switch's explicit LOS flag should create a no-signal state.
        // Very low/missing RX power can happen during partial polls, unsupported OIDs,
        // wrong LLDP-to-DDM mapping, or momentary SNMP gaps, and should not raise
        // a false "No optical signal" alert by itself.
        if hasExplicitLOS { return .noSignal }
        guard let rxDbm else { return .unknown }
        if rxDbm <= -40 { return .bad }
        if rxDbm < -15 { return .bad }
        if rxDbm < -10 { return .warning }
        return .good
    }
}

struct LLDPNeighbour: Identifiable, Codable, Equatable, Hashable, Sendable {
    var localPort: Int
    var remoteSystemName: String?
    var remoteChassisID: String?
    var remoteChassisIDSubtype: Int?
    var remotePortID: String?
    var remotePortDescription: String?

    var id: String {
        "\(localPort)-\(remoteSystemName ?? "")-\(remoteChassisID ?? "")-\(remoteChassisIDSubtype ?? -1)-\(remotePortID ?? "")-\(remotePortDescription ?? "")"
    }

    var remoteChassisMACAddress: String? {
        guard remoteChassisIDSubtype == 4, let remoteChassisID else { return nil }
        return Self.normalisedMACAddress(from: remoteChassisID)
    }

    var bestRemotePortText: String {
        if let remotePortID, !remotePortID.isEmpty { return remotePortID }
        if let remotePortDescription, !remotePortDescription.isEmpty { return remotePortDescription }
        return ""
    }

    private static func normalisedMACAddress(from text: String) -> String? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            .replacingOccurrences(of: "-", with: ":")
            .replacingOccurrences(of: " ", with: ":")

        let hexPairs = cleaned
            .split(separator: ":")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if hexPairs.count == 6, hexPairs.allSatisfy({ $0.count == 2 && $0.range(of: #"^[0-9A-Fa-f]{2}$"#, options: .regularExpression) != nil }) {
            return hexPairs.map { $0.uppercased() }.joined(separator: ":")
        }

        let compact = cleaned.replacingOccurrences(of: ":", with: "")
        if compact.count == 12, compact.range(of: #"^[0-9A-Fa-f]{12}$"#, options: .regularExpression) != nil {
            return stride(from: 0, to: 12, by: 2)
                .map { index in
                    let start = compact.index(compact.startIndex, offsetBy: index)
                    let end = compact.index(start, offsetBy: 2)
                    return String(compact[start..<end]).uppercased()
                }
                .joined(separator: ":")
        }

        return nil
    }
}

struct FibreConnection: Identifiable, Hashable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var aDeviceID: UUID
    var aPort: Int
    var bDeviceID: UUID
    var bPort: Int
    var name: String = ""

    init(
        id: UUID = UUID(),
        aDeviceID: UUID,
        aPort: Int,
        bDeviceID: UUID,
        bPort: Int,
        name: String = ""
    ) {
        self.id = id
        self.aDeviceID = aDeviceID
        self.aPort = aPort
        self.bDeviceID = bDeviceID
        self.bPort = bPort
        self.name = name
    }
}

enum TopologyLinkMedium: String, Codable, Hashable, Sendable {
    case fibre
    case copper
    case unknown

    var lineColor: Color {
        switch self {
        case .fibre: return .green
        case .copper: return .white
        case .unknown: return .secondary
        }
    }
}

struct FibreLossResult: Identifiable, Hashable, Sendable {
    let id: UUID
    let connection: FibreConnection
    let aDeviceName: String
    let bDeviceName: String
    let aTxDbm: Double?
    let aRxDbm: Double?
    let bTxDbm: Double?
    let bRxDbm: Double?
    let aTemperatureCelsius: Double?
    let bTemperatureCelsius: Double?
    let lossAToB: Double?
    let lossBToA: Double?
    let status: FibreSignalStatus
    let aIsOpticalPort: Bool
    let bIsOpticalPort: Bool
    let linkMedium: TopologyLinkMedium
    let isMissing: Bool
    let stpBlocking: Bool

    var displayName: String {
        let trimmed = connection.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "\(aDeviceName) P\(connection.aPort) ↔ \(bDeviceName) P\(connection.bPort)" : trimmed
    }

    var topologyLineColor: Color {
        if isMissing { return .red }
        return linkMedium.lineColor
    }

    var topologyLineWidth: CGFloat {
        if isMissing { return 4.0 }
        return status.lineWidth
    }

    var shortLabel: String {
        // Keep the map label deliberately simple. Detailed TX/RX/port telemetry
        // belongs in the Inspector/debug views, not on the workspace fibre tile.
        let bestLoss = preferredLossForCompactDisplay
        let hottestTemp = [aTemperatureCelsius, bTemperatureCelsius]
            .compactMap { $0 }
            .max()
        return "\(formatLossForDisplay(bestLoss)) • \(formatTemperatureForDisplay(hottestTemp))"
    }

    var aEndpointLabel: String {
        // The rendered fibre tile endpoints were visually reversed on the map.
        // Swap the displayed endpoint information so the tile next to each side
        // matches the physical port the user sees on the topology.
        compactEndpointLabel(
            port: connection.bPort,
            loss: lossAToB,
            temperature: bTemperatureCelsius,
            hasOpticalTelemetry: bHasOpticalTelemetry
        )
    }

    var bEndpointLabel: String {
        // See aEndpointLabel: keep the visual endpoint labels reversed so the
        // map display matches the actual physical link orientation.
        compactEndpointLabel(
            port: connection.aPort,
            loss: lossBToA,
            temperature: aTemperatureCelsius,
            hasOpticalTelemetry: aHasOpticalTelemetry
        )
    }

    private var aHasOpticalTelemetry: Bool {
        aIsOpticalPort && (aTxDbm != nil || aRxDbm != nil || aTemperatureCelsius != nil)
    }

    private var bHasOpticalTelemetry: Bool {
        bIsOpticalPort && (bTxDbm != nil || bRxDbm != nil || bTemperatureCelsius != nil)
    }

    private var preferredLossForCompactDisplay: Double? {
        let values = [lossAToB, lossBToA].compactMap { $0 }
        guard !values.isEmpty else { return nil }
        return values.max()
    }

    private func compactEndpointLabel(port: Int, loss: Double?, temperature: Double?, hasOpticalTelemetry: Bool) -> String {
        guard hasOpticalTelemetry else {
            return "P\(port)"
        }
        return "P\(port)\n\(formatLossForDisplay(loss))\n\(formatTemperatureForDisplay(temperature))"
    }

    private func formatTemperatureForDisplay(_ temperature: Double?) -> String {
        guard let temperature else { return "--°C" }
        return String(format: "%.0f°C", temperature)
    }

    private func formatLossForDisplay(_ loss: Double?) -> String {
        guard let loss else { return "-- dB" }
        return String(format: "-%.1f dB", abs(loss))
    }
}

enum FibreSignalStatus: Int, Sendable {
    case unknown
    case good
    case warning
    case bad
    case noSignal

    var lineWidth: CGFloat {
        switch self {
        case .unknown: return 1.5
        case .good: return 2.0
        case .warning: return 3.0
        case .bad, .noSignal: return 4.0
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .unknown: return .secondary
        case .good: return .green
        case .warning: return .yellow
        case .bad: return .orange
        case .noSignal: return .red
        }
    }
}

enum FibreLossCalculator {
    static func calculate(
        connection: FibreConnection,
        aDeviceName: String,
        bDeviceName: String,
        telemetry: [FibrePortTelemetry],
        aIsOpticalPort: Bool = true,
        bIsOpticalPort: Bool = true,
        stpBlocking: Bool = false
    ) -> FibreLossResult {
        let a = matchingTelemetry(
            deviceID: connection.aDeviceID,
            requestedPort: connection.aPort,
            telemetry: telemetry
        )
        let b = matchingTelemetry(
            deviceID: connection.bDeviceID,
            requestedPort: connection.bPort,
            telemetry: telemetry
        )

        let lossAToB = calculateLoss(txDbm: a?.txDbm, rxDbm: b?.rxDbm)
        let lossBToA = calculateLoss(txDbm: b?.txDbm, rxDbm: a?.rxDbm)

        return FibreLossResult(
            id: connection.id,
            connection: connection,
            aDeviceName: aDeviceName,
            bDeviceName: bDeviceName,
            aTxDbm: a?.txDbm,
            aRxDbm: a?.rxDbm,
            bTxDbm: b?.txDbm,
            bRxDbm: b?.rxDbm,
            aTemperatureCelsius: a?.temperatureCelsius,
            bTemperatureCelsius: b?.temperatureCelsius,
            lossAToB: lossAToB,
            lossBToA: lossBToA,
            status: worstStatus(aRx: a?.rxStatus ?? .unknown, bRx: b?.rxStatus ?? .unknown, lossAToB: lossAToB, lossBToA: lossBToA),
            aIsOpticalPort: aIsOpticalPort,
            bIsOpticalPort: bIsOpticalPort,
            linkMedium: (aIsOpticalPort || bIsOpticalPort) ? .fibre : .copper,
            isMissing: false,
            stpBlocking: stpBlocking
        )
    }

    static func calculateLoss(txDbm: Double?, rxDbm: Double?) -> Double? {
        guard let txDbm, let rxDbm else { return nil }

        // Correct directional fibre attenuation uses the sender SFP's TX power and
        // the opposite/receiving SFP's RX power:
        //
        //     A→B loss = A TX dBm - B RX dBm
        //     B→A loss = B TX dBm - A RX dBm
        //
        // Do not calculate local TX-RX on the same SFP; that is not a fibre path.
        // Internally this function returns a positive attenuation value for sorting
        // and threshold checks. The UI formats that same value with a leading minus
        // sign because the operator-facing number represents loss.
        guard txDbm > -40, rxDbm > -40 else { return nil }

        let attenuation = txDbm - rxDbm

        // Passive fibre cannot create optical gain, but real SFP DDM readings can
        // differ by calibration/timing tolerance and may occasionally make the
        // receiver look slightly stronger than the sender. Do not turn that into
        // nil because nil renders as "--" and prevents alerts/diagnostics from
        // seeing a measured link. Clamp any apparent gain to 0 dB loss.
        return max(0, attenuation)
    }

    private static func matchingTelemetry(
        deviceID: UUID,
        requestedPort: Int,
        telemetry: [FibrePortTelemetry]
    ) -> FibrePortTelemetry? {
        let devicePorts = telemetry
            .filter { $0.deviceID == deviceID && $0.hasOpticalPower }
            .sorted { $0.port < $1.port }
        guard !devicePorts.isEmpty else { return nil }

        if let exact = devicePorts.first(where: { $0.port == requestedPort }) {
            return exact
        }

        // NETGEAR M4250 quirk: LLDP local-port numbers can be interface indexes,
        // while the SFP DDM table reports physical fibre ports as 41...44.
        // Keep this mapping deterministic. Do not fall back to nearest/first port on
        // multi-SFP switches, because that can pair A TX with the wrong remote RX and
        // create impossible-looking optical gain/loss values.
        let translatedCandidates = [
            requestedPort - 30,
            requestedPort - 40,
            requestedPort + 30,
            requestedPort + 40,
            requestedPort - 8,
            requestedPort + 8,
            requestedPort - 20,
            requestedPort + 20
        ]

        for candidate in translatedCandidates {
            if let translated = devicePorts.first(where: { $0.port == candidate }) {
                return translated
            }
        }

        // A single optical port on the switch is unambiguous. More than one optical
        // port requires an exact/translated LLDP-to-DDM mapping.
        if devicePorts.count == 1 {
            return devicePorts[0]
        }

        return nil
    }

    private static func worstStatus(aRx: FibreSignalStatus, bRx: FibreSignalStatus, lossAToB: Double?, lossBToA: Double?) -> FibreSignalStatus {
        var statuses = [aRx, bRx]
        for loss in [lossAToB, lossBToA].compactMap({ $0 }) {
            if loss >= 8 { statuses.append(.bad) }
            else if loss >= 4 { statuses.append(.warning) }
            else { statuses.append(.good) }
        }
        return statuses.max(by: { $0.rawValue < $1.rawValue }) ?? .unknown
    }
}

enum FibreTelemetryExtractor {
    static func extractPorts(deviceID: UUID, rawOutput: String) -> [FibrePortTelemetry] {
        var ports: [Int: FibrePortTelemetry] = [:]

        func upsert(port: Int, update: (inout FibrePortTelemetry) -> Void) {
            var telemetry = ports[port] ?? FibrePortTelemetry(deviceID: deviceID, port: port)
            update(&telemetry)
            ports[port] = telemetry
        }

        for rawLine in rawOutput.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines).trimmedLeadingDot
            guard line.hasPrefix("1.3.6.1.4.1.4526.10.43.1.18.1.") else { continue }
            guard let oidAndValue = splitOIDLine(line) else { continue }

            let oidParts = oidAndValue.oid.split(separator: ".").compactMap { Int($0) }
            guard oidParts.count >= 14, let port = oidParts.last else { continue }
            let column = oidParts[oidParts.count - 2]

            upsert(port: port) { telemetry in
                switch column {
                case 2: telemetry.temperatureCelsius = parseNumber(oidAndValue.value).map { $0 / 10.0 }
                case 3: telemetry.voltage = parseNumber(oidAndValue.value).map { $0 / 1000.0 }
                case 4: telemetry.biasCurrentMilliAmps = parseNumber(oidAndValue.value).map { $0 / 10.0 }
                case 5: telemetry.txDbm = parseMilliDbm(oidAndValue.value)
                case 6: telemetry.rxDbm = parseMilliDbm(oidAndValue.value)
                case 7: telemetry.txFaultText = parseEnumText(oidAndValue.value, okValue: 2, faultValue: 1, faultText: "Fault")
                case 8: telemetry.losText = parseEnumText(oidAndValue.value, okValue: 2, faultValue: 1, faultText: "LOS")
                case 9: telemetry.faultStatusText = parseStringValue(oidAndValue.value)
                default: break
                }
            }
        }

        // Fallback for formatted summary lines generated by newer SNMPEngine builds,
        // for example: Port 41 • Temp 52.0°C • TX -6.14dBm • RX -9.06dBm
        for rawLine in rawOutput.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.localizedCaseInsensitiveContains("Port ") else { continue }
            guard let port = firstNumber(after: "Port", in: line).map(Int.init) else { continue }

            upsert(port: port) { telemetry in
                if let tx = numberBefore("dBm", after: "TX", in: line) {
                    telemetry.txDbm = normaliseOpticalDbm(tx)
                }

                if let rx = numberBefore("dBm", after: "RX", in: line) {
                    telemetry.rxDbm = normaliseOpticalDbm(rx)
                }

                if let temp = numberBefore("°C", after: "Temp", in: line) {
                    telemetry.temperatureCelsius = temp
                }
            }
        }

        return ports.values.filter { $0.hasOpticalPower || $0.temperatureCelsius != nil }.sorted { $0.port < $1.port }
    }

    private static func firstNumber(after marker: String, in text: String) -> Double? {
        guard let markerRange = text.range(of: marker, options: .caseInsensitive) else { return nil }
        let tail = String(text[markerRange.upperBound...])
        return parseNumber(tail)
    }

    private static func numberBefore(_ suffix: String, after marker: String, in text: String) -> Double? {
        guard let markerRange = text.range(of: marker, options: .caseInsensitive) else { return nil }
        let tail = String(text[markerRange.upperBound...])
        guard let suffixRange = tail.range(of: suffix, options: .caseInsensitive) else {
            return parseNumber(tail)
        }
        return parseNumber(String(tail[..<suffixRange.lowerBound]))
    }

    private static func splitOIDLine(_ line: String) -> (oid: String, value: String)? {
        let separators = [" = INTEGER:", " = Gauge32:", " = STRING:", " = UNSIGNED:"]
        for separator in separators {
            if let range = line.range(of: separator) {
                return (
                    String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines),
                    String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        }
        return nil
    }

    private static func parseNumber(_ text: String) -> Double? { text.matches(for: #"-?\d+(\.\d+)?"#).compactMap(Double.init).first }

    private static func normaliseOpticalDbm(_ value: Double) -> Double {
        // Netgear raw DDM and some formatted summaries can present optical power
        // as a positive magnitude. Optical TX/RX dBm in this app should always be
        // stored as a negative dBm value, where 0 dBm is strongest and lower values
        // are weaker. If the value is already negative, keep it negative.
        if abs(value) > 100 {
            return -abs(value / 1000.0)
        }
        return -abs(value)
    }
    private static func parseMilliDbm(_ text: String) -> Double? {
        guard let raw = parseNumber(text) else { return nil }

        // NETGEAR's fibre DDM table reports optical power as a positive magnitude.
        // Example: 6140 means -6.140 dBm, not +6.140 dBm.
        // Summary/debug lines may already be formatted as either "6.14dBm" or
        // "-6.14dBm", so normalise all valid optical powers to negative dBm here.
        if raw <= -40000 || raw >= 40000 { return -40.0 }

        if abs(raw) > 100 {
            return -abs(raw / 1000.0)
        }

        return -abs(raw)
    }
    private static func parseStringValue(_ text: String) -> String { text.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).trimmingCharacters(in: .whitespacesAndNewlines) }
    private static func parseEnumText(_ text: String, okValue: Int, faultValue: Int, faultText: String) -> String {
        guard let raw = parseNumber(text).map(Int.init) else { return parseStringValue(text) }
        if raw == okValue { return "OK" }
        if raw == faultValue { return faultText }
        return String(raw)
    }
}

enum LLDPTelemetryExtractor {
    static func extractNeighbours(rawOutput: String) -> [LLDPNeighbour] {
        var byKey: [String: LLDPNeighbour] = [:]

        for rawLine in rawOutput.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines).trimmedLeadingDot
            guard line.hasPrefix("1.0.8802.1.1.2.1.4.1.1.") else { continue }
            guard let parsed = splitOIDLine(line) else { continue }

            let oidParts = parsed.oid.split(separator: ".").compactMap { Int($0) }
            guard oidParts.count >= 14 else { continue }

            let column = oidParts[oidParts.count - 4]
            let timeMark = oidParts[oidParts.count - 3]
            let localPort = oidParts[oidParts.count - 2]
            let remoteIndex = oidParts[oidParts.count - 1]
            let key = "\(timeMark)-\(localPort)-\(remoteIndex)"

            var neighbour = byKey[key] ?? LLDPNeighbour(localPort: localPort)
            let value = parseStringValue(parsed.value)

            switch column {
            case 4:
                neighbour.remoteChassisIDSubtype = Int(value.matches(for: #"-?\d+"#).first ?? "")
            case 5:
                neighbour.remoteChassisID = normalisedMACAddress(from: value) ?? value
            case 7:
                neighbour.remotePortID = value
            case 8:
                neighbour.remotePortDescription = value
            case 9:
                neighbour.remoteSystemName = value
            default:
                break
            }

            byKey[key] = neighbour
        }

        return byKey.values
            .filter { ($0.remoteSystemName?.isEmpty == false) || ($0.remoteChassisID?.isEmpty == false) || ($0.remotePortID?.isEmpty == false) || ($0.remotePortDescription?.isEmpty == false) }
            .sorted { $0.localPort < $1.localPort }
    }

    private static func normalisedMACAddress(from text: String) -> String? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            .replacingOccurrences(of: "-", with: ":")
            .replacingOccurrences(of: " ", with: ":")

        let hexPairs = cleaned
            .split(separator: ":")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if hexPairs.count == 6, hexPairs.allSatisfy({ $0.count == 2 && $0.range(of: #"^[0-9A-Fa-f]{2}$"#, options: .regularExpression) != nil }) {
            return hexPairs.map { $0.uppercased() }.joined(separator: ":")
        }

        let compact = cleaned.replacingOccurrences(of: ":", with: "")
        if compact.count == 12, compact.range(of: #"^[0-9A-Fa-f]{12}$"#, options: .regularExpression) != nil {
            return stride(from: 0, to: 12, by: 2).map { offset in
                let start = compact.index(compact.startIndex, offsetBy: offset)
                let end = compact.index(start, offsetBy: 2)
                return String(compact[start..<end]).uppercased()
            }.joined(separator: ":")
        }

        return nil
    }

    private static func splitOIDLine(_ line: String) -> (oid: String, value: String)? {
        let separators = [" = INTEGER:", " = Gauge32:", " = STRING:", " = Hex-STRING:", " = OID:", " = Timeticks:"]
        for separator in separators {
            if let range = line.range(of: separator) {
                return (
                    String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines),
                    String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        }
        return nil
    }

    private static func parseStringValue(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet(charactersIn: "\"")).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum FibreAutoLinkBuilder {
    static func buildResults(from devices: [MonitoredDevice]) -> [FibreLossResult] {
        let switches = devices.filter { $0.deviceType == .netgearSwitch }
        guard switches.count >= 2 else { return [] }

        let observations = lldpLinkObservations(from: switches)

        // Build one stable visual/telemetry result per physical LLDP port-pair.
        // Reciprocal LLDP rows are merged by canonical endpoint key, but parallel
        // port-pairs between the same two switches are deliberately preserved.
        var bestByPhysicalLink: [String: LinkObservation] = [:]
        for observation in observations {
            let key = canonicalKey(
                observation.localDevice.id,
                observation.localPort,
                observation.remoteDevice.id,
                observation.remotePort
            )

            if let existing = bestByPhysicalLink[key] {
                if observation.quality > existing.quality {
                    bestByPhysicalLink[key] = observation
                }
            } else {
                bestByPhysicalLink[key] = observation
            }
        }

        let allLiveResults = bestByPhysicalLink.values.map { result(from: $0) }

        // Always show all LLDP-confirmed live links (fibre and copper).
        // Copper links only appear when LLDP is actively reporting them — they
        // are never persisted as stale. Fibre links are remembered and shown in
        // red when LLDP stops reporting them so the user knows something changed.
        let liveResults = allLiveResults

        // Only remember fibre links — copper links disappear naturally when
        // LLDP stops seeing them rather than persisting as stale red links.
        let fibreLiveResults = liveResults.filter { $0.linkMedium == .fibre }
        remember(fibreLiveResults)

        // Match by physical endpoints rather than ID — String.hashValue is
        // randomised per process so stableConnectionID produces a different UUID
        // each launch, meaning ID-based matching always fails across sessions.
        let liveEndpointKeys = Set(liveResults.map {
            canonicalKey($0.connection.aDeviceID, $0.connection.aPort,
                         $0.connection.bDeviceID, $0.connection.bPort)
        })
        let missingResults = rememberedLinks(devices: switches)
            .filter { result in
                let key = canonicalKey(result.connection.aDeviceID, result.connection.aPort,
                                       result.connection.bDeviceID, result.connection.bPort)
                return !liveEndpointKeys.contains(key)
            }
            .filter { $0.linkMedium == .fibre }

        return (liveResults + missingResults)
            .sorted { lhs, rhs in
                let lhsPair = devicePairKey(lhs.connection.aDeviceID, lhs.connection.bDeviceID)
                let rhsPair = devicePairKey(rhs.connection.aDeviceID, rhs.connection.bDeviceID)
                if lhsPair != rhsPair { return lhsPair < rhsPair }
                if lhs.connection.aPort != rhs.connection.aPort { return lhs.connection.aPort < rhs.connection.aPort }
                if lhs.connection.bPort != rhs.connection.bPort { return lhs.connection.bPort < rhs.connection.bPort }
                return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }
    }

    private struct RememberedTopologyLink: Codable, Hashable {
        let id: UUID
        let aDeviceID: UUID
        let aPort: Int
        let aDeviceName: String
        let bDeviceID: UUID
        let bPort: Int
        let bDeviceName: String
        let name: String
        let medium: TopologyLinkMedium
    }

    private static let rememberedLinksKey = "Mping.rememberedTopologyLinks.v1"
    private static let deletedLinksKey = "Mping.deletedTopologyLinks.v1"

    static func deleteRememberedLink(id: UUID) {
        var deleted = deletedLinkIDs()
        deleted.insert(id)
        saveDeletedLinkIDs(deleted)

        let remaining = loadRememberedLinks().filter { $0.id != id }
        saveRememberedLinks(remaining)
    }

    static func clearAllRememberedLinks() {
        UserDefaults.standard.removeObject(forKey: rememberedLinksKey)
        UserDefaults.standard.removeObject(forKey: deletedLinksKey)
    }

    private static func remember(_ results: [FibreLossResult]) {
        guard !results.isEmpty else { return }
        let deleted = deletedLinkIDs()

        // Key by canonical physical endpoint pair, NOT by the generated UUID.
        // stableConnectionID uses String.hashValue which is randomised per process,
        // so using UUID as key causes a new duplicate entry to be added on every boot
        // for the same physical link. Physical key is always deterministic.
        var byPhysicalKey: [String: RememberedTopologyLink] = [:]
        for remembered in loadRememberedLinks() {
            let key = canonicalKey(remembered.aDeviceID, remembered.aPort,
                                   remembered.bDeviceID, remembered.bPort)
            byPhysicalKey[key] = remembered
        }

        for result in results where !deleted.contains(result.id) {
            let key = canonicalKey(result.connection.aDeviceID, result.connection.aPort,
                                   result.connection.bDeviceID, result.connection.bPort)
            byPhysicalKey[key] = RememberedTopologyLink(
                id: result.id,
                aDeviceID: result.connection.aDeviceID,
                aPort: result.connection.aPort,
                aDeviceName: result.aDeviceName,
                bDeviceID: result.connection.bDeviceID,
                bPort: result.connection.bPort,
                bDeviceName: result.bDeviceName,
                name: result.connection.name,
                medium: result.linkMedium
            )
        }

        saveRememberedLinks(Array(byPhysicalKey.values))
    }

    private static func rememberedLinks(devices: [MonitoredDevice]) -> [FibreLossResult] {
        let deviceNames = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0.name) })
        let deleted = deletedLinkIDs()

        return loadRememberedLinks()
            .filter { !deleted.contains($0.id) }
            .compactMap { remembered in
                guard devices.contains(where: { $0.id == remembered.aDeviceID }) && devices.contains(where: { $0.id == remembered.bDeviceID }) else { return nil }

                let connection = FibreConnection(
                    id: remembered.id,
                    aDeviceID: remembered.aDeviceID,
                    aPort: remembered.aPort,
                    bDeviceID: remembered.bDeviceID,
                    bPort: remembered.bPort,
                    name: remembered.name
                )

                return FibreLossResult(
                    id: remembered.id,
                    connection: connection,
                    aDeviceName: deviceNames[remembered.aDeviceID] ?? remembered.aDeviceName,
                    bDeviceName: deviceNames[remembered.bDeviceID] ?? remembered.bDeviceName,
                    aTxDbm: nil,
                    aRxDbm: nil,
                    bTxDbm: nil,
                    bRxDbm: nil,
                    aTemperatureCelsius: nil,
                    bTemperatureCelsius: nil,
                    lossAToB: nil,
                    lossBToA: nil,
                    status: .noSignal,
                    aIsOpticalPort: remembered.medium == .fibre,
                    bIsOpticalPort: remembered.medium == .fibre,
                    linkMedium: remembered.medium,
                    isMissing: true,
                    stpBlocking: false
                )
            }
    }

    private static func loadRememberedLinks() -> [RememberedTopologyLink] {
        guard let data = UserDefaults.standard.data(forKey: rememberedLinksKey) else { return [] }
        return (try? JSONDecoder().decode([RememberedTopologyLink].self, from: data)) ?? []
    }

    private static func saveRememberedLinks(_ links: [RememberedTopologyLink]) {
        guard let data = try? JSONEncoder().encode(links) else { return }
        UserDefaults.standard.set(data, forKey: rememberedLinksKey)
    }

    private static func deletedLinkIDs() -> Set<UUID> {
        guard let strings = UserDefaults.standard.array(forKey: deletedLinksKey) as? [String] else { return [] }
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    private static func saveDeletedLinkIDs(_ ids: Set<UUID>) {
        UserDefaults.standard.set(ids.map { $0.uuidString }, forKey: deletedLinksKey)
    }

    private struct LinkObservation {
        let localDevice: MonitoredDevice
        let remoteDevice: MonitoredDevice
        let localPort: Int
        let remotePort: Int
        let remoteName: String
        let quality: Int
    }

    private static func lldpLinkObservations(from switches: [MonitoredDevice]) -> [LinkObservation] {
        var observations: [LinkObservation] = []

        for local in switches {
            for neighbour in local.switchTelemetry.lldpNeighbours {
                guard let remote = matchingDevice(for: neighbour, localDevice: local, devices: switches) else { continue }

                let localPort = neighbour.localPort
                let remotePort = bestRemotePort(for: neighbour, remoteDevice: remote, localDevice: local, allSwitches: switches) ?? neighbour.localPort
                let remoteName = neighbour.remoteSystemName?.trimmingCharacters(in: .whitespacesAndNewlines)

                observations.append(LinkObservation(
                    localDevice: local,
                    remoteDevice: remote,
                    localPort: localPort,
                    remotePort: remotePort,
                    remoteName: (remoteName?.isEmpty == false) ? remoteName! : remote.name,
                    quality: observationQuality(localPort: localPort, remotePort: remotePort, neighbour: neighbour)
                ))
            }
        }

        return observations
    }

    private static func result(from observation: LinkObservation) -> FibreLossResult {
        let key = canonicalKey(
            observation.localDevice.id,
            observation.localPort,
            observation.remoteDevice.id,
            observation.remotePort
        )

        let connection = FibreConnection(
            id: stableConnectionID(key: "lldp-physical-\(key)"),
            aDeviceID: observation.localDevice.id,
            aPort: observation.localPort,
            bDeviceID: observation.remoteDevice.id,
            bPort: observation.remotePort,
            name: "\(observation.localDevice.name) P\(observation.localPort) ↔ \(observation.remoteName) P\(observation.remotePort)"
        )

        let telemetry = observation.localDevice.switchTelemetry.fibrePorts + observation.remoteDevice.switchTelemetry.fibrePorts
        let aIsOptical = isOpticalPort(on: observation.localDevice, port: observation.localPort)
        let bIsOptical = isOpticalPort(on: observation.remoteDevice, port: observation.remotePort)
        // Show STP blocking on any inter-switch link — RSTP blocks both copper and fibre paths.
        let stpBlocking = observation.localDevice.switchTelemetry.stpBlockedPorts.contains(observation.localPort)
                       || observation.remoteDevice.switchTelemetry.stpBlockedPorts.contains(observation.remotePort)
        return FibreLossCalculator.calculate(
            connection: connection,
            aDeviceName: observation.localDevice.name,
            bDeviceName: observation.remoteDevice.name,
            telemetry: telemetry,
            aIsOpticalPort: aIsOptical,
            bIsOpticalPort: bIsOptical,
            stpBlocking: stpBlocking
        )
    }

    private static func isOpticalPort(on device: MonitoredDevice, port: Int) -> Bool {
        // Prefer the Device Ports SNMP table because the map label is about the
        // physical interface type, not whether we happened to find any DDM row
        // with the same numeric index. Some copper/CAT ports can otherwise borrow
        // unrelated SFP telemetry and incorrectly show loss/temperature.
        if let portRow = device.switchTelemetry.devicePorts.first(where: { $0.port == port }) {
            let medium = (portRow.transmissionMedium ?? "").lowercased()
            let name = (portRow.interfaceName ?? "").lowercased()
            let description = (portRow.interfaceDescription ?? "").lowercased()
            let combined = "\(medium) \(name) \(description)"

            if combined.contains("optical") || combined.contains("sfp") || combined.contains("fiber") || combined.contains("fibre") || combined.contains("xfp") || combined.contains("transceiver") {
                return true
            }

            if combined.contains("copper") || combined.contains("cat") || combined.contains("twisted") || combined.contains("ethernet") || combined.contains("rj45") || combined.contains("1000base-t") || combined.contains("10gbase-t") {
                return false
            }
        }

        // If the port table has not populated yet, only treat the endpoint as
        // optical when the SFP/DDM telemetry table explicitly contains that port.
        return device.switchTelemetry.fibrePorts.contains(where: { $0.port == port && ($0.hasOpticalPower || $0.temperatureCelsius != nil) })
    }

    private static func bestRemotePort(
        for neighbour: LLDPNeighbour,
        remoteDevice: MonitoredDevice,
        localDevice: MonitoredDevice,
        allSwitches: [MonitoredDevice]
    ) -> Int? {
        if let explicit = remotePortNumber(from: neighbour) {
            return explicit
        }

        // Fallback only when the local LLDP row does not contain a usable remote
        // port. Match the reciprocal row on the remote switch. This is intentionally
        // not used ahead of the explicit remote-port value, because doing that made
        // all parallel links borrow the first reciprocal port and flicker/collapse.
        return reciprocalLocalLLDPPort(on: remoteDevice, pointingTo: localDevice, allSwitches: allSwitches)
    }

    private static func observationQuality(localPort: Int, remotePort: Int, neighbour: LLDPNeighbour) -> Int {
        var score = 0
        if remotePort != localPort { score += 10 }
        if let remotePortID = neighbour.remotePortID, !remotePortID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += 20 }
        if let remotePortDescription = neighbour.remotePortDescription, !remotePortDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += 10 }
        if let remoteSystemName = neighbour.remoteSystemName, !remoteSystemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += 10 }
        return score
    }

    private static func reciprocalLocalLLDPPort(
        on remoteDevice: MonitoredDevice,
        pointingTo localDevice: MonitoredDevice,
        allSwitches: [MonitoredDevice]
    ) -> Int? {
        for neighbour in remoteDevice.switchTelemetry.lldpNeighbours {
            guard let matched = matchingDevice(for: neighbour, localDevice: remoteDevice, devices: allSwitches),
                  matched.id == localDevice.id else { continue }
            return neighbour.localPort
        }
        return nil
    }

    static func unmatchedNeighbours(from devices: [MonitoredDevice]) -> [(device: MonitoredDevice, neighbour: LLDPNeighbour)] {
        let switches = devices.filter { $0.deviceType == .netgearSwitch }
        var rows: [(MonitoredDevice, LLDPNeighbour)] = []

        for device in switches {
            for neighbour in device.switchTelemetry.lldpNeighbours {
                if matchingDevice(for: neighbour, localDevice: device, devices: switches) == nil {
                    rows.append((device, neighbour))
                }
            }
        }

        return rows
    }

    private static func matchingDevice(for neighbour: LLDPNeighbour, localDevice: MonitoredDevice, devices: [MonitoredDevice]) -> MonitoredDevice? {
        let remoteSystemName = neighbour.remoteSystemName?.normalisedForMatching ?? ""
        let remotePortText = neighbour.bestRemotePortText.normalisedForMatching

        guard !remoteSystemName.isEmpty || !remotePortText.isEmpty else { return nil }

        return devices.first { candidate in
            guard candidate.id != localDevice.id else { return false }

            let candidateName = candidate.name.normalisedForMatching
            let candidateIP = candidate.ipAddress.normalisedForMatching
            let candidateHostLike = candidateName
                .replacingOccurrences(of: "switch", with: "")
                .replacingOccurrences(of: "sw", with: "")

            if !remoteSystemName.isEmpty {
                if remoteSystemName == candidateName { return true }
                if remoteSystemName.contains(candidateName) || candidateName.contains(remoteSystemName) { return true }
                if !candidateHostLike.isEmpty && (remoteSystemName.contains(candidateHostLike) || candidateHostLike.contains(remoteSystemName)) { return true }
                if remoteSystemName == candidateIP { return true }
            }

            return false
        }
    }

    private static func remotePortNumber(from neighbour: LLDPNeighbour) -> Int? {
        let preferredTexts = [neighbour.remotePortID, neighbour.remotePortDescription]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for text in preferredTexts {
            if let interfacePort = interfaceStylePortNumber(from: text) {
                return interfacePort
            }
        }

        for text in preferredTexts {
            let matches = text.matches(for: #"\d+"#).compactMap(Int.init)
            if let last = matches.last { return last }
        }

        return nil
    }

    private static func interfaceStylePortNumber(from text: String) -> Int? {
        // Prefer the final component of names such as 0/42, g1/0/42, Gi1/0/42,
        // Te1/0/4, or 1/0/48. This avoids treating LLDP chassis/port subtype text
        // as the neighbour MAC address or as a single collapsed port number.
        let patterns = [
            #"(?:^|[^0-9])(\d+)\s*/\s*(\d+)\s*/\s*(\d+)(?:[^0-9]|$)"#,
            #"(?:^|[^0-9])(\d+)\s*/\s*(\d+)(?:[^0-9]|$)"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges >= 2 else { continue }
            let lastRange = match.range(at: match.numberOfRanges - 1)
            guard let swiftRange = Range(lastRange, in: text) else { continue }
            return Int(text[swiftRange])
        }

        return nil
    }

    private static func devicePairKey(_ aID: UUID, _ bID: UUID) -> String {
        let left = aID.uuidString
        let right = bID.uuidString
        return left < right ? "\(left)|\(right)" : "\(right)|\(left)"
    }

    private static func canonicalKey(_ aID: UUID, _ aPort: Int, _ bID: UUID, _ bPort: Int) -> String {
        let left = "\(aID.uuidString)-\(aPort)"
        let right = "\(bID.uuidString)-\(bPort)"
        return left < right ? "\(left)|\(right)" : "\(right)|\(left)"
    }

    private static func stableConnectionID(key: String) -> UUID {
        let hash = UInt64(bitPattern: Int64(key.hashValue))
        let hex = String(format: "%012llx", hash)
        return UUID(uuidString: "00000000-0000-4000-8000-\(String(hex.suffix(12)))") ?? UUID()
    }
}


struct FibreLinkLine: View {
    let start: CGPoint
    let end: CGPoint
    let result: FibreLossResult
    let showLine: Bool
    let showLabels: Bool
    let onSaveLabelOffset: (CGSize, String) -> Void
    let onDeleteMissingLink: () -> Void
    let automaticALabelOffset: CGSize
    let automaticBLabelOffset: CGSize

    @State private var aLabelOffset: CGSize
    @State private var bLabelOffset: CGSize
    @State private var aDragStartOffset: CGSize?
    @State private var bDragStartOffset: CGSize?
    @AppStorage("Mping.fibreLabelOpacity") private var fibreLabelOpacity: Double = 0.5
    @ObservedObject private var fibreBoxSettings = FibreBoxEditorSettings.shared
    @ObservedObject private var deviceTileSettings = DeviceTileEditorSettings.shared

    init(
        start: CGPoint,
        end: CGPoint,
        result: FibreLossResult,
        showLine: Bool,
        showLabels: Bool,
        initialALabelOffset: CGSize,
        initialBLabelOffset: CGSize,
        automaticALabelOffset: CGSize = .zero,
        automaticBLabelOffset: CGSize = .zero,
        onSaveLabelOffset: @escaping (CGSize, String) -> Void,
        onDeleteMissingLink: @escaping () -> Void = {}
    ) {
        self.start = start
        self.end = end
        self.result = result
        self.showLine = showLine
        self.showLabels = showLabels
        self.automaticALabelOffset = automaticALabelOffset
        self.automaticBLabelOffset = automaticBLabelOffset
        self.onSaveLabelOffset = onSaveLabelOffset
        self.onDeleteMissingLink = onDeleteMissingLink
        _aLabelOffset = State(initialValue: initialALabelOffset)
        _bLabelOffset = State(initialValue: initialBLabelOffset)
        _aDragStartOffset = State(initialValue: nil)
        _bDragStartOffset = State(initialValue: nil)
    }

    var body: some View {
        ZStack {
            if showLine {
                Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                .stroke(
                    result.stpBlocking ? Color.orange : result.topologyLineColor,
                    style: StrokeStyle(
                        lineWidth: result.topologyLineWidth,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: result.stpBlocking ? [10, 7] : []
                    )
                )
            }

            if showLabels {
                endpointLabel(result.aEndpointLabel)
                    .position(aLabelPosition)
                    .offset(combinedOffset(manual: aLabelOffset, automatic: automaticALabelOffset))
                    .zIndex(1001)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                let base = aDragStartOffset ?? aLabelOffset
                                aDragStartOffset = base
                                aLabelOffset = CGSize(
                                    width: base.width + value.translation.width,
                                    height: base.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                aDragStartOffset = nil
                                aLabelOffset = snappedManualOffsetIfCloseToLink(
                                    basePosition: aLabelPosition,
                                    manualOffset: aLabelOffset,
                                    automaticOffset: automaticALabelOffset
                                )
                                onSaveLabelOffset(aLabelOffset, "A")
                            }
                    )

                endpointLabel(result.bEndpointLabel)
                    .position(bLabelPosition)
                    .offset(combinedOffset(manual: bLabelOffset, automatic: automaticBLabelOffset))
                    .zIndex(1001)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                let base = bDragStartOffset ?? bLabelOffset
                                bDragStartOffset = base
                                bLabelOffset = CGSize(
                                    width: base.width + value.translation.width,
                                    height: base.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                bDragStartOffset = nil
                                bLabelOffset = snappedManualOffsetIfCloseToLink(
                                    basePosition: bLabelPosition,
                                    manualOffset: bLabelOffset,
                                    automaticOffset: automaticBLabelOffset
                                )
                                onSaveLabelOffset(bLabelOffset, "B")
                            }
                    )
            }
        }
        .contextMenu {
            if result.isMissing {
                Button("Delete Missing Link") {
                    onDeleteMissingLink()
                }
            }
        }
    }

    private func combinedOffset(manual: CGSize, automatic: CGSize) -> CGSize {
        CGSize(width: manual.width + automatic.width, height: manual.height + automatic.height)
    }

    private func snappedManualOffsetIfCloseToLink(
        basePosition: CGPoint,
        manualOffset: CGSize,
        automaticOffset: CGSize
    ) -> CGSize {
        let currentCentre = CGPoint(
            x: basePosition.x + manualOffset.width + automaticOffset.width,
            y: basePosition.y + manualOffset.height + automaticOffset.height
        )

        let projection = nearestPointOnLink(to: currentCentre)
        let distance = hypot(currentCentre.x - projection.x, currentCentre.y - projection.y)
        let snapDistance: CGFloat = 10.0

        guard distance <= snapDistance else { return manualOffset }

        return CGSize(
            width: projection.x - basePosition.x - automaticOffset.width,
            height: projection.y - basePosition.y - automaticOffset.height
        )
    }

    private func nearestPointOnLink(to point: CGPoint) -> CGPoint {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = (dx * dx) + (dy * dy)

        guard lengthSquared > 0.001 else { return start }

        let rawT = (((point.x - start.x) * dx) + ((point.y - start.y) * dy)) / lengthSquared
        let clampedT = min(max(rawT, 0.08), 0.92)

        return CGPoint(
            x: start.x + dx * clampedT,
            y: start.y + dy * clampedT
        )
    }

    private static func offsetStorageKey(for result: FibreLossResult, endpoint: String) -> String {
        "Mping.fibreLabelOffset.\(result.id.uuidString).\(endpoint)"
    }

    private static func savedOffset(for result: FibreLossResult, endpoint: String) -> CGSize {
        let key = offsetStorageKey(for: result, endpoint: endpoint)
        let values = UserDefaults.standard.array(forKey: key) as? [Double]
        guard let values, values.count == 2 else { return .zero }
        return CGSize(width: values[0], height: values[1])
    }

    private static func saveOffset(_ offset: CGSize, for result: FibreLossResult, endpoint: String) {
        let key = offsetStorageKey(for: result, endpoint: endpoint)
        UserDefaults.standard.set([Double(offset.width), Double(offset.height)], forKey: key)
    }

    private var aLabelPosition: CGPoint {
        endpointLabelPosition(from: start, toward: end)
    }

    private var bLabelPosition: CGPoint {
        endpointLabelPosition(from: end, toward: start)
    }

    /// Places the fibre label on the link vector just outside the device tile.
    ///
    /// `start` and `end` are device centre points.  The old layout used fixed
    /// fractions along the full link, which could place labels over the device
    /// tile on short links or diagonal links.  This calculates the distance from
    /// the device centre to the edge of the rectangular tile in the direction of
    /// the link, then adds enough clearance for the fibre label itself.
    private func endpointLabelPosition(from deviceCentre: CGPoint, toward remoteCentre: CGPoint) -> CGPoint {
        let vector = CGVector(
            dx: remoteCentre.x - deviceCentre.x,
            dy: remoteCentre.y - deviceCentre.y
        )

        let length = max(0.001, hypot(vector.dx, vector.dy))
        let ux = vector.dx / length
        let uy = vector.dy / length

        let halfTileWidth = max(1.0, deviceTileSettings.tileWidth / 2.0)
        let halfTileHeight = max(1.0, deviceTileSettings.tileHeight / 2.0)

        let distanceToVerticalEdge = abs(ux) > 0.0001 ? halfTileWidth / abs(ux) : CGFloat.greatestFiniteMagnitude
        let distanceToHorizontalEdge = abs(uy) > 0.0001 ? halfTileHeight / abs(uy) : CGFloat.greatestFiniteMagnitude
        let distanceToTileEdge = min(distanceToVerticalEdge, distanceToHorizontalEdge)

        let labelHalfProjection = estimatedLabelHalfProjectionAlongLine(unitX: ux, unitY: uy)
        let margin: CGFloat = 10.0
        let distanceFromCentre = distanceToTileEdge + labelHalfProjection + margin

        return CGPoint(
            x: deviceCentre.x + ux * distanceFromCentre,
            y: deviceCentre.y + uy * distanceFromCentre
        )
    }

    private func estimatedLabelHalfProjectionAlongLine(unitX ux: CGFloat, unitY uy: CGFloat) -> CGFloat {
        let estimatedWidth = max(
            fibreBoxSettings.minimumWidth,
            (fibreBoxSettings.textSize * 5.6) + (fibreBoxSettings.horizontalPadding * 2.0)
        )
        let estimatedHeight = (fibreBoxSettings.textSize * 3.4)
            + (fibreBoxSettings.lineSpacing * 2.0)
            + (fibreBoxSettings.verticalPadding * 2.0)

        return ((estimatedWidth / 2.0) * abs(ux)) + ((estimatedHeight / 2.0) * abs(uy))
    }

    private func endpointLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: fibreBoxSettings.textSize, weight: fibreBoxSettings.textBold ? .bold : .semibold, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(fibreBoxSettings.lineSpacing)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, fibreBoxSettings.horizontalPadding)
            .padding(.vertical, fibreBoxSettings.verticalPadding)
            .frame(minWidth: fibreBoxSettings.minimumWidth)
            .background(.black.opacity(clampedLabelOpacity), in: RoundedRectangle(cornerRadius: fibreBoxSettings.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: fibreBoxSettings.cornerRadius, style: .continuous)
                    .stroke(result.status.swiftUIColor.opacity(max(0.35, clampedLabelOpacity)), lineWidth: fibreBoxSettings.borderWidth)
            )
            .contentShape(Rectangle())
            .help("Drag to move this fibre label")
    }

    private var clampedLabelOpacity: Double {
        let sidebarOpacity = min(max(fibreLabelOpacity, 0.10), 1.0)
        let editorOpacity = min(max(Double(fibreBoxSettings.opacity), 0.10), 1.0)
        return min(max(sidebarOpacity * editorOpacity, 0.10), 1.0)
    }

    private var debugSuffix: String {
        let hasAnyNumbers = result.aTxDbm != nil || result.aRxDbm != nil || result.bTxDbm != nil || result.bRxDbm != nil
        return hasAnyNumbers ? "" : "  no DDM match"
    }
}

private struct FibreLinkRenderItem: Identifiable {
    let result: FibreLossResult
    let start: CGPoint
    let end: CGPoint

    var id: UUID { result.id }
}

struct FibreLinksLayer: View {
    let devices: [MonitoredDevice]
    let links: [FibreLossResult]
    let fibreLabelOffset: (FibreLossResult, String) -> CGSize
    let setFibreLabelOffset: (CGSize, FibreLossResult, String) -> Void
    var showLines: Bool = true
    var showLabels: Bool = true

    @ObservedObject private var fibreBoxSettings = FibreBoxEditorSettings.shared
    @ObservedObject private var deviceTileSettings = DeviceTileEditorSettings.shared
    @State private var deletedMissingLinkIDs: Set<UUID> = []

    private var devicePositionByID: [UUID: CGPoint] {
        Dictionary(uniqueKeysWithValues: devices.map { device in
            (device.id, CGPoint(x: device.x, y: device.y))
        })
    }

    var body: some View {
        let items = renderItems(positions: devicePositionByID)
            .filter { !deletedMissingLinkIDs.contains($0.result.id) }
        let labelOffsets = automaticLabelOffsets(for: items)

        ZStack(alignment: .topLeading) {
            ForEach(items) { item in
                FibreLinkLine(
                    start: item.start,
                    end: item.end,
                    result: item.result,
                    showLine: showLines,
                    showLabels: showLabels,
                    initialALabelOffset: fibreLabelOffset(item.result, "A"),
                    initialBLabelOffset: fibreLabelOffset(item.result, "B"),
                    automaticALabelOffset: labelOffsets[item.id]?.a ?? .zero,
                    automaticBLabelOffset: labelOffsets[item.id]?.b ?? .zero,
                    onSaveLabelOffset: { offset, endpoint in
                        setFibreLabelOffset(offset, item.result, endpoint)
                    },
                    onDeleteMissingLink: {
                        deletedMissingLinkIDs.insert(item.result.id)
                        FibreAutoLinkBuilder.deleteRememberedLink(id: item.result.id)
                    }
                )
            }
        }
    }


    private struct AutomaticEndpointOffsets {
        var a: CGSize = .zero
        var b: CGSize = .zero
    }

    private struct LabelCandidate: Identifiable {
        let id: String
        let resultID: UUID
        let endpoint: String
        let basePosition: CGPoint
        let text: String
    }

    private func automaticLabelOffsets(for items: [FibreLinkRenderItem]) -> [UUID: AutomaticEndpointOffsets] {
        guard showLabels else { return [:] }

        let candidates = items.flatMap { item in
            [
                LabelCandidate(
                    id: "\(item.id.uuidString)-A",
                    resultID: item.id,
                    endpoint: "A",
                    basePosition: endpointLabelPosition(from: item.start, toward: item.end),
                    text: item.result.aEndpointLabel
                ),
                LabelCandidate(
                    id: "\(item.id.uuidString)-B",
                    resultID: item.id,
                    endpoint: "B",
                    basePosition: endpointLabelPosition(from: item.end, toward: item.start),
                    text: item.result.bEndpointLabel
                )
            ]
        }
        .sorted { lhs, rhs in
            if abs(lhs.basePosition.y - rhs.basePosition.y) > 0.5 { return lhs.basePosition.y < rhs.basePosition.y }
            if abs(lhs.basePosition.x - rhs.basePosition.x) > 0.5 { return lhs.basePosition.x < rhs.basePosition.x }
            return lhs.id.localizedStandardCompare(rhs.id) == .orderedAscending
        }

        var acceptedRects: [CGRect] = []
        var offsets: [UUID: AutomaticEndpointOffsets] = [:]

        for candidate in candidates {
            let size = estimatedLabelSize(for: candidate.text)
            let chosenOffset = firstNonCollidingOffset(for: candidate, labelSize: size, acceptedRects: acceptedRects)
            let chosenRect = labelRect(center: CGPoint(
                x: candidate.basePosition.x + chosenOffset.width,
                y: candidate.basePosition.y + chosenOffset.height
            ), size: size).insetBy(dx: -4, dy: -4)
            acceptedRects.append(chosenRect)

            var pair = offsets[candidate.resultID] ?? AutomaticEndpointOffsets()
            if candidate.endpoint == "A" {
                pair.a = chosenOffset
            } else {
                pair.b = chosenOffset
            }
            offsets[candidate.resultID] = pair
        }

        return offsets
    }

    private func firstNonCollidingOffset(
        for candidate: LabelCandidate,
        labelSize: CGSize,
        acceptedRects: [CGRect]
    ) -> CGSize {
        for offset in collisionAvoidanceOffsets(labelSize: labelSize) {
            let rect = labelRect(center: CGPoint(
                x: candidate.basePosition.x + offset.width,
                y: candidate.basePosition.y + offset.height
            ), size: labelSize).insetBy(dx: -4, dy: -4)

            if !acceptedRects.contains(where: { $0.intersects(rect) }) {
                return offset
            }
        }

        // Extremely dense diagrams can exhaust the compact search pattern. Keep
        // moving the label downward in deterministic steps rather than allowing an
        // overlap. This makes the horizontal scrollbar/zoom preferable to stacked
        // unreadable fibre tiles.
        let step = max(labelSize.height + 12.0, 30.0)
        var multiplier: CGFloat = 1.0
        while multiplier < 200.0 {
            let offset = CGSize(width: 0, height: step * multiplier)
            let rect = labelRect(center: CGPoint(
                x: candidate.basePosition.x,
                y: candidate.basePosition.y + offset.height
            ), size: labelSize).insetBy(dx: -4, dy: -4)
            if !acceptedRects.contains(where: { $0.intersects(rect) }) {
                return offset
            }
            multiplier += 1.0
        }

        return .zero
    }

    private func collisionAvoidanceOffsets(labelSize: CGSize) -> [CGSize] {
        let horizontalStep = max(labelSize.width + 14.0, 86.0)
        let verticalStep = max(labelSize.height + 14.0, 42.0)
        var offsets: [CGSize] = [.zero]

        for ring in 1...10 {
            let r = CGFloat(ring)
            let horizontal = horizontalStep * r
            let vertical = verticalStep * r
            offsets.append(contentsOf: [
                CGSize(width: 0, height: -vertical),
                CGSize(width: 0, height: vertical),
                CGSize(width: -horizontal, height: 0),
                CGSize(width: horizontal, height: 0),
                CGSize(width: -horizontal, height: -vertical),
                CGSize(width: horizontal, height: -vertical),
                CGSize(width: -horizontal, height: vertical),
                CGSize(width: horizontal, height: vertical)
            ])
        }

        return offsets
    }

    private func labelRect(center: CGPoint, size: CGSize) -> CGRect {
        CGRect(
            x: center.x - (size.width / 2.0),
            y: center.y - (size.height / 2.0),
            width: size.width,
            height: size.height
        )
    }

    private func estimatedLabelSize(for text: String) -> CGSize {
        let lines = max(1, text.components(separatedBy: .newlines).count)
        let longestLine = text.components(separatedBy: .newlines).map(\.count).max() ?? 1
        let textWidth = CGFloat(longestLine) * fibreBoxSettings.textSize * 0.62
        let textHeight = CGFloat(lines) * fibreBoxSettings.textSize * 1.22
            + CGFloat(max(0, lines - 1)) * fibreBoxSettings.lineSpacing

        return CGSize(
            width: max(fibreBoxSettings.minimumWidth, textWidth + fibreBoxSettings.horizontalPadding * 2.0),
            height: textHeight + fibreBoxSettings.verticalPadding * 2.0
        )
    }

    private func endpointLabelPosition(from deviceCentre: CGPoint, toward remoteCentre: CGPoint) -> CGPoint {
        let vector = CGVector(
            dx: remoteCentre.x - deviceCentre.x,
            dy: remoteCentre.y - deviceCentre.y
        )

        let length = max(0.001, hypot(vector.dx, vector.dy))
        let ux = vector.dx / length
        let uy = vector.dy / length

        let halfTileWidth = max(1.0, deviceTileSettings.tileWidth / 2.0)
        let halfTileHeight = max(1.0, deviceTileSettings.tileHeight / 2.0)

        let distanceToVerticalEdge = abs(ux) > 0.0001 ? halfTileWidth / abs(ux) : CGFloat.greatestFiniteMagnitude
        let distanceToHorizontalEdge = abs(uy) > 0.0001 ? halfTileHeight / abs(uy) : CGFloat.greatestFiniteMagnitude
        let distanceToTileEdge = min(distanceToVerticalEdge, distanceToHorizontalEdge)

        let labelHalfProjection = estimatedLabelHalfProjectionAlongLine(unitX: ux, unitY: uy)
        let margin: CGFloat = 10.0
        let distanceFromCentre = distanceToTileEdge + labelHalfProjection + margin

        return CGPoint(
            x: deviceCentre.x + ux * distanceFromCentre,
            y: deviceCentre.y + uy * distanceFromCentre
        )
    }

    private func estimatedLabelHalfProjectionAlongLine(unitX ux: CGFloat, unitY uy: CGFloat) -> CGFloat {
        let estimatedSize = estimatedLabelSize(for: "P88\n-88.8 dB\n88°C")
        return ((estimatedSize.width / 2.0) * abs(ux)) + ((estimatedSize.height / 2.0) * abs(uy))
    }

    private func renderItems(positions: [UUID: CGPoint]) -> [FibreLinkRenderItem] {
        let grouped = Dictionary(grouping: links) { result in
            devicePairKey(result.connection.aDeviceID, result.connection.bDeviceID)
        }

        return grouped.values.flatMap { group -> [FibreLinkRenderItem] in
            let ordered = group.sorted { lhs, rhs in
                let left = "\(lhs.connection.aPort)-\(lhs.connection.bPort)-\(lhs.id.uuidString)"
                let right = "\(rhs.connection.aPort)-\(rhs.connection.bPort)-\(rhs.id.uuidString)"
                return left.localizedStandardCompare(right) == .orderedAscending
            }

            let spacing = parallelLinkSpacing(for: ordered, positions: positions)

            return ordered.enumerated().compactMap { index, result in
                guard let points = linkPoints(
                    for: result,
                    positions: positions,
                    index: index,
                    count: ordered.count,
                    spacing: spacing
                ) else { return nil }

                return FibreLinkRenderItem(result: result, start: points.start, end: points.end)
            }
        }
    }

    private func parallelLinkSpacing(
        for group: [FibreLossResult],
        positions: [UUID: CGPoint]
    ) -> CGFloat {
        guard group.count > 1,
              let first = group.first,
              let a = positions[first.connection.aDeviceID],
              let b = positions[first.connection.bDeviceID] else { return 18.0 }

        let dx = b.x - a.x
        let dy = b.y - a.y
        let length = max(0.001, hypot(dx, dy))
        let normalX = -dy / length
        let normalY = dx / length

        let largestProjectedTile = group.reduce(CGFloat(0.0)) { current, result in
            let aSize = estimatedLabelSize(for: result.aEndpointLabel)
            let bSize = estimatedLabelSize(for: result.bEndpointLabel)
            let aProjection = projectedLabelSizeAcrossParallelGap(size: aSize, normalX: normalX, normalY: normalY)
            let bProjection = projectedLabelSizeAcrossParallelGap(size: bSize, normalX: normalX, normalY: normalY)
            return max(current, aProjection, bProjection)
        }

        // The gap between neighbouring parallel links must be larger than the
        // fibre tile's projected size across that gap. Otherwise a tile snapped
        // onto one link visually sits on top of the next link. Keep the old 18 px
        // spacing as the absolute minimum, but expand automatically for larger
        // tile styles or long labels.
        return max(18.0, largestProjectedTile + 14.0)
    }

    private func projectedLabelSizeAcrossParallelGap(
        size: CGSize,
        normalX: CGFloat,
        normalY: CGFloat
    ) -> CGFloat {
        (size.width * abs(normalX)) + (size.height * abs(normalY))
    }

    private func linkPoints(
        for result: FibreLossResult,
        positions: [UUID: CGPoint],
        index: Int,
        count: Int,
        spacing: CGFloat
    ) -> (start: CGPoint, end: CGPoint)? {
        guard let a = positions[result.connection.aDeviceID],
              let b = positions[result.connection.bDeviceID] else { return nil }

        guard count > 1 else { return (a, b) }

        let dx = b.x - a.x
        let dy = b.y - a.y
        let length = max(0.001, hypot(dx, dy))
        let normalX = -dy / length
        let normalY = dx / length

        // Keep one-link telemetry as the centre/reference path. Parallel LLDP links
        // are spaced evenly around that centre line: 2 links sit either side; 3 links
        // are left/centre/right; larger bundles continue evenly spaced.
        let midpointIndex = (CGFloat(count) - 1.0) / 2.0
        let offset = (CGFloat(index) - midpointIndex) * spacing

        let shiftedStart = CGPoint(x: a.x + normalX * offset, y: a.y + normalY * offset)
        let shiftedEnd = CGPoint(x: b.x + normalX * offset, y: b.y + normalY * offset)
        return (shiftedStart, shiftedEnd)
    }

    private func devicePairKey(_ aID: UUID, _ bID: UUID) -> String {
        let left = aID.uuidString
        let right = bID.uuidString
        return left < right ? "\(left)|\(right)" : "\(right)|\(left)"
    }
}

private extension String {
    var trimmedLeadingDot: String { hasPrefix(".") ? String(dropFirst()) : self }

    var normalisedForMatching: String {
        lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "\"", with: "")
    }

    func matches(for pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..<endIndex, in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: self) else { return nil }
            return String(self[swiftRange])
        }
    }
}

