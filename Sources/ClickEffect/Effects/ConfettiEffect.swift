import AppKit
import QuartzCore

/// Short burst of square confetti particles falling with gravity.
struct ConfettiEffect: ClickEffect {
    var baseLifetime: Float = 1.0
    var baseVelocity: CGFloat = 200
    var baseBirthRate: Float = 400
    var burstDuration: CFTimeInterval = 0.06

    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
        let speed = max(0.1, Double(config.speedScale))

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterShape = .point
        emitter.emitterMode = .outline
        emitter.renderMode = .additive

        let cell = CAEmitterCell()
        cell.contents = ParticleSprites.square
        cell.color = config.color
        cell.birthRate = baseBirthRate * Float(config.sizeScale) * Float(config.intensity)
        cell.lifetime = baseLifetime / Float(speed)
        cell.lifetimeRange = 0.3
        cell.velocity = baseVelocity * config.sizeScale
        cell.velocityRange = 120 * config.sizeScale
        cell.emissionRange = .pi * 2
        cell.yAcceleration = 260
        cell.spin = 4
        cell.spinRange = 8
        cell.scale = 0.7
        cell.scaleRange = 0.4
        cell.alphaSpeed = -0.9
        // Per-particle color variation even if hue jitter is off — confetti
        // looks flat without it.
        cell.redRange = 0.25
        cell.greenRange = 0.25
        cell.blueRange = 0.25

        emitter.emitterCells = [cell]
        hostLayer.addSublayer(emitter)

        // Emit for a short burst then stop birthing.
        DispatchQueue.main.asyncAfter(deadline: .now() + burstDuration) {
            emitter.birthRate = 0
        }
        // Remove once particles have faded.
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(baseLifetime) / speed + 0.4) {
            emitter.removeFromSuperlayer()
        }
    }
}
