# ClickEffect

A small macOS menu bar app that shows a visual effect at your mouse pointer
whenever you click. Handy for screen sharing, demos, and recordings.

- Three built-in effects: **Ripple**, **Pulse**, **Burst**
- Separate colors for left and right clicks
- Adjustable size and speed
- Launch at login
- Menu bar only (no Dock icon)

## Requirements

- macOS 13 (Ventura) or later
- Accessibility permission (macOS asks on first launch)

## Build

```sh
./build-app.sh
```

The built app is `build/ClickEffect.app`.

For a Universal (Intel + Apple Silicon) build:

```sh
./build-app.sh --universal
```

## Install

1. Drag `build/ClickEffect.app` into `/Applications`.
2. Open it from Spotlight or Launchpad.
3. macOS will ask for **Accessibility** permission — grant it in
   **System Settings → Privacy & Security → Accessibility**, then relaunch
   the app if needed.

> **Note:** "Launch at Login" requires the app to live in `/Applications`
> (or `~/Applications`).

## Usage

Click the menu bar icon (`cursorarrow.rays`):

- **Enabled** — toggle the effect on/off
- **Effect** — switch between Ripple / Pulse / Burst
- **Settings…** — adjust colors, size, and speed
- **Launch at Login** — start ClickEffect automatically on login
- **Quit ClickEffect**

## Distribution (Gatekeeper workaround)

ClickEffect is **ad-hoc signed**, not notarized. When a coworker receives the
`.app` and opens it for the first time, macOS will refuse with
"ClickEffect cannot be opened because the developer cannot be verified."

To bypass this, **once**:

1. In Finder, **right-click (or Control-click) the app → Open**.
2. In the confirmation dialog, click **Open**.

After that, it launches normally from Spotlight, Dock, etc.

If the app was downloaded via a browser and `.app` has the quarantine
attribute, another option is:

```sh
xattr -dr com.apple.quarantine /Applications/ClickEffect.app
```

## Uninstall

1. Quit ClickEffect from the menu bar.
2. Delete `/Applications/ClickEffect.app`.
3. (Optional) Remove it from
   **System Settings → Privacy & Security → Accessibility**.

## Development

Source layout:

```
Sources/ClickEffect/
  main.swift              # entry point + CLI args
  AppDelegate.swift       # wiring
  EventTap.swift          # CGEventTap for mouse clicks
  OverlayController.swift # per-screen overlay management
  OverlayWindow.swift     # borderless, click-through NSWindow
  StatusItemController.swift  # menu bar UI
  SettingsStore.swift     # UserDefaults-backed ObservableObject
  SettingsView.swift      # SwiftUI settings form
  SettingsWindow.swift    # NSWindow wrapping the SwiftUI view
  LoginItemManager.swift  # SMAppService wrapper
  Effects/
    ClickEffect.swift     # protocol + EffectConfig + EffectKind
    RippleEffect.swift
    PulseEffect.swift
    BurstEffect.swift
```

### Signing (recommended, one-time)

By default the app is ad-hoc signed, which means macOS treats every
rebuild as a new app and you must re-grant **Accessibility** permission
each time. To avoid this, create a local self-signed certificate:

```sh
./setup-signing.sh   # one-time setup
```

After this, `./build-app.sh` automatically uses the certificate and
Accessibility permission persists across rebuilds.

### Build pipeline

The build pipeline is plain SwiftPM:

- `swift build` — debug build for development
- `./build-app.sh` — assembles `build/ClickEffect.app`
- `swift Tools/generate-icon.swift` — regenerate `Resources/AppIcon.iconset`
  from the SF Symbol (run once; files are checked in)
