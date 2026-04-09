# Contributing

Thanks for your interest in ClickEffect!

## Adding a new effect

1. Create `Sources/ClickEffect/Effects/YourEffect.swift`
2. Implement the `ClickEffect` protocol:
   ```swift
   struct YourEffect: ClickEffect {
       func play(at point: CGPoint, in hostLayer: CALayer, config: EffectConfig) {
           // Add sublayers, animate, then remove on completion.
       }
   }
   ```
3. Add a case to `EffectKind` in `Sources/ClickEffect/Effects/ClickEffect.swift`
4. Build and test: `swift build && ./build-app.sh && open build/ClickEffect.app`

Effects must be **self-cleaning**: add your own sublayer(s), animate, then
remove them when the animation completes.

## Adding a new setting

Three places need updating:

1. `Sources/ClickEffect/SettingsStore.swift` — add key, default, `@Published` property, and `resetToDefaults()` entry
2. `Sources/ClickEffect/SettingsView.swift` — add UI control
3. `Sources/ClickEffect/AppDelegate.swift` — bind the setting to `OverlayController` in `bindSettings()`

## Building

```sh
swift build              # debug build
./build-app.sh           # release .app bundle
./build-app.sh --universal  # Intel + Apple Silicon
```

## Code signing (optional, recommended)

Run `./setup-signing.sh` once to create a local self-signed certificate.
This keeps Accessibility permission across rebuilds.

## Pull requests

- Keep changes focused and small
- Test with `swift build` before submitting
- Follow existing code style and patterns
