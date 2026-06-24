import Foundation
import Network

enum SNMPEngine {
    struct SwitchTemperatureResult: Sendable {
        let temperatureCelsius: Double?
        let discoveredName: String?
        let statusText: String
        let rawOutput: String
    }

    static func readSwitchTemperature(
        ipAddress: String,
        community: String,
        timeoutSeconds: Int = 1,
        sourceInterfaceName: String? = nil,
        sourceIPAddress: String? = nil,
        deviceID: UUID? = nil,
        deviceLabel: String = "SNMP Device"
    ) async -> SwitchTemperatureResult {
        let ip = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedCommunity = community.trimmingCharacters(in: .whitespacesAndNewlines)
        let community = cleanedCommunity.isEmpty ? "public" : cleanedCommunity

        guard !ip.isEmpty else {
            ConsoleOutputStore.log(
                subsystem: "SNMP",
                direction: .error,
                deviceID: deviceID,
                deviceLabel: deviceLabel,
                ipAddress: nil,
                message: "Empty switch IP"
            )
            return SwitchTemperatureResult(
                temperatureCelsius: nil,
                discoveredName: nil,
                statusText: "No switch IP",
                rawOutput: "Empty IP"
            )
        }

        let client = SNMPClient(
            host: ip,
            community: community,
            timeoutSeconds: max(1, timeoutSeconds),
            sourceInterfaceName: sourceInterfaceName,
            sourceIPAddress: sourceIPAddress
        )

        ConsoleOutputStore.log(
            subsystem: "SNMP",
            direction: .command,
            deviceID: deviceID,
            deviceLabel: deviceLabel,
            ipAddress: ip,
            message: "SNMP v2c telemetry poll started • community=\(community) • timeout=\(max(1, timeoutSeconds))s • interface=\(sourceInterfaceName ?? "automatic") • source=\(sourceIPAddress ?? "automatic")"
        )

        var raw = "Native SNMP v2c polling\n"
        raw += "Host: \(ip)\n"
        raw += "Community: \(community)\n"
        raw += "Interface: \(sourceInterfaceName ?? "automatic")\n"
        raw += "Source IP: \(sourceIPAddress ?? "automatic")\n\n"

        let discoveredName = await readDiscoveredName(client: client, raw: &raw)

        let liveTemperatureColumns = [
            ("Temp sensor temperature", "1.3.6.1.4.1.4526.10.43.1.8.1.5"),
            ("Temp unit temperature", "1.3.6.1.4.1.4526.10.43.1.15.1.3"),
            ("M4250 direct temperature", "1.3.6.1.4.1.4526.10.1.1.2.1")
        ]

        print("")
        print("========== MPING SNMP TEMPERATURE ==========")
        print("Host:", ip)

        for column in liveTemperatureColumns {
            do {
                ConsoleOutputStore.log(
                    subsystem: "SNMP",
                    direction: .command,
                    deviceID: deviceID,
                    deviceLabel: deviceLabel,
                    ipAddress: ip,
                    message: "WALK \(column.1) • \(column.0)"
                )
                let values = try await client.walk(baseOID: column.1, maxResults: 24)
                raw += "--- \(column.0) \(column.1) ---\n"

                for value in values {
                    let line = "\(value.oid) = \(value.value.debugDescription)"
                    raw += line + "\n"
                    print(line)
                }

                if let candidate = firstTemperatureCandidate(in: values) {
                    print("Temperature candidate:", candidate.oid, candidate.temperatureCelsius)
                    print("===========================================")
                    print("")

                    let fibreSummary = await readFibreOpticsSummary(client: client, raw: &raw, deviceID: deviceID, deviceLabel: deviceLabel, ipAddress: ip)
                    let lldpSummary = await readLLDPNeighbourSummary(client: client, raw: &raw, deviceID: deviceID, deviceLabel: deviceLabel, ipAddress: ip)
                    let portSummary = await readInterfacePortSummary(client: client, raw: &raw, deviceID: deviceID, deviceLabel: deviceLabel, ipAddress: ip)
                    let suffixParts = [fibreSummary, lldpSummary, portSummary].filter { !$0.isEmpty }
                    let suffixJoined = suffixParts.joined(separator: " • ")
                    let suffix = suffixJoined.isEmpty ? "" : " • \(suffixJoined)"

                    ConsoleOutputStore.log(
                        subsystem: "SNMP",
                        direction: .output,
                        deviceID: deviceID,
                        deviceLabel: deviceLabel,
                        ipAddress: ip,
                        message: raw
                    )

                    return SwitchTemperatureResult(
                        temperatureCelsius: candidate.temperatureCelsius,
                        discoveredName: discoveredName,
                        statusText: "SNMP OK • \(candidate.oid)\(suffix)",
                        rawOutput: raw
                    )
                }
            } catch {
                let line = "\(column.0): failed - \(snmpErrorText(error))"
                raw += line + "\n"
                print(line)
            }
        }

        print("No live temperature value found in Netgear temperature tables")
        print("===========================================")
        print("")

        do {
            ConsoleOutputStore.log(
                subsystem: "SNMP",
                direction: .command,
                deviceID: deviceID,
                deviceLabel: deviceLabel,
                ipAddress: ip,
                message: "GET 1.3.6.1.4.1.4526.10.1.1.1.3.0 • model probe"
            )
            let model = try await client.get(oid: "1.3.6.1.4.1.4526.10.1.1.1.3.0")
            raw += "Model probe: \(model.oid) = \(model.value.debugDescription)\n"

            let fibreSummary = await readFibreOpticsSummary(client: client, raw: &raw, deviceID: deviceID, deviceLabel: deviceLabel, ipAddress: ip)
            let lldpSummary = await readLLDPNeighbourSummary(client: client, raw: &raw, deviceID: deviceID, deviceLabel: deviceLabel, ipAddress: ip)
            raw += "--- Device port/interface probe skipped on live telemetry poll ---\n"
            raw += "Mping no longer walks IF-MIB/EtherLike-MIB during every switch telemetry poll.\n"
            let suffixParts = [fibreSummary, lldpSummary].filter { !$0.isEmpty }
            let suffixJoined = suffixParts.joined(separator: " • ")
            let suffix = suffixJoined.isEmpty ? "" : " • \(suffixJoined)"

            ConsoleOutputStore.log(
                subsystem: "SNMP",
                direction: .output,
                deviceID: deviceID,
                deviceLabel: deviceLabel,
                ipAddress: ip,
                message: raw
            )

            return SwitchTemperatureResult(
                temperatureCelsius: nil,
                discoveredName: discoveredName,
                statusText: "SNMP OK • temp table empty/not exposed\(suffix)",
                rawOutput: raw
            )
        } catch {
            raw += "Model probe failed: \(snmpErrorText(error))\n"

            ConsoleOutputStore.log(
                subsystem: "SNMP",
                direction: .error,
                deviceID: deviceID,
                deviceLabel: deviceLabel,
                ipAddress: ip,
                message: raw
            )

            return SwitchTemperatureResult(
                temperatureCelsius: nil,
                discoveredName: discoveredName,
                statusText: "SNMP failed",
                rawOutput: raw
            )
        }
    }
}

