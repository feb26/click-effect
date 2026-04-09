import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            Section("Click Effect") {
                Picker("Style", selection: $store.effectKind) {
                    ForEach(EffectKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue.capitalized).tag(kind)
                    }
                }

                ColorPicker("Left click color", selection: $store.leftColor, supportsOpacity: false)
                ColorPicker("Right click color", selection: $store.rightColor, supportsOpacity: false)

                scaleSlider(label: "Size", value: $store.sizeScale)
                scaleSlider(label: "Speed", value: $store.speedScale)
            }

            Section("Cursor") {
                Toggle("Cursor highlight", isOn: $store.enableCursorHighlight)
                if store.enableCursorHighlight {
                    scaleSlider(label: "Highlight size", value: $store.cursorHighlightSize)
                }

                Toggle("Drag trail", isOn: $store.enableDragTrail)
            }

            Section("Juice") {
                Slider(value: $store.hueJitter, in: 0...60) {
                    Text("Hue randomness")
                } minimumValueLabel: {
                    Text("0°").font(.caption).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("60°").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    Text(String(format: "±%.0f°", store.hueJitter))
                        .font(.caption).foregroundStyle(.secondary)
                }

                Slider(value: $store.sizeJitter, in: 0...0.5) {
                    Text("Size randomness")
                } minimumValueLabel: {
                    Text("0%").font(.caption).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("50%").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    Text(String(format: "±%.0f%%", store.sizeJitter * 100))
                        .font(.caption).foregroundStyle(.secondary)
                }

                Slider(value: $store.rotationJitter, in: 0...180) {
                    Text("Rotation randomness")
                } minimumValueLabel: {
                    Text("0°").font(.caption).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("180°").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    Text(String(format: "±%.0f°", store.rotationJitter))
                        .font(.caption).foregroundStyle(.secondary)
                }

                Slider(value: $store.comboBoost, in: 0...1) {
                    Text("Combo boost")
                } minimumValueLabel: {
                    Text("0").font(.caption).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("max").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    Text(String(format: "%.0f%%", store.comboBoost * 100))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button("Reset to defaults") {
                        store.resetToDefaults()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 680)
    }

    @ViewBuilder
    private func scaleSlider(label: String, value: Binding<Double>) -> some View {
        Slider(value: value, in: 0.5...2.0) {
            Text(label)
        } minimumValueLabel: {
            Text("0.5×").font(.caption).foregroundStyle(.secondary)
        } maximumValueLabel: {
            Text("2×").font(.caption).foregroundStyle(.secondary)
        }
        HStack {
            Spacer()
            Text(String(format: "%.2f×", value.wrappedValue))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
