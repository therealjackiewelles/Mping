import Foundation
import Combine
import CoreGraphics
import Darwin
import AppKit
import UniformTypeIdentifiers


@MainActor
final class TelemetryPollingDebugSettings: ObservableObject {
    static let shared = TelemetryPollingDebugSettings()

    private static let snmpLLDPPollIntervalKey = "Mping.debug.snmpLLDPPollIntervalSeconds"
    private static let snmpTimeoutKey = "Mping.debug.snmpTimeoutSeconds"

    @Published var snmpLLDPPollIntervalSeconds: Double {
        didSet {
            UserDefaults.standard.set(min(120.0, max(5.0, snmpLLDPPollIntervalSeconds)), forKey: Self.snmpLLDPPollIntervalKey)
        }
    }

    @Published var snmpTimeoutSeconds: Double {
        didSet {
            UserDefaults.standard.set(min(5.0, max(0.5, snmpTimeoutSeconds)), forKey: Self.snmpTimeoutKey)
        }
    }

    private init() {
        if UserDefaults.standard.object(forKey: Self.snmpLLDPPollIntervalKey) == nil {
            snmpLLDPPollIntervalSeconds = 60.0
        } else {
            snmpLLDPPollIntervalSeconds = min(120.0, max(5.0, UserDefaults.standard.double(forKey: Self.snmpLLDPPollIntervalKey)))
        }

        if UserDefaults.standard.object(forKey: Self.snmpTimeoutKey) == nil {
            snmpTimeoutSeconds = 1.0
        } else {
            snmpTimeoutSeconds = min(5.0, max(0.5, UserDefaults.standard.double(forKey: Self.snmpTimeoutKey)))
        }
    }

    func resetDefaults() {
        snmpLLDPPollIntervalSeconds = 60.0
        snmpTimeoutSeconds = 1.0
    }
}

struct TemperatureHistorySample: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let temperatureCelsius: Double
}

@MainActor
final class DeviceStore: ObservableObject {
    @Published var devices: [MonitoredDevice] = []
    @Published var shapes: [WorkspaceShape] = []
    @Published private(set) var cachedFibreResults: [FibreLossResult] = []
    // Debounce flow direction changes: only commit after 2 consecutive polls agree,
    // to avoid oscillation while STP reconverges after a link state change.
    private var pendingFlowDirections: [UUID: (direction: FibreLossResult.FlowDirection, count: Int)] = [:]
    @Published private(set) var temperatureHistoryByDeviceID: [UUID: [TemperatureHistorySample]] = [:]
    @Published private(set) var alertEvents: [MpingAlertEvent] = []
    private var alertAcknowledgeCutoffs: [MpingAlertCategory: Date] = [:]
    @Published private(set) var flashingDeviceIDs: Set<UUID> = []
    @Published var pendingFocusDeviceID: UUID? = nil
    @Published var inspectorWidth: CGFloat = 280
    private let maximumTemperatureHistorySamples = 240

    private static let pingAlertThresholdKey = "Mping.alerting.pingThresholdMilliseconds"
    private static let switchTemperatureAlertThresholdKey = "Mping.alerting.switchTemperatureThresholdCelsius"
    private static let sfpTemperatureAlertThresholdKey = "Mping.alerting.sfpTemperatureThresholdCelsius"
    private static let fibreLossAlertThresholdKey = "Mping.alerting.fibreLossThresholdDb"
    private static let jitterAlertThresholdKey = "Mping.alerting.jitterThresholdMilliseconds"

    @Published var pingAlertThresholdMilliseconds: Double = DeviceStore.persistedAlertThreshold(
        key: DeviceStore.pingAlertThresholdKey,
        defaultValue: 100.0
    ) {
        didSet { alertThresholdDidChange() }
    }

    @Published var switchTemperatureAlertThresholdCelsius: Double = DeviceStore.persistedAlertThreshold(
        key: DeviceStore.switchTemperatureAlertThresholdKey,
        defaultValue: 70.0
    ) {
        didSet { alertThresholdDidChange() }
    }

    @Published var sfpTemperatureAlertThresholdCelsius: Double = DeviceStore.persistedAlertThreshold(
        key: DeviceStore.sfpTemperatureAlertThresholdKey,
        defaultValue: 75.0
    ) {
        didSet { alertThresholdDidChange() }
    }

    @Published var fibreLossAlertThresholdDb: Double = DeviceStore.persistedAlertThreshold(
        key: DeviceStore.fibreLossAlertThresholdKey,
        defaultValue: 4.0
    ) {
        didSet { alertThresholdDidChange() }
    }

    @Published var jitterAlertThresholdMilliseconds: Double = DeviceStore.persistedAlertThreshold(
        key: DeviceStore.jitterAlertThresholdKey,
        defaultValue: 2.0
    ) {
        didSet { alertThresholdDidChange() }
    }

    @Published private(set) var fibreLabelOffsets: [String: PersistedFibreLabelOffset] = [:]
    @Published var snapToGridEnabled: Bool = false
    @Published var snapGridSize: CGFloat = 40

    private var copiedDevices: [MonitoredDevice] = []
    private var copiedShapes: [WorkspaceShape] = []
    var hasClipboardContent: Bool { !copiedDevices.isEmpty || !copiedShapes.isEmpty }

    @Published var selectedDeviceID: UUID? = nil
    @Published var selectedShapeID: UUID? = nil
    @Published var selectedDeviceIDs: Set<UUID> = []
    @Published var selectedShapeIDs: Set<UUID> = []

    @Published var networkInterfaces: [NetworkInterfaceInfo] = []