private func readDiscoveredName(client: SNMPClient, raw: inout String) async -> String? {
    // Prefer SNMP sysName first because it is the standard device identity field.
    // LLDP local system name is used as a fallback where available.
    let identityOIDs = [
        (label: "SNMP sysName", oid: "1.3.6.1.2.1.1.5.0"),
        (label: "LLDP local system name", oid: "1.0.8802.1.1.2.1.3.3.0")
    ]

    raw += "--- Device identity probe ---\n"

    for item in identityOIDs {
        do {
            let value = try await client.get(oid: item.oid)
            let candidate = cleanedDiscoveredName(value.value.displayValue)
            raw += "\(item.label): \(value.oid) = \(value.value.debugDescription)\n"

            if let candidate {
                raw += "Resolved device name: \(candidate)\n\n"
                return candidate
            }
        } catch {
            raw += "\(item.label): failed - \(snmpErrorText(error))\n"
        }
    }

    raw += "Resolved device name: unavailable\n\n"
    return nil
}

private func cleanedDiscoveredName(_ value: String) -> String? {
    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return nil }

    let lower = cleaned.lowercased()
    guard lower != "null", lower != "unknown", lower != "not available", lower != "n/a" else { return nil }

    return cleaned
}

private struct SNMPTemperatureCandidate {
    let oid: String
    let temperatureCelsius: Double
}

private struct FibreOpticsReading {
    let port: Int
    var temperature: String?
    var voltage: String?
    var biasCurrent: String?
    var txPower: String?
    var rxPower: String?
    var txFault: String?
    var los: String?
    var faultStatus: String?

    var rxDbm: Double? {
        parseDbm(rxPower)
    }

    var txDbm: Double? {
        parseDbm(txPower)
    }

