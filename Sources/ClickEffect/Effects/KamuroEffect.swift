import AppKit
import QuartzCore

/// Kamuro firework: an extremely dense shower of fine particles that
/// lingers much longer than other effects, slowly raining down like
/// golden tinsel. Distinguished from Chrysanthemum by its high
/// particle count, tiny particle size, and very slow fade.
struct KamuroEffect: ClickEffect {
    var baseLifetime: Float = 0.5
    var baseVelocity: CGFloat = 110
    var baseBirthRate: Float = 900
    var burstDuration: CFTimeInterval = 0.04

    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
        let speed = max(0.1, Double(config.speedScale))

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterShape = .point
        emitter.emitterMode = .outline
        emitter.renderMode = .additive

        // Very small, numerous particles
        let cell = CAEmitterCell()
        cell.contents = ParticleSprites.circle
        cell.color = config.color
        cell.birthRate = baseBirthRate * Float(config.sizeScale) * Float(config.intensity)
        cell.lifetime = baseLifetime / Float(speed)
        cell.lifetimeRange = 0.25
        cell.velocity = baseVelocity * config.sizeScale
        cell.velocityRange = 40 * config.sizeScale
        cell.emissionRange = .pi * 2
        // Light gravity — particles drift down gently
        cell.yAcceleration = 60
        // Tiny particles, very slow fade = lingering shower
        cell.scale = 0.15
        cell.scaleRange = 0.06
        cell.scaleSpeed = -0.05
        cell.alphaSpeed = -1.2

        emitter.emitterCells = [cell]
        hostLayer.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + burstDuration) {
            emitter.birthRate = 0
        }
        let totalLife = Double(baseLifetime) / speed + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + totalLife) {
            emitter.removeFromSuperlayer()
        }
    }
}
