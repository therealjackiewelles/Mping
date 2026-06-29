import SwiftUI
import AppKit
import QuartzCore

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

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

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

// MARK: - PingRippleLayerView
// CALayer-based ping ripple — fires a one-shot CAAnimationGroup on the GPU render server
// when pulseID changes, replacing @State + withAnimation which drove SwiftUI re-renders
// on every animation frame.
struct PingRippleLayerView: NSViewRepresentable {
    var color: Color
    var rippleSize: CGFloat
    var lineWidth: CGFloat
    var startOpacity: Float
    var pulseID: Int

    func makeNSView(context: Context) -> PingRippleNSView { PingRippleNSView() }
    func updateNSView(_ view: PingRippleNSView, context: Context) {
        view.update(
            color: NSColor(color),
            rippleSize: rippleSize,
            lineWidth: lineWidth,
            startOpacity: startOpacity,
            pulseID: pulseID
        )
    }

    final class PingRippleNSView: NSView {
        private let rippleLayer = CAShapeLayer()
        private var lastPulseID = -1
        private var storedRippleSize: CGFloat = 0

        override init(frame: CGRect) {
            super.init(frame: frame)
            wantsLayer = true
            rippleLayer.fillColor = nil
            rippleLayer.opacity = 0
            layer?.addSublayer(rippleLayer)
        }
        required init?(coder: NSCoder) { fatalError() }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        func update(color: NSColor, rippleSize: CGFloat, lineWidth: CGFloat, startOpacity: Float, pulseID: Int) {
            rippleLayer.strokeColor = color.cgColor
            rippleLayer.lineWidth = lineWidth
            if rippleSize != storedRippleSize {
                storedRippleSize = rippleSize
                refreshPath()
            }
            guard pulseID != lastPulseID && pulseID > 0 else { return }
            lastPulseID = pulseID
            fireRipple(startOpacity: startOpacity)
        }

        private func refreshPath() {
            guard let hostLayer = layer else { return }
            rippleLayer.frame = hostLayer.bounds
            let cx = hostLayer.bounds.midX
            let cy = hostLayer.bounds.midY
            let r = storedRippleSize / 2
            rippleLayer.path = CGPath(ellipseIn: CGRect(x: cx - r, y: cy - r, width: storedRippleSize, height: storedRippleSize), transform: nil)
        }

        private func fireRipple(startOpacity: Float) {
            rippleLayer.removeAllAnimations()

            let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
            scaleAnim.fromValue = 0.45
            scaleAnim.toValue = 1.55

            let opacityAnim = CABasicAnimation(keyPath: "opacity")
            opacityAnim.fromValue = startOpacity
            opacityAnim.toValue = Float(0)

            let group = CAAnimationGroup()
            group.animations = [scaleAnim, opacityAnim]
            group.duration = 0.82
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            group.fillMode = .backwards
            group.isRemovedOnCompletion = true
            rippleLayer.add(group, forKey: "pingRipple")
        }

        override func layout() {
            super.layout()
            guard let hostLayer = layer else { return }
            hostLayer.frame = bounds
            refreshPath()
        }
    }
}
