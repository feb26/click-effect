import AppKit
import QuartzCore

/// Filled translucent circle that scales up and fades out.
struct PulseEffect: ClickEffect {
    var baseRadius: CGFloat = 38
    var baseDuration: CFTimeInterval = 0.25
    var fillAlpha: CGFloat = 0.4

    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
        let radius = baseRadius * config.sizeScale
        let duration = baseDuration / max(0.1, Double(config.speedScale))
        let fillColor = config.color.copy(alpha: fillAlpha) ?? config.color

        let size = radius * 2
        let layer = CAShapeLayer()
        layer.frame = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: size,
            height: size
        )
        layer.path = CGPath(
            ellipseIn: CGRect(x: 0, y: 0, width: size, height: size),
            transform: nil
        )
        layer.fillColor = fillColor
        layer.strokeColor = NSColor.clear.cgColor
        layer.opacity = 1.0
        layer.setAffineTransform(CGAffineTransform(scaleX: 0.3, y: 0.3))

        hostLayer.addSublayer(layer)

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.3
        scale.toValue = 1.2

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
        layer.add(group, forKey: "pulse")
        CATransaction.commit()
    }
}
