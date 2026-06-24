import SwiftUI
import AppKit

@MainActor
enum PanelInteractionRegistry {
    private static var blockedPanelRectsByID: [String: CGRect] = [:]

    static func update(id: String, rectInWindow: CGRect?) {
        if let rectInWindow {
            blockedPanelRectsByID[id] = rectInWindow
        } else {
            blockedPanelRectsByID.removeValue(forKey: id)
        }
    }

    static func isPointInsideBlockedPanel(_ windowPoint: NSPoint) -> Bool {
        blockedPanelRectsByID.values.contains { $0.contains(windowPoint) }
    }
}

struct PanelInteractionBlocker: NSViewRepresentable {
    let id: String

    func makeNSView(context: Context) -> PanelInteractionNSView {
        let view = PanelInteractionNSView()
        view.panelID = id
        return view
    }

    func updateNSView(_ nsView: PanelInteractionNSView, context: Context) {
        nsView.panelID = id
        nsView.updateRegisteredFrame()
    }

    final class PanelInteractionNSView: NSView {
        var panelID: String = "panel"

        override var acceptsFirstResponder: Bool { true }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            updateRegisteredFrame()
        }

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            updateRegisteredFrame()
        }

        override func layout() {
            super.layout()
            updateRegisteredFrame()
        }

        override func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            updateRegisteredFrame()
        }

        override func setFrameOrigin(_ newOrigin: NSPoint) {
            super.setFrameOrigin(newOrigin)
            updateRegisteredFrame()
        }

        func updateRegisteredFrame() {
            guard window != nil else {
                PanelInteractionRegistry.update(id: panelID, rectInWindow: nil)
                return
            }

            let rect = convert(bounds, to: nil)
            PanelInteractionRegistry.update(id: panelID, rectInWindow: rect)
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            bounds.contains(point) ? self : nil
        }

        override func mouseDown(with event: NSEvent) { }
        override func rightMouseDown(with event: NSEvent) { }
        override func rightMouseDragged(with event: NSEvent) { }
        override func rightMouseUp(with event: NSEvent) { }
        override func scrollWheel(with event: NSEvent) {
            nextResponder?.scrollWheel(with: event)
        }
    }
}
