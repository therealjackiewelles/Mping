import SwiftUI

struct InspectorView: View {
    @ObservedObject var store: DeviceStore

    @State private var lastDeviceID: UUID? = nil
    @State private var lastShapeID: UUID? = nil

    private var displayDevice: MonitoredDevice? {
        let id = store.selectedDeviceID ?? lastDeviceID
        return id.flatMap { id in store.devices.first { $0.id == id } }
    }

    private var displayShape: WorkspaceShape? {
        let id = store.selectedShapeID ?? lastShapeID
        return id.flatMap { id in store.shapes.first { $0.id == id } }
    }

    var body: some View {
        ZStack {
            Color(red: 0.075, green: 0.075, blue: 0.085)
            PanelInteractionBlocker(id: "inspector")

            if store.selectedItemCount > 1 {
                MultiSelectionInspector(store: store)
            } else if let device = displayDevice {
                DeviceInspector(store: store, device: device)
            } else if let shape = displayShape {
                ShapeInspector(store: store, shape: shape)
            }
        }
        .onChange(of: store.selectedDeviceID) { _, id in
            if let id { lastDeviceID = id; lastShapeID = nil }
        }
        .onChange(of: store.selectedShapeID) { _, id in
            if let id { lastShapeID = id; lastDeviceID = nil }
        }
    }
}

private struct MultiSelectionInspector: View {
    @ObservedObject var store: DeviceStore

    @State private var zoneField: String = ""
    @State private var zoneFieldDirty: Bool = false
    @State private var snmpField: String = ""
    @State private var snmpFieldDirty: Bool = false
    @State private var deviceTypeSelection: MonitoredDeviceType? = nil
    @State private var pingMonitoringSelection: Bool? = nil
    @State private var snmpMonitoringSelection: Bool? = nil
    @State private var applied: Bool = false

    private var selectedDevices: [MonitoredDevice] {
        store.selectedDeviceIDs.compactMap { id in store.devices.first { $0.id == id } }
    }

    private var hasNetgearInSelection: Bool {
        selectedDevices.contains { $0.deviceType == .netgearSwitch }
    }

    private var sharedZoneName: String? {
        let zones = Set(selectedDevices.map { $0.zoneName ?? "" })
        return zones.count == 1 ? zones.first : nil
    }

