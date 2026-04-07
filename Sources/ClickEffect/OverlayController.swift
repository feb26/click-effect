import AppKit

enum MouseButton {
    case left
    case right
}

/// Owns one OverlayWindow per NSScreen and routes clicks to the right one.
final class OverlayController {
    private var windows: [OverlayWindow] = []
    var effect: ClickEffect

    /// Colors are driven externally by SettingsStore. sizeScale/speedScale
    /// are also external; this struct is rebuilt on every playEffect call.
    var leftColor: CGColor
    var rightColor: CGColor
    var sizeScale: CGFloat = 1.0
    var speedScale: CGFloat = 1.0

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

        let config = EffectConfig(
            color: button == .left ? leftColor : rightColor,
            sizeScale: sizeScale,
            speedScale: speedScale
        )
        effect.play(at: localPoint, in: host, config: config)
    }

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
