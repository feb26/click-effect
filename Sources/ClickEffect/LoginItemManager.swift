import Foundation
import ServiceManagement

/// Thin wrapper around SMAppService.mainApp for the "Launch at Login" toggle.
/// Requires macOS 13+; the .app must live in /Applications or ~/Applications.
enum LoginItemManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Toggles registration. Returns the new state.
    /// Throws if registration fails (e.g. app not in /Applications).
    @discardableResult
    static func toggle() throws -> Bool {
        if isEnabled {
            try SMAppService.mainApp.unregister()
            return false
        } else {
            try SMAppService.mainApp.register()
            return true
        }
    }
}