    private var anyFieldDirty: Bool {
        zoneFieldDirty || snmpFieldDirty || deviceTypeSelection != nil
        || pingMonitoringSelection != nil || snmpMonitoringSelection != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Group Edit")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("\(store.selectedDeviceIDs.count) devices selected\(store.selectedShapeIDs.isEmpty ? "" : ", \(store.selectedShapeIDs.count) boxes")")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Divider()

                Text("Only fields you edit will be applied. Empty fields are ignored.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Zone")
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        if let shared = sharedZoneName {
                            Text(shared.isEmpty ? "None" : shared)
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.white.opacity(0.35))
                        } else {
                            Text("Mixed")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                    TextField("Type to set zone on all selected…", text: $zoneField)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: zoneField) { _, _ in zoneFieldDirty = true }
                    if zoneFieldDirty {
                        Text(zoneField.isEmpty ? "Will clear zone on all selected devices." : "Will set zone to \"\(zoneField)\" on all selected devices.")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(zoneField.isEmpty ? .orange : .green)
                    }
                }

                if hasNetgearInSelection {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SNMP Community")
                            .foregroundStyle(.white.opacity(0.7))
                        TextField("Type to set community on all selected…", text: $snmpField)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: snmpField) { _, _ in snmpFieldDirty = true }
                        if snmpFieldDirty && !snmpField.isEmpty {
                            Text("Will set SNMP community to \"\(snmpField)\" on all selected Netgear switches.")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.green)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ping Monitoring")
                        .foregroundStyle(.white.opacity(0.7))
                    Picker("Ping Monitoring", selection: $pingMonitoringSelection) {
                        Text("No change").tag(Bool?.none)
                        Text("Enabled").tag(Bool?.some(true))
                        Text("Disabled").tag(Bool?.some(false))
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    if let v = pingMonitoringSelection {
                        Text("Will \(v ? "enable" : "disable") ping monitoring on all selected devices.")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(v ? .green : .orange)
                    }
                }

                if selectedDevices.contains(where: { $0.deviceType == .netgearSwitch }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SNMP / LLDP")
                            .foregroundStyle(.white.opacity(0.7))
                        Picker("SNMP Monitoring", selection: $snmpMonitoringSelection) {
                            Text("No change").tag(Bool?.none)
                            Text("Enabled").tag(Bool?.some(true))
                            Text("Disabled").tag(Bool?.some(false))
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        if let v = snmpMonitoringSelection {
                            Text("Will \(v ? "enable" : "disable") SNMP/LLDP on all selected Netgear switches.")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(v ? .green : .orange)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Device Type")
                        .foregroundStyle(.white.opacity(0.7))
                    Picker("Device Type", selection: Binding(
                        get: { deviceTypeSelection },
                        set: { deviceTypeSelection = $0 }
                    )) {
                        Text("No change").tag(MonitoredDeviceType?.none)
                        ForEach(MonitoredDeviceType.allCases, id: \.self) { type in
                            Text(type.label).tag(MonitoredDeviceType?.some(type))
                        }
                    }
                    .labelsHidden()
                    if deviceTypeSelection != nil {
                        Text("Will set device type on all selected devices.")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 10) {
                    Button("Apply") {
                        var edit = DeviceStore.BulkDeviceEdit()
                        if zoneFieldDirty { edit.zoneName = zoneField }
                        if snmpFieldDirty && !snmpField.isEmpty { edit.snmpCommunity = snmpField }
                        edit.deviceType = deviceTypeSelection
                        edit.pingMonitoringEnabled = pingMonitoringSelection
                        edit.snmpMonitoringEnabled = snmpMonitoringSelection
                        store.bulkUpdateDevices(ids: store.selectedDeviceIDs, edit: edit)
                        applied = true
                        resetFields()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!anyFieldDirty)

                    if applied {
                        Text("Applied")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }

                Divider()

                Button("Clear Selection") {
                    store.clearSelection()
                }
                .foregroundStyle(.white.opacity(0.6))

                Spacer(minLength: 12)
            }
            .padding(18)
        }
        .onChange(of: store.selectedDeviceIDs) { _, _ in
            resetFields()
        }
    }

    private func resetFields() {
        zoneField = ""
        zoneFieldDirty = false
        snmpField = ""
        snmpFieldDirty = false
        deviceTypeSelection = nil
        pingMonitoringSelection = nil
        snmpMonitoringSelection = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { applied = false }
    }
}

private enum DeviceInspectorField: Hashable {
    case name
    case ipAddress
}

private struct DeviceInspector: View {
    @ObservedObject var store: DeviceStore
    let device: MonitoredDevice

    @State private var name: String = ""
    @State private var selectedNameSource: DeviceNameSource = .manual
    @State private var ip: String = ""
    @State private var selectedInterfaceID: String = "AUTO"
    @State private var selectedDeviceType: MonitoredDeviceType = .pingOnly
    @State private var zoneName: String = ""
    @State private var showDeleteConfirmation: Bool = false
    @FocusState private var focusedField: DeviceInspectorField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Device")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                monitoringControlsSection

