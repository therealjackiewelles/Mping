import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @ObservedObject var store: DeviceStore
    @Binding var showingDeviceView: Bool
    @Binding var showingDevicePortsView: Bool
    @State private var openAlertCategory: MpingAlertCategory? = nil
    @AppStorage("mping.showMinimap") private var showMinimap: Bool = true
    @State private var workspaceSearch: String = ""
    @EnvironmentObject private var preferences: AppPreferences
    @State private var sidebarWidth: CGFloat = 230
    @State private var hasLoadedSavedSidebarWidth: Bool = false
    @State private var isResizingSidebar: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            leftToolbar
                .frame(width: sidebarWidth)
                .background(
                    ZStack {
                        Color(red: 0.07, green: 0.07, blue: 0.08)
                        PanelInteractionBlocker(id: "left-sidebar")
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture { }

            SidebarResizeHandle(
                sidebarWidth: $sidebarWidth,
                isResizing: $isResizingSidebar,
                range: 210...420,
                onResizeEnded: { width in
                    preferences.setSidebarWidth(width)
                }
            )

            ZStack(alignment: .topTrailing) {
                WorkspacePlaneCoordinator(store: store, searchText: workspaceSearch)
                    .contentShape(Rectangle())

                if showMinimap && !store.hasSelection {
                    MiniMapView(store: store)
                        .frame(width: 320, height: 210)
                        .padding(18)
                        .zIndex(9999)
                        .allowsHitTesting(false)
                }

                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    InspectorView(store: store)
                        .frame(width: store.inspectorWidth)
                        .opacity(store.hasSelection ? 1 : 0)
                        .allowsHitTesting(store.hasSelection)
                }
            }
        }
        .frame(minWidth: 1100, minHeight: 700)
        .background(Color.black)
        .background(WindowTitleBarRemover())
        .sheet(isPresented: $showingDeviceView) {
            DeviceViewSheet(store: store)
        }
        .sheet(isPresented: $showingDevicePortsView) {
            DevicePortsView(store: store)
        }
        .onAppear {
            guard !hasLoadedSavedSidebarWidth else { return }
            let clamped = min(CGFloat(420), max(CGFloat(210), CGFloat(preferences.sidebarWidth)))
            sidebarWidth = clamped
            preferences.setSidebarWidth(clamped)
            hasLoadedSavedSidebarWidth = true

        }
    }

    private var leftToolbar: some View {
        VStack(alignment: .leading, spacing: 0) {
            TrafficLights()
                .padding(.leading, 12)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WindowDragArea())

        ScrollView(.vertical, showsIndicators: false) {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 10) {
                Image("MpingLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Mping")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Network Topology Monitoring")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }
            }

            Text("Workspace: \(store.currentWorkspaceName)\(store.hasUnsavedChanges ? " *" : "")")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)

            Text("NIC MODE ACTIVE")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.green)


            AlertingSidebarBox(
                store: store,
                openCategory: $openAlertCategory,
                sidebarWidth: sidebarWidth
            )

            AlertHistoryBox(store: store, sidebarWidth: sidebarWidth)

            Toggle("Monitoring", isOn: $store.monitoringEnabled)
                .toggleStyle(.switch)
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                TextField("Search devices…", text: $workspaceSearch)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white)
                if !workspaceSearch.isEmpty {
                    Button {
                        workspaceSearch = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Ping Interval: \(String(format: "%.1f", store.pingInterval))s")
                    .foregroundStyle(.white.opacity(0.8))

                Slider(value: $store.pingInterval, in: 0.5...10.0, step: 0.5)

                Text("Effective timeout: \(store.effectivePingTimeoutMilliseconds()) ms")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.orange)
            }

            Button("Clear Selection") {
                store.clearSelection()
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        } // ScrollView
        } // outer VStack
    }
}


// Makes the title bar invisible and extends content into that area, without
// removing .titled from the styleMask (which breaks event routing to the workspace).
// Native traffic light buttons are hidden — our custom ones in the sidebar replace them.
private struct WindowTitleBarRemover: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            guard let w = v.window else { return }
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.styleMask.insert(.fullSizeContentView)
            w.standardWindowButton(.closeButton)?.isHidden     = true
            w.standardWindowButton(.miniaturizeButton)?.isHidden = true
            w.standardWindowButton(.zoomButton)?.isHidden      = true
        }
        return v
    }
    func updateNSView(_ v: NSView, context: Context) {}
}