    var hasAnyValue: Bool {
        [
        temperature,
        voltage,
        biasCurrent,
        txPower,
        rxPower,
        txFault,
        los,
        faultStatus
        ].contains { value in
        guard let value else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var shortSummary: String {
        var parts = ["P\(port)"]

        if let rxPower, !rxPower.isEmpty {
        parts.append("RX \(rxPower)")
        }

        if let txPower, !txPower.isEmpty {
        parts.append("TX \(txPower)")
        }

        return parts.joined(separator: " ")
    }
}

private func firstTemperatureCandidate(in values: [SNMPClient.Value]) -> SNMPTemperatureCandidate? {
    for value in values {
        if let temperature = value.value.temperatureCelsiusCandidate {
        return SNMPTemperatureCandidate(oid: value.oid, temperatureCelsius: temperature)
        }
    }

    return nil
}

private func readFibreOpticsSummary(
    client: SNMPClient,
    raw: inout String,
    deviceID: UUID?,
    deviceLabel: String,
    ipAddress: String
) async -> String {
    // NETGEAR M4250 live SFP DDM table found from real switch walk:
    // 1.3.6.1.4.1.4526.10.43.1.18
    //
    // Columns seen on M4250:
    // .1 = port index
    // .2 = module temperature, tenths of °C
    // .3 = voltage, millivolts
    // .4 = bias current, likely tenths/hundredths of mA depending optic
    // .5 = TX optical power, thousandths of dBm
    // .6 = RX optical power, thousandths of dBm
    // .7 = TX fault enum
    // .8 = LOS enum
    // .9 = fault status text
    let fibreColumns: [(label: String, oid: String, apply: (inout FibreOpticsReading, SNMPValue) -> Void)] = [
        // Live topology/alerting only needs temperature, TX/RX optical power and LOS.
        // Voltage, bias current, TX fault and text fault status are intentionally not walked
        // during regular telemetry because they multiply the SNMP request count without
        // changing the current Mping UI.
        ("Fibre optics temperature", "1.3.6.1.4.1.4526.10.43.1.18.1.2", { $0.temperature = formatTenthsCelsius($1) }),
        ("Fibre optics TX power", "1.3.6.1.4.1.4526.10.43.1.18.1.5", { $0.txPower = formatMilliDbm($1) }),
        ("Fibre optics RX power", "1.3.6.1.4.1.4526.10.43.1.18.1.6", { $0.rxPower = formatMilliDbm($1) }),
        ("Fibre optics LOS", "1.3.6.1.4.1.4526.10.43.1.18.1.8", { $0.los = formatLOSEnum($1) })
    ]

    var readingsByPort: [Int: FibreOpticsReading] = [:]

    print("")
    print("========== MPING SNMP FIBRE OPTICS ==========")
    raw += "--- Fibre optics/DDM probe using Netgear table 1.3.6.1.4.1.4526.10.43.1.18 ---\n"

    for column in fibreColumns {
        do {
        ConsoleOutputStore.log(
            subsystem: "SNMP Fibre",
            direction: .command,
            deviceID: deviceID,
            deviceLabel: deviceLabel,
            ipAddress: ipAddress,
            message: "WALK \(column.oid) • \(column.label)"
        )
        let values = try await client.walk(baseOID: column.oid, maxResults: 80)

        raw += "--- \(column.label) \(column.oid) ---\n"
        print("--- \(column.label) \(column.oid) ---")
        print("Returned OIDs:", values.count)

        for value in values {
            let line = "\(value.oid) = \(value.value.debugDescription)"
            raw += line + "\n"
            print(line)

            guard let port = lastOIDComponent(value.oid) else {
                continue
            }

            var reading = readingsByPort[port] ?? FibreOpticsReading(port: port)
            column.apply(&reading, value.value)
            readingsByPort[port] = reading
        }

        raw += "\n"
        } catch {
        let line = "\(column.label): failed - \(snmpErrorText(error))"
        raw += line + "\n"
        print(line)
        ConsoleOutputStore.log(
            subsystem: "SNMP Fibre",
            direction: .error,
            deviceID: deviceID,
            deviceLabel: deviceLabel,
            ipAddress: ipAddress,
            message: line
        )
        }
    }

    let readings = readingsByPort
        .values
        .filter { $0.hasAnyValue }
        .sorted { $0.port < $1.port }

    guard !readings.isEmpty else {
        raw += "No fibre optics DDM rows returned from Netgear table 1.3.6.1.4.1.4526.10.43.1.18\n"
        print("No fibre optics DDM rows returned from Netgear table 1.3.6.1.4.1.4526.10.43.1.18")
        print("============================================")
        print("")
        return "Fibre OID not mapped"
    }

    raw += "--- Fibre optics summary ---\n"

    for reading in readings {
        var parts = ["Port \(reading.port)"]

        if let temperature = reading.temperature, !temperature.isEmpty {
        parts.append("Temp \(temperature)")
        }

        if let voltage = reading.voltage, !voltage.isEmpty {
        parts.append("V \(voltage)")
        }

        if let biasCurrent = reading.biasCurrent, !biasCurrent.isEmpty {
        parts.append("Bias \(biasCurrent)")
        }

        if let txPower = reading.txPower, !txPower.isEmpty {
        parts.append("TX \(txPower)")
        }

        if let rxPower = reading.rxPower, !rxPower.isEmpty {
        parts.append("RX \(rxPower)")
        }

        if let los = reading.los, !los.isEmpty {
        parts.append("LOS \(los)")
        }

        let line = parts.joined(separator: " • ")
        raw += line + "\n"
        print(line)
    }

    print("============================================")
    print("")

    if let worstRx = readings
        .compactMap({ reading -> (FibreOpticsReading, Double)? in
        guard let rx = reading.rxDbm else { return nil }
        return (reading, rx)
        })
        .min(by: { $0.1 < $1.1 }) {
        return "Fibre \(worstRx.0.shortSummary)"
    }

    return "Fibre \(readings.prefix(2).map { $0.shortSummary }.joined(separator: " | "))"
}


private func readInterfacePortSummary(
    client: SNMPClient,
    raw: inout String,
    deviceID: UUID?,
    deviceLabel: String,
    ipAddress: String
) async -> String {
    // Standard IF-MIB / EtherLike-MIB columns used by Device Ports view.
    let columns: [(label: String, oid: String)] = [
        // Device Ports needs these lightweight columns for operator visibility.
        // Keep this list intentionally small: do not add counters or full historical tables here.
        ("IF-MIB ifName", "1.3.6.1.2.1.31.1.1.1.1"),
        ("IF-MIB ifAdminStatus", "1.3.6.1.2.1.2.2.1.7"),
        ("IF-MIB ifOperStatus", "1.3.6.1.2.1.2.2.1.8"),
        ("IF-MIB ifHighSpeed", "1.3.6.1.2.1.31.1.1.1.15"),
        ("IF-MIB ifConnectorPresent", "1.3.6.1.2.1.31.1.1.1.17"),
        ("EtherLike dot3StatsDuplexStatus", "1.3.6.1.2.1.10.7.2.1.19")
    ]

    var returnedRows = 0
    raw += "--- Device port/interface probe ---\n"

    for column in columns {
        do {
            ConsoleOutputStore.log(
                subsystem: "SNMP Ports",
                direction: .command,
                deviceID: deviceID,
                deviceLabel: deviceLabel,
                ipAddress: ipAddress,
                message: "WALK \(column.oid) • \(column.label)"
            )

            let values = try await client.walk(baseOID: column.oid, maxResults: 80)
            returnedRows += values.count
            raw += "--- \(column.label) \(column.oid) ---\n"
            for value in values {
                raw += "\(value.oid) = \(value.value.debugDescription)\n"
            }
            raw += "\n"
        } catch {
            let line = "\(column.label): failed - \(snmpErrorText(error))"
            raw += line + "\n"
            ConsoleOutputStore.log(
                subsystem: "SNMP Ports",
                direction: .error,
                deviceID: deviceID,
                deviceLabel: deviceLabel,
                ipAddress: ipAddress,
                message: line
            )
        }
    }

    if returnedRows == 0 {
        raw += "No interface port rows returned.\n"
        return "Ports 0"
    }

    raw += "Interface port rows returned: \(returnedRows)\n"
    return "Ports \(returnedRows) rows"
}

private func readLLDPNeighbourSummary(
    client: SNMPClient,
    raw: inout String,
    deviceID: UUID?,
    deviceLabel: String,
    ipAddress: String
) async -> String {
    // LLDP remote systems table.
    // These columns are consumed by LLDPTelemetryExtractor in FibreLinkEngine.swift:
    // .4 = remote chassis ID subtype. Only subtype 4 is a real MAC address.
    // .5 = remote chassis ID / MAC where the neighbour advertises a MAC chassis ID
    // .7 = remote port ID
    // .8 = remote port description
    // .9 = remote system name
    let lldpColumns: [(label: String, oid: String)] = [
        ("LLDP remote chassis ID subtype", "1.0.8802.1.1.2.1.4.1.1.4"),
        ("LLDP remote chassis ID", "1.0.8802.1.1.2.1.4.1.1.5"),
        ("LLDP remote port ID", "1.0.8802.1.1.2.1.4.1.1.7"),
        ("LLDP remote port description", "1.0.8802.1.1.2.1.4.1.1.8"),
        ("LLDP remote system name", "1.0.8802.1.1.2.1.4.1.1.9")
    ]

    var returnedRows = 0
    raw += "--- LLDP neighbour probe using 1.0.8802.1.1.2.1.4.1.1 ---\n"

    for column in lldpColumns {
        do {
            ConsoleOutputStore.log(
                subsystem: "SNMP LLDP",
                direction: .command,
                deviceID: deviceID,
                deviceLabel: deviceLabel,
                ipAddress: ipAddress,
                message: "WALK \(column.oid) • \(column.label)"
            )

            let values = try await client.walk(baseOID: column.oid, maxResults: 80)
            returnedRows += values.count

            raw += "--- \(column.label) \(column.oid) ---\n"
            for value in values {
                raw += "\(value.oid) = \(value.value.debugDescription)\n"
            }
            raw += "\n"
        } catch {
            let line = "\(column.label): failed - \(snmpErrorText(error))"
            raw += line + "\n"
            ConsoleOutputStore.log(
                subsystem: "SNMP LLDP",
                direction: .error,
                deviceID: deviceID,
                deviceLabel: deviceLabel,
                ipAddress: ipAddress,
                message: line
            )
        }
    }

    if returnedRows == 0 {
        raw += "No LLDP neighbour rows returned.\n"
        return "LLDP 0"
    }

    raw += "LLDP neighbour rows returned: \(returnedRows)\n"
    return "LLDP \(returnedRows) rows"
}

private func snmpErrorText(_ error: Error) -> String {
    if let snmpError = error as? SNMPClient.SNMPError {
        switch snmpError {
        case .invalidHost:
        return "Invalid SNMP host"
        case .timeout:
        return "SNMP timed out"
        case .malformedResponse:
        return "Malformed SNMP response"
        }
    }

    return String(describing: error)
}

private func lastOIDComponent(_ oid: String) -> Int? {
    oid.split(separator: ".").last.flatMap { Int($0) }
}

private func parseDbm(_ text: String?) -> Double? {
    guard let text else { return nil }
    let matches = text.matches(for: #"-?\d+(\.\d+)?"#)
    return matches.compactMap(Double.init).first
}

private func numericSNMPValue(_ value: SNMPValue) -> Double? {
    switch value {
    case .integer(let intValue):
        return Double(intValue)
    case .unsigned(let uintValue):
        return Double(uintValue)
    case .string(let stringValue):
        return stringValue.matches(for: #"-?\d+(\.\d+)?"#).compactMap(Double.init).first
    default:
        return nil
    }
}

private func formatTenthsCelsius(_ value: SNMPValue) -> String {
    guard let rawValue = numericSNMPValue(value) else { return value.displayValue }
    return String(format: "%.1f°C", rawValue / 10.0)
}

private func formatMillivolts(_ value: SNMPValue) -> String {
    guard let rawValue = numericSNMPValue(value) else { return value.displayValue }
    return String(format: "%.3fV", rawValue / 1000.0)
}

private func formatBiasCurrent(_ value: SNMPValue) -> String {
    guard let rawValue = numericSNMPValue(value) else { return value.displayValue }
    return String(format: "%.1fmA", rawValue / 10.0)
}

private func formatMilliDbm(_ value: SNMPValue) -> String {
    guard let rawValue = numericSNMPValue(value) else { return value.displayValue }

    if rawValue <= -40000 || rawValue >= 40000 {
        return "No signal"
    }

    let dbm: Double
    if abs(rawValue) > 100 {
        dbm = -abs(rawValue / 1000.0)
    } else {
        dbm = -abs(rawValue)
    }

    return String(format: "%.2fdBm", dbm)
}

private func formatFaultEnum(_ value: SNMPValue) -> String {
    guard let rawValue = numericSNMPValue(value).map(Int.init) else { return value.displayValue }
    switch rawValue {
    case 1:
        return "Fault"
    case 2:
        return "OK"
    default:
        return String(rawValue)
    }
}

private func formatLOSEnum(_ value: SNMPValue) -> String {
    guard let rawValue = numericSNMPValue(value).map(Int.init) else { return value.displayValue }
    switch rawValue {
    case 1:
        return "LOS"
    case 2:
        return "OK"
    default:
        return String(rawValue)
    }
}

private final class SNMPClient: @unchecked Sendable {
    struct Value: Sendable {
        let oid: String
        let value: SNMPValue
    }

    enum SNMPError: Error {
        case invalidHost
        case timeout
        case malformedResponse
    }

    private let host: String
    private let community: String
    private let timeoutSeconds: Int
    private let sourceInterfaceName: String?
    private let sourceIPAddress: String?

    init(
        host: String,
        community: String,
        timeoutSeconds: Int,
        sourceInterfaceName: String? = nil,
        sourceIPAddress: String? = nil
    ) {
        self.host = host
        self.community = community
        self.timeoutSeconds = timeoutSeconds
        let cleanedInterfaceName = sourceInterfaceName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedSourceIPAddress = sourceIPAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sourceInterfaceName = (cleanedInterfaceName?.isEmpty == false) ? cleanedInterfaceName : nil
        self.sourceIPAddress = (cleanedSourceIPAddress?.isEmpty == false) ? cleanedSourceIPAddress : nil
    }

    func walk(baseOID: String, maxResults: Int) async throws -> [Value] {
        var results: [Value] = []
        var currentOID = baseOID

        for _ in 0..<maxResults {
        let next = try await getNext(oid: currentOID)
        guard next.oid == baseOID || next.oid.hasPrefix(baseOID + ".") else { break }
        results.append(next)
        currentOID = next.oid
        }

        return results
    }

    func get(oid: String) async throws -> Value {
        try await request(oid: oid, pduType: 0xA0)
    }

    func getNext(oid: String) async throws -> Value {
        try await request(oid: oid, pduType: 0xA1)
    }

    private func request(oid: String, pduType: UInt8) async throws -> Value {
        guard let port = NWEndpoint.Port(rawValue: 161) else { throw SNMPError.invalidHost }

        let requestID = Int.random(in: 10_000...999_999)
        let packet = SNMPBER.encodeRequest(
        community: community,
        requestID: requestID,
        pduType: pduType,
        oid: oid
        )

        let parameters = NWParameters.udp
        let requiredInterface = NetworkInterfaceResolver.interface(named: sourceInterfaceName)

        if let requiredInterface {
            parameters.requiredInterface = requiredInterface
        }

        let connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: parameters)

        return try await withCheckedThrowingContinuation { continuation in
        let finishQueue = DispatchQueue(label: "Mping.SNMPClient.finishQueue")
        var didFinish = false

        func finish(_ result: Result<Value, Error>) {
            let shouldResume = finishQueue.sync {
                if didFinish { return false }
                didFinish = true
                return true
            }

            if shouldResume {
                connection.cancel()
                continuation.resume(with: result)
            }
        }

        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                connection.send(content: packet, completion: .contentProcessed { error in
                    if let error {
                        finish(.failure(error))
                        return
                    }

                    connection.receiveMessage { data, _, _, error in
                        if let error {
                            finish(.failure(error))
                            return
                        }

                        guard let data else {
                            finish(.failure(SNMPError.timeout))
                            return
                        }

                        do {
                            let parsed = try SNMPBER.decodeResponse(data: data)
                            finish(.success(parsed))
                        } catch {
                            finish(.failure(error))
                        }
                    }
                })
            case .failed(let error):
                finish(.failure(error))
            default:
                break
            }
        }

        connection.start(queue: .global(qos: .utility))
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + .seconds(timeoutSeconds)) {
            finish(.failure(SNMPError.timeout))
        }
        }
    }
}

