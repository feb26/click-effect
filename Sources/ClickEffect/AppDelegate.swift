import AppKit
import ApplicationServices
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let effectKind: EffectKind
    private var overlayController: OverlayController?
    private var eventTap: EventTap?
    private var statusItemController: StatusItemController?
    private var settingsCancellables: Set<AnyCancellable> = []

    init(effectKind: EffectKind) {
        self.effectKind = effectKind
    }

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
            effect: effectKind.make(),
            leftColor: settings.leftCGColor,
            rightColor: settings.rightCGColor
        )
        controller.sizeScale = CGFloat(settings.sizeScale)
        controller.speedScale = CGFloat(settings.speedScale)
        self.overlayController = controller

        // Push settings changes into the controller as they happen.
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

        self.statusItemController = StatusItemController(
            overlayController: controller,
            eventTap: tap,
            initialEffect: effectKind
        )

        print("[ClickEffect] Running. Use the menu bar icon to switch effects or quit.")
    }

    private func ensureAccessibilityPermission() -> Bool {
        let opts: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(opts as CFDictionary)
    }
}