// macOS traffic light buttons — close / minimise / zoom — rendered inside the sidebar
// since the title bar has been removed via .windowStyle(.hiddenTitleBar).
private struct TrafficLights: View {
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            WinButton(hovering: hovering, fill: Color(red: 1.0,   green: 0.373, blue: 0.341), symbol: "xmark") {
                NSApplication.shared.keyWindow?.performClose(nil)
            }
            WinButton(hovering: hovering, fill: Color(red: 1.0,   green: 0.741, blue: 0.180), symbol: "minus") {
                NSApplication.shared.keyWindow?.miniaturize(nil)
            }
            WinButton(hovering: hovering, fill: Color(red: 0.157, green: 0.788, blue: 0.255), symbol: "plus") {
                NSApplication.shared.keyWindow?.zoom(nil)
            }
        }
        .onHover { hovering = $0 }
    }
}

private struct WinButton: View {
    let hovering: Bool
    let fill: Color
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(fill).frame(width: 12, height: 12)
                if hovering {
                    Image(systemName: symbol)
                        .font(.system(size: 6, weight: .black))
                        .foregroundStyle(.black.opacity(0.55))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// Makes the strip next to the traffic lights draggable so the window can still be moved.
private struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> DragNSView { DragNSView() }
    func updateNSView(_ nsView: DragNSView, context: Context) {}

    class DragNSView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }
}

private struct SidebarResizeHandle: View {
    @Binding var sidebarWidth: CGFloat
    @Binding var isResizing: Bool
    let range: ClosedRange<CGFloat>
    let onResizeEnded: (CGFloat) -> Void
    @State private var dragStartWidth: CGFloat = 230

    var body: some View {
        Rectangle()
            .fill(isResizing ? Color.white.opacity(0.28) : Color.white.opacity(0.10))
            .frame(width: isResizing ? 5 : 3)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(isResizing ? 0.18 : 0.06))
                    .frame(width: 1)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isResizing {
                            dragStartWidth = sidebarWidth
                            isResizing = true
                        }

                        let proposed = dragStartWidth + value.translation.width
                        sidebarWidth = min(range.upperBound, max(range.lowerBound, proposed))
                    }
                    .onEnded { _ in
                        let clamped = min(range.upperBound, max(range.lowerBound, sidebarWidth))
                        sidebarWidth = clamped
                        dragStartWidth = clamped
                        isResizing = false
                        onResizeEnded(clamped)
                    }
            )
            .onHover { hovering in
                #if os(macOS)
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
                #endif
            }
            .animation(.easeOut(duration: 0.12), value: isResizing)
    }
}

// MARK: - Device Manager Column

private enum DeviceManagerColumn: String {
    case redundant
    case name, nameSource, ipAddress, deviceType, snmpCommunity, urlPrefix, webUIPath, pingNIC

    // Standard columns that appear in all modes (excludes redundant which is conditional).
    static let standardCases: [DeviceManagerColumn] = [.name, .nameSource, .ipAddress, .deviceType, .snmpCommunity, .urlPrefix, .webUIPath, .pingNIC]

    var title: String {
        switch self {
        case .redundant: return "Redundant"
        case .name: return "Name"
        case .nameSource: return "SNMP/LLDP Name"
        case .ipAddress: return "IP Address"
        case .deviceType: return "Device Type"
        case .snmpCommunity: return "SNMP Community"
        case .urlPrefix: return "URL Prefix"
        case .webUIPath: return "URL Suffix"
        case .pingNIC: return "Ping NIC"
        }
    }

    var defaultWidth: CGFloat {
        switch self {
        case .redundant: return 90
        case .name: return 200
        case .nameSource: return 110
        case .ipAddress: return 150
        case .deviceType: return 160
        case .snmpCommunity: return 130
        case .urlPrefix: return 100
        case .webUIPath: return 240
        case .pingNIC: return 280
        }
    }

