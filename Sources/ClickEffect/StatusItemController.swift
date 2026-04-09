import AppKit

/// Menu bar icon + dropdown menu for toggling, opening settings, and
/// login-at-startup. Effect selection lives in Settings.
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let eventTap: EventTap

    private var enabledKey: String { SettingsStore.Key.isEnabled }

    init(eventTap: EventTap) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.eventTap = eventTap
        super.init()

        let defaults = UserDefaults.standard
        // Default-enabled on first launch.
        if defaults.object(forKey: enabledKey) == nil {
            defaults.set(true, forKey: enabledKey)
        }
        eventTap.isEnabled = defaults.bool(forKey: enabledKey)

        configureButton()
        rebuildMenu()
    }

    private func configureButton() {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "cursorarrow.rays",
                accessibilityDescription: "ClickEffect"
            )
            button.image?.isTemplate = true
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let toggle = NSMenuItem(
            title: "Enabled",
            action: #selector(toggleEnabled),
            keyEquivalent: "e"
        )
        toggle.target = self
        toggle.state = eventTap.isEnabled ? .on : .off
        menu.addItem(toggle)

        menu.addItem(.separator())

        let settings = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settings.target = self
        menu.addItem(settings)

        let launchAtLogin = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLogin.target = self
        launchAtLogin.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(launchAtLogin)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit ClickEffect", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        let next = !eventTap.isEnabled
        eventTap.isEnabled = next
        UserDefaults.standard.set(next, forKey: enabledKey)
        rebuildMenu()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            _ = try LoginItemManager.toggle()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn’t change Launch at Login"
            alert.informativeText = """
                \(error.localizedDescription)

                Make sure ClickEffect.app is in /Applications or ~/Applications.
                """
            alert.alertStyle = .warning
            alert.runModal()
        }
        rebuildMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
