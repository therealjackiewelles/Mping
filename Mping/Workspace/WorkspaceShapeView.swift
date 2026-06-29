import SwiftUI
import AppKit

enum ShapeResizeAnchor: String, CaseIterable, Sendable {
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left

    var movesLeftEdge: Bool {
        self == .topLeft || self == .left || self == .bottomLeft
    }

    var movesTopEdge: Bool {
        self == .topLeft || self == .top || self == .topRight
    }

    var cursor: NSCursor {
        switch self {
        case .left, .right:
            return .resizeLeftRight
        case .top, .bottom:
            return .resizeUpDown
        case .topLeft, .bottomRight:
            return DiagonalResizeCursor.northWestSouthEast
        case .topRight, .bottomLeft:
            return DiagonalResizeCursor.northEastSouthWest
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .topLeft: return .topLeading
        case .top: return .top
        case .topRight: return .topTrailing
        case .right: return .trailing
        case .bottomRight: return .bottomTrailing
        case .bottom: return .bottom
        case .bottomLeft: return .bottomLeading
        case .left: return .leading
        }
    }

    var hotspotSize: CGSize {
        switch self {
        case .top, .bottom:
            return CGSize(width: 44, height: 12)
        case .left, .right:
            return CGSize(width: 12, height: 44)
        default:
            return CGSize(width: 26, height: 26)
        }
    }

    var hotspotOffset: CGSize {
        switch self {
        case .topLeft: return CGSize(width: -7, height: -7)
        case .top: return CGSize(width: 0, height: -6)
        case .topRight: return CGSize(width: 7, height: -7)
        case .right: return CGSize(width: 6, height: 0)
        case .bottomRight: return CGSize(width: 7, height: 7)
        case .bottom: return CGSize(width: 0, height: 6)
        case .bottomLeft: return CGSize(width: -7, height: 7)
        case .left: return CGSize(width: -6, height: 0)
        }
    }
}

struct WorkspaceShapeView: View {
    let shape: WorkspaceShape
    let isSelected: Bool
    var tint: Color? = nil
    let onResizeStart: () -> Void
    let onResize: (ShapeResizeAnchor, CGSize) -> Void
    let onResizeEnd: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isSelected ? Color.white.opacity(0.85) : Color.white.opacity(0.22),
                            lineWidth: isSelected ? 2 : 1
                        )
                )

            if let tint {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint)
                    .allowsHitTesting(false)
            }

            Text(shape.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .padding(12)
        }
        .frame(width: shape.width, height: shape.height)
        .overlay {
            if isSelected {
                resizeHotspots
            }
        }
    }

    private var resizeHotspots: some View {
        ZStack {
            ForEach(ShapeResizeAnchor.allCases, id: \.rawValue) { anchor in
                ResizeHotspot(
                    anchor: anchor,
                    onResizeStart: onResizeStart,
                    onResize: onResize,
                    onResizeEnd: onResizeEnd
                )
                .frame(width: anchor.hotspotSize.width, height: anchor.hotspotSize.height)
                .offset(anchor.hotspotOffset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: anchor.frameAlignment)
            }
        }
    }
}

private struct ResizeHotspot: NSViewRepresentable {
    let anchor: ShapeResizeAnchor
    let onResizeStart: () -> Void
    let onResize: (ShapeResizeAnchor, CGSize) -> Void
    let onResizeEnd: () -> Void

    func makeNSView(context: Context) -> ResizeHotspotNSView {
        let view = ResizeHotspotNSView()
        view.anchor = anchor
        view.onResizeStart = onResizeStart
        view.onResize = onResize
        view.onResizeEnd = onResizeEnd
        return view
    }

    func updateNSView(_ nsView: ResizeHotspotNSView, context: Context) {
        nsView.anchor = anchor
        nsView.onResizeStart = onResizeStart
        nsView.onResize = onResize
        nsView.onResizeEnd = onResizeEnd
        nsView.window?.invalidateCursorRects(for: nsView)
        nsView.updateTrackingAreasIfNeeded()
    }

    final class ResizeHotspotNSView: NSView {
        var anchor: ShapeResizeAnchor = .bottomRight
        var onResizeStart: (() -> Void)?
        var onResize: ((ShapeResizeAnchor, CGSize) -> Void)?
        var onResizeEnd: (() -> Void)?

        private var dragStartLocation: NSPoint?
        private var trackingAreaRef: NSTrackingArea?

        override var acceptsFirstResponder: Bool { true }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            updateTrackingAreasIfNeeded()
            window?.invalidateCursorRects(for: self)
        }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: anchor.cursor)
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            bounds.contains(point) ? self : nil
        }

        func updateTrackingAreasIfNeeded() {
            if let trackingAreaRef {
                removeTrackingArea(trackingAreaRef)
            }

            let area = NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow, .inVisibleRect],
                owner: self,
                userInfo: nil
            )

            addTrackingArea(area)
            trackingAreaRef = area
        }

        override func mouseEntered(with event: NSEvent) {
            anchor.cursor.set()
        }

        override func mouseMoved(with event: NSEvent) {
            anchor.cursor.set()
        }

        override func mouseExited(with event: NSEvent) {
            NSCursor.arrow.set()
        }

        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(self)
            dragStartLocation = event.locationInWindow
            anchor.cursor.set()
            onResizeStart?()
        }

        override func mouseDragged(with event: NSEvent) {
            guard let dragStartLocation else { return }

            let dx = event.locationInWindow.x - dragStartLocation.x
            let dy = dragStartLocation.y - event.locationInWindow.y

            onResize?(anchor, CGSize(width: dx, height: dy))
            anchor.cursor.set()
        }

        override func mouseUp(with event: NSEvent) {
            dragStartLocation = nil
            anchor.cursor.set()
            onResizeEnd?()
        }
    }
}

private enum DiagonalResizeCursor {
    static let northWestSouthEast: NSCursor = makeCursor(direction: .northWestSouthEast)
    static let northEastSouthWest: NSCursor = makeCursor(direction: .northEastSouthWest)

    private enum Direction {
        case northWestSouthEast
        case northEastSouthWest
    }

    private static func makeCursor(direction: Direction) -> NSCursor {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let path = NSBezierPath()
        path.lineWidth = 2.2
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        let a: NSPoint
        let b: NSPoint

        switch direction {
        case .northWestSouthEast:
            a = NSPoint(x: 4, y: 14)
            b = NSPoint(x: 14, y: 4)
        case .northEastSouthWest:
            a = NSPoint(x: 14, y: 14)
            b = NSPoint(x: 4, y: 4)
        }

        NSColor.white.setStroke()
        path.move(to: a)
        path.line(to: b)
        path.stroke()

        drawArrowHead(at: a, toward: b)
        drawArrowHead(at: b, toward: a)

        image.unlockFocus()
        return NSCursor(image: image, hotSpot: NSPoint(x: 9, y: 9))
    }

    private static func drawArrowHead(at tip: NSPoint, toward other: NSPoint) {
        let angle = atan2(other.y - tip.y, other.x - tip.x)
        let length: CGFloat = 5
        let spread: CGFloat = .pi / 5

        let p1 = NSPoint(
            x: tip.x + cos(angle + spread) * length,
            y: tip.y + sin(angle + spread) * length
        )
        let p2 = NSPoint(
            x: tip.x + cos(angle - spread) * length,
            y: tip.y + sin(angle - spread) * length
        )

        let path = NSBezierPath()
        path.lineWidth = 2.0
        path.lineCapStyle = .round
        path.move(to: p1)
        path.line(to: tip)
        path.line(to: p2)
        NSColor.white.setStroke()
        path.stroke()
    }
}