    var minWidth: CGFloat {
        switch self {
        case .redundant: return 80
        case .nameSource: return 90
        case .urlPrefix: return 80
        default: return 80
        }
    }

    static var defaultOrder: [String] { standardCases.map(\.rawValue) }
    static var totalDefaultWidth: CGFloat { standardCases.reduce(0) { $0 + $1.defaultWidth } }
}

// MARK: - Device Manager Sheet

private struct DeviceViewSheet: View {
    @ObservedObject var store: DeviceStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: AppPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device Manager")
                        .font(.title2.bold())
                    Text("Drag column headers to reorder. Drag dividers to resize. All settings are saved.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    store.redundantModeActive.toggle()
                } label: {
                    Label("Redundant Mode", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(store.redundantModeActive ? .blue : .secondary)
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            Divider()

            DeviceManagerTableView(store: store, preferences: preferences)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(20)
        .frame(minWidth: 900, idealWidth: idealWidth, minHeight: 500, idealHeight: idealHeight)
        .background(DeviceManagerWindowSizer(idealWidth: idealWidth, idealHeight: idealHeight))
    }

    private var idealWidth: CGFloat {
        let screen = NSScreen.main?.visibleFrame.width ?? 1440
        let total = DeviceManagerColumn.standardCases.reduce(CGFloat(0)) { sum, col in
            let saved = preferences.deviceManagerColumnWidths[col.rawValue].map { CGFloat($0) }
            return sum + (saved ?? col.defaultWidth)
        }
        let redundantExtra: CGFloat = store.redundantModeActive ? DeviceManagerColumn.redundant.defaultWidth : 0
        return min(screen * 0.97, total + redundantExtra + 48)
    }

    private var idealHeight: CGFloat {
        let screen = NSScreen.main?.visibleFrame.height ?? 900
        let rowH = CGFloat(store.devices.count) * 28 + 160
        return min(screen * 0.90, max(500, rowH))
    }
}

private struct DeviceManagerWindowSizer: NSViewRepresentable {
    let idealWidth: CGFloat
    let idealHeight: CGFloat

    func makeNSView(context: Context) -> NSView {
        let v = NSView(); DispatchQueue.main.async { resize(v) }; return v
    }
    func updateNSView(_ v: NSView, context: Context) { DispatchQueue.main.async { resize(v) } }

    private func resize(_ view: NSView) {
        guard let window = view.window else { return }
        let screen = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x:0,y:0,width:1440,height:900)
        let w = min(idealWidth, screen.width * 0.97)
        let h = min(idealHeight, screen.height * 0.90)
        let cur = window.frame
        guard abs(cur.width - w) > 8 || abs(cur.height - h) > 8 else { return }
        var f = NSRect(x: cur.midX - w/2, y: cur.midY - h/2, width: w, height: h)
        if f.minX < screen.minX { f.origin.x = screen.minX }
        if f.maxX > screen.maxX { f.origin.x = screen.maxX - f.width }
        if f.minY < screen.minY { f.origin.y = screen.minY }
        if f.maxY > screen.maxY { f.origin.y = screen.maxY - f.height }
        window.setFrame(f, display: true, animate: false)
        window.minSize = NSSize(width: 900, height: 500)
    }
}

// MARK: - Device Manager NSTableView

private struct DeviceManagerTableView: NSViewRepresentable {
    @ObservedObject var store: DeviceStore
    @ObservedObject var preferences: AppPreferences

