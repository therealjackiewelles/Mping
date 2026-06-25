import Foundation
import CoreGraphics

enum DeviceStatus: String, Codable, Sendable {
    case unknown
    case healthy
    case slow
    case offline

    var label: String {
        switch self {
        case .unknown: return "Unknown"
        case .healthy: return "Online"
        case .slow: return "Slow"
        case .offline: return "Offline"
        }
    }
}


struct PingFailureRecord: Codable, Equatable, Sendable {
    var timestamp: Date
    var timeoutMilliseconds: Int
    var sourceInterfaceName: String?
    var sourceIPAddress: String?
    var rawOutput: String

    var sourceDisplayText: String {
        let interface = sourceInterfaceName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let address = sourceIPAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !interface.isEmpty && !address.isEmpty {
            return "\(interface) • \(address)"
        }

        if !interface.isEmpty { return interface }
        if !address.isEmpty { return address }
        return "Auto"
    }
}

enum MonitoredDeviceType: String, Codable, CaseIterable, Sendable {
    case pingOnly
    case netgearSwitch

    var label: String {
        switch self {
        case .pingOnly: return "Ping Device"
        case .netgearSwitch: return "Netgear Switch"
        }
    }
}


enum DeviceNameSource: String, Codable, CaseIterable, Sendable {
    case manual
    case automatic

    var label: String {
        switch self {
        case .manual: return "Manual"
        case .automatic: return "SNMP/LLDP"
        }
    }
}


struct DevicePortTelemetry: Identifiable, Codable, Equatable, Hashable, Sendable {
    var deviceID: UUID
    var port: Int
    var interfaceName: String?
    var interfaceDescription: String?
    var adminStatus: String?
    var operStatus: String?
    var duplex: String?
    var transmissionMedium: String?
    var speedText: String?
    var lldpRemoteDeviceName: String?
    var lldpRemoteMACAddress: String?
    var lldpRemotePort: String?

    var id: String { "\(deviceID.uuidString)-P\(port)" }

    var displayPort: String {
        if let interfaceName, !interfaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return interfaceName
        }
        if let interfaceDescription, !interfaceDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return interfaceDescription
        }
        return "P\(port)"
    }

    var isUp: Bool {
        operStatus?.lowercased() == "up"
    }
}

struct SwitchTelemetry: Codable, Equatable, Sendable {
    var temperatureCelsius: Double?
    var lastSNMPChecked: Date?
    var snmpStatusText: String?
    var fibrePorts: [FibrePortTelemetry]
    var lldpNeighbours: [LLDPNeighbour]
    var devicePorts: [DevicePortTelemetry]

    init(
        temperatureCelsius: Double? = nil,
        lastSNMPChecked: Date? = nil,
        snmpStatusText: String? = nil,
        fibrePorts: [FibrePortTelemetry] = [],
        lldpNeighbours: [LLDPNeighbour] = [],
        devicePorts: [DevicePortTelemetry] = []
    ) {
        self.temperatureCelsius = temperatureCelsius
        self.lastSNMPChecked = lastSNMPChecked
        self.snmpStatusText = snmpStatusText
        self.fibrePorts = fibrePorts
        self.lldpNeighbours = lldpNeighbours
        self.devicePorts = devicePorts
    }

    enum CodingKeys: String, CodingKey {
        case temperatureCelsius
        case lastSNMPChecked
        case snmpStatusText
        case fibrePorts
        case lldpNeighbours
        case devicePorts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        temperatureCelsius = try c.decodeIfPresent(Double.self, forKey: .temperatureCelsius)
        lastSNMPChecked = try c.decodeIfPresent(Date.self, forKey: .lastSNMPChecked)
        snmpStatusText = try c.decodeIfPresent(String.self, forKey: .snmpStatusText)
        fibrePorts = try c.decodeIfPresent([FibrePortTelemetry].self, forKey: .fibrePorts) ?? []
        lldpNeighbours = try c.decodeIfPresent([LLDPNeighbour].self, forKey: .lldpNeighbours) ?? []
        devicePorts = try c.decodeIfPresent([DevicePortTelemetry].self, forKey: .devicePorts) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(temperatureCelsius, forKey: .temperatureCelsius)
        try c.encodeIfPresent(lastSNMPChecked, forKey: .lastSNMPChecked)
        try c.encodeIfPresent(snmpStatusText, forKey: .snmpStatusText)
        try c.encode(fibrePorts, forKey: .fibrePorts)
        try c.encode(lldpNeighbours, forKey: .lldpNeighbours)
        try c.encode(devicePorts, forKey: .devicePorts)
    }
}

