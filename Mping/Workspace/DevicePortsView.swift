import SwiftUI
import Foundation
import AppKit

// MARK: - Device Ports View

private enum DevicePortsWindowSizing {
    static let outerPaddingAndChrome: CGFloat = 96

    static func width(for totalColumnWidth: CGFloat) -> CGFloat {
        let visibleWidth = NSScreen.main?.visibleFrame.width ?? 1440
        let wanted = totalColumnWidth + outerPaddingAndChrome
        return min(max(wanted, 1200), max(900, visibleWidth * 0.98))
    }

    static var defaultHeight: CGFloat {
        let visibleHeight = NSScreen.main?.visibleFrame.height ?? 900
        return min(max(visibleHeight * 0.80, 720), max(720, visibleHeight * 0.94))
    }

    static func totalColumnWidth(preferences: AppPreferences) -> CGFloat {
        DevicePortsColumn.allCases.reduce(CGFloat(0)) { total, column in
            let saved = preferences.devicePortsColumnWidths[column.rawValue].map { CGFloat($0) }
            return total + max(column.minWidth, saved ?? column.defaultWidth)
        }
    }
}

struct DevicePortsView: View {
    @ObservedObject var store: DeviceStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: AppPreferences
    @State private var selectedDeviceID: UUID?

    private var netgearDevices: [MonitoredDevice] {
        store.devices
            .filter { $0.deviceType == .netgearSwitch }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    private var selectedDevice: MonitoredDevice? {
        guard let selectedDeviceID else { return netgearDevices.first }
        return netgearDevices.first { $0.id == selectedDeviceID } ?? netgearDevices.first
    }

    private var selectedRows: [DevicePortTelemetry] {
        guard let device = selectedDevice else { return [] }
        return device.switchTelemetry.devicePorts.map { port in
            var row = port
            if row.deviceID != device.id {
                row.deviceID = device.id
            }
            return row
        }
        .filter { preferences.devicePortsShowDisconnectedPorts || $0.isUp }
        .sorted { a, b in
            if a.port != b.port { return a.port < b.port }
            return a.displayPort.localizedStandardCompare(b.displayPort) == .orderedAscending
        }
    }

    private var tableRows: [DevicePortsTableRow] {
        selectedRows.map { row in
            DevicePortsTableRow(
                id: row.id,
                deviceName: store.devices.first { $0.id == row.deviceID }?.displayName ?? "Unknown device",
                port: row.displayPort,
                up: row.operStatus ?? "Unknown",
                admin: row.adminStatus ?? "—",
                duplex: row.duplex ?? "—",
                medium: classifyMedium(row.transmissionMedium),
                speed: row.speedText ?? "—",
                lldpDevice: row.lldpRemoteDeviceName ?? "—",
                lldpPort: row.lldpRemotePort ?? "—",
                neighbourMAC: row.lldpRemoteMACAddress ?? "—",
                isUp: row.isUp
            )
        }
    }

    
    private func classifyMedium(_ value: String?) -> String {
        let text = (value ?? "").lowercased()
        if text.contains("sfp") || text.contains("fiber") || text.contains("fibre") || text.contains("1000base-x") || text.contains("10gbase") || text.contains("lr") || text.contains("sr") {
            return "Fibre"
        }
        if text.contains("rj45") || text.contains("copper") || text.contains("1000base-t") || text.contains("ethernet") || text.contains("physical connector") {
            return "Copper"
        }
        return "Unknown"
    }

private var preferredWidth: CGFloat {
        DevicePortsWindowSizing.width(for: DevicePortsWindowSizing.totalColumnWidth(preferences: preferences))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device Ports")
                        .font(.title2.bold())
                    Text("Per-port SNMP and LLDP view. Columns can be resized and reordered by dragging the table headers.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }

            Divider()

            deviceSelector

            Divider()

            portsTable
        }
        .padding(20)
        .frame(minWidth: min(preferredWidth, NSScreen.main?.visibleFrame.width ?? preferredWidth), idealWidth: preferredWidth, minHeight: 700, idealHeight: DevicePortsWindowSizing.defaultHeight)
        .background(DevicePortsWindowResizer(width: preferredWidth, height: DevicePortsWindowSizing.defaultHeight))
        .onAppear {
            if selectedDeviceID == nil,
               let savedID = preferences.devicePortsSelectedDeviceID.flatMap(UUID.init(uuidString:)),
               netgearDevices.contains(where: { $0.id == savedID }) {
                selectedDeviceID = savedID
            }
            if selectedDeviceID == nil {
                selectedDeviceID = netgearDevices.first?.id
            }
        }
        .onChange(of: netgearDevices.map(\.id)) { _, deviceIDs in
            if let selectedDeviceID, deviceIDs.contains(selectedDeviceID) {
                return
            }
            selectedDeviceID = deviceIDs.first
            preferences.devicePortsSelectedDeviceID = deviceIDs.first?.uuidString
        }
    }

    private var deviceSelector: some View {
        HStack(spacing: 12) {
            Text("Device")
                .font(.system(size: 13, weight: .bold, design: .rounded))

            Picker("Device", selection: Binding(
                get: { selectedDeviceID ?? netgearDevices.first?.id },
                set: { newValue in
                    selectedDeviceID = newValue
                    preferences.devicePortsSelectedDeviceID = newValue?.uuidString
                }
            )) {
                if netgearDevices.isEmpty {
                    Text("No Netgear switches found").tag(UUID?.none)
                } else {
                    ForEach(netgearDevices) { device in
                        Text("\(device.displayName) — \(device.ipAddress)")
                            .tag(Optional(device.id))
                    }
                }
            }
            .pickerStyle(.menu)
            .frame(width: 420, alignment: .leading)
            .disabled(netgearDevices.isEmpty)

            if let selectedDevice {
                Text(selectedDevice.ipAddress)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("Show disconnected ports", isOn: $preferences.devicePortsShowDisconnectedPorts)
                .toggleStyle(.checkbox)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
    }

    private var portsTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ports shown: \(selectedRows.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Drag headers to rearrange columns. Drag column dividers to resize.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            DevicePortsTableView(rows: tableRows, preferences: preferences)
                .frame(minHeight: 520)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
    }
}

private struct DevicePortsWindowResizer: NSViewRepresentable {
    let width: CGFloat
    let height: CGFloat

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { resizeWindow(containing: view) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { resizeWindow(containing: nsView) }
    }

    private func resizeWindow(containing view: NSView) {
        guard let window = view.window else { return }
        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let targetWidth = min(width, visibleFrame.width * 0.98)
        let targetHeight = min(height, visibleFrame.height * 0.94)
        let current = window.frame
        guard abs(current.width - targetWidth) > 8 || abs(current.height - targetHeight) > 8 else { return }

        var newFrame = NSRect(
            x: current.midX - targetWidth / 2,
            y: current.midY - targetHeight / 2,
            width: targetWidth,
            height: targetHeight
        )

        if newFrame.minX < visibleFrame.minX { newFrame.origin.x = visibleFrame.minX }
        if newFrame.maxX > visibleFrame.maxX { newFrame.origin.x = visibleFrame.maxX - newFrame.width }
        if newFrame.minY < visibleFrame.minY { newFrame.origin.y = visibleFrame.minY }
        if newFrame.maxY > visibleFrame.maxY { newFrame.origin.y = visibleFrame.maxY - newFrame.height }

        window.setFrame(newFrame, display: true, animate: false)
        window.minSize = NSSize(width: min(targetWidth, 980), height: 700)
    }
}

private struct DevicePortsTableRow: Identifiable, Equatable {
    let id: String
    let deviceName: String
    let port: String
    let up: String
    let admin: String
    let duplex: String
    let medium: String
    let speed: String
    let lldpDevice: String
    let lldpPort: String
    let neighbourMAC: String
    let isUp: Bool
}

private enum DevicePortsColumn: String, CaseIterable {
    case device
    case port
    case up
    case admin
    case duplex
    case medium
    case speed
    case lldpDevice
    case lldpPort
    case neighbourMAC

    var title: String {
        switch self {
        case .device: return "Device"
        case .port: return "Port"
        case .up: return "Up"
        case .admin: return "Admin"
        case .duplex: return "Duplex"
        case .medium: return "Medium"
        case .speed: return "Speed"
        case .lldpDevice: return "LLDP Device"
        case .lldpPort: return "LLDP Port"
        case .neighbourMAC: return "Neighbour MAC"
        }
    }

    var defaultWidth: CGFloat {
        switch self {
        case .device: return 220
        case .port: return 110
        case .up: return 75
        case .admin: return 90
        case .duplex: return 95
        case .medium: return 160
        case .speed: return 95
        case .lldpDevice: return 280
        case .lldpPort: return 260
        case .neighbourMAC: return 180
        }
    }

    var minWidth: CGFloat {
        switch self {
        case .up: return 55
        case .port, .admin, .duplex, .speed: return 70
        default: return 110
        }
    }

    var maxWidth: CGFloat { 520 }

    static var defaultOrder: [String] { allCases.map(\.rawValue) }
    static var defaultTotalWidth: CGFloat { allCases.reduce(CGFloat(0)) { $0 + $1.defaultWidth } }

    func value(from row: DevicePortsTableRow) -> String {
        switch self {
        case .device: return row.deviceName
        case .port: return row.port
        case .up: return row.up
        case .admin: return row.admin
        case .duplex: return row.duplex
        case .medium: return row.medium
        case .speed: return row.speed
        case .lldpDevice: return row.lldpDevice
        case .lldpPort: return row.lldpPort
        case .neighbourMAC: return row.neighbourMAC
        }
    }
}

private struct DevicePortsTableView: NSViewRepresentable {
    let rows: [DevicePortsTableRow]
    @ObservedObject var preferences: AppPreferences

    func makeCoordinator() -> Coordinator {
        Coordinator(preferences: preferences)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsColumnResizing = true
        tableView.allowsColumnReordering = true
        tableView.allowsColumnSelection = false
        tableView.allowsMultipleSelection = false
        tableView.columnAutoresizingStyle = .noColumnAutoresizing
        tableView.rowHeight = 28
        tableView.headerView = NSTableHeaderView()
        tableView.gridStyleMask = [.solidVerticalGridLineMask, .solidHorizontalGridLineMask]
        tableView.style = .fullWidth
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator

        context.coordinator.tableView = tableView
        context.coordinator.rows = rows
        context.coordinator.configureColumns(on: tableView)

        scrollView.documentView = tableView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let tableView = scrollView.documentView as? NSTableView else { return }
        context.coordinator.preferences = preferences
        context.coordinator.rows = rows
        context.coordinator.configureColumns(on: tableView)
        tableView.reloadData()
    }

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var rows: [DevicePortsTableRow] = []
        weak var tableView: NSTableView?
        var preferences: AppPreferences
        private var isConfiguringColumns = false

        init(preferences: AppPreferences) {
            self.preferences = preferences
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            rows.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard row >= 0, row < rows.count,
                  let identifier = tableColumn?.identifier.rawValue,
                  let column = DevicePortsColumn(rawValue: identifier)
            else { return nil }

            let cellID = NSUserInterfaceItemIdentifier("DevicePortsCell")
            let cell = tableView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView ?? NSTableCellView()
            cell.identifier = cellID

            let textField: NSTextField
            if let existing = cell.textField {
                textField = existing
            } else {
                textField = NSTextField(labelWithString: "")
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.lineBreakMode = .byTruncatingTail
                textField.maximumNumberOfLines = 1
                textField.font = NSFont.systemFont(ofSize: column == .neighbourMAC ? 11 : 12, weight: .medium)
                cell.addSubview(textField)
                cell.textField = textField
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
                    textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                ])
            }

            let value = column.value(from: rows[row])
            textField.stringValue = value
            textField.toolTip = value
            textField.font = NSFont.systemFont(ofSize: column == .neighbourMAC ? 11 : 12, weight: .medium)
            textField.textColor = color(for: column, row: rows[row])
            return cell
        }

        func configureColumns(on tableView: NSTableView) {
            isConfiguringColumns = true
            defer { isConfiguringColumns = false }

            let existingIDs = Set(tableView.tableColumns.map { $0.identifier.rawValue })
            for column in DevicePortsColumn.allCases where !existingIDs.contains(column.rawValue) {
                let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(column.rawValue))
                tableColumn.title = column.title
                tableColumn.minWidth = column.minWidth
                tableColumn.maxWidth = column.maxWidth
                tableColumn.resizingMask = .userResizingMask
                tableColumn.width = CGFloat(preferences.devicePortsColumnWidths[column.rawValue] ?? Double(column.defaultWidth))
                tableView.addTableColumn(tableColumn)
            }

            for tableColumn in tableView.tableColumns {
                guard let column = DevicePortsColumn(rawValue: tableColumn.identifier.rawValue) else { continue }
                tableColumn.title = column.title
                tableColumn.minWidth = column.minWidth
                tableColumn.maxWidth = column.maxWidth
                if let savedWidth = preferences.devicePortsColumnWidths[column.rawValue] {
                    tableColumn.width = CGFloat(savedWidth)
                }
            }

            applySavedColumnOrder(to: tableView)
            autosizeColumnsIfNeeded(on: tableView)
            fitTableFrameToColumns(tableView)
        }