private enum NetworkInterfaceResolver {
    static func interface(named interfaceName: String?) -> NWInterface? {
        guard let interfaceName = interfaceName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !interfaceName.isEmpty else {
            return nil
        }

        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "Mping.NetworkInterfaceResolver")
        let semaphore = DispatchSemaphore(value: 0)
        let resultBox = NetworkInterfaceLookupResult()

        monitor.pathUpdateHandler = { path in
            let match = path.availableInterfaces.first { $0.name == interfaceName }
            resultBox.set(match)
            semaphore.signal()
        }

        monitor.start(queue: queue)
        _ = semaphore.wait(timeout: .now() + .milliseconds(500))
        monitor.cancel()

        return resultBox.value
    }
}

private final class NetworkInterfaceLookupResult: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue: NWInterface?

    var value: NWInterface? {
        lock.lock()
        defer { lock.unlock() }
        return storedValue
    }

    func set(_ value: NWInterface?) {
        lock.lock()
        storedValue = value
        lock.unlock()
    }
}


private enum SNMPValue: Sendable {
    case integer(Int)
    case unsigned(UInt64)
    case string(String)
    case oid(String)
    case null
    case unsupported(type: UInt8, bytes: Data)

    var debugDescription: String {
        switch self {
        case .integer(let value): return "INTEGER: \(value)"
        case .unsigned(let value): return "UNSIGNED: \(value)"
        case .string(let value): return "STRING: \(value)"
        case .oid(let value): return "OID: \(value)"
        case .null: return "NULL"
        case .unsupported(let type, let bytes): return "TYPE 0x\(String(type, radix: 16)): \(bytes as NSData)"
        }
    }

