import SwiftUI
import AppKit

struct WorkspaceView: View {
    @ObservedObject var store: DeviceStore
    var searchText: String = ""

    @State private var deviceDragStart: [UUID: CGPoint] = [:]
    @State private var shapeDragStart: [UUID: CGPoint] = [:]
    @State private var selectionStart: CGPoint? = nil
    @State private var selectionCurrent: CGPoint? = nil
    @State private var hoverPoint: CGPoint? = nil
    @State private var resizingShapeID: UUID? = nil
    @State private var shapeResizeStartFrames: [UUID: CGRect] = [:]
    @State private var pendingPanDelta: CGSize = .zero
    @State private var panFlushScheduled: Bool = false
    @State private var pendingZoomDelta: Double = 0
    @State private var pendingZoomPoint: CGPoint = .zero
    @State private var zoomFlushScheduled: Bool = false

    private let canvasSize = CGSize(width: 5000, height: 3000)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.clearSelection()
                    }
                    .gesture(selectionBoxGesture)

                ZStack(alignment: .topLeading) {
                    grid

                    FibreLinksLayer(
                        devices: store.devices,
                        links: store.cachedFibreResults,
                        fibreLabelOffset: store.fibreLabelOffset,
                        setFibreLabelOffset: store.setFibreLabelOffset,
                        showLines: true,
                        showLabels: false
                    )
                        .frame(width: canvasSize.width, height: canvasSize.height)
                        .allowsHitTesting(false)

                    ForEach(store.shapes) { shape in
                        WorkspaceShapeView(
                            shape: shape,
                            isSelected: store.selectedShapeIDs.contains(shape.id),
                            onResizeStart: {
                                resizingShapeID = shape.id
                                shapeResizeStartFrames[shape.id] = CGRect(
                                    x: shape.x,
                                    y: shape.y,
                                    width: shape.width,
                                    height: shape.height
                                )

                                if !store.selectedShapeIDs.contains(shape.id) {
                                    store.selectOnlyShape(shape.id)
                                }
                            },
                            onResize: { anchor, translation in
                                let startFrame = shapeResizeStartFrames[shape.id] ?? CGRect(
                                    x: shape.x,
                                    y: shape.y,
                                    width: shape.width,
                                    height: shape.height
                                )

                                store.resizeShape(
                                    id: shape.id,
                                    anchor: anchor,
                                    startFrame: startFrame,
                                    translation: translation,
                                    scale: store.workspaceScale
                                )
                            },
                            onResizeEnd: {
                                resizingShapeID = nil
                                shapeResizeStartFrames.removeValue(forKey: shape.id)
                            }
                        )
                        .position(
                            x: shape.x + shape.width / 2,
                            y: shape.y + shape.height / 2
                        )
                        .onTapGesture {
                            if isMultiSelectModifierPressed {
                                store.toggleShapeSelection(shape.id)
                            } else {
                                store.selectOnlyShape(shape.id)
                            }
                        }
                        .gesture(shapeDragGesture(shape))
                    }

                    ForEach(store.devices) { device in
                        MpingMapDeviceTileView(
                            device: device,
                            isSelected: store.selectedDeviceIDs.contains(device.id),
                            shouldShowSecondaryDetail: store.workspaceScale >= 0.52
                        )
                        .equatable()
                        .opacity(deviceMatchesSearch(device) ? 1.0 : 0.22)
                        .position(x: device.x, y: device.y)
                        .onTapGesture {
                            if isMultiSelectModifierPressed {
                                store.toggleDeviceSelection(device.id)
                            } else if store.selectedDeviceIDs == [device.id] {
                                store.clearSelection()
                            } else {
                                store.selectOnlyDevice(device.id)
                            }
                        }
                        .gesture(deviceDragGesture(device))
                    }

                    FibreLinksLayer(
                        devices: store.devices,
                        links: store.cachedFibreResults,
                        fibreLabelOffset: store.fibreLabelOffset,
                        setFibreLabelOffset: store.setFibreLabelOffset,
                        showLines: false,
                        showLabels: true
                    )
                        .frame(width: canvasSize.width, height: canvasSize.height)
                        .zIndex(9999)
                }
                .frame(
                    width: canvasSize.width,
                    height: canvasSize.height,
                    alignment: .topLeading
                )
                .scaleEffect(store.workspaceScale, anchor: .topLeading)
                .offset(store.workspaceOffset)

                if let rect = selectionRect {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.13))
                        .overlay(
                            Rectangle()
                                .stroke(
                                    Color.accentColor.opacity(0.9),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                )
                        )
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .allowsHitTesting(false)
                }

                FibreTopologyHUD(store: store)
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)

                WorkspaceEventCatcher(
                    isSnapToGridEnabled: store.snapToGridEnabled,
                    gridSize: store.snapGridSize,
                    hasSelection: store.hasSelection,
                    hasClipboardContent: store.hasClipboardContent,
                    onScroll: { delta in
                        let point = hoverPoint ?? CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        queueWorkspaceZoom(delta: delta, around: point)
                    },
                    onRightPan: { delta in
                        queueWorkspacePan(delta)
                    },
                    onToggleSnapToGrid: {
                        store.snapToGridEnabled.toggle()
                    },
                    onSetGridSize: { size in
                        store.snapGridSize = size
                        store.snapToGridEnabled = true
                    },
                    onCopySelection: {
                        store.copySelection()
                    },
                    onPaste: {
                        store.pasteSelection()
                    },
                    onClearTopologyLinks: {
                        store.clearAllTopologyLinks()
                    },
                    deviceAt: { swiftUIPoint in
                        let scale = store.workspaceScale
                        let offset = store.workspaceOffset
                        let canvasX = (swiftUIPoint.x - offset.width) / scale
                        let canvasY = (swiftUIPoint.y - offset.height) / scale
                        let halfW = DeviceTileEditorSettings.shared.tileWidth / 2
                        let halfH = DeviceTileEditorSettings.shared.tileHeight / 2
                        return store.devices.first {
                            abs(CGFloat($0.x) - canvasX) <= halfW &&
                            abs(CGFloat($0.y) - canvasY) <= halfH
                        }
                    },
                    onOpenWebInterface: { id in store.openWebInterface(for: id) },
                    onSelectDevice: { id in store.selectOnlyDevice(id) },
                    onCopyDevice: { id in store.selectOnlyDevice(id); store.copySelection() },
                    onCutDevice: { id in store.selectOnlyDevice(id); store.cutSelection() },
                    onDuplicateDevice: { id in
                        store.selectOnlyDevice(id)
                        store.copySelection()
                        store.pasteSelection()
                    },
                    onDeleteDevice: { id in store.selectOnlyDevice(id); store.deleteSelection() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverPoint = location
                case .ended:
                    hoverPoint = nil
                }
            }
            .clipped()
            .background(Color(red: 0.055, green: 0.055, blue: 0.06))
        }
    }

    private func queueWorkspacePan(_ delta: CGSize) {
        guard delta.width != 0 || delta.height != 0 else { return }

        pendingPanDelta.width += delta.width
        pendingPanDelta.height += delta.height

        guard !panFlushScheduled else { return }
        panFlushScheduled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 / 60.0)) {
            let delta = pendingPanDelta
            pendingPanDelta = .zero
            panFlushScheduled = false

            guard delta.width != 0 || delta.height != 0 else { return }
            store.panWorkspace(by: delta)
        }
    }

    private func queueWorkspaceZoom(delta: Double, around point: CGPoint) {
        guard delta != 0 else { return }

        pendingZoomDelta += delta
        pendingZoomPoint = point

        guard !zoomFlushScheduled else { return }
        zoomFlushScheduled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 / 60.0)) {
            let delta = pendingZoomDelta
            let point = pendingZoomPoint
            pendingZoomDelta = 0
            zoomFlushScheduled = false

            guard delta != 0 else { return }
            store.zoomWorkspace(by: delta, around: point)
        }
    }

    private var isMultiSelectModifierPressed: Bool {
        NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command)
    }

    private var background: some View {
        Rectangle()
            .fill(Color(red: 0.055, green: 0.055, blue: 0.06))
    }

    private var selectionRect: CGRect? {
        guard let start = selectionStart, let current = selectionCurrent else { return nil }

        return CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }

    private var selectionBoxGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                selectionStart = selectionStart ?? value.startLocation
                selectionCurrent = value.location
            }
            .onEnded { value in
                defer {
                    selectionStart = nil
                    selectionCurrent = nil
                }

                let viewRect = CGRect(
                    x: min(value.startLocation.x, value.location.x),
                    y: min(value.startLocation.y, value.location.y),
                    width: abs(value.location.x - value.startLocation.x),
                    height: abs(value.location.y - value.startLocation.y)
                )

                if viewRect.width < 5 && viewRect.height < 5 {
                    store.clearSelection()
                    return
                }

                let worldTopLeft = store.viewportPointToWorld(CGPoint(x: viewRect.minX, y: viewRect.minY))
                let worldBottomRight = store.viewportPointToWorld(CGPoint(x: viewRect.maxX, y: viewRect.maxY))

                let worldRect = CGRect(
                    x: min(worldTopLeft.x, worldBottomRight.x),
                    y: min(worldTopLeft.y, worldBottomRight.y),
                    width: abs(worldBottomRight.x - worldTopLeft.x),
                    height: abs(worldBottomRight.y - worldTopLeft.y)
                )

                let selectedDevices = Set(
                    store.devices
                        .filter { device in
                            let rect = CGRect(x: device.x - 85, y: device.y - 52, width: 170, height: 104)
                            return worldRect.intersects(rect)
                        }
                        .map(\.id)
                )

                let selectedShapes = Set(
                    store.shapes
                        .filter { shape in
                            let rect = CGRect(x: shape.x, y: shape.y, width: shape.width, height: shape.height)
                            return worldRect.intersects(rect)
                        }
                        .map(\.id)
                )

                store.setSelection(deviceIDs: selectedDevices, shapeIDs: selectedShapes)
            }
    }

    private var grid: some View {
        Canvas { context, size in
            let spacing: CGFloat = 40
            var path = Path()

            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }

            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }

            context.stroke(path, with: .color(.white.opacity(0.055)), lineWidth: 1)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(false)
    }

    private func deviceDragGesture(_ device: MonitoredDevice) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if !store.selectedDeviceIDs.contains(device.id) {
                    store.selectOnlyDevice(device.id)
                }

                if deviceDragStart.isEmpty && shapeDragStart.isEmpty {
                    store.beginUndoTransaction()
                }

                if deviceDragStart.isEmpty {
                    let deviceIDs = store.selectedDeviceIDs.contains(device.id) ? store.selectedDeviceIDs : [device.id]

                    for id in deviceIDs {
                        if let d = store.devices.first(where: { $0.id == id }) {
                            deviceDragStart[id] = CGPoint(x: d.x, y: d.y)
                        }
                    }
                }

                if shapeDragStart.isEmpty {
                    for id in store.selectedShapeIDs {
                        if let s = store.shapes.first(where: { $0.id == id }) {
                            shapeDragStart[id] = CGPoint(x: s.x, y: s.y)
                        }
                    }
                }

                store.moveSelectedItems(
                    deviceStartPositions: deviceDragStart,
                    shapeStartPositions: shapeDragStart,
                    translation: value.translation,
                    scale: store.workspaceScale
                )
            }
            .onEnded { _ in
                store.endUndoTransaction()
                deviceDragStart.removeAll()
                shapeDragStart.removeAll()
            }
    }

    private func shapeDragGesture(_ shape: WorkspaceShape) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if !store.selectedShapeIDs.contains(shape.id) {
                    store.selectOnlyShape(shape.id)
                }

                if deviceDragStart.isEmpty && shapeDragStart.isEmpty {
                    store.beginUndoTransaction()
                }

                if shapeDragStart.isEmpty {
                    let shapeIDs = store.selectedShapeIDs.contains(shape.id) ? store.selectedShapeIDs : [shape.id]

                    for id in shapeIDs {
                        if let s = store.shapes.first(where: { $0.id == id }) {
                            shapeDragStart[id] = CGPoint(x: s.x, y: s.y)
                        }
                    }
                }

                if deviceDragStart.isEmpty {
                    for id in store.selectedDeviceIDs {
                        if let d = store.devices.first(where: { $0.id == id }) {
                            deviceDragStart[id] = CGPoint(x: d.x, y: d.y)
                        }
                    }
                }

                store.moveSelectedItems(
                    deviceStartPositions: deviceDragStart,
                    shapeStartPositions: shapeDragStart,
                    translation: value.translation,
                    scale: store.workspaceScale
                )
            }
            .onEnded { _ in
                store.endUndoTransaction()
                deviceDragStart.removeAll()
                shapeDragStart.removeAll()
            }
    }

    private func deviceMatchesSearch(_ device: MonitoredDevice) -> Bool {
        guard !searchText.isEmpty else { return true }
        let q = searchText.lowercased()
        return device.displayName.lowercased().contains(q)
            || device.ipAddress.contains(q)
            || (device.zoneName?.lowercased().contains(q) ?? false)
    }
}