        private func fitTableFrameToColumns(_ tableView: NSTableView) {
            let totalWidth = tableView.tableColumns.reduce(CGFloat(0)) { $0 + $1.width }
            var frame = tableView.frame
            frame.size.width = max(totalWidth, tableView.enclosingScrollView?.contentSize.width ?? totalWidth)
            tableView.frame = frame
        }

        private func applySavedColumnOrder(to tableView: NSTableView) {
            let savedOrder = preferences.devicePortsColumnOrder
            let wantedOrder = validColumnOrder(from: savedOrder.isEmpty ? DevicePortsColumn.defaultOrder : savedOrder)
            for targetIndex in wantedOrder.indices {
                let id = wantedOrder[targetIndex]
                guard let currentIndex = tableView.tableColumns.firstIndex(where: { $0.identifier.rawValue == id }), currentIndex != targetIndex else { continue }
                tableView.moveColumn(currentIndex, toColumn: targetIndex)
            }
        }

        private func validColumnOrder(from rawOrder: [String]) -> [String] {
            var seen = Set<String>()
            var order: [String] = []
            for id in rawOrder where DevicePortsColumn(rawValue: id) != nil && !seen.contains(id) {
                order.append(id)
                seen.insert(id)
            }
            for id in DevicePortsColumn.defaultOrder where !seen.contains(id) {
                order.append(id)
            }
            return order
        }