    func makeCoordinator() -> Coordinator { Coordinator(store: store, preferences: preferences) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false

        let table = NSTableView()
        table.usesAlternatingRowBackgroundColors = true
        table.allowsColumnResizing = true
        table.allowsColumnReordering = true
        table.allowsColumnSelection = false
        table.rowHeight = 28
        table.columnAutoresizingStyle = .noColumnAutoresizing
        table.style = .fullWidth
        table.dataSource = context.coordinator
        table.delegate = context.coordinator
        context.coordinator.tableView = table

        context.coordinator.configureColumns(on: table)
        scroll.documentView = table
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let table = scroll.documentView as? NSTableView else { return }
        context.coordinator.store = store
        context.coordinator.preferences = preferences
        let columnsChanged = context.coordinator.configureColumns(on: table)
        context.coordinator.reloadIfNeeded(table: table, scroll: scroll, columnsChanged: columnsChanged)
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
        var store: DeviceStore
        var preferences: AppPreferences
        weak var tableView: NSTableView?
        private var isConfiguringColumns = false
        // Track row structure so we only call reloadData() when it actually changes.
        private var lastRowIDs: [UUID] = []
        private var lastRedundantMode: Bool = false

        init(store: DeviceStore, preferences: AppPreferences) {
            self.store = store
            self.preferences = preferences
        }

        // Only reload when the visible row set changes or columns were rebuilt.
        // Never interrupts an active text-field edit — that would steal first responder
        // and discard in-progress input on every ping tick.
        func reloadIfNeeded(table: NSTableView, scroll: NSScrollView, columnsChanged: Bool) {
            let currentIDs = orderedDevices().map(\.id)
            let currentMode = store.redundantModeActive
            let rowsChanged = currentIDs != lastRowIDs || currentMode != lastRedundantMode
            guard columnsChanged || rowsChanged else { return }

            // When only row data changed (not column structure), protect any active edit.
            if !columnsChanged {
                if let fr = table.window?.firstResponder as? NSView, fr.isDescendant(of: scroll) {
                    return
                }
            }

            lastRowIDs = currentIDs
            lastRedundantMode = currentMode
            table.reloadData()
        }

        // MARK: Column setup

        @discardableResult
        func configureColumns(on table: NSTableView) -> Bool {
            guard !isConfiguringColumns else { return false }
            isConfiguringColumns = true
            defer { isConfiguringColumns = false }

            let savedOrder = preferences.deviceManagerColumnOrder
            let standardOrder: [DeviceManagerColumn] = savedOrder.isEmpty
                ? DeviceManagerColumn.standardCases
                : savedOrder.compactMap { DeviceManagerColumn(rawValue: $0) }.filter { $0 != .redundant }
            let allCovered = DeviceManagerColumn.standardCases.allSatisfy { col in standardOrder.contains(col) }
            var finalOrder = allCovered ? standardOrder : DeviceManagerColumn.standardCases

            // Redundant column always appears first when mode is active; never persisted to order prefs.
            if store.redundantModeActive {
                finalOrder.insert(.redundant, at: 0)
            }

            let existing = table.tableColumns.map { $0.identifier.rawValue }
            let desired  = finalOrder.map { $0.rawValue }
            if existing == desired { return false }

            table.tableColumns.forEach { table.removeTableColumn($0) }

            for col in finalOrder {
                let tc = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(col.rawValue))
                tc.title = col.title
                let saved = preferences.deviceManagerColumnWidths[col.rawValue].map { CGFloat($0) }
                tc.width = max(col.minWidth, saved ?? col.defaultWidth)
                tc.minWidth = col.minWidth
                tc.maxWidth = col == .redundant ? 100 : 600
                table.addTableColumn(tc)
            }
            return true
        }

        // MARK: Data source

        // When redundant mode is active, secondary devices appear immediately below their primary.
        private func orderedDevices() -> [MonitoredDevice] {
            guard store.redundantModeActive else { return store.devices }
            var result = [MonitoredDevice]()
            var secondaryIDs = Set<UUID>()
            for device in store.devices {
                if device.redundancyRole == .secondary { secondaryIDs.insert(device.id); continue }
                result.append(device)
                if device.redundancyRole == .primary, let peerID = device.redundantPeerID,
                   let secondary = store.devices.first(where: { $0.id == peerID }) {
                    result.append(secondary)
                }
            }
            // Append any secondary devices whose primary wasn't found (orphan guard)
            for device in store.devices where device.redundancyRole == .secondary && !result.contains(where: { $0.id == device.id }) {
                result.append(device)
            }
            return result
        }

        func numberOfRows(in tableView: NSTableView) -> Int { orderedDevices().count }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let ordered = orderedDevices()
            guard row < ordered.count,
                  let id = tableColumn?.identifier.rawValue,
                  let col = DeviceManagerColumn(rawValue: id) else { return nil }

