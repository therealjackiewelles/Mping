import SwiftUI

struct InspectorView: View {
    @ObservedObject var store: DeviceStore

    var body: some View {
        Group {
            if store.selectedItemCount > 1 {
                MultiSelectionInspector(store: store)
                    .frame(width: 280)
                    .background(
                        ZStack {
                            Color(red: 0.075, green: 0.075, blue: 0.085)
                            PanelInteractionBlocker(id: "inspector")
                        }
                    )
            } else if let id = store.selectedDeviceID,
                      let device = store.devices.first(where: { $0.id == id }) {
                DeviceInspector(store: store, device: device)
                    .id(device.id)
                    .frame(width: 280)
                    .background(
                        ZStack {
                            Color(red: 0.075, green: 0.075, blue: 0.085)
                            PanelInteractionBlocker(id: "inspector")
                        }
                    )
            } else if let id = store.selectedShapeID,
                      let shape = store.shapes.first(where: { $0.id == id }) {
                ShapeInspector(store: store, shape: shape)
                    .id(shape.id)
                    .frame(width: 280)
                    .background(
                        ZStack {
                            Color(red: 0.075, green: 0.075, blue: 0.085)
                            PanelInteractionBlocker(id: "inspector")
                        }
                    )
            }
        }
    }
}

private struct MultiSelectionInspector: View {
    @ObservedObject var store: DeviceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Selection")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("\(store.selectedItemCount) items selected")
                .foregroundStyle(.white.opacity(0.75))

            Text("\(store.selectedDeviceIDs.count) devices")
                .foregroundStyle(.white.opacity(0.6))

            Text("\(store.selectedShapeIDs.count) boxes")
                .foregroundStyle(.white.opacity(0.6))

            Button("Clear Selection") {
                store.clearSelection()
            }

            Spacer()
        }
        .padding(18)
    }
}

private enum DeviceInspectorField: Hashable {
    case name
    case ipAddress
    case snmpCommunity
}

private struct DeviceInspector: View {
    @ObservedObject var store: DeviceStore
    let device: MonitoredDevice

