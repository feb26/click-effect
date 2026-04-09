import AppKit
import QuartzCore

/// Crossette firework: a short radial burst from the click point,
/// where each ray splits into a small fan of sub-rays at its tip —
/// creating a satisfying two-stage "pop-pop" effect.
struct CrossetteEffect: ClickEffect {
    var primaryRayCount: Int = 6
    var baseInnerRadius: CGFloat = 6
    var baseMidRadius: CGFloat = 28
    var baseOuterRadius: CGFloat = 55
    var baseDuration: CFTimeInterval = 0.40
    var splitDelay: CFTimeInterval = 0.12
    var lineWidth: CGFloat = 2.0

    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
        let midRadius = baseMidRadius * config.sizeScale
        let outerRadius = baseOuterRadius * config.sizeScale
        let innerRadius = baseInnerRadius * config.sizeScale
        let speed = max(0.1, Double(config.speedScale))
        let duration = baseDuration / speed
        let splitDelayScaled = splitDelay / speed

        let rayCount = min(16, max(4, Int(CGFloat(primaryRayCount) * config.intensity)))

        let container = CALayer()
        let size = outerRadius * 2 + 10
        container.frame = CGRect(
            x: point.x - size / 2,
            y: point.y - size / 2,
            width: size,
            height: size
        )
        hostLayer.addSublayer(container)
        let center = CGPoint(x: size / 2, y: size / 2)

        let splitPoints = playPrimaryRays(
            in: container, center: center, config: config,
            rayCount: rayCount, innerRadius: innerRadius,
            midRadius: midRadius, splitDelayScaled: splitDelayScaled
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + splitDelayScaled) {
            self.playSubRays(
                in: container, config: config, splitPoints: splitPoints,
                outerRadius: outerRadius, midRadius: midRadius,
                subDuration: (duration - splitDelayScaled) * 0.85
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            container.removeFromSuperlayer()
        }
    }

    // MARK: - Phase 1: primary rays

    private func playPrimaryRays(
        in container: CALayer, center: CGPoint, config: EffectConfig,
        rayCount: Int, innerRadius: CGFloat, midRadius: CGFloat,
        splitDelayScaled: Double
    ) -> [(CGPoint, CGFloat)] {
        var splitPoints: [(CGPoint, CGFloat)] = []

        for i in 0..<rayCount {
            let angle = (CGFloat(i) / CGFloat(rayCount)) * 2 * .pi
                + CGFloat.random(in: -0.12...0.12)
            let cosA = cos(angle)
            let sinA = sin(angle)

            let startPt = CGPoint(
                x: center.x + cosA * innerRadius,
                y: center.y + sinA * innerRadius
            )
            let midPt = CGPoint(
                x: center.x + cosA * midRadius,
                y: center.y + sinA * midRadius
            )
            splitPoints.append((midPt, angle))

            let segLen: CGFloat = 4 * config.sizeScale
            let startPath = CGMutablePath()
            startPath.move(to: startPt)
            startPath.addLine(to: CGPoint(x: startPt.x + cosA * segLen, y: startPt.y + sinA * segLen))

            let endPath = CGMutablePath()
            endPath.move(to: CGPoint(x: midPt.x - cosA * segLen, y: midPt.y - sinA * segLen))
            endPath.addLine(to: midPt)

            let ray = CAShapeLayer()
            ray.frame = container.bounds
            ray.path = startPath
            ray.strokeColor = config.color
            ray.lineWidth = lineWidth
            ray.lineCap = .round
            ray.fillColor = nil

            let pathAnim = CABasicAnimation(keyPath: "path")
            pathAnim.fromValue = startPath
            pathAnim.toValue = endPath

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.0
            fade.beginTime = splitDelayScaled * 0.8
            fade.duration = splitDelayScaled * 0.4

            let group = CAAnimationGroup()
            group.animations = [pathAnim, fade]
            group.duration = splitDelayScaled * 1.2
            group.isRemovedOnCompletion = false
            group.fillMode = .forwards

            ray.add(group, forKey: "fly")
            container.addSublayer(ray)
        }

        return splitPoints
    }

    // MARK: - Phase 2: sub-rays at split points

    private func playSubRays(
        in container: CALayer, config: EffectConfig,
        splitPoints: [(CGPoint, CGFloat)],
        outerRadius: CGFloat, midRadius: CGFloat, subDuration: Double
    ) {
        let subRayCount = 3
        let subLength = outerRadius - midRadius

        for (splitPt, baseAngle) in splitPoints {
            let spread: CGFloat = .pi * 0.4
            for j in 0..<subRayCount {
                let fraction = CGFloat(j) / CGFloat(subRayCount - 1) - 0.5
                let subAngle = baseAngle + fraction * spread
                    + CGFloat.random(in: -0.08...0.08)
                let cosB = cos(subAngle)
                let sinB = sin(subAngle)

                let subEnd = CGPoint(
                    x: splitPt.x + cosB * subLength,
                    y: splitPt.y + sinB * subLength
                )

                let segLen: CGFloat = 3 * config.sizeScale
                let startPath = CGMutablePath()
                startPath.move(to: splitPt)
                startPath.addLine(to: CGPoint(x: splitPt.x + cosB * segLen, y: splitPt.y + sinB * segLen))

                let endPath = CGMutablePath()
                endPath.move(to: CGPoint(x: subEnd.x - cosB * segLen, y: subEnd.y - sinB * segLen))
                endPath.addLine(to: subEnd)

                let ray = CAShapeLayer()
                ray.frame = container.bounds
                ray.path = startPath
                ray.strokeColor = config.color
                ray.lineWidth = lineWidth * 0.8
                ray.lineCap = .round
                ray.fillColor = nil

                let pathAnim = CABasicAnimation(keyPath: "path")
                pathAnim.fromValue = startPath
                pathAnim.toValue = endPath

                let fadeOut = CABasicAnimation(keyPath: "opacity")
                fadeOut.fromValue = 1.0
                fadeOut.toValue = 0.0
                fadeOut.beginTime = subDuration * 0.4
                fadeOut.duration = subDuration * 0.6

                let group = CAAnimationGroup()
                group.animations = [pathAnim, fadeOut]
                group.duration = subDuration
                group.timingFunction = CAMediaTimingFunction(name: .easeOut)
                group.isRemovedOnCompletion = false
                group.fillMode = .forwards

                ray.add(group, forKey: "split")
                container.addSublayer(ray)
            }
        }
    }
}