            let device = ordered[row]
            let cellID = NSUserInterfaceItemIdentifier("DevMgrCell-\(id)")

            switch col {
            case .redundant:
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DevMgrRedundant-\(row)"), owner: self) as? NSTableCellView ?? NSTableCellView()
                cell.identifier = NSUserInterfaceItemIdentifier("DevMgrRedundant-\(row)")
                let btn: NSButton
                if let existing = cell.subviews.first as? NSButton {
                    btn = existing
                } else {
                    btn = NSButton(checkboxWithTitle: "", target: nil, action: nil)
                    btn.translatesAutoresizingMaskIntoConstraints = false
                    cell.addSubview(btn)
                    NSLayoutConstraint.activate([
                        btn.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
                        btn.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                    ])
                }
                switch device.redundancyRole {
                case .none:
                    btn.state = .off
                    btn.isEnabled = true
                    btn.title = ""
                case .primary:
                    btn.state = .on
                    btn.isEnabled = true
                    btn.title = "P"
                case .secondary:
                    btn.state = .on
                    btn.isEnabled = false
                    btn.title = "↳ S"
                }
                btn.tag = row
                btn.target = self
                btn.action = #selector(toggleRedundancy(_:))
                return cell

            case .nameSource:
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DevMgrCheck-\(id)"), owner: self) as? NSTableCellView ?? NSTableCellView()
                cell.identifier = NSUserInterfaceItemIdentifier("DevMgrCheck-\(id)")
                let btn: NSButton
                if let existing = cell.subviews.first as? NSButton {
                    btn = existing
                } else {
                    btn = NSButton(checkboxWithTitle: "Auto", target: nil, action: nil)
                    btn.translatesAutoresizingMaskIntoConstraints = false
                    cell.addSubview(btn)
                    NSLayoutConstraint.activate([
                        btn.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 6),
                        btn.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                    ])
                }
                btn.state = device.nameSource == .automatic ? .on : .off
                btn.tag = row
                btn.target = self
                btn.action = #selector(toggleNameSource(_:))
                return cell

            case .deviceType:
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DevMgrPopup-deviceType-\(row)"), owner: self) as? NSTableCellView ?? NSTableCellView()
                cell.identifier = NSUserInterfaceItemIdentifier("DevMgrPopup-deviceType-\(row)")
                let popup: NSPopUpButton
                if let existing = cell.subviews.first as? NSPopUpButton {
                    popup = existing
                } else {
                    popup = NSPopUpButton()
                    popup.translatesAutoresizingMaskIntoConstraints = false
                    popup.isBordered = false
                    cell.addSubview(popup)
                    NSLayoutConstraint.activate([
                        popup.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                        popup.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                        popup.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                    ])
                }
                popup.removeAllItems()
                MonitoredDeviceType.allCases.forEach { popup.addItem(withTitle: $0.label) }
                popup.selectItem(withTitle: device.deviceType.label)
                popup.tag = row
                popup.target = self
                popup.action = #selector(deviceTypeChanged(_:))
                return cell

            case .pingNIC:
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DevMgrPopup-nic-\(row)"), owner: self) as? NSTableCellView ?? NSTableCellView()
                cell.identifier = NSUserInterfaceItemIdentifier("DevMgrPopup-nic-\(row)")
                let popup: NSPopUpButton
                if let existing = cell.subviews.first as? NSPopUpButton {
                    popup = existing
                } else {
                    popup = NSPopUpButton()
                    popup.translatesAutoresizingMaskIntoConstraints = false
                    popup.isBordered = false
                    cell.addSubview(popup)
                    NSLayoutConstraint.activate([
                        popup.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                        popup.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                        popup.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                    ])
                }
                popup.removeAllItems()
                popup.addItem(withTitle: "Auto")
                store.networkInterfaces.forEach { popup.addItem(withTitle: $0.pickerTitle) }
                let currentNIC: String
                if let bsd = device.sourceInterfaceName, let ip = device.sourceIPAddress,
                   let match = store.networkInterfaces.first(where: { $0.bsdName == bsd && $0.ipv4Address == ip }) {
                    currentNIC = match.pickerTitle
                } else {
                    currentNIC = "Auto"
                }
                popup.selectItem(withTitle: currentNIC)
                popup.tag = row
                popup.target = self
                popup.action = #selector(nicChanged(_:))
                return cell

