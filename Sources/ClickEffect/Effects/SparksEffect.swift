import AppKit
import QuartzCore

/// Bright radial spark burst that fades quickly.
struct SparksEffect: ClickEffect {
    var baseLifetime: Float = 0.5
    var baseVelocity: CGFloat = 260
    var baseBirthRate: Float = 600
    var burstDuration: CFTimeInterval = 0.04

    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
        let speed = max(0.1, Double(config.speedScale))

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterShape = .point
        emitter.emitterMode = .points
        emitter.renderMode = .additive

        let cell = CAEmitterCell()
        cell.contents = ParticleSprites.circle
        cell.color = config.color
        cell.birthRate = baseBirthRate * Float(config.sizeScale) * Float(config.intensity)
        cell.lifetime = baseLifetime / Float(speed)
        cell.lifetimeRange = 0.2
        cell.velocity = baseVelocity * config.sizeScale
        cell.velocityRange = 140 * config.sizeScale
        cell.emissionRange = .pi * 2
        cell.yAcceleration = 60
        cell.scale = 0.4
        cell.scaleRange = 0.2
        cell.scaleSpeed = -0.5
        cell.alphaSpeed = -1.6

        emitter.emitterCells = [cell]
        hostLayer.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + burstDuration) {
            emitter.birthRate = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(baseLifetime) / speed + 0.3) {
            emitter.removeFromSuperlayer()
        }
    }
}