        private func autosizeColumnsIfNeeded(on tableView: NSTableView) {
            guard preferences.devicePortsColumnWidths.isEmpty else { return }
            let sampleRows = Array(rows.prefix(100))
            for tableColumn in tableView.tableColumns {
                guard let column = DevicePortsColumn(rawValue: tableColumn.identifier.rawValue) else { continue }
                let headerWidth = measuredWidth(column.title, font: NSFont.boldSystemFont(ofSize: 12)) + 28
                let contentWidth = sampleRows.map { measuredWidth(column.value(from: $0), font: NSFont.systemFont(ofSize: 12)) + 28 }.max() ?? column.defaultWidth
                tableColumn.width = min(column.maxWidth, max(column.minWidth, max(column.defaultWidth, headerWidth, contentWidth)))
            }
        }

        private func measuredWidth(_ text: String, font: NSFont) -> CGFloat {
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            return ceil((text as NSString).size(withAttributes: attributes).width)
        }

        private func color(for column: DevicePortsColumn, row: DevicePortsTableRow) -> NSColor {
            if column == .up {
                return row.isUp ? .systemGreen : .systemRed
            }
            if column == .neighbourMAC {
                return .secondaryLabelColor
            }
            return .labelColor
        }

        func tableViewColumnDidResize(_ notification: Notification) {
            guard !isConfiguringColumns,
                  let tableView = notification.object as? NSTableView
            else { return }
            saveColumnWidths(from: tableView)
            fitTableFrameToColumns(tableView)
        }