            default:
                let editable: Bool
                switch col {
                case .name:          editable = device.nameSource != .automatic
                case .snmpCommunity: editable = device.deviceType == .netgearSwitch
                case .ipAddress, .urlPrefix, .webUIPath: editable = true
                default:             editable = false
                }

                let cell = tableView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView ?? NSTableCellView()
                cell.identifier = cellID
                let tf: NSTextField
                if let existing = cell.textField {
                    tf = existing
                } else {
                    tf = NSTextField(frame: .zero)
                    tf.translatesAutoresizingMaskIntoConstraints = false
                    tf.font = NSFont.systemFont(ofSize: 12)
                    tf.cell?.wraps = false
                    tf.cell?.isScrollable = true
                    cell.addSubview(tf)
                    cell.textField = tf
                    NSLayoutConstraint.activate([
                        tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                        tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                        tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                    ])
                }
                tf.stringValue = cellText(col: col, device: device)
                tf.isEditable = editable
                tf.isSelectable = editable
                tf.isBordered = editable
                tf.isBezeled = editable
                tf.bezelStyle = editable ? .roundedBezel : .squareBezel
                tf.drawsBackground = editable
                tf.alphaValue = editable ? 1.0 : 0.4
                tf.textColor = editable ? .labelColor : .secondaryLabelColor
                tf.delegate = self
                tf.tag = row * 100 + columnTag(col)
                return cell
            }
        }

        private func cellText(col: DeviceManagerColumn, device: MonitoredDevice) -> String {
            switch col {
            case .name: return device.displayName.isEmpty ? device.name : device.name
            case .ipAddress: return device.ipAddress
            case .snmpCommunity: return device.snmpCommunity
            case .urlPrefix: return device.webInterfacePrefix
            case .webUIPath: return device.webInterfacePath
            default: return ""
            }
        }

        private func columnTag(_ col: DeviceManagerColumn) -> Int {
            switch col {
            case .name: return 1
            case .ipAddress: return 2
            case .snmpCommunity: return 3
            case .urlPrefix: return 4
            case .webUIPath: return 5
            default: return 0
            }
        }

        // MARK: NSTextFieldDelegate

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            let row = tf.tag / 100
            let colTag = tf.tag % 100
            let ordered = orderedDevices()
            guard row >= 0, row < ordered.count else { return }
            let device = ordered[row]
            let value = tf.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch colTag {
                case 1: self.store.updateDevice(id: device.id, name: value.isEmpty ? device.name : value, ipAddress: device.ipAddress)
                case 2: self.store.updateDevice(id: device.id, name: device.name, ipAddress: value)
                case 3: self.store.updateDeviceSNMPCommunity(id: device.id, community: value.isEmpty ? "public" : value)
                case 4: self.store.updateDeviceWebInterfacePrefix(id: device.id, prefix: value)
                case 5: self.store.updateDeviceWebInterfacePath(id: device.id, path: value)
                default: break
                }
            }
        }

        // MARK: Popup actions

        @objc private func toggleRedundancy(_ sender: NSButton) {
            let row = sender.tag
            let ordered = orderedDevices()
            guard row < ordered.count else { return }
            let device = ordered[row]
            if device.redundancyRole == .none {
                store.enableRedundancy(for: device.id)
            } else if device.redundancyRole == .primary {
                store.disableRedundancy(for: device.id)
            }
            tableView?.reloadData()
        }

        @objc private func toggleNameSource(_ sender: NSButton) {
            let row = sender.tag
            let ordered = orderedDevices()
            guard row < ordered.count else { return }
            let device = ordered[row]
            let newSource: DeviceNameSource = sender.state == .on ? .automatic : .manual
            store.updateDeviceNameSource(id: device.id, source: newSource)
        }

        @objc private func deviceTypeChanged(_ sender: NSPopUpButton) {
            let row = sender.tag
            let ordered = orderedDevices()
            guard row < ordered.count else { return }
            let device = ordered[row]
            guard let title = sender.selectedItem?.title,
                  let type = MonitoredDeviceType.allCases.first(where: { $0.label == title }) else { return }
            store.updateDeviceType(id: device.id, type: type)
            tableView?.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(0..<(tableView?.numberOfColumns ?? 0)))
        }

        @objc private func nicChanged(_ sender: NSPopUpButton) {
            let row = sender.tag
            let ordered = orderedDevices()
            guard row < ordered.count else { return }
            let device = ordered[row]
            guard let title = sender.selectedItem?.title else { return }
            if title == "Auto" {
                store.updateDeviceInterface(id: device.id, interfaceID: "AUTO")
            } else if let nic = store.networkInterfaces.first(where: { $0.pickerTitle == title }) {
                store.updateDeviceInterface(id: device.id, interfaceID: nic.id)
            }
        }

        // MARK: Column move / resize → save preferences

        func tableViewColumnDidMove(_ notification: Notification) {
            guard !isConfiguringColumns, let table = tableView else { return }
            let order = table.tableColumns.map { $0.identifier.rawValue }
            preferences.deviceManagerColumnOrder = order
        }

        func tableViewColumnDidResize(_ notification: Notification) {
            guard !isConfiguringColumns, let table = tableView else { return }
            var widths = preferences.deviceManagerColumnWidths
            for col in table.tableColumns {
                widths[col.identifier.rawValue] = Double(col.width)
            }
            preferences.deviceManagerColumnWidths = widths
        }
    }
}