    var displayValue: String {
        switch self {
        case .integer(let value):
        return String(value)
        case .unsigned(let value):
        return String(value)
        case .string(let value):
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .oid(let value):
        return value
        case .null:
        return ""
        case .unsupported(_, let bytes):
        return "\(bytes as NSData)"
        }
    }

    var temperatureCelsiusCandidate: Double? {
        switch self {
        case .integer(let value): return normaliseTemperature(Double(value))
        case .unsigned(let value): return normaliseTemperature(Double(value))
        case .string(let value):
        let matches = value.matches(for: #"-?\d+(\.\d+)?"#).compactMap(Double.init)
        for match in matches {
            if let temperature = normaliseTemperature(match) { return temperature }
        }
        return nil
        default:
        return nil
        }
    }

    private func normaliseTemperature(_ value: Double) -> Double? {
        if value >= 150 && value <= 900 { return value / 10.0 }
        if value >= 10 && value <= 100 { return value }
        return nil
    }
}

private enum SNMPBER {
    static func encodeRequest(community: String, requestID: Int, pduType: UInt8, oid: String) -> Data {
        let version = encodeInteger(1)
        let community = encodeOctetString(community)
        let requestID = encodeInteger(requestID)
        let errorStatus = encodeInteger(0)
        let errorIndex = encodeInteger(0)
        let varbind = encodeSequence(encodeOID(oid) + encodeNull())
        let varbindList = encodeSequence(varbind)
        let pdu = encodeTLV(type: pduType, value: requestID + errorStatus + errorIndex + varbindList)
        return encodeSequence(version + community + pdu)
    }

