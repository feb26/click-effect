import QuartzCore

/// Runtime-tweakable parameters shared by all effects.
struct EffectConfig {
    var color: CGColor
    var sizeScale: CGFloat   // 1.0 = default
    var speedScale: CGFloat  // 1.0 = default; higher = faster
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

    func make() -> ClickEffect {
        switch self {
        case .ripple: return RippleEffect()
        case .pulse:  return PulseEffect()
        case .burst:  return BurstEffect()
        }
    }
}
