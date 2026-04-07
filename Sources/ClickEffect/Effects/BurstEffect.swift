import AppKit
import QuartzCore

/// Short radial lines flying outward from the click point.
struct BurstEffect: ClickEffect {
    var rayCount: Int = 10
    var baseInnerRadius: CGFloat = 8
    var baseOuterRadius: CGFloat = 34
    var baseDuration: CFTimeInterval = 0.24
    var lineWidth: CGFloat = 2.5

    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
        let innerRadius = baseInnerRadius * config.sizeScale
        let outerRadius = baseOuterRadius * config.sizeScale
        let duration = baseDuration / max(0.1, Double(config.speedScale))

        // Container layer so we can remove all rays in one shot.
        let container = CALayer()
        container.frame = CGRect(
            x: point.x - outerRadius,
            y: point.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        )
        hostLayer.addSublayer(container)

        let center = CGPoint(x: outerRadius, y: outerRadius)
        let innerPadding = 6 * config.sizeScale

        for i in 0..<rayCount {
            let angle = (CGFloat(i) / CGFloat(rayCount)) * 2 * .pi
            let cosA = cos(angle)
            let sinA = sin(angle)

            let startInner = CGPoint(x: center.x + cosA * innerRadius, y: center.y + sinA * innerRadius)
            let startOuter = CGPoint(x: center.x + cosA * (innerRadius + innerPadding), y: center.y + sinA * (innerRadius + innerPadding))
            let endInner = CGPoint(x: center.x + cosA * (outerRadius - innerPadding), y: center.y + sinA * (outerRadius - innerPadding))
            let endOuter = CGPoint(x: center.x + cosA * outerRadius, y: center.y + sinA * outerRadius)

            let startPath = CGMutablePath()
            startPath.move(to: startInner)
            startPath.addLine(to: startOuter)

            let endPath = CGMutablePath()
            endPath.move(to: endInner)
            endPath.addLine(to: endOuter)

            let ray = CAShapeLayer()
            ray.frame = container.bounds
            ray.path = startPath
            ray.strokeColor = config.color
            ray.lineWidth = lineWidth
            ray.lineCap = .round
            ray.fillColor = NSColor.clear.cgColor

            let pathAnim = CABasicAnimation(keyPath: "path")
            pathAnim.fromValue = startPath
            pathAnim.toValue = endPath

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.0

            let group = CAAnimationGroup()
            group.animations = [pathAnim, fade]
            group.duration = duration
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            group.isRemovedOnCompletion = false
            group.fillMode = .forwards

            ray.add(group, forKey: "burst")
            container.addSublayer(ray)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            container.removeFromSuperlayer()
        }
    }
}
