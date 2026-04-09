import AppKit
import QuartzCore

/// Willow firework: particles fan out with low initial speed, then
/// droop heavily downward like weeping willow branches. Distinguished
/// from Sparks by its strong gravity and graceful, arcing trails.
struct WillowEffect: ClickEffect {
    var baseLifetime: Float = 0.45
    var baseVelocity: CGFloat = 120
    var baseBirthRate: Float = 350
    var burstDuration: CFTimeInterval = 0.04

    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
        let speed = max(0.1, Double(config.speedScale))

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterShape = .point
        emitter.emitterMode = .outline
        emitter.renderMode = .additive

        let cell = CAEmitterCell()
        cell.contents = ParticleSprites.circle
        cell.color = config.color
        cell.birthRate = baseBirthRate * Float(config.sizeScale) * Float(config.intensity)
        cell.lifetime = baseLifetime / Float(speed)
        cell.lifetimeRange = 0.15
        cell.velocity = baseVelocity * config.sizeScale
        cell.velocityRange = 40 * config.sizeScale
        cell.emissionRange = .pi * 2
        // Very strong gravity — the defining trait of willow
        cell.yAcceleration = 450
        cell.scale = 0.25
        cell.scaleRange = 0.08
        cell.scaleSpeed = -0.1
        // Slow fade so the drooping arcs stay visible
        cell.alphaSpeed = -1.5

        // Subtle trailing dots to show the arc path
        let trail = CAEmitterCell()
        trail.contents = ParticleSprites.circle
        trail.color = config.color
        trail.birthRate = 50
        trail.lifetime = 0.2 / Float(speed)
        trail.velocity = 0
        trail.scale = 0.12
        trail.scaleSpeed = -0.3
        trail.alphaSpeed = -3.5

        cell.emitterCells = [trail]
        emitter.emitterCells = [cell]
        hostLayer.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + burstDuration) {
            emitter.birthRate = 0
        }
        let totalLife = Double(baseLifetime) / speed + Double(trail.lifetime) + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalLife) {
            emitter.removeFromSuperlayer()
        }
    }
}
