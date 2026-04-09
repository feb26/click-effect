import AppKit
import QuartzCore

/// Chrysanthemum firework: particles radiate outward with clearly
/// visible trailing tails that curve downward, like the iconic "kiku"
/// shell. Distinguished from Sparks by its long, luminous streaks.
struct ChrysanthemumEffect: ClickEffect {
    var baseLifetime: Float = 0.45
    var baseVelocity: CGFloat = 120
    var baseBirthRate: Float = 300
    var burstDuration: CFTimeInterval = 0.04

    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
        let speed = max(0.1, Double(config.speedScale))

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterShape = .point
        emitter.emitterMode = .outline
        emitter.renderMode = .additive

        // Main particle — the bright head
        let head = CAEmitterCell()
        head.contents = ParticleSprites.circle
        head.color = config.color
        head.birthRate = baseBirthRate * Float(config.sizeScale) * Float(config.intensity)
        head.lifetime = baseLifetime / Float(speed)
        head.lifetimeRange = 0.1
        head.velocity = baseVelocity * config.sizeScale
        head.velocityRange = 40 * config.sizeScale
        head.emissionRange = .pi * 2
        head.yAcceleration = 100
        head.scale = 0.3
        head.scaleRange = 0.08
        head.scaleSpeed = -0.25
        head.alphaSpeed = -1.5

        // Trail sub-cell — high birthRate + longer lifetime = clearly
        // visible streaks behind each head particle.
        let trail = CAEmitterCell()
        trail.contents = ParticleSprites.circle
        trail.color = config.color
        trail.birthRate = 120
        trail.lifetime = 0.25 / Float(speed)
        trail.velocity = 0
        trail.scale = 0.18
        trail.scaleSpeed = -0.4
        trail.alphaSpeed = -3.0
        trail.yAcceleration = 30

        head.emitterCells = [trail]
        emitter.emitterCells = [head]
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