private struct MiniMapView: View {
    @ObservedObject var store: DeviceStore

    private let canvasSize = CGSize(width: 5000, height: 3000)
    private let approximateWorkspaceViewSize = CGSize(width: 900, height: 700)

    var body: some View {
        GeometryReader { proxy in
            let sx = proxy.size.width / canvasSize.width
            let sy = proxy.size.height / canvasSize.height
            let scale = max(0.25, store.workspaceScale)
            let visibleX = (-store.workspaceOffset.width / scale) * sx
            let visibleY = (-store.workspaceOffset.height / scale) * sy
            let visibleW = max(10, (approximateWorkspaceViewSize.width / scale) * sx)
            let visibleH = max(10, (approximateWorkspaceViewSize.height / scale) * sy)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.01, green: 0.01, blue: 0.015).opacity(0.50))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.cyan.opacity(0.65), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)

                // Single Canvas for all shapes and device dots — eliminates N SwiftUI
                // views being created/diffed/laid out on every ping cycle.
                Canvas { ctx, _ in
                    // Location boxes
                    for shape in store.shapes {
                        let rect = CGRect(
                            x: shape.x * sx,
                            y: shape.y * sy,
                            width: max(4, shape.width * sx),
                            height: max(4, shape.height * sy)
                        )
                        ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(.white.opacity(0.10)))
                        ctx.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .color(.white.opacity(0.55)), lineWidth: 1)
                    }

                    // Device dots
                    for device in store.devices {
                        let cx = device.x * sx
                        let cy = device.y * sy
                        let dot = CGRect(x: cx - 4, y: cy - 4, width: 8, height: 8)
                        ctx.fill(Path(ellipseIn: dot), with: .color(dotColor(for: device.status)))
                        ctx.stroke(Path(ellipseIn: dot), with: .color(.white.opacity(0.75)), lineWidth: 1)
                    }

                    // Viewport box
                    let vpRect = CGRect(x: visibleX, y: visibleY, width: visibleW, height: visibleH)
                    ctx.fill(Path(vpRect), with: .color(.yellow.opacity(0.08)))
                    ctx.stroke(Path(vpRect), with: .color(.yellow.opacity(0.95)), lineWidth: 2)
                }
                .allowsHitTesting(false)

                Text("MINI MAP")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.cyan)
                    .padding(.top, 10)
                    .padding(.leading, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func dotColor(for status: DeviceStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .slow:    return .yellow
        case .offline: return .red
        case .unknown: return .gray
        }
    }
}
