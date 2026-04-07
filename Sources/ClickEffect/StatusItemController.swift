import AppKit

/// Menu bar icon + dropdown menu for toggling, switching effects, settings,
/// and login-at-startup.
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let overlayController: OverlayController
    private let eventTap: EventTap

    private let enabledKey = "ClickEffect.isEnabled"
    private let effectKey = "ClickEffect.effectKind"

    private var currentEffect: EffectKind = .ripple

    init(overlayController: OverlayController, eventTap: EventTap, initialEffect: EffectKind) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.overlayController = overlayController
        self.eventTap = eventTap
        super.init()

        let defaults = UserDefaults.standard
        // Default-enabled on first launch.
        if defaults.object(forKey: enabledKey) == nil {
            defaults.set(true, forKey: enabledKey)
        }
        let storedEffect = defaults.string(forKey: effectKey).flatMap(EffectKind.init(rawValue:))
        let effect = storedEffect ?? initialEffect
        self.currentEffect = effect
        overlayController.effect = effect.make()
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

        let header = NSMenuItem(title: "Effect", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        for kind in EffectKind.allCases {
            let item = NSMenuItem(
                title: "  " + kind.rawValue.capitalized,
                action: #selector(selectEffect(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = kind.rawValue
            item.state = (kind == currentEffect) ? .on : .off
            menu.addItem(item)
        }

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

    @objc private func selectEffect(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let kind = EffectKind(rawValue: raw) else { return }
        currentEffect = kind
        overlayController.effect = kind.make()
        UserDefaults.standard.set(raw, forKey: effectKey)
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