                // Name
                compactCard {
                    HStack(spacing: 6) {
                        Text("NAME")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.46))
                            .textCase(.uppercase)
                        Spacer()
                        Toggle("SNMP/LLDP", isOn: Binding(
                            get: { selectedNameSource == .automatic },
                            set: { useAutomatic in
                                commitDeviceTextFields()
                                let src: DeviceNameSource = useAutomatic ? .automatic : .manual
                                selectedNameSource = src
                                store.updateDeviceNameSource(id: device.id, source: src)
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                    }
                    TextField("Name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(selectedNameSource == .automatic ? .white.opacity(0.45) : .white.opacity(0.92))
                        .focused($focusedField, equals: .name)
                        .disabled(selectedNameSource == .automatic)
                        .onSubmit { commitDeviceTextFields() }
                }

                // IP + Device Type
                HStack(spacing: 8) {
                    compactCard {
                        Text("IP ADDRESS")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.46))
                        TextField("IP", text: $ip)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                            .focused($focusedField, equals: .ipAddress)
                            .onSubmit { commitDeviceTextFields() }
                    }

                    compactCard {
                        Text("TYPE")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.46))
                        Picker("", selection: $selectedDeviceType) {
                            ForEach(MonitoredDeviceType.allCases, id: \.self) { type in
                                Text(type.label).tag(type)
                            }
                        }
                        .labelsHidden()
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .onChange(of: selectedDeviceType) { _, newValue in
                            guard newValue != device.deviceType else { return }
                            store.updateDeviceType(id: device.id, type: newValue)
                        }
                    }
                }

                if selectedDeviceType == .netgearSwitch {
                    temperatureHistorySection
                    fibreLossSection
                }

                // Zone
                compactCard {
                    Text("ZONE")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.46))
                    TextField("Optional", text: $zoneName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .onSubmit { commitZoneName() }
                }

                // NIC
                compactCard {
                    HStack(spacing: 6) {
                        Text("PING NIC")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.46))
                        Spacer()
                        Button("Refresh") {
                            store.refreshNetworkInterfaces()
                            syncInterfaceSelection()
                        }
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.40))
                        .buttonStyle(.plain)
                    }
                    Picker("", selection: $selectedInterfaceID) {
                        Text("Auto Routing").tag("AUTO")
                        ForEach(store.networkInterfaces) { nic in
                            Text(nic.pickerTitle).tag(nic.id)
                        }
                    }
                    .labelsHidden()
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .onChange(of: selectedInterfaceID) { _, newValue in
                        let currentID: String
                        if let sourceIPAddress = device.sourceIPAddress,
                           let match = store.networkInterfaces.first(where: { $0.ipv4Address == sourceIPAddress }) {
                            currentID = match.id
                        } else {
                            currentID = "AUTO"
                        }
                        guard newValue != currentID else { return }
                        store.updateDeviceInterface(id: device.id, interfaceID: newValue)
                    }
                }

                Divider()

                pingStatusSection

                if let lastChecked = device.lastChecked {
                    Text("Last checked: \(lastChecked.formatted(date: .omitted, time: .standard))")
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer(minLength: 12)

                deleteSection
            }
            .padding(18)
        }
        .onAppear {
            syncFromDevice()
        }
        .onDisappear {
            commitDeviceTextFields()
            commitZoneName()
        }
        .onChange(of: device.id) { _, _ in
            syncFromDevice()
        }
        .onChange(of: device.sourceIPAddress) { _, _ in
            syncInterfaceSelection()
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                commitDeviceTextFields()
            }
        }
    }


    private var monitoringControlsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { device.pingMonitoringEnabled },
                set: { store.updateDevicePingMonitoring(id: device.id, enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ping Monitoring")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                    if !device.pingMonitoringEnabled {
                        Text("Device is excluded from all ping cycles.")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .toggleStyle(.switch)

            if device.deviceType == .netgearSwitch {
                Toggle(isOn: Binding(
                    get: { device.snmpMonitoringEnabled },
                    set: { store.updateDeviceSNMPMonitoring(id: device.id, enabled: $0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SNMP / LLDP")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                        if !device.snmpMonitoringEnabled {
                            Text("Device is excluded from telemetry polling.")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .toggleStyle(.switch)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.045)))
    }

    private var pingStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ping")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(device.status.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusColor)
            }

            if device.pingRTTHistory.count >= 2 {
                PingSparklineView(
                    values: Array(device.pingRTTHistory.suffix(60)),
                    valueFormatter: { String(format: "%.2f ms", $0) }
                )
                .frame(height: 56)
            }

            HStack(spacing: 6) {
                pingStatCard(title: "Min", value: formattedPingValue(device.minimumRTT))
                pingStatCard(title: "Avg", value: formattedPingValue(device.averageRTT))
                pingStatCard(title: "Max", value: formattedPingValue(device.maximumRTT))
            }

            HStack(spacing: 6) {
                pingStatCard(
                    title: "Loss",
                    value: device.packetLossPercent.map { String(format: "%.1f%%", $0) } ?? "—",
                    valueColor: lossColor
                )
                pingStatCard(
                    title: "Jitter",
                    value: device.jitter.map { String(format: "%.2g ms", $0) } ?? "—",
                    valueColor: jitterColor
                )
                pingStatCard(
                    title: "Uptime",
                    value: device.uptimeDuration.map { formattedUptime($0) } ?? "—"
                )
                pingStatCard(
                    title: "Samples",
                    value: "\(device.pingLossHistory.count)"
                )
            }

        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.045))
        )
    }

    private var statusColor: Color {
        switch device.status {
        case .healthy: return .green
        case .slow:    return .yellow
        case .offline: return .red
        case .unknown: return .gray
        }
    }

    private var lossColor: Color {
        guard let loss = device.packetLossPercent else { return .white.opacity(0.88) }
        if loss >= 10 { return .red }
        if loss >= 2  { return .orange }
        return .green
    }

    private var jitterColor: Color {
        guard let jitter = device.jitter else { return .white.opacity(0.88) }
        let threshold = store.jitterAlertThresholdMilliseconds
        if jitter >= threshold        { return .red }
        if jitter >= threshold * 0.70 { return .orange }
        return .green
    }

    private func formattedUptime(_ interval: TimeInterval) -> String {
        let s = Int(interval)
        if s < 60   { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m \(s % 60)s" }
        return "\(s / 3600)h \(s % 3600 / 60)m"
    }

    private func pingStatCard(title: String, value: String, valueColor: Color = .white.opacity(0.88)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.46))
                .lineLimit(1)

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func formattedPingValue(_ value: Double?) -> String {
        guard device.status != .offline else { return "—" }
        guard let value else { return "—" }

        if value < 10 {
            return String(format: "%.1f ms", value)
        }

        return "\(Int(value.rounded())) ms"
    }

    private var temperatureHistorySection: some View {
        let history = store.temperatureHistory(for: device.id)
        let allValues = history.map(\.temperatureCelsius)
        let windowSamples = Array(history.suffix(20))
        let windowValues = windowSamples.map(\.temperatureCelsius)
        let windowTimestamps = windowSamples.map(\.timestamp)
        let minTemp = allValues.min()
        let maxTemp = allValues.max()
        let avgTemp = allValues.isEmpty ? nil : allValues.reduce(0, +) / Double(allValues.count)
        let currentTemp = device.switchTelemetry.temperatureCelsius

        let graphColor: Color = {
            guard let t = maxTemp else { return .green }
            if t >= 70 { return .red }
            if t >= 55 { return .orange }
            return .green
        }()

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Temperature")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(currentTemp.map { String(format: "%.1f°C", $0) } ?? "—")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(temperatureColor)
            }

            if windowValues.count >= 2 {
                PingSparklineView(
                    values: windowValues,
                    lineColor: graphColor,
                    valueFormatter: { String(format: "%.0f°C", $0) },
                    timestamps: windowTimestamps
                )
                .frame(height: 56)
            }

            HStack(spacing: 6) {
                pingStatCard(title: "Min", value: formatTemperature(minTemp))
                pingStatCard(title: "Avg", value: formatTemperature(avgTemp))
                pingStatCard(title: "Max", value: formatTemperature(maxTemp))
            }

            if windowValues.isEmpty {
                Text("Temperature history will appear after SNMP polling records samples.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.045))
        )
    }

    private var fibreLossSection: some View {
        let results = store.fibreResults(for: device.id)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Fibre Loss")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(results.count) links")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))
            }

            if results.isEmpty {
                Text("No fibre links are currently matched for this device.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 6) {
                    ForEach(results) { result in
                        fibreLossRow(result)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.045))
        )
    }

    private func fibreLossRow(_ result: FibreLossResult) -> some View {
        let isAEndpoint = result.connection.aDeviceID == device.id
        let localPort = isAEndpoint ? result.connection.aPort : result.connection.bPort
        let remoteDeviceName = isAEndpoint ? result.bDeviceName : result.aDeviceName
        let remotePort = isAEndpoint ? result.connection.bPort : result.connection.aPort
        let incomingLoss = isAEndpoint ? result.lossBToA : result.lossAToB
        let outgoingLoss = isAEndpoint ? result.lossAToB : result.lossBToA
        let localTemperature = isAEndpoint ? result.aTemperatureCelsius : result.bTemperatureCelsius

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("P\(localPort) ↔ \(remoteDeviceName) P\(remotePort)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 8)

                Text(formatTemperature(localTemperature))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(temperatureHistoryColor(localTemperature))
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                fibreLossPill(title: "IN", value: formatLoss(incomingLoss), loss: incomingLoss)
                fibreLossPill(title: "OUT", value: formatLoss(outgoingLoss), loss: outgoingLoss)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(result.status.swiftUIColor.opacity(0.26), lineWidth: 1)
        )
    }


    private func fibreLossPill(title: String, value: String, loss: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(fibreLossColor(loss))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func formatTemperature(_ temperature: Double?) -> String {
        guard let temperature, temperature.isFinite else { return "—" }
        return String(format: "%.2g°C", temperature)
    }

    private func formatLoss(_ loss: Double?) -> String {
        guard let loss, loss.isFinite else { return "—" }
        return String(format: "-%.1f dB", abs(loss))
    }

    private func temperatureHistoryColor(_ temperature: Double?) -> Color {
        guard let temperature else { return .white.opacity(0.46) }
        if temperature >= 70 { return .red }
        if temperature >= 55 { return .orange }
        return .green
    }

    private func fibreLossColor(_ loss: Double?) -> Color {
        guard let loss else { return .white.opacity(0.46) }
        if loss >= store.fibreLossAlertThresholdDb { return .red }
        if loss >= store.fibreLossAlertThresholdDb * 0.75 { return .orange }
        return .green
    }

    private var deleteSection: some View {
        VStack(spacing: 0) {
            if showDeleteConfirmation {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.red.opacity(0.85))
                        Text("Delete \(device.displayName.isEmpty ? "this device" : device.displayName)?")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Text("This cannot be undone. All monitoring data for this device will be lost.")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.50))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Button("Cancel") {
                            withAnimation(.easeOut(duration: 0.15)) {
                                showDeleteConfirmation = false
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.10), lineWidth: 1))

                        Button("Delete") {
                            commitDeviceTextFields()
                            store.deleteSelectedDevice()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.90), lineWidth: 1))
                    }
                }
                .padding(12)
                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.25), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        showDeleteConfirmation = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                        Text("Delete Device")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.red.opacity(0.70))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: showDeleteConfirmation)
        .onChange(of: device.id) { _, _ in showDeleteConfirmation = false }
    }

    @ViewBuilder
    private func compactCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func commitZoneName() {
        let trimmed = zoneName.trimmingCharacters(in: .whitespacesAndNewlines)
        let newZone: String? = trimmed.isEmpty ? nil : trimmed
        guard newZone != device.zoneName else { return }
        store.updateDeviceZoneName(id: device.id, zoneName: newZone)
    }

    private var temperatureColor: Color {
        guard let temp = device.switchTelemetry.temperatureCelsius else { return .gray }
        if temp >= 70 { return .red }
        if temp >= 55 { return .orange }
        return .green
    }

    private func syncFromDevice() {
        name = device.name
        selectedNameSource = device.nameSource
        ip = device.ipAddress
        selectedDeviceType = device.deviceType
        zoneName = device.zoneName ?? ""
        syncInterfaceSelection()
    }

    private func syncInterfaceSelection() {
        if let sourceIPAddress = device.sourceIPAddress,
           let match = store.networkInterfaces.first(where: { $0.ipv4Address == sourceIPAddress }) {
            selectedInterfaceID = match.id
        } else {
            selectedInterfaceID = "AUTO"
        }
    }

    private func commitDeviceTextFields() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? device.name : trimmedName
        let finalIP = ip.trimmingCharacters(in: .whitespacesAndNewlines)

        if finalName != device.name || finalIP != device.ipAddress {
            store.updateDevice(id: device.id, name: finalName, ipAddress: finalIP)
            name = finalName
            ip = finalIP
        }
    }
}


