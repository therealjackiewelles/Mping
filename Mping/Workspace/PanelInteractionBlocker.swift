import SwiftUI
import AppKit

// WorkspaceEventNSView intercepts ALL right-mouse events via NSEvent.addLocalMonitorForEvents
// at the window level — it never sees which SwiftUI view the click landed on. Without this
// registry, right-clicking anywhere in the window (including the sidebar or inspector) would
// be captured by the workspace event handler and treated as a canvas right-click.
//
// PanelInteractionBlocker is placed inside each panel (sidebar, inspector). It tracks the
// panel's current frame in window coordinates. WorkspaceEventNSView checks the registry before
// acting on any right-click: if the click point is inside a registered panel rect, it returns
// nil from the monitor (allowing normal AppKit/SwiftUI handling) instead of showing the canvas
// context menu.
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
