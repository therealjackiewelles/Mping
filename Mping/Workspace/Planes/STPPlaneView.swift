import SwiftUI
import AppKit

// MARK: - STP Plane

struct STPPlaneView: View {
    @ObservedObject var store: DeviceStore

    private let canvasSize = CGSize(width: 5000, height: 3000)
    @State private var pendingZoomDelta: Double = 0
    @State private var pendingZoomPoint: CGPoint = .zero
    @State private var zoomFlushScheduled = false
    @State private var pendingPanDelta: CGSize = .zero
    @State private var panFlushScheduled = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.055, green: 0.055, blue: 0.06)
                    .ignoresSafeArea()

                ZStack(alignment: .topLeading) {
                    FibreLinksLayer(
                        devicePositions: Dictionary(uniqueKeysWithValues: store.devices.map { ($0.id, CGPoint(x: $0.x, y: $0.y)) }),
                        links: store.cachedFibreResults,
                        fibreLabelOffset: store.fibreLabelOffset,
                        setFibreLabelOffset: store.setFibreLabelOffset,
                        showLines: true,
                        showLabels: true
                    )
                    .equatable()
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .allowsHitTesting(false)

                    ForEach(store.devices) { device in
                        STPDeviceTile(device: device)
                            .position(x: device.x, y: device.y)
                    }
                }
                .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
                .scaleEffect(store.workspaceScale, anchor: .topLeading)
                .offset(store.workspaceOffset)

                STPLegend()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(12)
                    .allowsHitTesting(false)

                STPInputCatcher(
                    onScroll: { delta in
                        let point = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        queueZoom(delta: delta, around: point)
                    },
                    onRightPan: { delta in
                        queuePan(delta)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
            .clipped()
        }
    }

    private func queueZoom(delta: Double, around point: CGPoint) {
        guard delta != 0 else { return }
        pendingZoomDelta += delta
        pendingZoomPoint = point
        guard !zoomFlushScheduled else { return }
        zoomFlushScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 60.0) {
            let d = pendingZoomDelta; let p = pendingZoomPoint
            pendingZoomDelta = 0; zoomFlushScheduled = false
            guard d != 0 else { return }
            store.zoomWorkspace(by: d, around: p)
        }
    }

    private func queuePan(_ delta: CGSize) {
        guard delta.width != 0 || delta.height != 0 else { return }
        pendingPanDelta.width += delta.width
        pendingPanDelta.height += delta.height
        guard !panFlushScheduled else { return }
        panFlushScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 60.0) {
            let d = pendingPanDelta
            pendingPanDelta = .zero; panFlushScheduled = false
            guard d.width != 0 || d.height != 0 else { return }
            store.panWorkspace(by: d)
        }
    }
}

// MARK: - Device Tile

private struct STPDeviceTile: View {
    let device: MonitoredDevice

    private var isSwitch: Bool { device.deviceType == .netgearSwitch }
    private var isRoot: Bool { device.switchTelemetry.stpIsRootBridge }
    private var hasBlockingPort: Bool { !device.switchTelemetry.stpBlockedPorts.isEmpty }

    private var tileWidth: CGFloat { isSwitch ? 120 : 90 }

    private var fillColor: Color {
        if isRoot { return Color(red: 0.55, green: 0.40, blue: 0.05) }
        if hasBlockingPort { return Color(red: 0.30, green: 0.16, blue: 0.04) }
        if isSwitch { return Color(red: 0.10, green: 0.13, blue: 0.20) }
        return Color(red: 0.08, green: 0.08, blue: 0.10)
    }

    private var borderColor: Color {
        if isRoot { return Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.85) }
        if hasBlockingPort { return Color.orange.opacity(0.7) }
        if isSwitch { return Color.white.opacity(0.25) }
        return Color.white.opacity(0.10)
    }

    private var labelColor: Color {
        isSwitch ? .white.opacity(0.92) : .white.opacity(0.45)
    }

    var body: some View {
        VStack(spacing: 3) {
            if isRoot {
                Text("ROOT")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.20))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.18), in: Capsule())
            }

            Text(device.name.isEmpty ? device.ipAddress : device.name)
                .font(.system(size: isSwitch ? 11 : 9, weight: isSwitch ? .semibold : .regular, design: .rounded))
                .foregroundStyle(labelColor)
                .lineLimit(1)
                .truncationMode(.middle)

            if isSwitch {
                Text(stpStatusLabel)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(stpStatusColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, isSwitch ? 8 : 5)
        .frame(width: tileWidth)
        .background(fillColor, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: isRoot ? 1.5 : 1))
        .shadow(color: isRoot ? Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.35) : .clear, radius: 10)
    }

    private var stpStatusLabel: String {
        if isRoot { return "Root Bridge" }
        if hasBlockingPort {
            let count = device.switchTelemetry.stpBlockedPorts.count
            return count == 1 ? "1 Port Blocking" : "\(count) Ports Blocking"
        }
        return "Forwarding"
    }

    private var stpStatusColor: Color {
        if isRoot { return Color(red: 1.0, green: 0.80, blue: 0.20) }
        if hasBlockingPort { return .orange }
        return .green.opacity(0.8)
    }
}

// MARK: - Legend

private struct STPLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STP VIEW")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.40))
                .kerning(1.2)

            legendRow(color: Color(red: 1.0, green: 0.80, blue: 0.20), label: "Root Bridge")
            legendRow(color: .green, label: "Active Link")
            legendRow(color: .orange, label: "Blocking Link", dashed: true)
            legendRow(color: .white.opacity(0.45), label: "Non-Switch Device")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.10), lineWidth: 1))
    }

    private func legendRow(color: Color, label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 7) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 4, height: 2)
                    }
                }
                .frame(width: 20, alignment: .leading)
            } else {
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 20, height: 2)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
        }
    }
}

// MARK: - Input Handler

private struct STPInputCatcher: NSViewRepresentable {
    let onScroll: (Double) -> Void
    let onRightPan: (CGSize) -> Void

    func makeNSView(context: Context) -> STPInputNSView {
        let v = STPInputNSView()
        v.onScroll = onScroll
        v.onRightPan = onRightPan
        return v
    }

    func updateNSView(_ nsView: STPInputNSView, context: Context) {
        nsView.onScroll = onScroll
        nsView.onRightPan = onRightPan
    }

    final class STPInputNSView: NSView {
        var onScroll: ((Double) -> Void)?
        var onRightPan: ((CGSize) -> Void)?
        private var monitor: Any?
        private var lastRightPoint: NSPoint?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil { installMonitor() } else { removeMonitor() }
        }

        deinit { removeMonitor() }

        private func installMonitor() {
            removeMonitor()
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .rightMouseDragged, .rightMouseDown, .rightMouseUp]) { [weak self] event in
                self?.handle(event)
                return event
            }
        }

        private func removeMonitor() {
            if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
        }

        private func handle(_ event: NSEvent) {
            switch event.type {
            case .scrollWheel:
                let delta = Double(event.deltaY) * 0.06
                if delta != 0 { onScroll?(delta) }
            case .rightMouseDown:
                lastRightPoint = event.locationInWindow
            case .rightMouseDragged:
                if let last = lastRightPoint {
                    let current = event.locationInWindow
                    let dx = current.x - last.x
                    let dy = -(current.y - last.y)
                    onRightPan?(CGSize(width: dx, height: dy))
                    lastRightPoint = current
                }
            case .rightMouseUp:
                lastRightPoint = nil
            default:
                break
            }
        }

        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
}
