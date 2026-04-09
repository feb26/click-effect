import AppKit
import Combine
import SwiftUI

/// Observable, UserDefaults-backed settings. Everything visible in the
/// Settings UI lives here.
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    // MARK: - Keys

    enum Key {
        static let leftColor      = "ClickEffect.leftColor"
        static let rightColor     = "ClickEffect.rightColor"
        static let sizeScale      = "ClickEffect.sizeScale"
        static let speedScale     = "ClickEffect.speedScale"
        static let effectKind     = "ClickEffect.effectKind"
        static let hueJitter      = "ClickEffect.hueJitter"
        static let sizeJitter     = "ClickEffect.sizeJitter"
        static let rotationJitter = "ClickEffect.rotationJitter"
        static let comboBoost            = "ClickEffect.comboBoost"
        static let enableCursorHighlight = "ClickEffect.enableCursorHighlight"
        static let cursorHighlightSize   = "ClickEffect.cursorHighlightSize"
        static let enableDragTrail       = "ClickEffect.enableDragTrail"
        static let isEnabled             = "ClickEffect.isEnabled"
    }

    // MARK: - Defaults

    static let defaultLeftColor   = Color(nsColor: .systemCyan)
    static let defaultRightColor  = Color(nsColor: .systemPink)
    static let defaultSizeScale:  Double = 1.0
    static let defaultSpeedScale: Double = 1.0
    static let defaultEffectKind: EffectKind = .ripple

    // Juice (all default-off so functionality always wins).
    static let defaultHueJitter:      Double = 0      // degrees, 0...60
    static let defaultSizeJitter:     Double = 0      // fraction, 0...0.5
    static let defaultRotationJitter: Double = 0      // degrees, 0...180
    static let defaultComboBoost:     Double = 0      // strength, 0...1

    // Cursor & trail (default-off).
    static let defaultEnableCursorHighlight: Bool = false
    static let defaultCursorHighlightSize: Double = 1.0
    static let defaultEnableDragTrail: Bool = false

    // MARK: - Published state

    @Published var leftColor: Color {
        didSet { persistColor(leftColor, forKey: Key.leftColor) }
    }
    @Published var rightColor: Color {
        didSet { persistColor(rightColor, forKey: Key.rightColor) }
    }
    @Published var sizeScale: Double {
        didSet { UserDefaults.standard.set(sizeScale, forKey: Key.sizeScale) }
    }
    @Published var speedScale: Double {
        didSet { UserDefaults.standard.set(speedScale, forKey: Key.speedScale) }
    }
    @Published var effectKind: EffectKind {
        didSet { UserDefaults.standard.set(effectKind.rawValue, forKey: Key.effectKind) }
    }

    @Published var hueJitter: Double {
        didSet { UserDefaults.standard.set(hueJitter, forKey: Key.hueJitter) }
    }
    @Published var sizeJitter: Double {
        didSet { UserDefaults.standard.set(sizeJitter, forKey: Key.sizeJitter) }
    }
    @Published var rotationJitter: Double {
        didSet { UserDefaults.standard.set(rotationJitter, forKey: Key.rotationJitter) }
    }
    @Published var comboBoost: Double {
        didSet { UserDefaults.standard.set(comboBoost, forKey: Key.comboBoost) }
    }

    @Published var enableCursorHighlight: Bool {
        didSet { UserDefaults.standard.set(enableCursorHighlight, forKey: Key.enableCursorHighlight) }
    }
    @Published var cursorHighlightSize: Double {
        didSet { UserDefaults.standard.set(cursorHighlightSize, forKey: Key.cursorHighlightSize) }
    }
    @Published var enableDragTrail: Bool {
        didSet { UserDefaults.standard.set(enableDragTrail, forKey: Key.enableDragTrail) }
    }

    // MARK: - Init

    private init() {
        let defaults = UserDefaults.standard
        self.leftColor = Self.loadColor(forKey: Key.leftColor)
            ?? Self.defaultLeftColor
        self.rightColor = Self.loadColor(forKey: Key.rightColor)
            ?? Self.defaultRightColor
        self.sizeScale = defaults.object(forKey: Key.sizeScale) as? Double
            ?? Self.defaultSizeScale
        self.speedScale = defaults.object(forKey: Key.speedScale) as? Double
            ?? Self.defaultSpeedScale
        self.effectKind = defaults.string(forKey: Key.effectKind)
            .flatMap(EffectKind.init(rawValue:))
            ?? Self.defaultEffectKind

        self.hueJitter = defaults.object(forKey: Key.hueJitter) as? Double
            ?? Self.defaultHueJitter
        self.sizeJitter = defaults.object(forKey: Key.sizeJitter) as? Double
            ?? Self.defaultSizeJitter
        self.rotationJitter = defaults.object(forKey: Key.rotationJitter) as? Double
            ?? Self.defaultRotationJitter
        self.comboBoost = defaults.object(forKey: Key.comboBoost) as? Double
            ?? Self.defaultComboBoost

        self.enableCursorHighlight = defaults.object(forKey: Key.enableCursorHighlight) as? Bool
            ?? Self.defaultEnableCursorHighlight
        self.cursorHighlightSize = defaults.object(forKey: Key.cursorHighlightSize) as? Double
            ?? Self.defaultCursorHighlightSize
        self.enableDragTrail = defaults.object(forKey: Key.enableDragTrail) as? Bool
            ?? Self.defaultEnableDragTrail
    }

    // MARK: - Helpers

    func resetToDefaults() {
        leftColor      = Self.defaultLeftColor
        rightColor     = Self.defaultRightColor
        sizeScale      = Self.defaultSizeScale
        speedScale     = Self.defaultSpeedScale
        effectKind     = Self.defaultEffectKind

        hueJitter      = Self.defaultHueJitter
        sizeJitter     = Self.defaultSizeJitter
        rotationJitter = Self.defaultRotationJitter
        comboBoost     = Self.defaultComboBoost

        enableCursorHighlight = Self.defaultEnableCursorHighlight
        cursorHighlightSize   = Self.defaultCursorHighlightSize
        enableDragTrail       = Self.defaultEnableDragTrail
    }

    var leftCGColor: CGColor  { NSColor(leftColor).cgColor }
    var rightCGColor: CGColor { NSColor(rightColor).cgColor }

    // MARK: - Color persistence (archived NSColor)

    private func persistColor(_ color: Color, forKey key: String) {
        let ns = NSColor(color)
        if let data = try? NSKeyedArchiver.archivedData(
            withRootObject: ns, requiringSecureCoding: true
        ) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func loadColor(forKey key: String) -> Color? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let ns = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSColor.self, from: data
              ) else {
            return nil
        }
        return Color(nsColor: ns)
    }
}