    @State private var name: String = ""
    @State private var selectedNameSource: DeviceNameSource = .manual
    @State private var ip: String = ""
    @State private var selectedInterfaceID: String = "AUTO"
    @State private var selectedDeviceType: MonitoredDeviceType = .pingOnly
    @State private var snmpCommunity: String = "public"
    @FocusState private var focusedField: DeviceInspectorField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Device")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Name")
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer()

                        Toggle("Use SNMP/LLDP", isOn: Binding(
                            get: { selectedNameSource == .automatic },
                            set: { useAutomaticName in
                                commitDeviceTextFields()
                                let newSource: DeviceNameSource = useAutomaticName ? .automatic : .manual
                                selectedNameSource = newSource
                                store.updateDeviceNameSource(id: device.id, source: newSource)
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                    }

                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .name)
                        .disabled(selectedNameSource == .automatic)
                        .opacity(selectedNameSource == .automatic ? 0.48 : 1.0)
                        .onSubmit {
                            commitDeviceTextFields()
                        }

                    if selectedNameSource == .automatic {
                        Text("Automatic naming will use the discovered SNMP/LLDP name when available. Manual name is kept as a fallback.")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("IP Address").foregroundStyle(.white.opacity(0.7))
                    TextField("IP Address", text: $ip)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .ipAddress)
                        .onSubmit {
                            commitDeviceTextFields()
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Type")
                        .foregroundStyle(.white.opacity(0.7))

                    Picker("Device Type", selection: $selectedDeviceType) {
                        ForEach(MonitoredDeviceType.allCases, id: \.self) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedDeviceType) { _, newValue in
                        guard newValue != device.deviceType else { return }
                        store.updateDeviceType(id: device.id, type: newValue)
                    }
                }

                if selectedDeviceType == .netgearSwitch {
                    switchSection
                    temperatureHistorySection
                    fibreLossSection
                }

                nicSection

                Text("Text changes apply when you press Return or click away.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
                    .fixedSize(horizontal: false, vertical: true)

                Button("Delete Device", role: .destructive) {
                    commitDeviceTextFields()
                    store.deleteSelectedDevice()
                }

                Divider()

                pingStatusSection

                if let lastChecked = device.lastChecked {
                    Text("Last checked: \(lastChecked.formatted(date: .omitted, time: .standard))")
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer(minLength: 12)
            }
            .padding(18)
        }
        .onAppear {
            syncFromDevice()
            store.refreshNetworkInterfaces()
        }
        .onDisappear {
            commitDeviceTextFields()
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


    private var pingStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ping")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Text("Status")
                    .foregroundStyle(.white.opacity(0.62))

                Spacer()

                Text(device.status.label)
                    .foregroundStyle(.white.opacity(0.86))
            }

            HStack(spacing: 8) {
                pingStatCard(title: "Current", value: formattedPingValue(device.lastRTT))
                pingStatCard(title: "Min", value: formattedPingValue(device.minimumRTT))
                pingStatCard(title: "Avg", value: formattedPingValue(device.averageRTT))
                pingStatCard(title: "Max", value: formattedPingValue(device.maximumRTT))
            }

            Text("Statistics are calculated from the current rolling ping history.")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.38))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.045))
        )
    }

    private func pingStatCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.46))
                .lineLimit(1)

            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var switchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Switch SNMP")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 6) {
                Text("Community")
                    .foregroundStyle(.white.opacity(0.7))

                TextField("public", text: $snmpCommunity)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .snmpCommunity)
                    .onSubmit {
                        commitDeviceTextFields()
                    }
            }

            HStack {
                Text(device.temperatureDisplayText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(temperatureColor)

                Spacer()
            }

            if let status = device.switchTelemetry.snmpStatusText {
                Text(status)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }

            if let last = device.switchTelemetry.lastSNMPChecked {
                Text("SNMP checked: \(last.formatted(date: .omitted, time: .standard))")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Text("This creates the SNMP layer we can reuse for fibre DDM later.")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.38))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.045))
        )
    }

    private var temperatureHistorySection: some View {
        let history = store.temperatureHistory(for: device.id)
        let latestSamples = Array(history.suffix(8).reversed())
        let values = history.map(\.temperatureCelsius)
        let minTemp = values.min()
        let maxTemp = values.max()
        let avgTemp = values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Temperature History")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(history.count) samples")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))
            }

            HStack(spacing: 8) {
                temperatureStatCard(title: "Current", value: formatTemperature(device.switchTelemetry.temperatureCelsius))
                temperatureStatCard(title: "Min", value: formatTemperature(minTemp))
                temperatureStatCard(title: "Avg", value: formatTemperature(avgTemp))
                temperatureStatCard(title: "Max", value: formatTemperature(maxTemp))
            }

            if latestSamples.isEmpty {
                Text("Temperature history will appear after SNMP polling records samples.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 4) {
                    ForEach(latestSamples) { sample in
                        HStack {
                            Text(sample.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.45))

                            Spacer()

                            Text(formatTemperature(sample.temperatureCelsius))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(temperatureHistoryColor(sample.temperatureCelsius))
                                .monospacedDigit()
                        }
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

    private func temperatureStatCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.46))
                .lineLimit(1)

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        return String(format: "%.1f°C", temperature)
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

    private var nicSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ping NIC").foregroundStyle(.white.opacity(0.7))

                Spacer()

                Button("Refresh") {
                    store.refreshNetworkInterfaces()
                    syncInterfaceSelection()
                }
                .font(.caption)
            }

            Picker("Ping NIC", selection: $selectedInterfaceID) {
                Text("Auto Routing").tag("AUTO")

                ForEach(store.networkInterfaces) { nic in
                    Text(nic.pickerTitle).tag(nic.id)
                }
            }
            .labelsHidden()
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

            Text("Current: \(device.nicDisplayText)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
        }
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
        snmpCommunity = device.snmpCommunity
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
        let finalCommunity = snmpCommunity.trimmingCharacters(in: .whitespacesAndNewlines)

        if finalName != device.name || finalIP != device.ipAddress {
            store.updateDevice(id: device.id, name: finalName, ipAddress: finalIP)
            name = finalName
            ip = finalIP
        }

        let cleanedCommunity = finalCommunity.isEmpty ? "public" : finalCommunity
        if cleanedCommunity != device.snmpCommunity {
            store.updateDeviceSNMPCommunity(id: device.id, community: cleanedCommunity)
            snmpCommunity = cleanedCommunity
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
