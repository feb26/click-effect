import AppKit
import QuartzCore

/// Ring firework: tiny sparkle dots expand outward in a clean ring
/// shape, with a faint circle outline. Lightweight and geometric.
struct RingEffect: ClickEffect {
    var baseRadius: CGFloat = 55
    var baseDuration: CFTimeInterval = 0.35
    var dotCount: Int = 28

    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
        let radius = baseRadius * config.sizeScale
        let speed = max(0.1, Double(config.speedScale))
        let duration = baseDuration / speed
        let count = min(48, max(12, Int(CGFloat(dotCount) * config.intensity)))

        let container = CALayer()
        let size = radius * 2 + 10
        container.frame = CGRect(
            x: point.x - size / 2,
            y: point.y - size / 2,
            width: size,
            height: size
        )
        hostLayer.addSublayer(container)
        let center = CGPoint(x: size / 2, y: size / 2)

        // Small dots arranged in a ring
        for i in 0..<count {
            let angle = (CGFloat(i) / CGFloat(count)) * 2 * .pi
            let cosA = cos(angle)
            let sinA = sin(angle)

            let endPt = CGPoint(
                x: center.x + cosA * radius,
                y: center.y + sinA * radius
            )

            let dotSize: CGFloat = 2.5 * config.sizeScale
            let dot = CALayer()
            dot.frame = CGRect(
                x: center.x - dotSize / 2,
                y: center.y - dotSize / 2,
                width: dotSize,
                height: dotSize
            )
            dot.cornerRadius = dotSize / 2
            dot.backgroundColor = config.color

            let move = CABasicAnimation(keyPath: "position")
            move.fromValue = NSValue(point: NSPoint(x: center.x, y: center.y))
            move.toValue = NSValue(point: NSPoint(x: endPt.x, y: endPt.y))

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.0
            fade.beginTime = duration * 0.5
            fade.duration = duration * 0.5

            let group = CAAnimationGroup()
            group.animations = [move, fade]
            group.duration = duration
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            group.isRemovedOnCompletion = false
            group.fillMode = .forwards

            dot.add(group, forKey: "ring")
            container.addSublayer(dot)
        }

        // Expanding ring outline
        let ring = CAShapeLayer()
        ring.frame = container.bounds

        let smallRing = CGPath(
            ellipseIn: CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4),
            transform: nil
        )
        let bigRing = CGPath(
            ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ),
            transform: nil
        )
        ring.path = smallRing
        ring.strokeColor = config.color.copy(alpha: 0.35)
        ring.fillColor = nil
        ring.lineWidth = 1.0

        let ringExpand = CABasicAnimation(keyPath: "path")
        ringExpand.fromValue = smallRing
        ringExpand.toValue = bigRing

        let ringFade = CABasicAnimation(keyPath: "opacity")
        ringFade.fromValue = 0.5
        ringFade.toValue = 0.0

        let ringGroup = CAAnimationGroup()
        ringGroup.animations = [ringExpand, ringFade]
        ringGroup.duration = duration * 0.7
        ringGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        ringGroup.isRemovedOnCompletion = false
        ringGroup.fillMode = .forwards

        ring.add(ringGroup, forKey: "expand")
        container.addSublayer(ring)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            container.removeFromSuperlayer()
        }
    }
}
