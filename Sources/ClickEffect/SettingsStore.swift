import AppKit
import Combine
import SwiftUI

/// Observable, UserDefaults-backed settings.
/// Effects and overlay read the plain CG values via the non-published
/// helpers; SwiftUI binds to @Published Color wrappers.
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    // MARK: - Keys

    private enum Key {
        static let leftColor  = "ClickEffect.leftColor"
        static let rightColor = "ClickEffect.rightColor"
        static let sizeScale  = "ClickEffect.sizeScale"
        static let speedScale = "ClickEffect.speedScale"
    }

    // MARK: - Defaults

    static let defaultLeftColor  = Color(nsColor: .systemCyan)
    static let defaultRightColor = Color(nsColor: .systemPink)
    static let defaultSizeScale: Double  = 1.0
    static let defaultSpeedScale: Double = 1.0

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
    }

    // MARK: - Helpers

    func resetToDefaults() {
        leftColor  = Self.defaultLeftColor
        rightColor = Self.defaultRightColor
        sizeScale  = Self.defaultSizeScale
        speedScale = Self.defaultSpeedScale
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