private struct PingSparklineView: View {
    let values: [Double]
    var lineColor: Color = .green
    var minLabel: String? = nil
    var maxLabel: String? = nil
    var valueFormatter: ((Double) -> String)? = nil
    var timestamps: [Date]? = nil

    @State private var hoverIndex: Int? = nil

    private static let tooltipTimeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f
    }()

    var body: some View {
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1

        VStack(alignment: .leading, spacing: 2) {
            Text(maxLabel ?? (valueFormatter?(maxV) ?? String(format: "%.1f ms", maxV)))
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.40))

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let range = max(0.1, maxV - minV)
                let count = values.count

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.18))

                    Path { path in
                        for (i, v) in values.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(max(1, count - 1))
                            let y = h - (h * CGFloat((v - minV) / range)) * 0.85 - h * 0.075
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(lineColor.opacity(0.75), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                    if let idx = hoverIndex, idx < count {
                        let x = w * CGFloat(idx) / CGFloat(max(1, count - 1))
                        let y = h - (h * CGFloat((values[idx] - minV) / range)) * 0.85 - h * 0.075

                        Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: h))
                        }
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)

                        Circle()
                            .fill(lineColor)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)

                        let tipX = x > w * 0.6 ? x - 4 : x + 4
                        let tipAlignment: Alignment = x > w * 0.6 ? .trailing : .leading
                        VStack(alignment: x > w * 0.6 ? .trailing : .leading, spacing: 1) {
                            if let ts = timestamps, idx < ts.count {
                                Text(Self.tooltipTimeFormatter.string(from: ts[idx]))
                                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            Text(valueFormatter?(values[idx]) ?? String(format: "%.2f", values[idx]))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(lineColor.opacity(0.5), lineWidth: 1))
                        .position(x: tipX, y: max(24, y - 20))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: tipAlignment)
                    }
                }
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let loc):
                        guard count > 1 else { return }
                        let idx = Int((loc.x / w * CGFloat(count - 1)).rounded())
                        hoverIndex = max(0, min(count - 1, idx))
                    case .ended:
                        hoverIndex = nil
                    }
                }
            }

            Text(minLabel ?? (valueFormatter?(minV) ?? String(format: "%.1f", minV)))
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.40))
        }
    }
}