    static func decodeResponse(data: Data) throws -> SNMPClient.Value {
        var reader = BERReader(data: data)
        var message = try reader.readConstructed(expectedType: 0x30)
        _ = try message.readInteger()
        _ = try message.readString()
        var pdu = try message.readConstructed(expectedType: 0xA2)
        _ = try pdu.readInteger()
        _ = try pdu.readInteger()
        _ = try pdu.readInteger()
        var varbindList = try pdu.readConstructed(expectedType: 0x30)
        var varbind = try varbindList.readConstructed(expectedType: 0x30)
        let oid = try varbind.readOID()
        let value = try varbind.readValue()
        return SNMPClient.Value(oid: oid, value: value)
    }

    private static func encodeSequence(_ value: Data) -> Data { encodeTLV(type: 0x30, value: value) }

    private static func encodeInteger(_ value: Int) -> Data {
        var value = value
        var bytes: [UInt8] = []
        repeat {
        bytes.insert(UInt8(value & 0xFF), at: 0)
        value >>= 8
        } while value > 0
        if let first = bytes.first, first & 0x80 != 0 { bytes.insert(0, at: 0) }
        return encodeTLV(type: 0x02, value: Data(bytes))
    }

    private static func encodeOctetString(_ value: String) -> Data { encodeTLV(type: 0x04, value: Data(value.utf8)) }
    private static func encodeNull() -> Data { encodeTLV(type: 0x05, value: Data()) }