private struct MpingMapDeviceTileView: View, Equatable {
    let device: MonitoredDevice
    let isSelected: Bool
    let shouldShowSecondaryDetail: Bool

    @ObservedObject private var tileStyle = DeviceTileEditorSettings.shared

    @State private var pulseScale: CGFloat = 0.45
    @State private var pulseOpacity: Double = 0.0

    static func == (lhs: MpingMapDeviceTileView, rhs: MpingMapDeviceTileView) -> Bool {
        // Keep the map tile stable during SNMP/LLDP polling.
        // The full MonitoredDevice value includes LLDP neighbours, raw SFP telemetry,
        // and lastSNMPChecked. Comparing the whole struct makes every telemetry pass
        // invalidate every visible tile even when the displayed tile content is unchanged.
        lhs.device.id == rhs.device.id
            && lhs.device.displayName == rhs.device.displayName
            && lhs.device.ipAddress == rhs.device.ipAddress
            && lhs.device.x == rhs.device.x
            && lhs.device.y == rhs.device.y
            && lhs.device.status == rhs.device.status
            && lhs.device.lastRTT == rhs.device.lastRTT
            && lhs.device.pingPulseID == rhs.device.pingPulseID
            && lhs.device.deviceType == rhs.device.deviceType
            && lhs.device.switchTelemetry.temperatureCelsius == rhs.device.switchTelemetry.temperatureCelsius
            && lhs.device.lastSeenOnline == rhs.device.lastSeenOnline
            && lhs.device.verificationState == rhs.device.verificationState
            && lhs.device.zoneName == rhs.device.zoneName
            && lhs.device.switchTelemetry.stpIsRootBridge == rhs.device.switchTelemetry.stpIsRootBridge
            && lhs.device.switchTelemetry.stpBlockedPorts == rhs.device.switchTelemetry.stpBlockedPorts
            && lhs.isSelected == rhs.isSelected
            && lhs.shouldShowSecondaryDetail == rhs.shouldShowSecondaryDetail
    }