private enum ShapeInspectorField: Hashable {
    case title
}

private struct ShapeInspector: View {
    @ObservedObject var store: DeviceStore
    let shape: WorkspaceShape

    @State private var title: String = ""
    @State private var width: Double = 0
    @State private var height: Double = 0
    @State private var isSyncingFromShape: Bool = false
    @FocusState private var focusedField: ShapeInspectorField?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location Box")
                .font(.title2.bold())
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 6) {
                Text("Title").foregroundStyle(.white.opacity(0.7))
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .title)
                    .onSubmit {
                        commitShapeTitle()
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Width").foregroundStyle(.white.opacity(0.7))
                Slider(
                    value: $width,
                    in: 80...1200,
                    onEditingChanged: { editing in
                        editing ? store.beginUndoTransaction() : store.endUndoTransaction()
                    }
                )
                Text("\(Int(width)) px").foregroundStyle(.white.opacity(0.55))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Height").foregroundStyle(.white.opacity(0.7))
                Slider(
                    value: $height,
                    in: 60...900,
                    onEditingChanged: { editing in
                        editing ? store.beginUndoTransaction() : store.endUndoTransaction()
                    }
                )
                Text("\(Int(height)) px").foregroundStyle(.white.opacity(0.55))
            }

            Text("Text changes apply when you press Return or click away. Size changes apply immediately.")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.38))
                .fixedSize(horizontal: false, vertical: true)

            Button("Delete Box", role: .destructive) {
                commitShapeTitle()
                store.deleteSelectedShape()
            }

            Spacer()
        }
        .padding(18)
        .onAppear {
            syncFromShape()
        }
        .onDisappear {
            commitShapeTitle()
        }
        .onChange(of: shape.id) { _, _ in
            commitShapeTitle()
            syncFromShape()
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                commitShapeTitle()
            }
        }
        .onChange(of: width) { _, newValue in
            guard !isSyncingFromShape else { return }
            guard abs(newValue - shape.width) > 0.5 else { return }
            store.resizeShape(id: shape.id, width: newValue, height: height)
        }
        .onChange(of: height) { _, newValue in
            guard !isSyncingFromShape else { return }
            guard abs(newValue - shape.height) > 0.5 else { return }
            store.resizeShape(id: shape.id, width: width, height: newValue)
        }
    }

    private func syncFromShape() {
        isSyncingFromShape = true
        title = shape.title
        width = shape.width
        height = shape.height
        isSyncingFromShape = false
    }

    private func commitShapeTitle() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? shape.title : trimmedTitle

        guard finalTitle != shape.title else { return }
        store.updateShape(id: shape.id, title: finalTitle)
        title = finalTitle
    }
}
