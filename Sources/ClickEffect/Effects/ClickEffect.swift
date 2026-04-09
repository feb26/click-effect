import AppKit
import QuartzCore

/// Runtime-tweakable parameters shared by all effects.
struct EffectConfig {
    var color: CGColor
    var sizeScale: CGFloat       // 1.0 = default
    var speedScale: CGFloat      // 1.0 = default; higher = faster
    /// Maximum rotation in radians. 0 = no rotation. Each effect chooses
    /// how to use this (global orientation, per-element jitter, …).
    var rotationRange: CGFloat
    /// Combo/hype multiplier (1.0 = baseline). Effects scale particle
    /// count, ray count, brightness, etc. by this so rapid clicks
    /// actually feel louder.
    var intensity: CGFloat
}

/// Plays a visual effect centered at `point` on the given host layer.
/// Implementations must be self-cleaning: add their own sub-layer, animate,
/// then remove it on completion.
protocol ClickEffect {
    func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig)
}

enum EffectKind: String, CaseIterable {
    case ripple
    case pulse
    case burst
    case confetti
    case sparks
    case chrysanthemum
    case crossette
    case willow
    case ring
    case kamuro

    func make() -> ClickEffect {
        switch self {
        case .ripple:         return RippleEffect()
        case .pulse:          return PulseEffect()
        case .burst:          return BurstEffect()
        case .confetti:       return ConfettiEffect()
        case .sparks:         return SparksEffect()
        case .chrysanthemum:  return ChrysanthemumEffect()
        case .crossette:      return CrossetteEffect()
        case .willow:         return WillowEffect()
        case .ring:           return RingEffect()
        case .kamuro:         return KamuroEffect()
        }
    }
}

/// Shared tiny sprites used by emitter-based effects.
enum ParticleSprites {
    static let square: CGImage = makeSolid(size: 10, rounded: false)
    static let circle: CGImage = makeSolid(size: 12, rounded: true)

    private static func makeSolid(size: Int, rounded: Bool) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        if rounded {
            ctx.fillEllipse(in: rect)
        } else {
            ctx.fill(rect)
        }
        return ctx.makeImage()!
    }
}