    private static func encodeOID(_ oid: String) -> Data {
        let parts = oid.split(separator: ".").compactMap { Int($0) }
        guard parts.count >= 2 else { return encodeTLV(type: 0x06, value: Data()) }
        var bytes: [UInt8] = [UInt8((parts[0] * 40) + parts[1])]
        for part in parts.dropFirst(2) { bytes.append(contentsOf: encodeBase128(part)) }
        return encodeTLV(type: 0x06, value: Data(bytes))
    }

    private static func encodeBase128(_ value: Int) -> [UInt8] {
        var value = value
        var bytes: [UInt8] = [UInt8(value & 0x7F)]
        value >>= 7
        while value > 0 {
        bytes.insert(UInt8(value & 0x7F) | 0x80, at: 0)
        value >>= 7
        }
        return bytes
    }

    private static func encodeTLV(type: UInt8, value: Data) -> Data {
        var data = Data([type])
        data.append(encodeLength(value.count))
        data.append(value)
        return data
    }

    private static func encodeLength(_ length: Int) -> Data {
        if length < 128 { return Data([UInt8(length)]) }
        var length = length
        var bytes: [UInt8] = []
        while length > 0 {
        bytes.insert(UInt8(length & 0xFF), at: 0)
        length >>= 8
        }
        return Data([0x80 | UInt8(bytes.count)] + bytes)
    }
}

private struct BERReader {
    private let data: Data
    private var offset: Int = 0

