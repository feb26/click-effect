import AppKit

/// Borderless, transparent, click-through window pinned above all apps.
final class OverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        setFrame(screen.frame, display: false)

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        // AppKit's default flipped=false matches CoreAnimation's y-up — leave as is.
        contentView = view

        orderFrontRegardless()
    }

    var hostLayer: CALayer? { contentView?.layer }

    // MARK: - Cursor Highlight

    private(set) lazy var cursorHighlightLayer: CALayer = {
        let layer = CALayer()
        let size: CGFloat = 40
        layer.frame = CGRect(x: 0, y: 0, width: size, height: size)
        layer.cornerRadius = size / 2
        layer.backgroundColor = NSColor.systemCyan.withAlphaComponent(0.15).cgColor
        layer.shadowColor = NSColor.systemCyan.cgColor
        layer.shadowRadius = 12
        layer.shadowOpacity = 0.5
        layer.shadowOffset = .zero
        layer.isHidden = true
        hostLayer?.addSublayer(layer)
        return layer
    }()

    func updateHighlight(at point: CGPoint, color: CGColor, radius: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let size = radius * 2
        cursorHighlightLayer.frame = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: size,
            height: size
        )
        cursorHighlightLayer.cornerRadius = radius
        cursorHighlightLayer.backgroundColor = color.copy(alpha: 0.12)
        cursorHighlightLayer.shadowColor = color
        CATransaction.commit()
    }

    func setHighlightVisible(_ visible: Bool) {
        cursorHighlightLayer.isHidden = !visible
    }
}