    @Published var monitoringEnabled: Bool = UserDefaults.standard.object(forKey: "mping.monitoringEnabled") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(monitoringEnabled, forKey: "mping.monitoringEnabled")
            monitoringEnabled ? startMonitoring() : stopMonitoring()
            monitoringEnabled ? startSNMPMonitoring() : stopSNMPMonitoring()
            markWorkspaceDirty()
        }
    }

    @Published var pingInterval: Double = 2.0 {
        didSet {
            // Do not restart monitoring while the slider is moving.
            // The running monitor loop reads pingInterval live on every cycle.
            markWorkspaceDirty()
        }
    }

    @Published var pingTimeoutMilliseconds: Int = 1000 {
        didSet {
            // The running monitor loop reads this live; restarting can interrupt fast polling.
        }
    }

    @Published var workspaceScale: Double = 1.0
    @Published var workspaceOffset: CGSize = .zero

    private var monitorTask: Task<Void, Never>? = nil
    private var snmpTask: Task<Void, Never>? = nil
    private let telemetryPollingSettings = TelemetryPollingDebugSettings.shared
    private var pingVerificationTasks: [UUID: Task<Void, Never>] = [:]
    private var pingVerificationFailuresByDeviceID: [UUID: [PingFailureRecord]] = [:]

    private let appSupportFolder: URL
    private let defaultWorkspaceURL: URL
    private let legacySaveURL: URL
    private let workingStateURL: URL
    private let lastWorkspacePathKey = "Mping.lastWorkspacePath"
    private let lastWorkspaceBookmarkKey = "Mping.lastWorkspaceBookmark"

    @Published private(set) var currentWorkspaceURL: URL? = nil
    @Published private(set) var currentWorkspaceName: String = "Default Workspace"
    @Published private(set) var hasUnsavedChanges: Bool = false

    private var isApplyingWorkspace: Bool = false

    private var undoStack: [PersistedWorkspace] = []
    private var redoStack: [PersistedWorkspace] = []
    private var undoBaselineData: Data? = nil
    private var undoTransactionDepth: Int = 0
    private var undoTransactionStartWorkspace: PersistedWorkspace? = nil
    private var undoTransactionStartData: Data? = nil
    private let maximumUndoSnapshots = 80

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    var canRedo: Bool {
        !redoStack.isEmpty
    }

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = support.appendingPathComponent("Mping", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        self.appSupportFolder = folder
        self.defaultWorkspaceURL = folder.appendingPathComponent("Default Workspace.mpw")
        self.legacySaveURL = folder.appendingPathComponent("workspace.json")
        self.workingStateURL = folder.appendingPathComponent("Working Workspace.mpingstate")

        if UserDefaults.standard.bool(forKey: "mping.clearTopologyLinksOnBoot") {
            FibreAutoLinkBuilder.clearAllRememberedLinks()
        }

        refreshNetworkInterfaces()
        loadStartupWorkspace()

        if monitoringEnabled {
            startMonitoring()
            startSNMPMonitoring()
        }
    }

    deinit {
        monitorTask?.cancel()
        snmpTask?.cancel()
    }

    var hasSelection: Bool {
        !selectedDeviceIDs.isEmpty || !selectedShapeIDs.isEmpty
    }

    var selectedItemCount: Int {
        selectedDeviceIDs.count + selectedShapeIDs.count
    }

    func refreshNetworkInterfaces() {
        networkInterfaces = NetworkInterfaceProvider.ipv4Interfaces()
    }

    func effectivePingTimeoutMilliseconds() -> Int {
        // Keep timeout shorter than the interval so offline devices cannot stretch the cycle.
        // Examples:
        // 0.5s interval -> 250ms timeout
        // 1.0s interval -> 500ms timeout
        // 2.0s interval -> 1000ms timeout, capped by the user timeout
        let safeInterval = min(10.0, max(0.5, pingInterval))
        let intervalBasedTimeout = Int(max(100.0, (safeInterval * 1000.0) * 0.50))
        return max(100, min(pingTimeoutMilliseconds, intervalBasedTimeout))
    }

    func startMonitoring() {
        monitorTask?.cancel()

        guard monitoringEnabled else { return }

        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                await self.startPingCycleWithoutBlockingTimer()

                let intervalSeconds = min(10.0, max(0.5, self.pingInterval))
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }
    }

    func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil

        for task in pingVerificationTasks.values {
            task.cancel()
        }
        pingVerificationTasks.removeAll()

        for index in devices.indices {
            devices[index].isPinging = false
            devices[index].verificationState = devices[index].status == .offline ? .offline : .online
        }
    }

    func restartMonitoring() {
        guard monitoringEnabled else { return }
        startMonitoring()
    }

    private func startPingCycleWithoutBlockingTimer() async {
        let timeout = effectivePingTimeoutMilliseconds()

        let snapshot = devices
            .filter { $0.pingMonitoringEnabled && !$0.isPinging && pingVerificationTasks[$0.id] == nil }
            .map { device in
                (
                    id: device.id,
                    ip: device.ipAddress,
                    sourceIP: device.sourceIPAddress,
                    sourceInterfaceName: device.sourceInterfaceName,
                    name: device.displayName
                )
            }

        guard !snapshot.isEmpty else { return }

        markDevicesAsPinging(ids: snapshot.map(\.id), checkedAt: Date())

        // Run all pings concurrently, then apply ALL results in a single MainActor block.
        // This reduces SwiftUI render passes from N (one per ping result) to 1 per cycle.
        typealias PingBatchItem = (id: UUID, ip: String, sourceIP: String?, sourceInterfaceName: String?, name: String, result: PingEngine.PingResult)
        var batchResults: [PingBatchItem] = []
        await withTaskGroup(of: PingBatchItem.self) { group in
            for item in snapshot {
                group.addTask {
                    let result = await PingEngine.ping(
                        ipAddress: item.ip,
                        timeoutMilliseconds: timeout,
                        sourceIPAddress: item.sourceIP,
                        sourceInterfaceName: item.sourceInterfaceName,
                        deviceID: item.id,
                        deviceLabel: item.name
                    )
                    return (item.id, item.ip, item.sourceIP, item.sourceInterfaceName, item.name, result)
                }
            }
            for await item in group { batchResults.append(item) }
        }

        await MainActor.run { [weak self] in
            guard let self else { return }
            let checkedAt = Date()
            var pendingOfflineVerification: [PingBatchItem] = []
            var pendingOnlineVerification: [PingBatchItem] = []

            for item in batchResults {
                // Inline the per-device update against a local copy via updateDeviceRuntime
                // (which still mutates self.devices[index] directly — all mutations happen
                // within this single MainActor block so SwiftUI coalesces into one render pass).
                var updatedDevice: MonitoredDevice?

                self.updateDeviceRuntime(id: item.id) { device in
                    let wasOffline = device.status == .offline
                    device.recordPingResult(item.result.rtt)
                    device.recordPingAttempt(success: item.result.status != .offline)
                    device.lastChecked = checkedAt
                    if item.result.status != .offline { device.lastSeenOnline = checkedAt }
                    device.isPinging = false

                    if item.result.status == .offline {
                        if wasOffline {
                            device.verificationState = .offline
                            updatedDevice = device
                        } else {
                            device.verificationState = .verifyingOffline
                            pendingOfflineVerification.append(item)
                        }
                    } else if wasOffline {
                        device.verificationState = .verifyingOnline
                        pendingOnlineVerification.append(item)
                    } else {
                        device.verificationState = .online
                        device.verificationFailures.removeAll(keepingCapacity: false)
                        self.pingVerificationFailuresByDeviceID[item.id] = nil
                        device.status = self.effectiveRuntimeStatus(for: device, pingStatus: item.result.status)
                        if device.currentOnlineSince == nil { device.currentOnlineSince = checkedAt }
                        updatedDevice = device
                    }
                }

                if let updatedDevice { self.evaluatePingAlerts(for: updatedDevice) }
            }

            // Start verification tasks after all devices are updated
            for item in pendingOfflineVerification {
                self.startOfflinePingVerification(
                    id: item.id, ipAddress: item.ip, timeoutMilliseconds: timeout,
                    sourceInterfaceName: item.sourceInterfaceName, sourceIPAddress: item.sourceIP,
                    deviceLabel: item.name)
            }
            for item in pendingOnlineVerification {
                self.startOnlinePingVerification(
                    id: item.id, ipAddress: item.ip, timeoutMilliseconds: timeout,
                    sourceInterfaceName: item.sourceInterfaceName, sourceIPAddress: item.sourceIP,
                    deviceLabel: item.name)
            }
        }

    }

    func lookupMACAddress(for deviceID: UUID, ip: String) {
        Task { [weak self] in
            guard let self else { return }
            guard let mac = await Self.arpLookup(ip: ip) else { return }
            updateDeviceRuntime(id: deviceID) { device in
                device.macAddress = mac
            }
        }
    }

    private static func arpLookup(ip: String) async -> String? {
        await Task.detached(priority: .background) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/arp")
            process.arguments = ["-n", ip]
            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = Pipe()
            guard (try? process.run()) != nil else { return nil }
            process.waitUntilExit()
            let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            guard let range = output.range(of: #"\b([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2}\b"#, options: .regularExpression) else { return nil }
            return String(output[range]).uppercased()
        }.value
    }

    struct BulkDeviceEdit {
        var zoneName: String? = nil          // nil = no change, "" = clear, "value" = set
        var snmpCommunity: String? = nil     // nil = no change
        var deviceType: MonitoredDeviceType? = nil  // nil = no change
        var pingMonitoringEnabled: Bool? = nil      // nil = no change
        var snmpMonitoringEnabled: Bool? = nil      // nil = no change
    }

    func bulkUpdateDevices(ids: Set<UUID>, edit: BulkDeviceEdit) {
        for id in ids {
            if let zone = edit.zoneName {
                updateDeviceZoneName(id: id, zoneName: zone.isEmpty ? nil : zone)
            }
            if let community = edit.snmpCommunity, !community.isEmpty {
                updateDeviceSNMPCommunity(id: id, community: community)
            }
            if let type = edit.deviceType {
                updateDeviceType(id: id, type: type)
            }
            if let pingEnabled = edit.pingMonitoringEnabled {
                updateDevicePingMonitoring(id: id, enabled: pingEnabled)
            }
            if let snmpEnabled = edit.snmpMonitoringEnabled {
                updateDeviceSNMPMonitoring(id: id, enabled: snmpEnabled)
            }
        }
    }

    func updateDevicePingMonitoring(id: UUID, enabled: Bool) {
        updateDeviceRuntime(id: id) { device in
            device.pingMonitoringEnabled = enabled
            if !enabled {
                device.status = .unknown
                device.lastRTT = nil
                device.pingRTTHistory.removeAll(keepingCapacity: false)
                device.pingLossHistory.removeAll(keepingCapacity: false)
                device.currentOnlineSince = nil
                device.verificationState = .online
                device.isPinging = false
            }
        }
        markWorkspaceDirty()
    }

    func updateDeviceSNMPMonitoring(id: UUID, enabled: Bool) {
        updateDeviceRuntime(id: id) { device in
            device.snmpMonitoringEnabled = enabled
        }
        markWorkspaceDirty()
    }

    func updateDeviceZoneName(id: UUID, zoneName: String?) {
        updateDeviceRuntime(id: id) { device in
            let trimmed = zoneName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            device.zoneName = trimmed.isEmpty ? nil : trimmed
        }
        markWorkspaceDirty()
    }

    private func startOfflinePingVerification(
        id: UUID,
        ipAddress: String,
        timeoutMilliseconds: Int,
        sourceInterfaceName: String?,
        sourceIPAddress: String?,
        deviceLabel: String
    ) {
        guard pingVerificationTasks[id] == nil else { return }

        let task = Task { [weak self] in
            let engine = PingVerificationEngine()
            let burst = await engine.verifyOffline {
                await PingEngine.ping(
                    ipAddress: ipAddress,
                    timeoutMilliseconds: timeoutMilliseconds,
                    sourceIPAddress: sourceIPAddress,
                    sourceInterfaceName: sourceInterfaceName,
                    deviceID: id,
                    deviceLabel: deviceLabel
                )
            }

            await MainActor.run {
                guard let self else { return }
                self.pingVerificationTasks[id] = nil

                guard self.devices.contains(where: { $0.id == id }) else { return }

                if burst.confirmed {
                    let failures = burst.failedAttempts.map {
                        Self.pingFailureRecord(
                            from: $0,
                            timeoutMilliseconds: timeoutMilliseconds,
                            sourceInterfaceName: sourceInterfaceName,
                            sourceIPAddress: sourceIPAddress
                        )
                    }
                    self.pingVerificationFailuresByDeviceID[id] = failures

                    var updatedDevice: MonitoredDevice?
                    self.updateDeviceRuntime(id: id) { device in
                        device.verificationState = .offline
                        device.verificationFailures = failures
                        device.status = .offline
                        device.lastChecked = failures.last?.timestamp ?? Date()
                        device.isPinging = false
                        device.currentOnlineSince = nil
                        updatedDevice = device
                    }

                    if let updatedDevice {
                        self.evaluatePingAlerts(for: updatedDevice)
                    }
                } else if let success = burst.successfulAttempt {
                    self.pingVerificationFailuresByDeviceID[id] = nil

                    var updatedDevice: MonitoredDevice?
                    self.updateDeviceRuntime(id: id) { device in
                        device.verificationState = .online
                        device.verificationFailures.removeAll(keepingCapacity: false)
                        device.recordPingResult(success.result.rtt)
                        device.lastSeenOnline = success.timestamp
                        device.status = self.effectiveRuntimeStatus(for: device, pingStatus: success.result.status)
                        device.lastChecked = success.timestamp
                        device.isPinging = false
                        if device.currentOnlineSince == nil {
                            device.currentOnlineSince = success.timestamp
                        }
                        updatedDevice = device
                    }

                    if let updatedDevice {
                        self.evaluatePingAlerts(for: updatedDevice)
                    }
                }
            }
        }

        pingVerificationTasks[id] = task
    }

    private func startOnlinePingVerification(
        id: UUID,
        ipAddress: String,
        timeoutMilliseconds: Int,
        sourceInterfaceName: String?,
        sourceIPAddress: String?,
        deviceLabel: String
    ) {
        guard pingVerificationTasks[id] == nil else { return }

        let task = Task { [weak self] in
            let engine = PingVerificationEngine()
            let burst = await engine.verifyOnline {
                await PingEngine.ping(
                    ipAddress: ipAddress,
                    timeoutMilliseconds: timeoutMilliseconds,
                    sourceIPAddress: sourceIPAddress,
                    sourceInterfaceName: sourceInterfaceName,
                    deviceID: id,
                    deviceLabel: deviceLabel
                )
            }

            await MainActor.run {
                guard let self else { return }
                self.pingVerificationTasks[id] = nil

                guard self.devices.contains(where: { $0.id == id }) else { return }

                if burst.confirmed, let success = burst.attempts.last {
                    self.pingVerificationFailuresByDeviceID[id] = nil

                    var updatedDevice: MonitoredDevice?
                    self.updateDeviceRuntime(id: id) { device in
                        device.verificationState = .online
                        device.verificationFailures.removeAll(keepingCapacity: false)
                        device.recordPingResult(success.result.rtt)
                        device.lastSeenOnline = success.timestamp
                        device.status = self.effectiveRuntimeStatus(for: device, pingStatus: success.result.status)
                        device.lastChecked = success.timestamp
                        device.isPinging = false
                        device.currentOnlineSince = success.timestamp
                        updatedDevice = device
                    }

                    if let updatedDevice {
                        self.evaluatePingAlerts(for: updatedDevice)
                    }
                } else {
                    let failures = burst.failedAttempts.map {
                        Self.pingFailureRecord(
                            from: $0,
                            timeoutMilliseconds: timeoutMilliseconds,
                            sourceInterfaceName: sourceInterfaceName,
                            sourceIPAddress: sourceIPAddress
                        )
                    }

                    if !failures.isEmpty {
                        self.pingVerificationFailuresByDeviceID[id] = failures
                    }

                    self.updateDeviceRuntime(id: id) { device in
                        device.verificationState = .offline
                        if !failures.isEmpty {
                            device.verificationFailures = failures
                        }
                        device.status = .offline
                        device.lastChecked = failures.last?.timestamp ?? Date()
                        device.isPinging = false
                    }
                }
            }
        }

        pingVerificationTasks[id] = task
    }

    private static func pingFailureRecord(
        from attempt: PingVerificationAttempt,
        timeoutMilliseconds: Int,
        sourceInterfaceName: String?,
        sourceIPAddress: String?
    ) -> PingFailureRecord {
        PingFailureRecord(
            timestamp: attempt.timestamp,
            timeoutMilliseconds: timeoutMilliseconds,
            sourceInterfaceName: sourceInterfaceName,
            sourceIPAddress: sourceIPAddress,
            rawOutput: attempt.result.rawOutput
        )
    }

    // SNMP currently fetches switch temperature, SFP DDM and LLDP in one telemetry pass.
    // Keep this slower for now because LLDP walks are comparatively expensive.
    // Later this should be split into separate user-adjustable intervals.
    func startSNMPMonitoring() {
        snmpTask?.cancel()

        guard monitoringEnabled else { return }

        snmpTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.pollSwitchTelemetry()
                let intervalSeconds = min(120.0, max(5.0, self.telemetryPollingSettings.snmpLLDPPollIntervalSeconds))
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }
    }

    func stopSNMPMonitoring() {
        snmpTask?.cancel()
        snmpTask = nil
    }

    func temperatureHistory(for deviceID: UUID) -> [TemperatureHistorySample] {
        temperatureHistoryByDeviceID[deviceID] ?? []
    }

    func fibreResults(for deviceID: UUID) -> [FibreLossResult] {
        cachedFibreResults
            .filter { result in
                result.connection.aDeviceID == deviceID || result.connection.bDeviceID == deviceID
            }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    private func recordTemperatureHistory(deviceID: UUID, temperatureCelsius: Double?) {
        guard let temperatureCelsius, temperatureCelsius.isFinite else { return }

        var history = temperatureHistoryByDeviceID[deviceID] ?? []

        // Avoid duplicate samples when a view refresh or failed SNMP poll reuses the same value
        // within the same short interval. The SNMP loop normally runs once per minute.
        if let last = history.last,
           abs(last.temperatureCelsius - temperatureCelsius) < 0.001,
           Date().timeIntervalSince(last.timestamp) < 5 {
            return
        }

        history.append(TemperatureHistorySample(timestamp: Date(), temperatureCelsius: temperatureCelsius))

        if history.count > maximumTemperatureHistorySamples {
            history.removeFirst(history.count - maximumTemperatureHistorySamples)
        }

        temperatureHistoryByDeviceID[deviceID] = history
    }

    private func effectiveRuntimeStatus(for device: MonitoredDevice, pingStatus: DeviceStatus) -> DeviceStatus {
        guard pingStatus == .offline else {
            return pingStatus
        }

        // Ping timeout is the fast fault detector. Do not let stale SNMP/LLDP reachability
        // hold a previously ping-reachable device online for minutes after it has stopped
        // responding to ICMP.
        //
        // The SNMP grace below is deliberately short and only helps Netgear switches that
        // have no selected source interface and have not yet produced a valid ping RTT.
        // This preserves the useful Wi-Fi/Auto behaviour without delaying real offline
        // alerts once ping has been working.
        let snmpReachabilityGraceSeconds: TimeInterval = 20

        // If SNMP has just succeeded, the switch is not truly offline even if ICMP
        // missed a few replies. Treat recent SNMP reachability as a guard against
        // false disconnect alerts, especially when using Auto routing over Wi-Fi.
        guard device.deviceType == .netgearSwitch,
              device.switchTelemetry.snmpStatusText?.hasPrefix("SNMP OK") == true,
              let lastSNMPChecked = device.switchTelemetry.lastSNMPChecked,
              Date().timeIntervalSince(lastSNMPChecked) <= snmpReachabilityGraceSeconds else {
            return .offline
        }

        return .healthy
    }

    private func refreshCachedFibreResults(forceAlertEvaluation: Bool = false) {
        var rebuiltResults = FibreAutoLinkBuilder.buildResults(from: devices)

        // Debounce flow direction changes. STP reconvergence causes the designated-bridge
        // OIDs to oscillate across polls while RSTP is still electing. Only commit a
        // direction change after it has been consistent for 2 consecutive polls.
        let requiredStablePolls = 2
        for i in rebuiltResults.indices {
            let result = rebuiltResults[i]
            let key = result.connection.id
            let currentDirection = cachedFibreResults.first(where: { $0.connection.id == key })?.flowDirection

            guard let current = currentDirection, result.flowDirection != current else {
                // No prior direction, or direction unchanged — clear any pending and keep result.
                pendingFlowDirections.removeValue(forKey: key)
                continue
            }

            // Direction changed — require stability before committing.
            let pending = pendingFlowDirections[key]
            if pending?.direction == result.flowDirection {
                let newCount = (pending?.count ?? 0) + 1
                if newCount >= requiredStablePolls {
                    pendingFlowDirections.removeValue(forKey: key)
                    // Commit the new direction — leave rebuiltResults[i] as-is.
                } else {
                    pendingFlowDirections[key] = (result.flowDirection, newCount)
                    rebuiltResults[i].flowDirection = current  // hold old direction
                }
            } else {
                // Different pending direction — reset counter.
                pendingFlowDirections[key] = (result.flowDirection, 1)
                rebuiltResults[i].flowDirection = current  // hold old direction
            }
        }

        // LLDP polling can run even when the physical topology has not changed.
        // Re-publishing an identical fibre result array forces the workspace/link layer
        // to redraw and is a common source of visible SwiftUI jitter.
        guard rebuiltResults != cachedFibreResults else {
            if forceAlertEvaluation {
                evaluateFibreAlerts(from: cachedFibreResults)
            }
            return
        }

        cachedFibreResults = rebuiltResults
        evaluateFibreAlerts(from: rebuiltResults)
    }

    private func pollSwitchTelemetry() async {
        let switches = devices
            .filter { $0.deviceType == .netgearSwitch && $0.snmpMonitoringEnabled }
            .map {
                (
                    id: $0.id,
                    ip: $0.ipAddress,
                    community: $0.snmpCommunity,
                    name: $0.displayName,
                    sourceInterfaceName: $0.sourceInterfaceName,
                    sourceIPAddress: $0.sourceIPAddress
                )
            }

        guard !switches.isEmpty else { return }

        let pollCompletedAt = Date()
        let snmpTimeoutSeconds = Int(ceil(max(0.5, min(5.0, telemetryPollingSettings.snmpTimeoutSeconds))))
        var results: [(UUID, SNMPEngine.SwitchTemperatureResult)] = []

        await withTaskGroup(of: (UUID, SNMPEngine.SwitchTemperatureResult).self) { group in
            for item in switches {
                group.addTask {
                    let result = await SNMPEngine.readSwitchTemperature(
                        ipAddress: item.ip,
                        community: item.community,
                        timeoutSeconds: snmpTimeoutSeconds,
                        sourceInterfaceName: item.sourceInterfaceName,
                        sourceIPAddress: item.sourceIPAddress,
                        deviceID: item.id,
                        deviceLabel: item.name
                    )
                    return (item.id, result)
                }
            }

            for await result in group {
                results.append(result)
            }
        }

        guard !results.isEmpty else { return }

        // Apply all SNMP/LLDP results in one array publish instead of one publish per switch.
        // This keeps the map from rebuilding repeatedly during a single telemetry pass.
        var updatedDevices = devices
        var changedDeviceIDs = Set<UUID>()
        var topologyInputsChanged = false
        var updatedDevicesForAlerts: [MonitoredDevice] = []

        for (id, result) in results {
            guard let index = updatedDevices.firstIndex(where: { $0.id == id }) else { continue }

            var device = updatedDevices[index]
            var deviceChanged = false
            var topologyChangedForDevice = false

            if device.switchTelemetry.temperatureCelsius != result.temperatureCelsius {
                device.switchTelemetry.temperatureCelsius = result.temperatureCelsius
                deviceChanged = true
            }

            if device.switchTelemetry.lastSNMPChecked != pollCompletedAt {
                device.switchTelemetry.lastSNMPChecked = pollCompletedAt
                deviceChanged = true
            }

            if device.switchTelemetry.snmpStatusText != result.statusText {
                device.switchTelemetry.snmpStatusText = result.statusText
                deviceChanged = true
            }

            // Treat successful SNMP/LLDP telemetry as management reachability.
            // On Wi-Fi or multi-NIC Macs, ICMP can be routed differently from native SNMP,
            // so an automatic ping route can briefly report offline while the switch is
            // actively answering SNMP/LLDP. Do not leave Netgear devices red in that case.
            if result.statusText.hasPrefix("SNMP OK"), device.status == .offline || device.status == .unknown {
                device.status = .healthy
                deviceChanged = true
            }

            if let discoveredName = result.discoveredName, !discoveredName.isEmpty, device.discoveredName != discoveredName {
                device.discoveredName = discoveredName
                deviceChanged = true
            }

            let fibrePorts = FibreTelemetryExtractor.extractPorts(
                deviceID: id,
                rawOutput: result.rawOutput
            )
            if device.switchTelemetry.fibrePorts != fibrePorts {
                device.switchTelemetry.fibrePorts = fibrePorts
                deviceChanged = true
                topologyChangedForDevice = true
            }

            let lldpNeighbours = LLDPTelemetryExtractor.extractNeighbours(
                rawOutput: result.rawOutput
            )
            if device.switchTelemetry.lldpNeighbours != lldpNeighbours {
                device.switchTelemetry.lldpNeighbours = lldpNeighbours
                deviceChanged = true
                topologyChangedForDevice = true
            }

            let devicePorts = DevicePortTelemetryExtractor.extractPorts(
                deviceID: id,
                rawOutput: result.rawOutput,
                lldpNeighbours: lldpNeighbours,
                fibrePorts: fibrePorts
            )
            if device.switchTelemetry.devicePorts != devicePorts {
                device.switchTelemetry.devicePorts = devicePorts
                deviceChanged = true
            }

            let stp = STPTelemetryExtractor.extract(rawOutput: result.rawOutput)
            if device.switchTelemetry.stpIsRootBridge != stp.isRootBridge {
                device.switchTelemetry.stpIsRootBridge = stp.isRootBridge
                deviceChanged = true
                topologyChangedForDevice = true  // triggers tile re-render via Equatable + topology rebuild
            }
            if device.switchTelemetry.stpRootBridgeID != stp.rootBridgeID {
                device.switchTelemetry.stpRootBridgeID = stp.rootBridgeID
                deviceChanged = true
            }
            if device.switchTelemetry.stpBlockedPorts != stp.blockedPorts {
                device.switchTelemetry.stpBlockedPorts = stp.blockedPorts
                deviceChanged = true
                topologyChangedForDevice = true
            }
            if device.switchTelemetry.stpDesignatedBridgePerPort != stp.designatedBridgePerPort {
                device.switchTelemetry.stpDesignatedBridgePerPort = stp.designatedBridgePerPort
                deviceChanged = true
                topologyChangedForDevice = true
            }

            ConsoleOutputStore.log(
                subsystem: "SNMP STP",
                direction: .info,
                deviceID: id,
                deviceLabel: device.displayName,
                ipAddress: device.ipAddress,
                message: "STP — isRoot: \(stp.isRootBridge) | rootBridgeID: \(stp.rootBridgeID ?? "unknown") | blocking: \(stp.blockedPorts)"
            )

            guard deviceChanged else { continue }

            updatedDevices[index] = device
            changedDeviceIDs.insert(id)
            topologyInputsChanged = topologyInputsChanged || topologyChangedForDevice
            updatedDevicesForAlerts.append(device)
        }

        if !changedDeviceIDs.isEmpty {
            devices = updatedDevices
        }

        for device in updatedDevicesForAlerts {
            recordTemperatureHistory(deviceID: device.id, temperatureCelsius: device.switchTelemetry.temperatureCelsius)
            evaluateTemperatureAlerts(for: device)
        }

        if topologyInputsChanged {
            refreshCachedFibreResults()
        }
    }



    private static func persistedAlertThreshold(key: String, defaultValue: Double) -> Double {
        guard UserDefaults.standard.object(forKey: key) != nil else { return defaultValue }
        return UserDefaults.standard.double(forKey: key)
    }

    private func alertThresholdDidChange() {
        UserDefaults.standard.set(pingAlertThresholdMilliseconds, forKey: Self.pingAlertThresholdKey)
        UserDefaults.standard.set(switchTemperatureAlertThresholdCelsius, forKey: Self.switchTemperatureAlertThresholdKey)
        UserDefaults.standard.set(sfpTemperatureAlertThresholdCelsius, forKey: Self.sfpTemperatureAlertThresholdKey)
        UserDefaults.standard.set(fibreLossAlertThresholdDb, forKey: Self.fibreLossAlertThresholdKey)
        UserDefaults.standard.set(jitterAlertThresholdMilliseconds, forKey: Self.jitterAlertThresholdKey)
        reevaluateAllAlerts()
        markWorkspaceDirty()
    }

    func resetAlertThresholdsToDefaults() {
        pingAlertThresholdMilliseconds = 100.0
        switchTemperatureAlertThresholdCelsius = 70.0
        sfpTemperatureAlertThresholdCelsius = 75.0
        fibreLossAlertThresholdDb = 4.0
        jitterAlertThresholdMilliseconds = 2.0
    }

    func fibreLabelOffset(for result: FibreLossResult, endpoint: String) -> CGSize {
        let key = fibreLabelOffsetKey(for: result, endpoint: endpoint)
        if let persisted = fibreLabelOffsets[key] {
            return CGSize(width: persisted.width, height: persisted.height)
        }

        // Migration fallback for labels moved before offsets became workspace data.
        let legacyKey = "Mping.fibreLabelOffset.\(result.id.uuidString).\(endpoint)"
        if let values = UserDefaults.standard.array(forKey: legacyKey) as? [Double], values.count == 2 {
            return CGSize(width: values[0], height: values[1])
        }

        return .zero
    }

    func setFibreLabelOffset(_ offset: CGSize, for result: FibreLossResult, endpoint: String) {
        let key = fibreLabelOffsetKey(for: result, endpoint: endpoint)
        fibreLabelOffsets[key] = PersistedFibreLabelOffset(width: Double(offset.width), height: Double(offset.height))
        markWorkspaceDirty()
    }

    func clearAllTopologyLinks() {
        FibreAutoLinkBuilder.clearAllRememberedLinks()
        pendingFlowDirections = [:]
        cachedFibreResults = []
        refreshCachedFibreResults()
    }

    func rebuildFibreTopology() {
        pendingFlowDirections = [:]
        cachedFibreResults = []
        refreshCachedFibreResults()
    }

    func fibreBoxStyleDidChange() {
        markWorkspaceDirty()
    }

    private func fibreLabelOffsetKey(for result: FibreLossResult, endpoint: String) -> String {
        "\(result.connection.id.uuidString).\(endpoint)"
    }

    private func reevaluateAllAlerts() {
        for device in devices {
            evaluatePingAlerts(for: device)
            evaluateTemperatureAlerts(for: device)
        }
        evaluateFibreAlerts(from: cachedFibreResults)
    }
    /// Total stored event count for the sidebar tally.
    /// Includes alert snapshots and OK/recovery events so the UI count matches the full event history.
    func alertCount(for category: MpingAlertCategory) -> Int {
        alertEvents.filter { $0.category == category }.count
    }

    func storedAlertCount(for category: MpingAlertCategory) -> Int {
        alertCount(for: category)
    }

    /// New/unacknowledged alert count for red visual state only.
    /// Recovery/OK rows are history events and should not keep the UI in an alarming state.
    func newAlertCount(for category: MpingAlertCategory) -> Int {
        Set(
            alertEvents
                .filter { $0.category == category && $0.kind == .alert && !$0.isAcknowledged }
                .map { $0.conditionKey }
        ).count
    }

    /// Alert menus are always chronological, newest first.
    /// They intentionally do not regroup by acknowledged/current state because that makes the log jump around.
    func alerts(for category: MpingAlertCategory) -> [MpingAlertEvent] {
        alertEvents
            .filter { $0.category == category }
            .sorted {
                if $0.firstTriggeredAt != $1.firstTriggeredAt { return $0.firstTriggeredAt > $1.firstTriggeredAt }
                return $0.lastUpdatedAt > $1.lastUpdatedAt
            }
    }

    func focusDevice(_ id: UUID) {
        pendingFocusDeviceID = id
        selectOnlyDevice(id)
        flashingDeviceIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.flashingDeviceIDs.remove(id)
        }
    }

    func allAlerts() -> [MpingAlertEvent] {
        alertEvents.sorted {
            if $0.firstTriggeredAt != $1.firstTriggeredAt { return $0.firstTriggeredAt > $1.firstTriggeredAt }
            return $0.lastUpdatedAt > $1.lastUpdatedAt
        }
    }

    func acknowledgeAlerts(category: MpingAlertCategory? = nil) {
        let acknowledgeTime = Date()
        let categoriesToAcknowledge = category.map { [$0] } ?? MpingAlertCategory.allCases

        for acknowledgedCategory in categoriesToAcknowledge {
            alertAcknowledgeCutoffs[acknowledgedCategory] = acknowledgeTime
        }

        for index in alertEvents.indices {
            guard category == nil || alertEvents[index].category == category else { continue }
            guard alertEvents[index].firstTriggeredAt <= acknowledgeTime else { continue }
            alertEvents[index].isAcknowledged = true
        }
    }

    func clearAlerts(category: MpingAlertCategory? = nil) {
        acknowledgeAlerts(category: category)
    }

    private func offlineAlertDetail(for device: MonitoredDevice) -> String {
        "Offline"
    }

    private func evaluatePingAlerts(for device: MonitoredDevice) {
        let disconnectKey = alertKey(.deviceDisconnect, deviceID: device.id)
        if device.status == .offline {
            raiseAlert(
                category: .deviceDisconnect,
                conditionKey: disconnectKey,
                deviceID: device.id,
                deviceName: device.displayName,
                location: device.ipAddress,
                detail: offlineAlertDetail(for: device)
            )
        } else {
            resolveAlert(conditionKey: disconnectKey)
        }

        let pingKey = alertKey(.pingThreshold, deviceID: device.id)
        if let rtt = device.lastRTT, rtt >= pingAlertThresholdMilliseconds {
            raiseAlert(
                category: .pingThreshold,
                conditionKey: pingKey,
                deviceID: device.id,
                deviceName: device.displayName,
                location: device.ipAddress,
                detail: String(format: "RTT %.0f ms (limit %.0f ms)", rtt, pingAlertThresholdMilliseconds)
            )
        } else {
            resolveAlert(conditionKey: pingKey)
        }

        let jitterKey = alertKey(.pingThreshold, deviceID: device.id, suffix: "jitter")
        if device.status != .offline,
           let jitter = device.jitter,
           jitter >= jitterAlertThresholdMilliseconds {
            raiseAlert(
                category: .pingThreshold,
                conditionKey: jitterKey,
                deviceID: device.id,
                deviceName: device.displayName,
                location: device.ipAddress,
                detail: String(format: "Jitter %.2f ms (limit %.1f ms)", jitter, jitterAlertThresholdMilliseconds)
            )
        } else {
            resolveAlert(conditionKey: jitterKey)
        }
    }

    private func evaluateTemperatureAlerts(for device: MonitoredDevice) {
        let switchKey = alertKey(.overTemperature, deviceID: device.id, suffix: "switch")
        if let temperature = device.switchTelemetry.temperatureCelsius,
           temperature >= switchTemperatureAlertThresholdCelsius {
            raiseAlert(
                category: .overTemperature,
                conditionKey: switchKey,
                deviceID: device.id,
                deviceName: device.displayName,
                location: device.ipAddress,
                detail: String(format: "%.0f°C", temperature)
            )
        } else {
            resolveAlert(conditionKey: switchKey)
        }

        var currentSFPKeys = Set<String>()
        for port in device.switchTelemetry.fibrePorts {
            let sfpKey = alertKey(.overTemperature, deviceID: device.id, suffix: "sfp-\(port.port)")
            currentSFPKeys.insert(sfpKey)

            if let temperature = port.temperatureCelsius,
               temperature >= sfpTemperatureAlertThresholdCelsius {
                raiseAlert(
                    category: .overTemperature,
                    conditionKey: sfpKey,
                    deviceID: device.id,
                    deviceName: device.displayName,
                    location: "SFP P\(port.port)",
                    detail: String(format: "SFP %.0f°C", temperature)
                )
            } else {
                resolveAlert(conditionKey: sfpKey)
            }
        }

        let sfpPrefix = alertKey(.overTemperature, deviceID: device.id, suffix: "sfp-")
        for alert in alertEvents where alert.conditionKey.hasPrefix(sfpPrefix) && !currentSFPKeys.contains(alert.conditionKey) {
            resolveAlert(conditionKey: alert.conditionKey)
        }
    }

    private func evaluateFibreAlerts(from results: [FibreLossResult]) {
        var activeFibreKeys = Set<String>()

        for result in results {
            guard !result.isMissing else { continue }

            let lossValues = [result.lossAToB, result.lossBToA].compactMap { $0 }
            let worstLoss = lossValues.max()
            let hasNoSignal = result.status == .noSignal
            let hasBadLoss = worstLoss.map { $0 >= fibreLossAlertThresholdDb } ?? false

            guard hasNoSignal || hasBadLoss else { continue }

            let conditionKey = alertKey(.fibreLoss, deviceID: result.connection.aDeviceID, suffix: result.connection.id.uuidString)
            activeFibreKeys.insert(conditionKey)

            let detail: String
            if hasNoSignal {
                detail = "No Link"
            } else if let worstLoss {
                detail = String(format: "%.1f dB", worstLoss)
            } else {
                detail = "Loss"
            }

            raiseAlert(
                category: .fibreLoss,
                conditionKey: conditionKey,
                deviceID: result.connection.aDeviceID,
                deviceName: result.displayName,
                location: "P\(result.connection.aPort) ↔ P\(result.connection.bPort)",
                detail: detail
            )
        }

        let currentFibreKeys = alertEvents
            .filter { $0.category == .fibreLoss && $0.kind == .alert && $0.isCurrent }
            .map { $0.conditionKey }

        for conditionKey in currentFibreKeys where !activeFibreKeys.contains(conditionKey) {
            resolveAlert(conditionKey: conditionKey)
        }
    }

    private func raiseAlert(
        category: MpingAlertCategory,
        conditionKey: String,
        deviceID: UUID?,
        deviceName: String,
        location: String,
        detail: String
    ) {
        let now = Date()

        // Alert rows are now event snapshots. Once a condition creates a row,
        // its original time/detail/location are preserved for review until the
        // user acknowledges it. Repeated polling of the same still-active
        // condition does not rewrite the row or create a storm of duplicates.
        if let index = alertEvents.firstIndex(where: { $0.conditionKey == conditionKey && $0.kind == .alert && $0.isCurrent }) {
            alertEvents[index].lastUpdatedAt = now
            return
        }

        alertEvents.append(
            MpingAlertEvent(
                category: category,
                conditionKey: conditionKey,
                deviceID: deviceID,
                deviceName: deviceName,
                location: location,
                detail: detail,
                firstTriggeredAt: now,
                lastUpdatedAt: now,
                isCurrent: true,
                isAcknowledged: false,
                kind: .alert
            )
        )

        // Intentionally uncapped: alert history is allowed to grow for debugging/event review.
    }

    private func shouldKeepAlertAcknowledged(category: MpingAlertCategory, wasResolved: Bool, now: Date) -> Bool {
        if wasResolved { return false }
        guard let acknowledgeCutoff = alertAcknowledgeCutoffs[category] else { return false }
        return now <= acknowledgeCutoff
    }

    private func resolveAlert(conditionKey: String) {
        let now = Date()
        var recoveryEvents: [MpingAlertEvent] = []

        for index in alertEvents.indices where alertEvents[index].conditionKey == conditionKey && alertEvents[index].kind == .alert && alertEvents[index].isCurrent {
            let resolvedAlert = alertEvents[index]
            alertEvents[index].isCurrent = false
            alertEvents[index].lastUpdatedAt = now

            recoveryEvents.append(
                MpingAlertEvent(
                    category: resolvedAlert.category,
                    conditionKey: "\(resolvedAlert.conditionKey)|recovery|\(now.timeIntervalSince1970)",
                    deviceID: resolvedAlert.deviceID,
                    deviceName: resolvedAlert.deviceName,
                    location: resolvedAlert.location,
                    detail: "Recovered",
                    firstTriggeredAt: now,
                    lastUpdatedAt: now,
                    isCurrent: false,
                    isAcknowledged: true,
                    kind: .recovery
                )
            )
        }

        if !recoveryEvents.isEmpty {
            alertEvents.append(contentsOf: recoveryEvents)
        }
    }

    private func alertKey(_ category: MpingAlertCategory, deviceID: UUID?, suffix: String = "") -> String {
        "\(category.rawValue)|\(deviceID?.uuidString ?? "global")|\(suffix)"
    }

    private func trimAlertHistoryIfNeeded() {
        // Alert history is intentionally uncapped.
        // This function is retained as a no-op to keep the alerting code easy to cap again later
        // if a bounded production history or per-workspace retention policy is added.
    }

    private func markDevicesAsPinging(ids: [UUID], checkedAt: Date) {
        let idSet = Set(ids)
        guard !idSet.isEmpty else { return }

        var updatedDevices = devices
        var changed = false

        for index in updatedDevices.indices where idSet.contains(updatedDevices[index].id) {
            updatedDevices[index].isPinging = true
            updatedDevices[index].pingPulseID += 1
            updatedDevices[index].lastChecked = checkedAt
            changed = true
        }

        if changed {
            devices = updatedDevices
        }
    }

    private func updateDeviceRuntime(id: UUID, update: (inout MonitoredDevice) -> Void) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        update(&devices[index])
    }


    func snapped(_ value: CGFloat) -> CGFloat {
        guard snapToGridEnabled, snapGridSize > 0 else { return value }
        return (value / snapGridSize).rounded() * snapGridSize
    }

    func snappedSize(width: CGFloat, height: CGFloat) -> CGSize {
        CGSize(
            width: max(80, snapped(width)),
            height: max(60, snapped(height))
        )
    }

    func copySelection() {
        copiedDevices = devices.filter { selectedDeviceIDs.contains($0.id) }
        copiedShapes = shapes.filter { selectedShapeIDs.contains($0.id) }
    }

    func pasteSelection(offset: CGFloat = 40) {
        guard !copiedDevices.isEmpty || !copiedShapes.isEmpty else { return }

        clearSelection()

        var newDeviceIDs = Set<UUID>()
        var newShapeIDs = Set<UUID>()

        for original in copiedDevices {
            var copy = original
            copy.id = UUID()
            copy.name = uniqueDeviceName(base: original.name)
            copy.x = Double(snapped(CGFloat(original.x) + offset))
            copy.y = Double(snapped(CGFloat(original.y) + offset))
            copy.status = .unknown
            copy.resetPingStatistics()
            copy.lastChecked = nil
            copy.isPinging = false
            copy.pingPulseID = 0
            devices.append(copy)
            newDeviceIDs.insert(copy.id)
        }

        for original in copiedShapes {
            var copy = original
            copy.id = UUID()
            copy.x = Double(snapped(CGFloat(original.x) + offset))
            copy.y = Double(snapped(CGFloat(original.y) + offset))
            copy.width = Double(snappedSize(width: CGFloat(original.width), height: CGFloat(original.height)).width)
            copy.height = Double(snappedSize(width: CGFloat(original.width), height: CGFloat(original.height)).height)
            shapes.append(copy)
            newShapeIDs.insert(copy.id)
        }

        selectedDeviceIDs = newDeviceIDs
        selectedShapeIDs = newShapeIDs
        selectedDeviceID = newDeviceIDs.first
        selectedShapeID = newShapeIDs.first
        markWorkspaceDirty()
    }


    func deleteSelection() {
        guard hasSelection else { return }

        let removedDeviceIDs = selectedDeviceIDs
        devices.removeAll { removedDeviceIDs.contains($0.id) }
        for id in removedDeviceIDs {
            temperatureHistoryByDeviceID[id] = nil
        }

        shapes.removeAll { selectedShapeIDs.contains($0.id) }

        selectedDeviceIDs.removeAll()
        selectedShapeIDs.removeAll()
        selectedDeviceID = nil
        selectedShapeID = nil

        markWorkspaceDirty()
    }

    func cutSelection() {
        guard hasSelection else { return }
        copySelection()
        deleteSelection()
    }

    func updateDeviceName(id: UUID, name: String) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[index].name = name
        markWorkspaceDirty()
    }

    func updateDeviceNameSource(id: UUID, source: DeviceNameSource) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[index].nameSource = source
        markWorkspaceDirty()
    }

    func updateDeviceDiscoveredName(id: UUID, discoveredName: String?) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        let cleaned = discoveredName?.trimmingCharacters(in: .whitespacesAndNewlines)
        devices[index].discoveredName = cleaned?.isEmpty == true ? nil : cleaned
        markWorkspaceDirty()
    }

    func updateDeviceIPAddress(id: UUID, ipAddress: String) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[index].ipAddress = ipAddress
        markWorkspaceDirty()
    }

    private func uniqueDeviceName(base: String) -> String {
        let plainBase = base.hasSuffix(" copy") ? String(base.dropLast(5)) : base
        var candidate = "\(plainBase) copy"
        var index = 2

        while devices.contains(where: { $0.name == candidate }) {
            candidate = "\(plainBase) copy \(index)"
            index += 1
        }

        return candidate
    }

    func addDevice() {
        devices.append(MonitoredDevice(name: "New Device", ipAddress: "192.168.1.100", x: 300, y: 260))
        if let id = devices.last?.id {
            selectOnlyDevice(id)
        }
        markWorkspaceDirty()
    }

    func deleteSelectedDevice() {
        guard let id = selectedDeviceID else { return }
        devices.removeAll { $0.id == id }
        temperatureHistoryByDeviceID[id] = nil
        selectedDeviceIDs.remove(id)
        selectedDeviceID = selectedDeviceIDs.first
        markWorkspaceDirty()
    }

    func moveDevice(id: UUID, x: Double, y: Double) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[index].x = Double(snapped(CGFloat(x)))
        devices[index].y = Double(snapped(CGFloat(y)))
        markWorkspaceDirty()
    }

    func moveSelectedDevices(anchorID: UUID, startPositions: [UUID: CGPoint], translation: CGSize, scale: Double) {
        let ids = selectedDeviceIDs.contains(anchorID) ? selectedDeviceIDs : [anchorID]

        // Drag gestures are attached inside the scaled workspace content, so SwiftUI already
        // reports translation in workspace-local coordinates. Do not divide by zoom here,
        // otherwise dragged items lag behind the cursor when zoomed in and outrun it when zoomed out.
        let dx = translation.width
        let dy = translation.height

        for id in ids {
            guard let start = startPositions[id] else { continue }
            moveDevice(id: id, x: start.x + dx, y: start.y + dy)
        }
    }

    func updateDevice(id: UUID, name: String, ipAddress: String) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[index].name = name
        devices[index].ipAddress = ipAddress
        markWorkspaceDirty()
    }

    func updateDeviceInterface(id: UUID, interfaceID: String) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }

        if interfaceID == "AUTO" {
            devices[index].sourceInterfaceName = nil
            devices[index].sourceIPAddress = nil
        } else if let nic = networkInterfaces.first(where: { $0.id == interfaceID }) {
            devices[index].sourceInterfaceName = nic.bsdName
            devices[index].sourceIPAddress = nic.ipv4Address
        }

        markWorkspaceDirty()
        restartMonitoring()
    }

    func updateDeviceType(id: UUID, type: MonitoredDeviceType) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[index].deviceType = type
        if type == .netgearSwitch {
            if devices[index].webInterfacePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                devices[index].webInterfacePath = MonitoredDevice.defaultNetgearWebInterfacePath
            }
            if devices[index].webInterfacePrefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                devices[index].webInterfacePrefix = "https://"
            }
        }
        markWorkspaceDirty()
        startSNMPMonitoring()
    }

    func updateDeviceSNMPCommunity(id: UUID, community: String) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        let cleaned = community.trimmingCharacters(in: .whitespacesAndNewlines)
        devices[index].snmpCommunity = cleaned.isEmpty ? "public" : cleaned
        markWorkspaceDirty()
        startSNMPMonitoring()
    }

    func updateDeviceWebInterfacePath(id: UUID, path: String) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[index].webInterfacePath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        markWorkspaceDirty()
    }

    func openWebInterface(for id: UUID) {
        guard let device = devices.first(where: { $0.id == id }) else { return }
        openWebInterface(for: device)
    }

    func openWebInterface(for device: MonitoredDevice) {
        let ip = device.ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty else { return }

        let rawPrefix = device.webInterfacePrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = rawPrefix.isEmpty ? "https://" : rawPrefix
        let credentials = "" // Auto-login disabled — credentials not embedded in URL
        let suffix = device.effectiveWebInterfacePath
        let normalisedSuffix: String
        if suffix.isEmpty {
            normalisedSuffix = ""
        } else if suffix.hasPrefix(":") || suffix.hasPrefix("/") {
            normalisedSuffix = suffix
        } else {
            normalisedSuffix = "/" + suffix
        }

        let target = "\(prefix)\(credentials)\(ip)\(normalisedSuffix)"
        ConsoleOutputStore.log(subsystem: "WebUI", direction: .info, deviceID: device.id, deviceLabel: device.displayName, ipAddress: ip, message: "Opening web interface: \(target)")
        guard let url = URL(string: target) else {
            ConsoleOutputStore.log(subsystem: "WebUI", direction: .error, deviceID: device.id, deviceLabel: device.displayName, ipAddress: ip, message: "Invalid URL — could not parse: \(target)")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSWorkspace.shared.open(url)
        }
    }

    func updateDeviceWebInterfacePrefix(id: UUID, prefix: String) {
        updateDeviceRuntime(id: id) { device in
            device.webInterfacePrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        markWorkspaceDirty()
    }

    func addShape() {
        shapes.append(WorkspaceShape(title: "Location", x: 160, y: 150, width: 420, height: 240))
        if let id = shapes.last?.id {
            selectOnlyShape(id)
        }
        markWorkspaceDirty()
    }

    func deleteSelectedShape() {
        guard let id = selectedShapeID else { return }
        shapes.removeAll { $0.id == id }
        selectedShapeIDs.remove(id)
        selectedShapeID = selectedShapeIDs.first
        markWorkspaceDirty()
    }

    func moveShape(id: UUID, x: Double, y: Double) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        shapes[index].x = Double(snapped(CGFloat(x)))
        shapes[index].y = Double(snapped(CGFloat(y)))
        markWorkspaceDirty()
    }

    func moveSelectedShapes(anchorID: UUID, startPositions: [UUID: CGPoint], translation: CGSize, scale: Double) {
        let ids = selectedShapeIDs.contains(anchorID) ? selectedShapeIDs : [anchorID]

        // Drag gestures are attached inside the scaled workspace content, so SwiftUI already
        // reports translation in workspace-local coordinates. Do not divide by zoom here.
        let dx = translation.width
        let dy = translation.height

        for id in ids {
            guard let start = startPositions[id] else { continue }
            moveShape(id: id, x: start.x + dx, y: start.y + dy)
        }
    }

    func moveSelectedItems(deviceStartPositions: [UUID: CGPoint], shapeStartPositions: [UUID: CGPoint], translation: CGSize, scale: Double) {
        // Drag gestures are attached inside the scaled workspace content, so SwiftUI already
        // reports translation in workspace-local coordinates. Do not divide by zoom here.
        let dx = translation.width
        let dy = translation.height

        for id in selectedDeviceIDs {
            guard let start = deviceStartPositions[id] else { continue }
            moveDevice(id: id, x: start.x + dx, y: start.y + dy)
        }

        for id in selectedShapeIDs {
            guard let start = shapeStartPositions[id] else { continue }
            moveShape(id: id, x: start.x + dx, y: start.y + dy)
        }
    }

    func resizeShape(id: UUID, width: Double, height: Double) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        let size = snappedSize(width: CGFloat(width), height: CGFloat(height))
        shapes[index].width = Double(size.width)
        shapes[index].height = Double(size.height)
        markWorkspaceDirty()
    }

    func resizeShape(
        id: UUID,
        anchor: ShapeResizeAnchor,
        startFrame: CGRect,
        translation: CGSize,
        scale: Double
    ) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }

        // Resize gestures are attached inside the scaled workspace content, so SwiftUI already
        // reports translation in workspace-local coordinates. Do not divide by zoom here.
        let dx = translation.width
        let dy = translation.height

        var x = startFrame.origin.x
        var y = startFrame.origin.y
        var width = startFrame.width
        var height = startFrame.height

        switch anchor {
        case .topLeft:
            x += dx
            y += dy
            width -= dx
            height -= dy
        case .top:
            y += dy
            height -= dy
        case .topRight:
            y += dy
            width += dx
            height -= dy
        case .right:
            width += dx
        case .bottomRight:
            width += dx
            height += dy
        case .bottom:
            height += dy
        case .bottomLeft:
            x += dx
            width -= dx
            height += dy
        case .left:
            x += dx
            width -= dx
        }

        if width < 80 {
            if anchor.movesLeftEdge { x -= (80 - width) }
            width = 80
        }

        if height < 60 {
            if anchor.movesTopEdge { y -= (60 - height) }
            height = 60
        }

        let snappedSize = snappedSize(width: width, height: height)
        shapes[index].x = Double(snapped(x))
        shapes[index].y = Double(snapped(y))
        shapes[index].width = Double(snappedSize.width)
        shapes[index].height = Double(snappedSize.height)
        markWorkspaceDirty()
    }

    func updateShape(id: UUID, title: String) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        shapes[index].title = title
        markWorkspaceDirty()
    }

    func selectOnlyDevice(_ id: UUID) {
        selectedDeviceIDs = [id]
        selectedShapeIDs.removeAll()
        selectedDeviceID = id
        selectedShapeID = nil
    }

    func selectOnlyShape(_ id: UUID) {
        selectedShapeIDs = [id]
        selectedDeviceIDs.removeAll()
        selectedShapeID = id
        selectedDeviceID = nil
    }

    func toggleDeviceSelection(_ id: UUID) {
        selectedShapeID = nil

        if selectedDeviceIDs.contains(id) {
            selectedDeviceIDs.remove(id)
        } else {
            selectedDeviceIDs.insert(id)
        }

        selectedDeviceID = selectedDeviceIDs.first
    }

    func toggleShapeSelection(_ id: UUID) {
        selectedDeviceID = nil

        if selectedShapeIDs.contains(id) {
            selectedShapeIDs.remove(id)
        } else {
            selectedShapeIDs.insert(id)
        }

        selectedShapeID = selectedShapeIDs.first
    }

    func setSelection(deviceIDs: Set<UUID>, shapeIDs: Set<UUID>) {
        selectedDeviceIDs = deviceIDs
        selectedShapeIDs = shapeIDs
        selectedDeviceID = deviceIDs.first
        selectedShapeID = shapeIDs.first
    }

    func clearSelection() {
        selectedDeviceID = nil
        selectedShapeID = nil
        selectedDeviceIDs.removeAll()
        selectedShapeIDs.removeAll()
    }

    func zoomWorkspace(by delta: Double) {
        guard delta != 0 else { return }
        let step = 0.01
        let direction = delta > 0 ? 1.0 : -1.0
        workspaceScale = min(3.5, max(0.25, workspaceScale + (step * direction)))
    }

    func zoomWorkspace(by delta: Double, around viewportPoint: CGPoint) {
        guard delta != 0 else { return }
        let oldScale = workspaceScale
        let step = 0.01
        let direction = delta > 0 ? 1.0 : -1.0
        let newScale = min(3.5, max(0.25, oldScale + (step * direction)))
        guard newScale != oldScale else { return }

        let worldX = (viewportPoint.x - workspaceOffset.width) / oldScale
        let worldY = (viewportPoint.y - workspaceOffset.height) / oldScale

        workspaceScale = newScale
        workspaceOffset.width = viewportPoint.x - (worldX * newScale)
        workspaceOffset.height = viewportPoint.y - (worldY * newScale)
    }

    func panWorkspace(by translation: CGSize) {
        workspaceOffset.width += translation.width
        workspaceOffset.height += translation.height
    }

    func viewportPointToWorld(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x - workspaceOffset.width) / max(0.25, workspaceScale),
            y: (point.y - workspaceOffset.height) / max(0.25, workspaceScale)
        )
    }

    private struct PersistedWorkspace: Codable {
        var version: Int
        var name: String
        var devices: [MonitoredDevice]
        var shapes: [WorkspaceShape]
        var pingInterval: Double
        var snapToGridEnabled: Bool
        var snapGridSize: Double
        var workspaceScale: Double
        var workspaceOffsetWidth: Double
        var workspaceOffsetHeight: Double
        var pingAlertThresholdMilliseconds: Double
        var switchTemperatureAlertThresholdCelsius: Double
        var sfpTemperatureAlertThresholdCelsius: Double
        var fibreLossAlertThresholdDb: Double
        var fibreBoxStyle: PersistedFibreBoxStyle
        var fibreLabelOffsets: [String: PersistedFibreLabelOffset]

        init(
            version: Int = 1,
            name: String,
            devices: [MonitoredDevice],
            shapes: [WorkspaceShape],
            pingInterval: Double,
            snapToGridEnabled: Bool,
            snapGridSize: Double,
            workspaceScale: Double,
            workspaceOffsetWidth: Double,
            workspaceOffsetHeight: Double,
            pingAlertThresholdMilliseconds: Double = 100.0,
            switchTemperatureAlertThresholdCelsius: Double = 70.0,
            sfpTemperatureAlertThresholdCelsius: Double = 75.0,
            fibreLossAlertThresholdDb: Double = 4.0,
            fibreBoxStyle: PersistedFibreBoxStyle = PersistedFibreBoxStyle(),
            fibreLabelOffsets: [String: PersistedFibreLabelOffset] = [:]
        ) {
            self.version = version
            self.name = name
            self.devices = devices
            self.shapes = shapes
            self.pingInterval = pingInterval
            self.snapToGridEnabled = snapToGridEnabled
            self.snapGridSize = snapGridSize
            self.workspaceScale = workspaceScale
            self.workspaceOffsetWidth = workspaceOffsetWidth
            self.workspaceOffsetHeight = workspaceOffsetHeight
            self.pingAlertThresholdMilliseconds = pingAlertThresholdMilliseconds
            self.switchTemperatureAlertThresholdCelsius = switchTemperatureAlertThresholdCelsius
            self.sfpTemperatureAlertThresholdCelsius = sfpTemperatureAlertThresholdCelsius
            self.fibreLossAlertThresholdDb = fibreLossAlertThresholdDb
            self.fibreBoxStyle = fibreBoxStyle
            self.fibreLabelOffsets = fibreLabelOffsets
        }

        enum CodingKeys: String, CodingKey {
            case version
            case name
            case devices
            case shapes
            case pingInterval
            case snapToGridEnabled
            case snapGridSize
            case workspaceScale
            case workspaceOffsetWidth
            case workspaceOffsetHeight
            case pingAlertThresholdMilliseconds
            case switchTemperatureAlertThresholdCelsius
            case sfpTemperatureAlertThresholdCelsius
            case fibreLossAlertThresholdDb
            case fibreBoxStyle
            case fibreLabelOffsets
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
            name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Workspace"
            devices = try c.decodeIfPresent([MonitoredDevice].self, forKey: .devices) ?? []
            shapes = try c.decodeIfPresent([WorkspaceShape].self, forKey: .shapes) ?? []
            pingInterval = try c.decodeIfPresent(Double.self, forKey: .pingInterval) ?? 2.0
            snapToGridEnabled = try c.decodeIfPresent(Bool.self, forKey: .snapToGridEnabled) ?? false
            snapGridSize = try c.decodeIfPresent(Double.self, forKey: .snapGridSize) ?? 40
            workspaceScale = try c.decodeIfPresent(Double.self, forKey: .workspaceScale) ?? 1.0
            workspaceOffsetWidth = try c.decodeIfPresent(Double.self, forKey: .workspaceOffsetWidth) ?? 0
            workspaceOffsetHeight = try c.decodeIfPresent(Double.self, forKey: .workspaceOffsetHeight) ?? 0
            pingAlertThresholdMilliseconds = try c.decodeIfPresent(Double.self, forKey: .pingAlertThresholdMilliseconds) ?? DeviceStore.persistedAlertThreshold(key: DeviceStore.pingAlertThresholdKey, defaultValue: 100.0)
            switchTemperatureAlertThresholdCelsius = try c.decodeIfPresent(Double.self, forKey: .switchTemperatureAlertThresholdCelsius) ?? DeviceStore.persistedAlertThreshold(key: DeviceStore.switchTemperatureAlertThresholdKey, defaultValue: 70.0)
            sfpTemperatureAlertThresholdCelsius = try c.decodeIfPresent(Double.self, forKey: .sfpTemperatureAlertThresholdCelsius) ?? DeviceStore.persistedAlertThreshold(key: DeviceStore.sfpTemperatureAlertThresholdKey, defaultValue: 75.0)
            fibreLossAlertThresholdDb = try c.decodeIfPresent(Double.self, forKey: .fibreLossAlertThresholdDb) ?? DeviceStore.persistedAlertThreshold(key: DeviceStore.fibreLossAlertThresholdKey, defaultValue: 4.0)
            fibreBoxStyle = try c.decodeIfPresent(PersistedFibreBoxStyle.self, forKey: .fibreBoxStyle) ?? PersistedFibreBoxStyle()
            fibreLabelOffsets = try c.decodeIfPresent([String: PersistedFibreLabelOffset].self, forKey: .fibreLabelOffsets) ?? [:]
        }
    }

    struct PersistedFibreLabelOffset: Codable, Equatable {
        var width: Double
        var height: Double
    }

    private struct PersistedFibreBoxStyle: Codable, Equatable {
        var textSize: Double
        var textBold: Bool
        var lineSpacing: Double
        var horizontalPadding: Double
        var verticalPadding: Double
        var minimumWidth: Double
        var cornerRadius: Double
        var borderWidth: Double
        var opacity: Double

        nonisolated init(
            textSize: Double = 10.0,
            textBold: Bool = true,
            lineSpacing: Double = 1.0,
            horizontalPadding: Double = 10.0,
            verticalPadding: Double = 5.0,
            minimumWidth: Double = 62.0,
            cornerRadius: Double = 7.0,
            borderWidth: Double = 1.0,
            opacity: Double = 0.5
        ) {
            self.textSize = textSize
            self.textBold = textBold
            self.lineSpacing = lineSpacing
            self.horizontalPadding = horizontalPadding
            self.verticalPadding = verticalPadding
            self.minimumWidth = minimumWidth
            self.cornerRadius = cornerRadius
            self.borderWidth = borderWidth
            self.opacity = opacity
        }

        @MainActor
        init(settings: FibreBoxEditorSettings) {
            self.init(
                textSize: Double(settings.textSize),
                textBold: settings.textBold,
                lineSpacing: Double(settings.lineSpacing),
                horizontalPadding: Double(settings.horizontalPadding),
                verticalPadding: Double(settings.verticalPadding),
                minimumWidth: Double(settings.minimumWidth),
                cornerRadius: Double(settings.cornerRadius),
                borderWidth: Double(settings.borderWidth),
                opacity: Double(settings.opacity)
            )
        }

        func apply(to settings: FibreBoxEditorSettings) {
            settings.textSize = CGFloat(textSize)
            settings.textBold = textBold
            settings.lineSpacing = CGFloat(lineSpacing)
            settings.horizontalPadding = CGFloat(horizontalPadding)
            settings.verticalPadding = CGFloat(verticalPadding)
            settings.minimumWidth = CGFloat(minimumWidth)
            settings.cornerRadius = CGFloat(cornerRadius)
            settings.borderWidth = CGFloat(borderWidth)
            settings.opacity = CGFloat(opacity)
        }
    }

    private struct PersistedWorkingState: Codable {
        var version: Int
        var workspace: PersistedWorkspace
        var currentWorkspacePath: String?
        var currentWorkspaceName: String
        var hasUnsavedChanges: Bool

        init(
            version: Int = 1,
            workspace: PersistedWorkspace,
            currentWorkspacePath: String?,
            currentWorkspaceName: String,
            hasUnsavedChanges: Bool
        ) {
            self.version = version
            self.workspace = workspace
            self.currentWorkspacePath = currentWorkspacePath
            self.currentWorkspaceName = currentWorkspaceName
            self.hasUnsavedChanges = hasUnsavedChanges
        }
    }

    private func markWorkspaceDirty() {
        guard !isApplyingWorkspace else { return }

        // Normal edits create an undo checkpoint immediately.
        // Drag-style edits are wrapped in an undo transaction so a long drag only
        // creates one undo step: the position before the drag started.
        if undoTransactionDepth == 0 {
            recordUndoCheckpointIfNeeded()
        }

        hasUnsavedChanges = true
        saveWorkingState()
    }

    func beginUndoTransaction() {
        guard !isApplyingWorkspace else { return }

        if undoTransactionDepth == 0 {
            let current = makePersistedWorkspace(named: currentWorkspaceName)
            undoTransactionStartWorkspace = current
            undoTransactionStartData = encodedWorkspaceData(current)
        }

        undoTransactionDepth += 1
    }

    func endUndoTransaction() {
        guard undoTransactionDepth > 0 else { return }

        undoTransactionDepth -= 1
        guard undoTransactionDepth == 0 else { return }

        defer {
            undoTransactionStartWorkspace = nil
            undoTransactionStartData = nil
        }

        let current = makePersistedWorkspace(named: currentWorkspaceName)
        guard let currentData = encodedWorkspaceData(current) else { return }

        guard currentData != undoTransactionStartData else {
            undoBaselineData = currentData
            return
        }

        if let start = undoTransactionStartWorkspace {
            undoStack.append(start)
            if undoStack.count > maximumUndoSnapshots {
                undoStack.removeFirst(undoStack.count - maximumUndoSnapshots)
            }
        }

        redoStack.removeAll()
        undoBaselineData = currentData
    }

    func cancelUndoTransaction() {
        undoTransactionDepth = 0
        undoTransactionStartWorkspace = nil
        undoTransactionStartData = nil
        setUndoBaselineToCurrentWorkspace()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }

        let current = makePersistedWorkspace(named: currentWorkspaceName)
        redoStack.append(current)

        applyWorkspaceSnapshotForHistory(previous)
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }

        let current = makePersistedWorkspace(named: currentWorkspaceName)
        undoStack.append(current)

        applyWorkspaceSnapshotForHistory(next)
    }

    private func recordUndoCheckpointIfNeeded() {
        let current = makePersistedWorkspace(named: currentWorkspaceName)
        guard let currentData = encodedWorkspaceData(current) else { return }

        if undoBaselineData == nil {
            undoBaselineData = currentData
            return
        }

        guard currentData != undoBaselineData else { return }

        if let previous = undoBaselineWorkspace() {
            undoStack.append(previous)
            if undoStack.count > maximumUndoSnapshots {
                undoStack.removeFirst(undoStack.count - maximumUndoSnapshots)
            }
        }

        redoStack.removeAll()
        undoBaselineData = currentData
    }

    private func undoBaselineWorkspace() -> PersistedWorkspace? {
        guard let data = undoBaselineData else { return nil }
        return try? JSONDecoder().decode(PersistedWorkspace.self, from: data)
    }

    private func resetUndoHistoryToCurrentWorkspace() {
        undoStack.removeAll()
        redoStack.removeAll()
        undoBaselineData = encodedWorkspaceData(makePersistedWorkspace(named: currentWorkspaceName))
    }

    private func setUndoBaselineToCurrentWorkspace() {
        undoBaselineData = encodedWorkspaceData(makePersistedWorkspace(named: currentWorkspaceName))
    }

    private func encodedWorkspaceData(_ workspace: PersistedWorkspace) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(workspace)
    }

    private func applyWorkspaceSnapshotForHistory(_ workspace: PersistedWorkspace) {
        let wasMonitoringEnabled = monitoringEnabled
        stopMonitoring()
        stopSNMPMonitoring()

        isApplyingWorkspace = true
        applyPersistedWorkspace(workspace)
        isApplyingWorkspace = false

        hasUnsavedChanges = true
        setUndoBaselineToCurrentWorkspace()
        saveWorkingState()

        if wasMonitoringEnabled {
            startMonitoring()
            startSNMPMonitoring()
        }
    }

    func save() {
        guard let destination = currentWorkspaceURL else {
            saveWorkspaceAs()
            return
        }

        writeWorkspace(to: destination)
        rememberWorkspaceURL(destination)
        saveWorkingState()
    }

    func saveWorkspaceAs() {
        let panel = NSSavePanel()
        panel.title = "Save Mping Workspace"
        panel.nameFieldStringValue = currentWorkspaceName.hasSuffix(".mpw") ? currentWorkspaceName : "\(currentWorkspaceName).mpw"
        panel.allowedContentTypes = [.mpingWorkspace, .mpingLegacyWorkspace, .json]
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            let finalURL = url.pathExtension.isEmpty ? url.appendingPathExtension("mpw") : url
            writeWorkspace(to: finalURL)
            rememberWorkspaceURL(finalURL)
            saveWorkingState()
        }
    }

    func openWorkspace() {
        let panel = NSOpenPanel()
        panel.title = "Open Mping Workspace"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mpingWorkspace, .mpingLegacyWorkspace, .json]

        if panel.runModal() == .OK, let url = panel.url {
            loadWorkspace(from: url)
        }
    }

    func newWorkspace() {
        stopMonitoring()
        stopSNMPMonitoring()
        devices = []
        shapes = []
        clearSelection()
        workspaceScale = 1.0
        workspaceOffset = .zero
        currentWorkspaceURL = nil
        currentWorkspaceName = "Untitled Workspace"
        hasUnsavedChanges = true
        resetUndoHistoryToCurrentWorkspace()
        saveWorkingState()
        if monitoringEnabled {
            startMonitoring()
            startSNMPMonitoring()
        }
    }

    private func loadStartupWorkspace() {
        if loadWorkingState() {
            return
        }

        if let lastURL = restoredLastWorkspaceURL(), FileManager.default.fileExists(atPath: lastURL.path) {
            loadWorkspace(from: lastURL)
            return
        }

        if FileManager.default.fileExists(atPath: defaultWorkspaceURL.path) {
            loadWorkspace(from: defaultWorkspaceURL)
            return
        }

        if FileManager.default.fileExists(atPath: legacySaveURL.path) {
            loadWorkspace(from: legacySaveURL, rememberAs: defaultWorkspaceURL)
            return
        }

        createStarterWorkspace()
        hasUnsavedChanges = true
        resetUndoHistoryToCurrentWorkspace()
        saveWorkingState()
    }

    private func loadWorkspace(from url: URL, rememberAs overrideURL: URL? = nil) {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url),
              let workspace = try? JSONDecoder().decode(PersistedWorkspace.self, from: data) else {
            return
        }

        stopMonitoring()
        stopSNMPMonitoring()

        isApplyingWorkspace = true
        defer { isApplyingWorkspace = false }

        applyPersistedWorkspace(workspace)

        let rememberedURL = overrideURL ?? url
        currentWorkspaceURL = rememberedURL
        currentWorkspaceName = displayName(for: rememberedURL)
        rememberWorkspaceURL(rememberedURL)
        hasUnsavedChanges = false

        if overrideURL != nil {
            writeWorkspace(to: rememberedURL)
        }

        resetUndoHistoryToCurrentWorkspace()
        saveWorkingState()

        if monitoringEnabled {
            startMonitoring()
            startSNMPMonitoring()
        }
    }

    private func createStarterWorkspace() {
        devices = [
            MonitoredDevice(name: "Example Device", ipAddress: "192.168.1.10", x: 260, y: 220),
            MonitoredDevice(name: "Example Switch", ipAddress: "192.168.1.1", x: 480, y: 220, deviceType: .netgearSwitch)
        ]
        shapes = [
            WorkspaceShape(title: "Example Area", x: 140, y: 110, width: 560, height: 300)
        ]
        workspaceScale = 1.0
        workspaceOffset = .zero
        currentWorkspaceURL = nil
        currentWorkspaceName = "Untitled Workspace"
    }

    private func makePersistedWorkspace(named name: String) -> PersistedWorkspace {
        PersistedWorkspace(
            name: name,
            devices: devices.map(cleanDeviceForPersistence),
            shapes: shapes,
            pingInterval: pingInterval,
            snapToGridEnabled: snapToGridEnabled,
            snapGridSize: Double(snapGridSize),
            workspaceScale: workspaceScale,
            workspaceOffsetWidth: workspaceOffset.width,
            workspaceOffsetHeight: workspaceOffset.height,
            pingAlertThresholdMilliseconds: pingAlertThresholdMilliseconds,
            switchTemperatureAlertThresholdCelsius: switchTemperatureAlertThresholdCelsius,
            sfpTemperatureAlertThresholdCelsius: sfpTemperatureAlertThresholdCelsius,
            fibreLossAlertThresholdDb: fibreLossAlertThresholdDb,
            fibreBoxStyle: PersistedFibreBoxStyle(settings: FibreBoxEditorSettings.shared),
            fibreLabelOffsets: fibreLabelOffsets
        )
    }

    private func applyPersistedWorkspace(_ workspace: PersistedWorkspace) {
        devices = workspace.devices.map(cleanDeviceForRuntime)
        shapes = workspace.shapes
        pingInterval = min(10.0, max(0.5, workspace.pingInterval))
        snapToGridEnabled = workspace.snapToGridEnabled
        snapGridSize = CGFloat(max(20, workspace.snapGridSize))
        workspaceScale = min(3.5, max(0.25, workspace.workspaceScale))
        workspaceOffset = CGSize(width: workspace.workspaceOffsetWidth, height: workspace.workspaceOffsetHeight)
        pingAlertThresholdMilliseconds = workspace.pingAlertThresholdMilliseconds
        switchTemperatureAlertThresholdCelsius = workspace.switchTemperatureAlertThresholdCelsius
        sfpTemperatureAlertThresholdCelsius = workspace.sfpTemperatureAlertThresholdCelsius
        fibreLossAlertThresholdDb = workspace.fibreLossAlertThresholdDb
        fibreLabelOffsets = workspace.fibreLabelOffsets
        workspace.fibreBoxStyle.apply(to: FibreBoxEditorSettings.shared)
        clearSelection()
        refreshCachedFibreResults()
    }

    private func saveWorkingState() {
        let state = PersistedWorkingState(
            workspace: makePersistedWorkspace(named: currentWorkspaceName),
            currentWorkspacePath: currentWorkspaceURL?.path,
            currentWorkspaceName: currentWorkspaceName,
            hasUnsavedChanges: hasUnsavedChanges
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: workingStateURL, options: [.atomic])
    }

    private func loadWorkingState() -> Bool {
        guard let data = try? Data(contentsOf: workingStateURL),
              let state = try? JSONDecoder().decode(PersistedWorkingState.self, from: data) else {
            return false
        }

        stopMonitoring()
        stopSNMPMonitoring()

        isApplyingWorkspace = true
        applyPersistedWorkspace(state.workspace)
        isApplyingWorkspace = false

        if let path = state.currentWorkspacePath, !path.isEmpty {
            currentWorkspaceURL = URL(fileURLWithPath: path)
        } else {
            currentWorkspaceURL = nil
        }

        currentWorkspaceName = state.currentWorkspaceName
        hasUnsavedChanges = state.hasUnsavedChanges

        if let currentWorkspaceURL {
            rememberWorkspaceURL(currentWorkspaceURL)
        }

        resetUndoHistoryToCurrentWorkspace()

        if monitoringEnabled {
            startMonitoring()
            startSNMPMonitoring()
        }

        return true
    }

    private func writeWorkspace(to url: URL) {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }

        let workspace = makePersistedWorkspace(named: displayName(for: url))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(workspace) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: [.atomic])

        currentWorkspaceURL = url
        currentWorkspaceName = displayName(for: url)
        hasUnsavedChanges = false
        setUndoBaselineToCurrentWorkspace()
    }

    private func rememberWorkspaceURL(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: lastWorkspacePathKey)

        if let bookmark = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(bookmark, forKey: lastWorkspaceBookmarkKey)
        }
    }

    private func restoredLastWorkspaceURL() -> URL? {
        if let bookmark = UserDefaults.standard.data(forKey: lastWorkspaceBookmarkKey) {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale) {
                if stale { rememberWorkspaceURL(url) }
                _ = url.startAccessingSecurityScopedResource()
                return url
            }
        }

        if let lastPath = UserDefaults.standard.string(forKey: lastWorkspacePathKey) {
            return URL(fileURLWithPath: lastPath)
        }

        return nil
    }

    private func displayName(for url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }

    private func cleanDeviceForPersistence(_ device: MonitoredDevice) -> MonitoredDevice {
        MonitoredDevice(
            id: device.id,
            name: device.name,
            nameSource: device.nameSource,
            discoveredName: device.discoveredName,
            ipAddress: device.ipAddress,
            x: device.x,
            y: device.y,
            status: .unknown,
            lastRTT: nil,
            pingRTTHistory: [],
            lastChecked: nil,
            lastSeenOnline: nil,
            isPinging: false,
            pingPulseID: 0,
            sourceInterfaceName: device.sourceInterfaceName,
            sourceIPAddress: device.sourceIPAddress,
            deviceType: device.deviceType,
            snmpCommunity: device.snmpCommunity,
            webInterfacePrefix: device.webInterfacePrefix,
            webInterfacePath: device.webInterfacePath,
            switchTelemetry: SwitchTelemetry(),
            pingLossHistory: [],
            currentOnlineSince: nil,
            macAddress: device.macAddress,
            zoneName: device.zoneName,
            pingMonitoringEnabled: device.pingMonitoringEnabled,
            snmpMonitoringEnabled: device.snmpMonitoringEnabled
        )
    }

    private func cleanDeviceForRuntime(_ device: MonitoredDevice) -> MonitoredDevice {
        cleanDeviceForPersistence(device)
    }
}

