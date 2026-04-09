import AppKit
import ApplicationServices
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayController: OverlayController?
    private var eventTap: EventTap?
    private var statusItemController: StatusItemController?
    private var settingsCancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        guard ensureAccessibilityPermission() else {
            FileHandle.standardError.write(Data("""
                [ClickEffect] Accessibility permission is required.
                Grant it in System Settings → Privacy & Security → Accessibility,
                then re-run this command.

                """.utf8))
            NSApp.terminate(nil)
            return
        }

        let settings = SettingsStore.shared

        let controller = OverlayController(
            effect: settings.effectKind.make(),
            leftColor: settings.leftCGColor,
            rightColor: settings.rightCGColor
        )
        controller.sizeScale = CGFloat(settings.sizeScale)
        controller.speedScale = CGFloat(settings.speedScale)
        controller.hueJitter = CGFloat(settings.hueJitter)
        controller.sizeJitter = CGFloat(settings.sizeJitter)
        controller.rotationJitter = CGFloat(settings.rotationJitter)
        controller.comboBoost = CGFloat(settings.comboBoost)

        self.overlayController = controller

        bindSettings(to: controller, settings: settings)

        let tap = EventTap { [weak controller] point, button in
            controller?.playEffect(atGlobal: point, button: button)
        }
        if !tap.start() {
            FileHandle.standardError.write(Data(
                "[ClickEffect] Failed to create event tap. Check Accessibility permission.\n".utf8
            ))
            NSApp.terminate(nil)
            return
        }
        self.eventTap = tap

        self.statusItemController = StatusItemController(eventTap: tap)

        print("[ClickEffect] Running. Use the menu bar icon to open settings or quit.")
    }

    private func bindSettings(
        to controller: OverlayController,
        settings: SettingsStore
    ) {
        settings.$effectKind
            .sink { [weak controller] kind in controller?.effect = kind.make() }
            .store(in: &settingsCancellables)

        settings.$leftColor
            .sink { [weak controller] _ in controller?.leftColor = settings.leftCGColor }
            .store(in: &settingsCancellables)
        settings.$rightColor
            .sink { [weak controller] _ in controller?.rightColor = settings.rightCGColor }
            .store(in: &settingsCancellables)

        settings.$sizeScale
            .sink { [weak controller] value in controller?.sizeScale = CGFloat(value) }
            .store(in: &settingsCancellables)
        settings.$speedScale
            .sink { [weak controller] value in controller?.speedScale = CGFloat(value) }
            .store(in: &settingsCancellables)

        settings.$hueJitter
            .sink { [weak controller] value in controller?.hueJitter = CGFloat(value) }
            .store(in: &settingsCancellables)
        settings.$sizeJitter
            .sink { [weak controller] value in controller?.sizeJitter = CGFloat(value) }
            .store(in: &settingsCancellables)
        settings.$rotationJitter
            .sink { [weak controller] value in controller?.rotationJitter = CGFloat(value) }
            .store(in: &settingsCancellables)
        settings.$comboBoost
            .sink { [weak controller] value in controller?.comboBoost = CGFloat(value) }
            .store(in: &settingsCancellables)
    }

    private func ensureAccessibilityPermission() -> Bool {
        let opts: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(opts as CFDictionary)
    }
}