    private var tileWidth: CGFloat { tileStyle.tileWidth }
    private var tileHeight: CGFloat { tileStyle.tileHeight }
    private var cornerRadius: CGFloat { tileStyle.tileCornerRadius }

    private var statusColor: Color {
        switch device.status {
        case .healthy:
            return Color(red: 0.20, green: 0.72, blue: 0.34)
        case .slow:
            return Color(red: 0.86, green: 0.60, blue: 0.14)
        case .offline:
            return Color(red: 0.76, green: 0.22, blue: 0.20)
        case .unknown:
            return Color(red: 0.40, green: 0.42, blue: 0.46)
        }
    }

    private var tileFillColor: Color {
        switch device.status {
        case .healthy:
            return Color(red: 0.060, green: 0.195, blue: 0.105)
        case .slow:
            return Color(red: 0.225, green: 0.165, blue: 0.055)
        case .offline:
            return Color(red: 0.215, green: 0.060, blue: 0.060)
        case .unknown:
            return Color(red: 0.120, green: 0.125, blue: 0.135)
        }
    }

    private var iconName: String {
        switch device.deviceType {
        case .pingOnly:
            return "network"
        case .netgearSwitch:
            return "switch.2"
        }
    }

    private var shouldShowLastSeen: Bool {
        device.status == .offline || device.verificationState == .offline
    }

