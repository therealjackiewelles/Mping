import SwiftUI
import AppKit

struct ScrollWheelCatcher: NSViewRepresentable {
    var onScroll: (NSEvent) -> Void

    func makeNSView(context: Context) -> WheelMonitorView {
        let view = WheelMonitorView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: WheelMonitorView, context: Context) {
        nsView.onScroll = onScroll
    }

    final class WheelMonitorView: NSView {
        var onScroll: ((NSEvent) -> Void)?
        private var localMonitor: Any?

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

            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self, self.window != nil else { return event }
                self.onScroll?(event)
                return event
            }
        }

        private func removeMonitor() {
            if let localMonitor {
                NSEvent.removeMonitor(localMonitor)
                self.localMonitor = nil
            }
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }
}
