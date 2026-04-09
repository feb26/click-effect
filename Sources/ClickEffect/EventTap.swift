import AppKit
import CoreGraphics

/// Global mouse event listener built on CGEventTap.
/// Requires Accessibility permission.
final class EventTap {
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let onClick: (CGPoint, MouseButton) -> Void
    var onMouseMoved: ((CGPoint) -> Void)?
    var onMouseDragged: ((CGPoint, MouseButton) -> Void)?
    var isEnabled: Bool = true

    init(onClick: @escaping (CGPoint, MouseButton) -> Void) {
        self.onClick = onClick
    }

    @discardableResult
    func start() -> Bool {
        let mask = (1 << CGEventType.leftMouseDown.rawValue)
                 | (1 << CGEventType.rightMouseDown.rawValue)
                 | (1 << CGEventType.mouseMoved.rawValue)
                 | (1 << CGEventType.leftMouseDragged.rawValue)
                 | (1 << CGEventType.rightMouseDragged.rawValue)

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

            let location = event.location

            switch type {
            case .leftMouseDown, .rightMouseDown:
                let button: MouseButton = (type == .leftMouseDown) ? .left : .right
                DispatchQueue.main.async {
                    tap.onClick(location, button)
                }
            case .mouseMoved:
                if let handler = tap.onMouseMoved {
                    DispatchQueue.main.async { handler(location) }
                }
            case .leftMouseDragged, .rightMouseDragged:
                let button: MouseButton = (type == .leftMouseDragged) ? .left : .right
                if let handler = tap.onMouseDragged {
                    DispatchQueue.main.async { handler(location, button) }
                }
                if let handler = tap.onMouseMoved {
                    DispatchQueue.main.async { handler(location) }
                }
            default:
                break
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
