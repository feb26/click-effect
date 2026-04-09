import AppKit

enum MouseButton {
    case left
    case right
}

/// Owns one OverlayWindow per NSScreen and routes clicks to the right one.
final class OverlayController {
    private var windows: [OverlayWindow] = []
    var effect: ClickEffect

    // Colors / scales are driven externally by SettingsStore. A new
    // EffectConfig is built per click.
    var leftColor: CGColor
    var rightColor: CGColor
    var sizeScale: CGFloat = 1.0
    var speedScale: CGFloat = 1.0

    // Juice controls (all default-off).
    var hueJitter: CGFloat = 0       // degrees, 0...60
    var sizeJitter: CGFloat = 0      // fraction, 0...0.5
    var rotationJitter: CGFloat = 0  // degrees, 0...180
    var comboBoost: CGFloat = 0      // strength, 0...1

    // Cursor highlight
    var enableCursorHighlight: Bool = false {
        didSet { if !enableCursorHighlight { hideAllHighlights() } }
    }
    var cursorHighlightSize: CGFloat = 1.0

    // Drag trail
    var enableDragTrail: Bool = false
    private var lastTrailPoint: CGPoint = .zero

    // Combo tracking. Window is generous enough that casual rapid-fire
    // clicking actually chains.
    private var lastClickTime: CFTimeInterval = 0
    private var comboCount: Int = 0
    private let comboWindow: CFTimeInterval = 0.9
    private let comboMaxHits: Int = 8

    init(effect: ClickEffect, leftColor: CGColor, rightColor: CGColor) {
        self.effect = effect
        self.leftColor = leftColor
        self.rightColor = rightColor
        rebuildWindows()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screensChanged() {
        rebuildWindows()
    }

    private func rebuildWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows = NSScreen.screens.map { OverlayWindow(screen: $0) }
    }

    /// `globalPoint` is in CoreGraphics global coordinates (top-left origin, y-down).
    func playEffect(atGlobal globalPoint: CGPoint, button: MouseButton) {
        guard let (window, localPoint) = windowAndLocalPoint(for: globalPoint) else {
            return
        }
        guard let host = window.hostLayer else { return }

        let baseColor = (button == .left) ? leftColor : rightColor
        let color = jitterHue(baseColor, byDegrees: hueJitter)

        let sizeNoise = (sizeJitter > 0)
            ? CGFloat.random(in: (1 - sizeJitter)...(1 + sizeJitter))
            : 1.0

        let combo = advanceCombo(strength: comboBoost)
        let effectiveSize = sizeScale * sizeNoise * combo.sizeMultiplier

        let rotationRange = rotationJitter * .pi / 180  // deg → rad

        let config = EffectConfig(
            color: color,
            sizeScale: effectiveSize,
            speedScale: speedScale,
            rotationRange: rotationRange,
            intensity: combo.intensity
        )
        effect.play(at: localPoint, in: host, config: config)
    }

    // MARK: - Combo

    private struct ComboResult {
        var intensity: CGFloat
        var sizeMultiplier: CGFloat
    }

    /// Advances (or resets) the combo counter. Returns both an intensity
    /// multiplier (used by effects to boost particle/ray counts, brightness)
    /// AND a direct size multiplier. At strength = 1 and max combo,
    /// intensity reaches ~3.5× and size ~1.7×.
    private func advanceCombo(strength: CGFloat) -> ComboResult {
        guard strength > 0 else {
            comboCount = 0
            lastClickTime = 0
            return ComboResult(intensity: 1, sizeMultiplier: 1)
        }
        let now = CACurrentMediaTime()
        if now - lastClickTime < comboWindow {
            comboCount = min(comboCount + 1, comboMaxHits)
        } else {
            comboCount = 0
        }
        lastClickTime = now
        let fraction = CGFloat(comboCount) / CGFloat(comboMaxHits)
        return ComboResult(
            intensity: 1 + strength * 2.5 * fraction,
            sizeMultiplier: 1 + strength * 0.7 * fraction
        )
    }

    // MARK: - Hue jitter

    private func jitterHue(_ cgColor: CGColor, byDegrees degrees: CGFloat) -> CGColor {
        guard degrees > 0, let ns = NSColor(cgColor: cgColor) else {
            return cgColor
        }
        let rgb = ns.usingColorSpace(.sRGB) ?? ns
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let shift = CGFloat.random(in: -degrees...degrees) / 360
        var newHue = h + shift
        if newHue < 0 { newHue += 1 }
        if newHue > 1 { newHue -= 1 }
        return NSColor(hue: newHue, saturation: s, brightness: b, alpha: a).cgColor
    }

    // MARK: - Cursor Highlight

    func updateCursorHighlight(atGlobal globalPoint: CGPoint) {
        guard enableCursorHighlight else { return }
        guard let (window, localPoint) = windowAndLocalPoint(for: globalPoint) else {
            return
        }
        let radius: CGFloat = 20 * cursorHighlightSize
        window.updateHighlight(at: localPoint, color: leftColor, radius: radius)
        window.setHighlightVisible(true)

        // Hide highlight on other screens
        for w in windows where w !== window {
            w.setHighlightVisible(false)
        }
    }

    private func hideAllHighlights() {
        for w in windows {
            w.setHighlightVisible(false)
        }
    }

    // MARK: - Drag Trail

    func playDragTrail(atGlobal globalPoint: CGPoint, button: MouseButton) {
        guard enableDragTrail else { return }

        // Throttle: only draw if moved at least 4px from last point
        let dx = globalPoint.x - lastTrailPoint.x
        let dy = globalPoint.y - lastTrailPoint.y
        guard dx * dx + dy * dy >= 16 else { return }
        lastTrailPoint = globalPoint

        guard let (window, localPoint) = windowAndLocalPoint(for: globalPoint) else {
            return
        }
        guard let host = window.hostLayer else { return }

        let baseColor = (button == .left) ? leftColor : rightColor
        let dotRadius: CGFloat = 3 * sizeScale
        let dot = CALayer()
        dot.frame = CGRect(
            x: localPoint.x - dotRadius,
            y: localPoint.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        )
        dot.cornerRadius = dotRadius
        dot.backgroundColor = baseColor.copy(alpha: 0.6)
        host.addSublayer(dot)

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.6
        fade.toValue = 0.0
        fade.duration = 0.4
        fade.isRemovedOnCompletion = false
        fade.fillMode = .forwards

        CATransaction.begin()
        CATransaction.setCompletionBlock { dot.removeFromSuperlayer() }
        dot.add(fade, forKey: "fade")
        CATransaction.commit()
    }

    // MARK: - Geometry

    private func windowAndLocalPoint(for globalCG: CGPoint) -> (OverlayWindow, CGPoint)? {
        for window in windows {
            guard let screen = window.screen else { continue }
            let frame = screen.frame

            // Convert CG global (top-left origin of the primary display) to
            // AppKit global (bottom-left origin of the primary display).
            guard let primaryHeight = NSScreen.screens.first?.frame.height else { continue }
            let appKitGlobal = CGPoint(x: globalCG.x, y: primaryHeight - globalCG.y)

            if NSPointInRect(appKitGlobal, frame) {
                let local = CGPoint(
                    x: appKitGlobal.x - frame.origin.x,
                    y: appKitGlobal.y - frame.origin.y
                )
                return (window, local)
            }
        }
        return nil
    }
}
