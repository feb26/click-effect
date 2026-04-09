import AppKit
import QuartzCore

/// Thin circle that expands outward while fading out.
struct RippleEffect: ClickEffect {
    var baseStartRadius: CGFloat = 6
    var baseEndRadius: CGFloat = 55
    var baseDuration: CFTimeInterval = 0.28
    var lineWidth: CGFloat = 3

    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
        let endRadius = baseEndRadius * config.sizeScale
        let startRadius = baseStartRadius * config.sizeScale
        let duration = baseDuration / max(0.1, Double(config.speedScale))

        let size = endRadius * 2
        let layer = CAShapeLayer()
        layer.frame = CGRect(
            x: point.x - endRadius,
            y: point.y - endRadius,
            width: size,
            height: size
        )
        layer.path = CGPath(
            ellipseIn: CGRect(x: 0, y: 0, width: size, height: size),
            transform: nil
        )
        layer.fillColor = NSColor.clear.cgColor
        layer.strokeColor = config.color
        layer.lineWidth = lineWidth * min(2.5, max(1.0, config.intensity))
        layer.opacity = 1.0

        // Start at a small scale, grow to full.
        let initialScale = startRadius / endRadius
        layer.setAffineTransform(CGAffineTransform(scaleX: initialScale, y: initialScale))

        hostLayer.addSublayer(layer)

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = initialScale
        scale.toValue = 1.0

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1.0
        fade.toValue = 0.0

        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = duration
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards

        CATransaction.begin()
        CATransaction.setCompletionBlock { layer.removeFromSuperlayer() }
        layer.add(group, forKey: "ripple")
        CATransaction.commit()
    }
}