    private var latestValidRTT: Double? {
        if let rtt = device.lastRTT, rtt.isFinite, rtt >= 0 { return rtt }
        return device.pingRTTHistory.last(where: { $0.isFinite && $0 >= 0 })
    }

    private var lastSeenDisplayText: String {
        if let t = device.lastSeenOnline { return "Last Seen\n" + Self.lastSeenFormatter.string(from: t) }
        return "Never Seen"
    }

    private static let lastSeenFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f
    }()

    private var latencyText: String {
        if shouldShowLastSeen { return lastSeenDisplayText }
        if let rtt = latestValidRTT {
            return rtt < 10 ? String(format: "%.1f", rtt) : "\(Int(rtt.rounded()))"
        }
        return "—"
    }

    private var pingMinText: String {
        formattedPingValue(device.minimumRTT)
    }

    private var pingAvgText: String {
        formattedPingValue(device.averageRTT)
    }

    private var pingMaxText: String {
        formattedPingValue(device.maximumRTT)
    }

    private func formattedPingValue(_ value: Double?) -> String {
        guard device.status != .offline else { return "—" }
        guard let value else { return "—" }

        if value < 10 {
            return String(format: "%.1f", value)
        }

        return "\(Int(value.rounded()))"
    }

    private var temperatureText: String {
        guard device.deviceType == .netgearSwitch else {
            return "—°C"
        }

        guard let temp = device.switchTelemetry.temperatureCelsius else {
            return "—°C"
        }

        return "\(Int(temp.rounded()))°C"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tileFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: isSelected ? tileStyle.selectedBorderWidth : tileStyle.normalBorderWidth)
                )
                .overlay(selectionGlow)
                .shadow(
                    color: .black.opacity(isSelected ? tileStyle.selectedShadowOpacity : tileStyle.normalShadowOpacity),
                    radius: isSelected ? tileStyle.selectedShadowRadius : tileStyle.normalShadowRadius,
                    x: 0,
                    y: isSelected ? tileStyle.selectedShadowYOffset : tileStyle.normalShadowYOffset
                )
                .shadow(color: statusColor.opacity(statusGlowOpacity), radius: statusGlowRadius, x: 0, y: 0)

            tileContent
                .padding(.horizontal, tileStyle.tileHorizontalPadding)
                .padding(.top, tileStyle.tileTopPadding)
                .padding(.bottom, tileStyle.tileBottomPadding)

            heartbeatIndicator
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, tileStyle.statusTrailingPadding)
                .allowsHitTesting(false)
        }
        .frame(width: tileWidth, height: tileHeight)
        .overlay(alignment: .leading) {
            if let zone = device.zoneName, !zone.isEmpty {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(zoneColor(for: zone))
                    .frame(width: 3)
                    .padding(.vertical, 6)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if device.switchTelemetry.stpIsRootBridge {
                Text("ROOT")
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.yellow, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                    .padding(5)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .animation(.easeOut(duration: 0.16), value: isSelected)
        .animation(.easeOut(duration: 0.16), value: device.status)
        .onChange(of: device.pingPulseID) { _, _ in
            runSinglePingRipple()
        }
        .onAppear {
            if device.pingPulseID > 0 {
                runSinglePingRipple()
            }
        }
        .help(helpText)
    }

    private var helpText: String {
        if shouldShowTemperatureBadge {
            return "\(device.displayName) · Ping: \(device.status.label) · \(latencyText) · Temp: \(temperatureText)"
        }

        return "\(device.displayName) · Ping: \(device.status.label) · \(latencyText)"
    }

    private var tileContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(device.displayName)
                .font(.system(size: tileStyle.titleSize, weight: tileStyle.titleBold ? .semibold : .regular, design: .rounded))
                .italicIf(tileStyle.titleItalic)
                .foregroundStyle(.white.opacity(tileStyle.titleOpacity))
                .lineLimit(1)
                .minimumScaleFactor(tileStyle.titleMinimumScale)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, tileStyle.titleTrailingPadding)
                .padding(.top, tileStyle.titleTopSpacing)

            Text(device.ipAddress)
                .font(.system(size: tileStyle.ipSize, weight: tileStyle.ipBold ? .semibold : .regular, design: .rounded))
                .italicIf(tileStyle.ipItalic)
                .foregroundStyle(.white.opacity(tileStyle.ipOpacity))
                .lineLimit(1)
                .minimumScaleFactor(tileStyle.ipMinimumScale)
                .truncationMode(.middle)
                .padding(.top, tileStyle.ipTopSpacing)
                .padding(.trailing, tileStyle.ipTrailingPadding)

            if shouldShowSecondaryDetail {
                HStack(spacing: tileStyle.typeIconSpacing) {
                    Image(systemName: iconName)
                        .font(.system(size: tileStyle.typeIconSize, weight: .regular))
                        .foregroundStyle(.white.opacity(tileStyle.typeOpacity))
                        .frame(width: tileStyle.typeIconWidth)

                    Text(device.deviceType.label)
                        .font(.system(size: tileStyle.typeSize, weight: tileStyle.typeBold ? .semibold : .regular, design: .rounded))
                        .italicIf(tileStyle.typeItalic)
                        .foregroundStyle(.white.opacity(tileStyle.typeOpacity))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .truncationMode(.tail)
                }
                .padding(.top, tileStyle.typeTopSpacing)
                .padding(.trailing, tileStyle.typeTrailingPadding)
            }

            Spacer(minLength: 0)

            HStack(alignment: .bottom, spacing: tileStyle.bottomRowSpacing) {
                pingBadge

                if shouldShowTemperatureBadge {
                    Spacer(minLength: tileStyle.bottomRowSpacerMinLength)
                    tempBadge
                }
            }
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentColor.opacity(tileStyle.selectedBorderOpacity)
        }

        return Color.white.opacity(tileStyle.normalBorderOpacity)
    }

    private var statusGlowOpacity: Double {
        switch device.status {
        case .healthy:
            return 0.22
        case .slow:
            return 0.28
        case .offline:
            return 0.30
        case .unknown:
            return 0.10
        }
    }

    private var statusGlowRadius: CGFloat {
        switch device.status {
        case .unknown:
            return 2
        default:
            return 7
        }
    }

    @ViewBuilder
    private var selectionGlow: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.accentColor.opacity(tileStyle.selectedGlowOpacity), lineWidth: tileStyle.selectedGlowWidth)
                .blur(radius: tileStyle.selectedGlowBlur)
        }
    }

    private var heartbeatIndicator: some View {
        ZStack {
            Circle()
                .stroke(statusColor.opacity(pulseOpacity), lineWidth: tileStyle.statusRippleLineWidth)
                .frame(width: tileStyle.statusRippleSize, height: tileStyle.statusRippleSize)
                .scaleEffect(pulseScale)

            Circle()
                .fill(Color.black.opacity(tileStyle.statusBackgroundOpacity))
                .frame(width: tileStyle.statusBackgroundSize, height: tileStyle.statusBackgroundSize)

            Circle()
                .fill(statusColor)
                .frame(width: tileStyle.statusIconSize, height: tileStyle.statusIconSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(tileStyle.statusIconBorderOpacity), lineWidth: tileStyle.statusIconBorderWidth)
                )
                .shadow(color: statusColor.opacity(0.78), radius: tileStyle.statusShadowRadius, x: 0, y: 0)
        }
        .frame(width: tileStyle.statusOuterFrameSize, height: tileStyle.statusOuterFrameSize)
        .accessibilityLabel("Ping status \(device.status.label)")
    }

    private func runSinglePingRipple() {
        pulseScale = 0.45
        pulseOpacity = device.status == .offline ? 0.42 : 0.84

        withAnimation(.easeOut(duration: 0.82)) {
            pulseScale = 1.55
            pulseOpacity = 0.0
        }
    }

    private var shouldShowTemperatureBadge: Bool {
        device.deviceType == .netgearSwitch
    }

    private var tempBadge: some View {
        Text(temperatureText)
            .font(.system(size: tileStyle.temperatureSize, weight: tileStyle.temperatureBold ? .semibold : .regular, design: .rounded))
            .italicIf(tileStyle.temperatureItalic)
            .foregroundStyle(temperatureColor)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, tileStyle.temperatureBoxHorizontalPadding)
            .padding(.vertical, tileStyle.temperatureBoxVerticalPadding)
            .background(.black.opacity(tileStyle.temperatureBoxOpacity), in: RoundedRectangle(cornerRadius: tileStyle.temperatureBoxCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: tileStyle.temperatureBoxCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(tileStyle.temperatureBorderOpacity), lineWidth: 1)
            )
    }

    private var pingBadge: some View {
        Group {
            if shouldShowLastSeen {
                Text(latencyText)
                    .font(.system(size: max(7, tileStyle.pingValueSize * 0.78), weight: tileStyle.pingValueBold ? .semibold : .regular, design: .monospaced))
                    .italicIf(tileStyle.pingValueItalic)
                    .foregroundStyle(.white.opacity(tileStyle.pingValueOpacity))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.58)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(latencyText)
                        .font(.system(size: tileStyle.pingValueSize, weight: tileStyle.pingValueBold ? .semibold : .regular, design: .rounded))
                        .italicIf(tileStyle.pingValueItalic)
                        .foregroundStyle(.white.opacity(tileStyle.pingValueOpacity))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("ms")
                        .font(.system(size: tileStyle.pingHeaderSize, weight: tileStyle.pingHeaderBold ? .semibold : .regular, design: .rounded))
                        .italicIf(tileStyle.pingHeaderItalic)
                        .foregroundStyle(.white.opacity(tileStyle.pingHeaderOpacity))
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, tileStyle.pingBoxHorizontalPadding)
        .padding(.vertical, tileStyle.pingBoxVerticalPadding)
        .background(.black.opacity(tileStyle.pingBoxOpacity), in: RoundedRectangle(cornerRadius: tileStyle.pingBoxCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: tileStyle.pingBoxCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(tileStyle.pingBorderOpacity), lineWidth: 1)
        )
        .accessibilityLabel("Ping latency \(latencyText)")
    }

    private static let zoneColors: [Color] = [.cyan, .purple, .orange, .mint, .pink, .indigo, .yellow, .teal]

    private func zoneColor(for name: String) -> Color {
        Self.zoneColors[abs(name.hashValue) % Self.zoneColors.count]
    }

    private var temperatureColor: Color {
        guard device.deviceType == .netgearSwitch else {
            return .white.opacity(0.36)
        }

        guard let temp = device.switchTelemetry.temperatureCelsius else {
            return .white.opacity(0.46)
        }

        if temp >= 70 { return Color(red: 1.00, green: 0.30, blue: 0.26) }
        if temp >= 55 { return Color(red: 1.00, green: 0.66, blue: 0.18) }
        return Color(red: 0.34, green: 0.86, blue: 0.44)
    }
}