private enum NetworkInterfaceProvider {
    static func ipv4Interfaces() -> [NetworkInterfaceInfo] {
        var pointer: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&pointer) == 0, let first = pointer else {
            return []
        }

        defer {
            freeifaddrs(pointer)
        }

        var interfaces: [NetworkInterfaceInfo] = []
        var current: UnsafeMutablePointer<ifaddrs>? = first

        while let item = current {
            let interface = item.pointee
            current = interface.ifa_next

            guard let address = interface.ifa_addr else { continue }
            guard address.pointee.sa_family == UInt8(AF_INET) else { continue }

            let flags = Int32(interface.ifa_flags)
            guard (flags & IFF_UP) != 0 else { continue }
            guard (flags & IFF_LOOPBACK) == 0 else { continue }

            let name = String(cString: interface.ifa_name)

            var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                address,
                socklen_t(address.pointee.sa_len),
                &hostBuffer,
                socklen_t(hostBuffer.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            guard result == 0 else { continue }

            let ip = String(cString: hostBuffer)
            guard !ip.isEmpty else { continue }

            let nic = NetworkInterfaceInfo(
                bsdName: name,
                displayName: friendlyName(for: name),
                ipv4Address: ip
            )

            if !interfaces.contains(nic) {
                interfaces.append(nic)
            }
        }

        return interfaces.sorted {
            if $0.bsdName == $1.bsdName {
                return $0.ipv4Address < $1.ipv4Address
            }

            return $0.bsdName.localizedStandardCompare($1.bsdName) == .orderedAscending
        }
    }

    private static func friendlyName(for bsdName: String) -> String {
        switch bsdName {
        case "en0":
            return "Primary"
        case "en1":
            return "Secondary"
        case "bridge0":
            return "Bridge"
        case "awdl0":
            return "AWDL"
        case "llw0":
            return "Low Latency Wi-Fi"
        default:
            return "Interface"
        }
    }
}


private extension UTType {
    static var mpingWorkspace: UTType {
        UTType(filenameExtension: "mpw") ?? .json
    }

    static var mpingLegacyWorkspace: UTType {
        UTType(filenameExtension: "mpingworkspace") ?? .json
    }
}