struct MonitoredDevice: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var name: String
    var nameSource: DeviceNameSource
    var discoveredName: String?
    var ipAddress: String
    var x: Double
    var y: Double
    var status: DeviceStatus
    var lastRTT: Double?
    var pingRTTHistory: [Double]
    var lastChecked: Date?
    var lastSeenOnline: Date?
    var isPinging: Bool
    var pingPulseID: Int
    var verificationState: PingVerificationState
    var verificationFailures: [PingFailureRecord]

    var sourceInterfaceName: String?
    var sourceIPAddress: String?

    var deviceType: MonitoredDeviceType
    var snmpCommunity: String
    var webInterfacePath: String
    var switchTelemetry: SwitchTelemetry
    var pingLossHistory: [Bool]
    var currentOnlineSince: Date?
    var macAddress: String?
    var zoneName: String?

    init(
        id: UUID = UUID(),
        name: String,
        nameSource: DeviceNameSource = .manual,
        discoveredName: String? = nil,
        ipAddress: String,
        x: Double,
        y: Double,
        status: DeviceStatus = .unknown,
        lastRTT: Double? = nil,
        pingRTTHistory: [Double] = [],
        lastChecked: Date? = nil,
        lastSeenOnline: Date? = nil,
        isPinging: Bool = false,
        pingPulseID: Int = 0,
        verificationState: PingVerificationState = .online,
        verificationFailures: [PingFailureRecord] = [],
        sourceInterfaceName: String? = nil,
        sourceIPAddress: String? = nil,
        deviceType: MonitoredDeviceType = .pingOnly,
        snmpCommunity: String = "public",
        webInterfacePath: String = "",
        switchTelemetry: SwitchTelemetry = SwitchTelemetry(),
        pingLossHistory: [Bool] = [],
        currentOnlineSince: Date? = nil,
        macAddress: String? = nil,
        zoneName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.nameSource = nameSource
        self.discoveredName = discoveredName
        self.ipAddress = ipAddress
        self.x = x
        self.y = y
        self.status = status
        self.lastRTT = lastRTT
        self.pingRTTHistory = MonitoredDevice.sanitisedPingHistory(pingRTTHistory)
        self.lastChecked = lastChecked
        self.lastSeenOnline = lastSeenOnline
        self.isPinging = isPinging
        self.pingPulseID = pingPulseID
        self.verificationState = verificationState
        self.verificationFailures = Array(verificationFailures.suffix(4))
        self.sourceInterfaceName = sourceInterfaceName
        self.sourceIPAddress = sourceIPAddress
        self.deviceType = deviceType
        self.snmpCommunity = snmpCommunity
        self.webInterfacePath = webInterfacePath
        self.switchTelemetry = switchTelemetry
        self.pingLossHistory = pingLossHistory
        self.currentOnlineSince = currentOnlineSince
        self.macAddress = macAddress
        self.zoneName = zoneName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nameSource
        case discoveredName
        case ipAddress
        case x
        case y
        case status
        case lastRTT
        case pingRTTHistory
        case lastChecked
        case lastSeenOnline
        case isPinging
        case pingPulseID
        case verificationState
        case verificationFailures
        case sourceInterfaceName
        case sourceIPAddress
        case deviceType
        case snmpCommunity
        case webInterfacePath
        case switchTelemetry
        case pingLossHistory
        case currentOnlineSince
        case macAddress
        case zoneName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Device"
        nameSource = try c.decodeIfPresent(DeviceNameSource.self, forKey: .nameSource) ?? .manual
        discoveredName = try c.decodeIfPresent(String.self, forKey: .discoveredName)
        ipAddress = try c.decodeIfPresent(String.self, forKey: .ipAddress) ?? ""
        x = try c.decodeIfPresent(Double.self, forKey: .x) ?? 300
        y = try c.decodeIfPresent(Double.self, forKey: .y) ?? 260
        status = try c.decodeIfPresent(DeviceStatus.self, forKey: .status) ?? .unknown
        lastRTT = try c.decodeIfPresent(Double.self, forKey: .lastRTT)
        pingRTTHistory = MonitoredDevice.sanitisedPingHistory(
            try c.decodeIfPresent([Double].self, forKey: .pingRTTHistory) ?? []
        )
        lastChecked = try c.decodeIfPresent(Date.self, forKey: .lastChecked)
        lastSeenOnline = try c.decodeIfPresent(Date.self, forKey: .lastSeenOnline)
        isPinging = try c.decodeIfPresent(Bool.self, forKey: .isPinging) ?? false
        pingPulseID = try c.decodeIfPresent(Int.self, forKey: .pingPulseID) ?? 0
        verificationState = try c.decodeIfPresent(PingVerificationState.self, forKey: .verificationState) ?? .online
        verificationFailures = Array((try c.decodeIfPresent([PingFailureRecord].self, forKey: .verificationFailures) ?? []).suffix(4))
        sourceInterfaceName = try c.decodeIfPresent(String.self, forKey: .sourceInterfaceName)
        sourceIPAddress = try c.decodeIfPresent(String.self, forKey: .sourceIPAddress)
        deviceType = try c.decodeIfPresent(MonitoredDeviceType.self, forKey: .deviceType) ?? .pingOnly
        snmpCommunity = try c.decodeIfPresent(String.self, forKey: .snmpCommunity) ?? "public"
        webInterfacePath = try c.decodeIfPresent(String.self, forKey: .webInterfacePath) ?? ""
        if deviceType == .netgearSwitch && webInterfacePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            webInterfacePath = MonitoredDevice.defaultNetgearWebInterfacePath
        }
        switchTelemetry = try c.decodeIfPresent(SwitchTelemetry.self, forKey: .switchTelemetry) ?? SwitchTelemetry()
        pingLossHistory = try c.decodeIfPresent([Bool].self, forKey: .pingLossHistory) ?? []
        currentOnlineSince = try c.decodeIfPresent(Date.self, forKey: .currentOnlineSince)
        macAddress = try c.decodeIfPresent(String.self, forKey: .macAddress)
        zoneName = try c.decodeIfPresent(String.self, forKey: .zoneName)
    }


    mutating func recordPingResult(_ rtt: Double?) {
        lastRTT = rtt

        guard let rtt, rtt.isFinite, rtt >= 0 else { return }

        pingRTTHistory.append(rtt)

        if pingRTTHistory.count > Self.maximumPingHistorySamples {
            pingRTTHistory.removeFirst(pingRTTHistory.count - Self.maximumPingHistorySamples)
        }
    }

    mutating func recordPingAttempt(success: Bool) {
        pingLossHistory.append(success)
        if pingLossHistory.count > Self.maximumLossHistorySamples {
            pingLossHistory.removeFirst(pingLossHistory.count - Self.maximumLossHistorySamples)
        }
    }

    mutating func resetPingStatistics() {
        lastRTT = nil
        pingRTTHistory.removeAll(keepingCapacity: false)
        pingLossHistory.removeAll(keepingCapacity: false)
        currentOnlineSince = nil
        verificationState = .online
        verificationFailures.removeAll(keepingCapacity: false)
    }

    var packetLossPercent: Double? {
        guard pingLossHistory.count >= 3 else { return nil }
        let failures = pingLossHistory.filter { !$0 }.count
        return Double(failures) / Double(pingLossHistory.count) * 100.0
    }

    var jitter: Double? {
        guard pingRTTHistory.count >= 2 else { return nil }
        var total = 0.0
        for i in 1..<pingRTTHistory.count {
            total += abs(pingRTTHistory[i] - pingRTTHistory[i - 1])
        }
        return total / Double(pingRTTHistory.count - 1)
    }

    var uptimeDuration: TimeInterval? {
        guard let since = currentOnlineSince else { return nil }
        return Date().timeIntervalSince(since)
    }

    var minimumRTT: Double? {
        pingRTTHistory.min()
    }

    var maximumRTT: Double? {
        pingRTTHistory.max()
    }

    var averageRTT: Double? {
        guard !pingRTTHistory.isEmpty else { return nil }
        return pingRTTHistory.reduce(0, +) / Double(pingRTTHistory.count)
    }

    private static let maximumPingHistorySamples = 120
    private static let maximumLossHistorySamples = 50

    private static func sanitisedPingHistory(_ values: [Double]) -> [Double] {
        let clean = values.filter { $0.isFinite && $0 >= 0 }
        if clean.count <= maximumPingHistorySamples { return clean }
        return Array(clean.suffix(maximumPingHistorySamples))
    }

    var displayName: String {
        if nameSource == .automatic,
           let discoveredName,
           !discoveredName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return discoveredName
        }

        return name
    }

    static let defaultNetgearWebInterfacePath = ":49152/v1/base/cheetah_login.html"

    var effectiveWebInterfacePath: String {
        let cleaned = webInterfacePath.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty && deviceType == .netgearSwitch {
            return Self.defaultNetgearWebInterfacePath
        }
        return cleaned
    }

    var nicDisplayText: String {
        if let sourceInterfaceName,
           let sourceIPAddress,
           !sourceInterfaceName.isEmpty,
           !sourceIPAddress.isEmpty {
            return "\(sourceInterfaceName) • \(sourceIPAddress)"
        }

        return "Auto"
    }

    var temperatureDisplayText: String {
        guard let temp = switchTelemetry.temperatureCelsius else {
            return "Temp --"
        }

        return String(format: "Temp %.1f°C", temp)
    }
}

struct WorkspaceShape: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(id: UUID = UUID(), title: String, x: Double, y: Double, width: Double, height: Double) {
        self.id = id
        self.title = title
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

struct NetworkInterfaceInfo: Identifiable, Hashable, Sendable {
    var id: String { "\(bsdName)|\(ipv4Address)" }

    let bsdName: String
    let displayName: String
    let ipv4Address: String

    var pickerTitle: String {
        "\(displayName) (\(bsdName)) • \(ipv4Address)"
    }
}