private struct FibreTopologyHUD: View {
    @ObservedObject var store: DeviceStore

    private var links: [FibreLossResult] {
        store.cachedFibreResults
    }

    private var lldpCount: Int {
        store.devices.reduce(0) { $0 + $1.switchTelemetry.lldpNeighbours.count }
    }

    private var sfpCount: Int {
        store.devices.reduce(0) { $0 + $1.switchTelemetry.fibrePorts.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Fibre Topology")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Links: \(links.count)   LLDP: \(lldpCount)   SFP: \(sfpCount)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            if links.isEmpty && lldpCount > 0 {
                Text("LLDP seen — rename Mping devices to match LLDP system names to draw links")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.orange.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 290, alignment: .leading)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

private struct WorkspaceEventCatcher: NSViewRepresentable {
    let isSnapToGridEnabled: Bool
    let gridSize: CGFloat
    let hasSelection: Bool
    let hasClipboardContent: Bool
    let onScroll: (Double) -> Void
    let onRightPan: (CGSize) -> Void
    let onToggleSnapToGrid: () -> Void
    let onSetGridSize: (CGFloat) -> Void
    let onCopySelection: () -> Void
    let onPaste: () -> Void
    var onClearTopologyLinks: (() -> Void)?
    var deviceAt: ((CGPoint) -> MonitoredDevice?)?
    var onOpenWebInterface: ((UUID) -> Void)?
    var onSelectDevice: ((UUID) -> Void)?
    var onCopyDevice: ((UUID) -> Void)?
    var onCutDevice: ((UUID) -> Void)?
    var onDuplicateDevice: ((UUID) -> Void)?
    var onDeleteDevice: ((UUID) -> Void)?

    func makeNSView(context: Context) -> WorkspaceEventNSView {
        let view = WorkspaceEventNSView()
        apply(to: view)
        return view
    }

    func updateNSView(_ nsView: WorkspaceEventNSView, context: Context) {
        apply(to: nsView)
    }

    private func apply(to view: WorkspaceEventNSView) {
        view.isSnapToGridEnabled = isSnapToGridEnabled
        view.gridSize = gridSize
        view.hasSelection = hasSelection
        view.hasClipboardContent = hasClipboardContent
        view.onClearTopologyLinks = onClearTopologyLinks
        view.onScroll = onScroll
        view.onRightPan = onRightPan
        view.onToggleSnapToGrid = onToggleSnapToGrid
        view.onSetGridSize = onSetGridSize
        view.onCopySelection = onCopySelection
        view.onPaste = onPaste
        view.deviceAt = deviceAt
        view.onOpenWebInterface = onOpenWebInterface
        view.onSelectDevice = onSelectDevice
        view.onCopyDevice = onCopyDevice
        view.onCutDevice = onCutDevice
        view.onDuplicateDevice = onDuplicateDevice
        view.onDeleteDevice = onDeleteDevice
    }

    final class WorkspaceEventNSView: NSView {
        var isSnapToGridEnabled: Bool = false
        var gridSize: CGFloat = 40
        var hasSelection: Bool = false
        var hasClipboardContent: Bool = false
        var onScroll: ((Double) -> Void)?
        var onRightPan: ((CGSize) -> Void)?
        var onToggleSnapToGrid: (() -> Void)?
        var onSetGridSize: ((CGFloat) -> Void)?
        var onCopySelection: (() -> Void)?
        var onPaste: (() -> Void)?
        var onClearTopologyLinks: (() -> Void)?
        var deviceAt: ((CGPoint) -> MonitoredDevice?)?
        var onOpenWebInterface: ((UUID) -> Void)?
        var onSelectDevice: ((UUID) -> Void)?
        var onCopyDevice: ((UUID) -> Void)?
        var onCutDevice: ((UUID) -> Void)?
        var onDuplicateDevice: ((UUID) -> Void)?
        var onDeleteDevice: ((UUID) -> Void)?

        private var monitor: Any?
        private var lastRightPoint: NSPoint?
        private var rightMouseDownEvent: NSEvent?
        private var didRightDrag = false
        private var menuTargets: [MenuActionTarget] = []

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            if window != nil {
                installMonitor()
            } else {
                removeMonitor()
            }
        }

        deinit {
            removeMonitor()
        }

        private func installMonitor() {
            removeMonitor()

            monitor = NSEvent.addLocalMonitorForEvents(
                matching: [.rightMouseDown, .rightMouseDragged, .rightMouseUp, .scrollWheel]
            ) { [weak self] event in
                guard let self, let window = self.window else { return event }
                guard event.window === window else { return event }

                if PanelInteractionRegistry.isPointInsideBlockedPanel(event.locationInWindow) {
                    self.lastRightPoint = nil
                    self.rightMouseDownEvent = nil
                    self.didRightDrag = false
                    return event
                }

                let localPoint = self.convert(event.locationInWindow, from: nil)
                guard self.bounds.contains(localPoint) else {
                    self.lastRightPoint = nil
                    self.rightMouseDownEvent = nil
                    self.didRightDrag = false
                    return event
                }

                switch event.type {
                case .scrollWheel:
                    self.onScroll?(event.scrollingDeltaY)
                    return nil

                case .rightMouseDown:
                    self.lastRightPoint = event.locationInWindow
                    self.rightMouseDownEvent = event
                    self.didRightDrag = false
                    return nil

                case .rightMouseDragged:
                    let current = event.locationInWindow

                    if let down = self.rightMouseDownEvent {
                        let dx = current.x - down.locationInWindow.x
                        let dy = current.y - down.locationInWindow.y
                        if abs(dx) > 3 || abs(dy) > 3 {
                            self.didRightDrag = true
                        }
                    }

                    if let last = self.lastRightPoint {
                        self.onRightPan?(
                            CGSize(
                                width: current.x - last.x,
                                height: last.y - current.y
                            )
                        )
                    }

                    self.lastRightPoint = current
                    return nil

                case .rightMouseUp:
                    if !self.didRightDrag,
                       let downEvent = self.rightMouseDownEvent {
                        self.showWorkspaceMenu(for: downEvent)
                    }

                    self.lastRightPoint = nil
                    self.rightMouseDownEvent = nil
                    self.didRightDrag = false
                    return nil

                default:
                    return event
                }
            }
        }

        private func showWorkspaceMenu(for event: NSEvent) {
            menuTargets.removeAll()

            let localPoint = convert(event.locationInWindow, from: nil)
            let swiftUIPoint = CGPoint(x: localPoint.x, y: bounds.height - localPoint.y)

            if let device = deviceAt?(swiftUIPoint) {
                showDeviceMenu(for: device, with: event)
            } else {
                showCanvasMenu(for: event)
            }
        }

        private func showDeviceMenu(for device: MonitoredDevice, with event: NSEvent) {
            let menu = NSMenu()

            addMenuItem(
                to: menu,
                title: "Open Web Interface",
                isEnabled: !device.effectiveWebInterfacePath.isEmpty,
                action: { [weak self] in self?.onOpenWebInterface?(device.id) }
            )

            menu.addItem(.separator())

            addMenuItem(to: menu, title: "Select",
                action: { [weak self] in self?.onSelectDevice?(device.id) }
            )

            menu.addItem(.separator())

            addMenuItem(to: menu, title: "Copy",
                action: { [weak self] in self?.onCopyDevice?(device.id) }
            )

            addMenuItem(to: menu, title: "Cut",
                action: { [weak self] in self?.onCutDevice?(device.id) }
            )

            addMenuItem(to: menu, title: "Duplicate",
                action: { [weak self] in self?.onDuplicateDevice?(device.id) }
            )

            menu.addItem(.separator())

            addMenuItem(to: menu, title: "Paste",
                isEnabled: hasClipboardContent,
                action: { [weak self] in self?.onPaste?() }
            )

            menu.addItem(.separator())

            let deleteItem = NSMenuItem(title: "Delete", action: nil, keyEquivalent: "")
            deleteItem.attributedTitle = NSAttributedString(
                string: "Delete",
                attributes: [.foregroundColor: NSColor.systemRed]
            )
            let deleteTarget = MenuActionTarget { [weak self] in self?.onDeleteDevice?(device.id) }
            menuTargets.append(deleteTarget)
            deleteItem.target = deleteTarget
            deleteItem.action = #selector(MenuActionTarget.runMenuAction)
            menu.addItem(deleteItem)

            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }

        private func showCanvasMenu(for event: NSEvent) {
            let menu = NSMenu()

            addMenuItem(
                to: menu,
                title: "Snap to Grid",
                state: isSnapToGridEnabled ? .on : .off,
                action: { [weak self] in self?.onToggleSnapToGrid?() }
            )

            let gridMenu = NSMenu()
            for size in [20, 40, 80] as [CGFloat] {
                addMenuItem(
                    to: gridMenu,
                    title: "\(Int(size)) px",
                    state: Int(gridSize) == Int(size) ? .on : .off,
                    action: { [weak self] in self?.onSetGridSize?(size) }
                )
            }

            let gridItem = NSMenuItem(title: "Grid Size", action: nil, keyEquivalent: "")
            menu.setSubmenu(gridMenu, for: gridItem)
            menu.addItem(gridItem)
            menu.addItem(.separator())

            addMenuItem(
                to: menu,
                title: "Copy Selection",
                isEnabled: hasSelection,
                action: { [weak self] in self?.onCopySelection?() }
            )

            addMenuItem(
                to: menu,
                title: "Paste",
                action: { [weak self] in self?.onPaste?() }
            )

            menu.addItem(.separator())

            addMenuItem(
                to: menu,
                title: "Clear All Topology Links",
                action: { [weak self] in self?.onClearTopologyLinks?() }
            )

            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }

        private func addMenuItem(
            to menu: NSMenu,
            title: String,
            state: NSControl.StateValue = .off,
            isEnabled: Bool = true,
            action: @escaping () -> Void
        ) {
            let target = MenuActionTarget(action: action)
            menuTargets.append(target)

            let item = NSMenuItem(title: title, action: #selector(MenuActionTarget.runMenuAction), keyEquivalent: "")
            item.target = target
            item.state = state
            item.isEnabled = isEnabled
            menu.addItem(item)
        }

        private func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }
}

private final class MenuActionTarget: NSObject {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    @objc func runMenuAction() {
        action()
    }
}
