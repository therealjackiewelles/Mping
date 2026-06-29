import SwiftUI
import AppKit

// CALayer-based pulsing border — zero SwiftUI re-renders per frame.
// Replaces @State-driven repeatForever animations that caused ViewGraph to
// re-evaluate at 60fps for every view carrying the animation.
struct PulsingBorderView: NSViewRepresentable {
    var color: NSColor
    var lineWidth: CGFloat
    var cornerRadius: CGFloat
    var minOpacity: Float = 0.10
    var maxOpacity: Float = 0.85
    var duration: Double = 1.4

    func makeNSView(context: Context) -> PulsingBorderNSView { PulsingBorderNSView() }

    func updateNSView(_ view: PulsingBorderNSView, context: Context) {
        view.configure(
            color: color,
            lineWidth: lineWidth,
            cornerRadius: cornerRadius,
            minOpacity: minOpacity,
            maxOpacity: maxOpacity,
            duration: duration
        )
    }

    final class PulsingBorderNSView: NSView {
        private let shapeLayer = CAShapeLayer()
        private var storedCornerRadius: CGFloat = 8

        override init(frame: CGRect) {
            super.init(frame: frame)
            wantsLayer = true
            shapeLayer.fillColor = nil
            layer?.addSublayer(shapeLayer)
        }
        required init?(coder: NSCoder) { fatalError() }

        func configure(color: NSColor, lineWidth: CGFloat, cornerRadius: CGFloat,
                       minOpacity: Float, maxOpacity: Float, duration: Double) {
            storedCornerRadius = cornerRadius
            shapeLayer.strokeColor = color.cgColor
            shapeLayer.lineWidth = lineWidth
            refreshPath()

            shapeLayer.removeAllAnimations()
            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue = minOpacity
            anim.toValue = maxOpacity
            anim.duration = duration
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            anim.repeatCount = .infinity
            anim.autoreverses = true
            shapeLayer.add(anim, forKey: "pulse")
        }

        override func layout() {
            super.layout()
            refreshPath()
        }

        private func refreshPath() {
            guard let layer = self.layer else { return }
            shapeLayer.frame = layer.bounds
            let inset = shapeLayer.lineWidth / 2
            let rect = layer.bounds.insetBy(dx: inset, dy: inset)
            shapeLayer.path = CGPath(
                roundedRect: rect,
                cornerWidth: storedCornerRadius,
                cornerHeight: storedCornerRadius,
                transform: nil
            )
        }
    }
}