    init(data: Data) { self.data = data }

    mutating func readConstructed(expectedType: UInt8) throws -> BERReader {
        let (type, value) = try readTLV()
        guard type == expectedType else { throw SNMPClient.SNMPError.malformedResponse }
        return BERReader(data: value)
    }

    mutating func readInteger() throws -> Int {
        let (type, value) = try readTLV()
        guard type == 0x02 else { throw SNMPClient.SNMPError.malformedResponse }
        return Self.decodeSignedInteger(value)
    }

    mutating func readString() throws -> String {
        let (type, value) = try readTLV()
        guard type == 0x04 else { throw SNMPClient.SNMPError.malformedResponse }
        return String(data: value, encoding: .utf8) ?? ""
    }

    mutating func readOID() throws -> String {
        let (type, value) = try readTLV()
        guard type == 0x06 else { throw SNMPClient.SNMPError.malformedResponse }
        return decodeOID(value)
    }

    mutating func readValue() throws -> SNMPValue {
        let (type, value) = try readTLV()
        switch type {
        case 0x02:
        return .integer(Self.decodeSignedInteger(value))
        case 0x04:
        return .string(String(data: value, encoding: .utf8) ?? "")
        case 0x05:
        return .null
        case 0x06:
        return .oid(decodeOID(value))
        case 0x41, 0x42, 0x43, 0x46, 0x47:
        var result: UInt64 = 0
        for byte in value { result = (result << 8) | UInt64(byte) }
        return .unsigned(result)
        default:
        return .unsupported(type: type, bytes: value)
        }
    }


    private static func decodeSignedInteger(_ value: Data) -> Int {
        guard !value.isEmpty else { return 0 }

        var result = 0
        for byte in value {
            result = (result << 8) | Int(byte)
        }

        // SNMP INTEGER is BER signed two's-complement. The previous decoder treated
        // all INTEGER values as unsigned, so negative optical DDM readings such as
        // -6140 could become large positive values and then be classified as
        // "No signal" before the fibre-loss calculator ever saw them.
        if let first = value.first, first & 0x80 != 0 {
            result -= 1 << (value.count * 8)
        }

        return result
    }

    private mutating func readTLV() throws -> (UInt8, Data) {
        guard offset < data.count else { throw SNMPClient.SNMPError.malformedResponse }
        let type = data[offset]
        offset += 1
        let length = try readLength()
        guard offset + length <= data.count else { throw SNMPClient.SNMPError.malformedResponse }
        let value = data.subdata(in: offset..<(offset + length))
        offset += length
        return (type, value)
    }

    private mutating func readLength() throws -> Int {
        guard offset < data.count else { throw SNMPClient.SNMPError.malformedResponse }
        let first = data[offset]
        offset += 1
        if first & 0x80 == 0 { return Int(first) }
        let count = Int(first & 0x7F)
        guard count > 0, offset + count <= data.count else { throw SNMPClient.SNMPError.malformedResponse }
        var length = 0
        for _ in 0..<count {
        length = (length << 8) | Int(data[offset])
        offset += 1
        }
        return length
    }

    private func decodeOID(_ data: Data) -> String {
        guard let first = data.first else { return "" }
        var parts: [Int] = [Int(first) / 40, Int(first) % 40]
        var value = 0
        for byte in data.dropFirst() {
        value = (value << 7) | Int(byte & 0x7F)
        if byte & 0x80 == 0 {
            parts.append(value)
            value = 0
        }
        }
        return parts.map(String.init).joined(separator: ".")
    }
}

private extension String {
    func matches(for pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..<endIndex, in: self)
        return regex.matches(in: self, range: range).compactMap { match in
        guard let swiftRange = Range(match.range, in: self) else { return nil }
        return String(self[swiftRange])
        }
    }
}
