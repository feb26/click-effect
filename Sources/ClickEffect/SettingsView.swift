import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            Section("Colors") {
                ColorPicker("Left click", selection: $store.leftColor, supportsOpacity: false)
                ColorPicker("Right click", selection: $store.rightColor, supportsOpacity: false)
            }

            Section("Size") {
                Slider(value: $store.sizeScale, in: 0.5...2.0) {
                    Text("Size")
                } minimumValueLabel: {
                    Text("0.5×").font(.caption).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("2×").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    Text(String(format: "%.2f×", store.sizeScale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Speed") {
                Slider(value: $store.speedScale, in: 0.5...2.0) {
                    Text("Speed")
                } minimumValueLabel: {
                    Text("0.5×").font(.caption).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("2×").font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    Text(String(format: "%.2f×", store.speedScale))
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .frame(width: 400, height: 520)
    }
}