        func tableViewColumnDidMove(_ notification: Notification) {
            guard !isConfiguringColumns,
                  let tableView = notification.object as? NSTableView
            else { return }
            preferences.devicePortsColumnOrder = tableView.tableColumns.map { $0.identifier.rawValue }
        }

        private func saveColumnWidths(from tableView: NSTableView) {
            var widths = preferences.devicePortsColumnWidths
            for tableColumn in tableView.tableColumns {
                widths[tableColumn.identifier.rawValue] = Double(tableColumn.width)
            }
            preferences.devicePortsColumnWidths = widths
        }
    }
}

// MARK: - SNMP Raw Output -> Device Port Rows

enum DevicePortTelemetryExtractor {
    static func extractPorts(deviceID: UUID, rawOutput: String, lldpNeighbours: [LLDPNeighbour], fibrePorts: [FibrePortTelemetry]) -> [DevicePortTelemetry] {
        var rows: [Int: DevicePortTelemetry] = [:]

        func upsert(_ port: Int, _ update: (inout DevicePortTelemetry) -> Void) {
            guard port > 0 else { return }
            var row = rows[port] ?? DevicePortTelemetry(deviceID: deviceID, port: port)
            update(&row)
            rows[port] = row
        }

        for rawLine in rawOutput.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines).trimmedLeadingDot
            guard let parsed = splitOIDLine(line) else { continue }
            let oid = parsed.oid
            let value = parsed.value

