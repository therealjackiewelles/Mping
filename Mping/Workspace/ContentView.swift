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
    @EnvironmentObject private var preferences: AppPreferences
    @State private var sidebarWidth: CGFloat = 230
    @State private var hasLoadedSavedSidebarWidth: Bool = false
    @State private var isResizingSidebar: Bool = false
    @ObservedObject private var fibreBoxStyle = FibreBoxEditorSettings.shared

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
                WorkspaceView(store: store)
                    .contextMenu {
                        Toggle("Snap to Grid", isOn: $store.snapToGridEnabled)

                        Picker("Grid Size", selection: $store.snapGridSize) {
                            Text("20 px").tag(CGFloat(20))
                            Text("40 px").tag(CGFloat(40))
                            Text("80 px").tag(CGFloat(80))
                        }

                        Divider()

                        Button("Copy Selection") {
                            store.copySelection()
                        }
                        .disabled(!store.hasSelection)

                        Button("Paste") {
                            store.pasteSelection()
                        }
                    }

                if showMinimap && !store.hasSelection {
                    MiniMapView(store: store)
                        .frame(width: 320, height: 210)
                        .padding(18)
                        .zIndex(9999)
                        .allowsHitTesting(false)
                }
            }

            if store.hasSelection {
                InspectorView(store: store)
            }
        }
        .frame(minWidth: 1100, minHeight: 700)
        .background(Color.black)
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

            Toggle("Monitoring", isOn: $store.monitoringEnabled)
                .toggleStyle(.switch)
                .foregroundStyle(.white)

            Toggle("Minimap", isOn: $showMinimap)
                .toggleStyle(.switch)
                .foregroundStyle(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Fibre Box Opacity")
                    Spacer()
                    Text("\(Int(fibreBoxStyle.opacity * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))

                Slider(value: $fibreBoxStyle.opacity, in: 0.10...1.0, step: 0.05)
                    .onChange(of: fibreBoxStyle.opacity) { _, _ in
                        store.fibreBoxStyleDidChange()
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Ping Interval: \(String(format: "%.1f", store.pingInterval))s")
                    .foregroundStyle(.white.opacity(0.8))

                Slider(value: $store.pingInterval, in: 0.5...10.0, step: 0.5)

                Text("Effective timeout: \(store.effectivePingTimeoutMilliseconds()) ms")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Zoom: \(Int(store.workspaceScale * 100))%")
                    .foregroundStyle(.white.opacity(0.8))

                Slider(value: $store.workspaceScale, in: 0.25...3.5)
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Snap to Grid", isOn: $store.snapToGridEnabled)
                    .foregroundStyle(.white)

                if store.snapToGridEnabled {
                    Text("Grid Size: \(Int(store.snapGridSize)) px")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))

                    Slider(value: $store.snapGridSize, in: 20...100, step: 20)
                }
            }



            Button("Clear Selection") {
                store.clearSelection()
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        } // ScrollView
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

private struct DeviceViewSheet: View {
    @ObservedObject var store: DeviceStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device Manager")
                        .font(.title2.bold())

                    Text("Edit all monitored devices from one place.")
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

            DeviceViewHeader()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(store.devices) { device in
                        DeviceViewRow(store: store, deviceID: device.id)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .frame(minWidth: 1380, minHeight: 520)
    }
}

private struct DeviceViewHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Name")
                .frame(width: 220, alignment: .leading)
            Text("Name Source")
                .frame(width: 120, alignment: .leading)
            Text("IP Address")
                .frame(width: 170, alignment: .leading)
            Text("Device Type")
                .frame(width: 180, alignment: .leading)
            Text("Web UI Path")
                .frame(width: 280, alignment: .leading)
            Text("Ping NIC")
                .frame(minWidth: 300, alignment: .leading)
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
    }
}

private struct DeviceViewRow: View {
    @ObservedObject var store: DeviceStore
    let deviceID: UUID

    private var device: MonitoredDevice? {
        store.devices.first { $0.id == deviceID }
    }

