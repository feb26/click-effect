import AppKit
import CoreGraphics

/// Global mouse click listener built on CGEventTap.
/// Requires Accessibility permission.
final class EventTap {
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let onClick: (CGPoint, MouseButton) -> Void
    var isEnabled: Bool = true

    init(onClick: @escaping (CGPoint, MouseButton) -> Void) {
        self.onClick = onClick
    }

    @discardableResult
    func start() -> Bool {
        let mask = (1 << CGEventType.leftMouseDown.rawValue)
                 | (1 << CGEventType.rightMouseDown.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let tap = Unmanaged<EventTap>.fromOpaque(refcon).takeUnretainedValue()

            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let port = tap.tap {
                    CGEvent.tapEnable(tap: port, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }

            guard tap.isEnabled else {
                return Unmanaged.passUnretained(event)
            }

            let button: MouseButton?
            switch type {
            case .leftMouseDown:  button = .left
            case .rightMouseDown: button = .right
            default:              button = nil
            }

            if let button {
                let location = event.location
                DispatchQueue.main.async {
                    tap.onClick(location, button)
                }
            }
            return Unmanaged.passUnretained(event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: refcon
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)

        self.tap = port
        self.runLoopSource = source
        return true
    }
}