            if let port = suffixPort(oid, base: "1.3.6.1.2.1.2.2.1.2") {
                upsert(port) { $0.interfaceDescription = cleanedString(value) }
            } else if let port = suffixPort(oid, base: "1.3.6.1.2.1.31.1.1.1.1") {
                upsert(port) { $0.interfaceName = cleanedString(value) }
            } else if let port = suffixPort(oid, base: "1.3.6.1.2.1.2.2.1.7") {
                upsert(port) { $0.adminStatus = statusText(value) }
            } else if let port = suffixPort(oid, base: "1.3.6.1.2.1.2.2.1.8") {
                upsert(port) { $0.operStatus = statusText(value) }
            } else if let port = suffixPort(oid, base: "1.3.6.1.2.1.10.7.2.1.19") {
                upsert(port) { $0.duplex = duplexText(value) }
            } else if let port = suffixPort(oid, base: "1.3.6.1.2.1.2.2.1.5") {
                upsert(port) { row in
                    if row.speedText == nil { row.speedText = speedText(value, isHighSpeed: false) }
                }
            } else if let port = suffixPort(oid, base: "1.3.6.1.2.1.31.1.1.1.15") {
                upsert(port) { row in
                    if let text = speedText(value, isHighSpeed: true) { row.speedText = text }
                }
            } else if let port = suffixPort(oid, base: "1.3.6.1.2.1.2.2.1.3") {
                upsert(port) { $0.transmissionMedium = ifTypeText(value) }
            } else if let port = suffixPort(oid, base: "1.3.6.1.2.1.31.1.1.1.17") {
                upsert(port) { row in
                    if row.transmissionMedium == nil || row.transmissionMedium == "Ethernet" {
                        row.transmissionMedium = connectorText(value)
                    }
                }
            }
        }

        for fibre in fibrePorts {
            upsert(fibre.port) { row in
                row.transmissionMedium = "Optical / SFP"
            }
        }

        for neighbour in lldpNeighbours {
            upsert(neighbour.localPort) { row in
                row.lldpRemoteDeviceName = cleanOptional(neighbour.remoteSystemName)
                row.lldpRemoteMACAddress = cleanOptional(neighbour.remoteChassisMACAddress)
                row.lldpRemotePort = cleanOptional(neighbour.bestRemotePortText)
            }
        }

        return rows.values.sorted { a, b in
            if a.port != b.port { return a.port < b.port }
            return a.displayPort.localizedStandardCompare(b.displayPort) == .orderedAscending
        }
    }

    private static func splitOIDLine(_ line: String) -> (oid: String, value: String)? {
        let separators = [" = INTEGER:", " = Gauge32:", " = Counter32:", " = Counter64:", " = STRING:", " = Hex-STRING:", " = OID:", " = Timeticks:", " = UNSIGNED:"]
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

    private static func suffixPort(_ oid: String, base: String) -> Int? {
        guard oid == base || oid.hasPrefix(base + ".") else { return nil }
        return oid.split(separator: ".").last.flatMap { Int($0) }
    }

    private static func cleanedString(_ value: String) -> String? {
        cleanOptional(value.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
    }

    private static func cleanOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func intValue(_ value: String) -> Int? {
        value.matches(for: #"-?\d+"#).first.flatMap(Int.init)
    }

    private static func statusText(_ value: String) -> String {
        switch intValue(value) {
        case 1: return "Up"
        case 2: return "Down"
        case 3: return "Testing"
        case 4: return "Unknown"
        case 5: return "Dormant"
        case 6: return "NotPresent"
        case 7: return "LowerDown"
        default: return cleanedString(value) ?? "Unknown"
        }
    }

    private static func duplexText(_ value: String) -> String {
        switch intValue(value) {
        case 1: return "Unknown"
        case 2: return "Half"
        case 3: return "Full"
        default: return cleanedString(value) ?? "—"
        }
    }

    private static func ifTypeText(_ value: String) -> String? {
        switch intValue(value) {
        case 6: return "Ethernet"
        case 117: return "Gigabit Ethernet"
        case 53: return "Virtual / VLAN"
        case 24: return "Loopback"
        default: return nil
        }
    }

    private static func connectorText(_ value: String) -> String? {
        switch intValue(value) {
        case 1: return "Physical connector"
        case 2: return "No connector"
        default: return nil
        }
    }

    private static func speedText(_ value: String, isHighSpeed: Bool) -> String? {
        guard let raw = intValue(value), raw > 0 else { return nil }
        if isHighSpeed {
            if raw >= 1000 { return "\(raw / 1000)G" }
            return "\(raw)M"
        }

        if raw >= 1_000_000_000 { return "\(raw / 1_000_000_000)G" }
        if raw >= 1_000_000 { return "\(raw / 1_000_000)M" }
        if raw >= 1_000 { return "\(raw / 1_000)K" }
        return "\(raw)b"
    }
}

private extension String {
    func matches(for pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..<endIndex, in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let r = Range(match.range, in: self) else { return nil }
            return String(self[r])
        }
    }
}

private extension String {
    var trimmedLeadingDot: String { hasPrefix(".") ? String(dropFirst()) : self }
}