    var body: some View {
        if let device {
            HStack(spacing: 10) {
                TextField("Name", text: nameBinding(for: device))
                    .textFieldStyle(.roundedBorder)
                    .disabled((currentDevice() ?? device).nameSource == .automatic)
                    .opacity((currentDevice() ?? device).nameSource == .automatic ? 0.48 : 1.0)
                    .frame(width: 220)

                Toggle("SNMP/LLDP", isOn: automaticNameBinding(for: device))
                    .toggleStyle(.checkbox)
                    .frame(width: 120, alignment: .leading)

                TextField("IP Address", text: ipAddressBinding(for: device))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 170)

                Picker("Device Type", selection: deviceTypeBinding(for: device)) {
                    ForEach(MonitoredDeviceType.allCases, id: \.self) { type in
                        Text(type.label).tag(type)
                    }
                }
                .labelsHidden()
                .frame(width: 180)

                TextField("Web UI path", text: webInterfacePathBinding(for: device))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)
                    .help("Double-click the device on the workspace to open http://<IP><path>. Netgear switches default to :49152/v1/base/cheetah_login.html.")

                Picker("Ping NIC", selection: interfaceBinding(for: device)) {
                    Text("Auto").tag("AUTO")

                    ForEach(store.networkInterfaces) { nic in
                        Text(nic.pickerTitle).tag(nic.id)
                    }
                }
                .labelsHidden()
                .frame(minWidth: 300, alignment: .leading)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func nameBinding(for device: MonitoredDevice) -> Binding<String> {
        Binding(
            get: { currentDevice()?.name ?? device.name },
            set: { store.updateDeviceName(id: deviceID, name: $0) }
        )
    }


    private func automaticNameBinding(for device: MonitoredDevice) -> Binding<Bool> {
        Binding(
            get: { (currentDevice() ?? device).nameSource == .automatic },
            set: { useAutomaticName in
                store.updateDeviceNameSource(id: deviceID, source: useAutomaticName ? .automatic : .manual)
            }
        )
    }

    private func ipAddressBinding(for device: MonitoredDevice) -> Binding<String> {
        Binding(
            get: { currentDevice()?.ipAddress ?? device.ipAddress },
            set: { store.updateDeviceIPAddress(id: deviceID, ipAddress: $0) }
        )
    }

    private func deviceTypeBinding(for device: MonitoredDevice) -> Binding<MonitoredDeviceType> {
        Binding(
            get: { currentDevice()?.deviceType ?? device.deviceType },
            set: { store.updateDeviceType(id: deviceID, type: $0) }
        )
    }

    private func webInterfacePathBinding(for device: MonitoredDevice) -> Binding<String> {
        Binding(
            get: { currentDevice()?.webInterfacePath ?? device.webInterfacePath },
            set: { store.updateDeviceWebInterfacePath(id: deviceID, path: $0) }
        )
    }

    private func interfaceBinding(for device: MonitoredDevice) -> Binding<String> {
        Binding(
            get: {
                guard let current = currentDevice() else { return "AUTO" }
                guard let interfaceName = current.sourceInterfaceName,
                      let sourceIP = current.sourceIPAddress else {
                    return "AUTO"
                }

                return store.networkInterfaces.first {
                    $0.bsdName == interfaceName && $0.ipv4Address == sourceIP
                }?.id ?? "AUTO"
            },
            set: { store.updateDeviceInterface(id: deviceID, interfaceID: $0) }
        )
    }

    private func currentDevice() -> MonitoredDevice? {
        store.devices.first { $0.id == deviceID }
    }
}

private struct MiniMapView: View {
    @ObservedObject var store: DeviceStore

    private let canvasSize = CGSize(width: 5000, height: 3000)

    var body: some View {
        GeometryReader { proxy in
            let sx = proxy.size.width / canvasSize.width
            let sy = proxy.size.height / canvasSize.height
            let scale = max(0.25, store.workspaceScale)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.01, green: 0.01, blue: 0.015).opacity(0.50))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.cyan.opacity(0.65), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)

                Text("MINI MAP")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.cyan)
                    .padding(.top, 10)
                    .padding(.leading, 12)

                ForEach(store.shapes) { shape in
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.10))
                        )
                        .frame(
                            width: max(4, shape.width * sx),
                            height: max(4, shape.height * sy)
                        )
                        .position(
                            x: (shape.x + shape.width / 2) * sx,
                            y: (shape.y + shape.height / 2) * sy
                        )
                }

                ForEach(store.devices) { device in
                    Circle()
                        .fill(color(for: device.status))
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.white.opacity(0.75), lineWidth: 1))
                        .position(
                            x: device.x * sx,
                            y: device.y * sy
                        )
                }

                viewportBox(proxySize: proxy.size, sx: sx, sy: sy, scale: scale)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func viewportBox(proxySize: CGSize, sx: CGFloat, sy: CGFloat, scale: Double) -> some View {
        let approximateWorkspaceViewSize = CGSize(width: 900, height: 700)

        let visibleX = (-store.workspaceOffset.width / scale) * sx
        let visibleY = (-store.workspaceOffset.height / scale) * sy
        let visibleW = (approximateWorkspaceViewSize.width / scale) * sx
        let visibleH = (approximateWorkspaceViewSize.height / scale) * sy

        return Rectangle()
            .stroke(Color.yellow.opacity(0.95), lineWidth: 2)
            .background(Color.yellow.opacity(0.08))
            .frame(
                width: max(10, visibleW),
                height: max(10, visibleH)
            )
            .position(
                x: visibleX + visibleW / 2,
                y: visibleY + visibleH / 2
            )
    }

    private func color(for status: DeviceStatus) -> Color {
        switch status {
        case .healthy:
            return .green
        case .slow:
            return .yellow
        case .offline:
            return .red
        case .unknown:
            return .gray
        }
    }
}
