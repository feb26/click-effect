import AppKit

func parseEffect(from args: [String]) -> EffectKind {
    if let idx = args.firstIndex(of: "--effect"), idx + 1 < args.count,
       let kind = EffectKind(rawValue: args[idx + 1].lowercased()) {
        return kind
    }
    return .ripple
}

let effect = parseEffect(from: CommandLine.arguments)

let app = NSApplication.shared
let delegate = AppDelegate(effectKind: effect)
app.delegate = delegate
app.run()
