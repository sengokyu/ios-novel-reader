import SwiftUI

struct SettingsView: View {
    @AppStorage("readerFontSize") private var fontSize = 18
    @AppStorage("readerLineHeight") private var lineHeight = 2.0
    @AppStorage("readerMarginV") private var marginV = 20
    @AppStorage("readerMarginH") private var marginH = 16
    @AppStorage("readerFont") private var font = "mincho"
    @AppStorage("appTheme") private var theme = "system"

    var body: some View {
        Form {
            Section("文字") {
                Picker("フォント", selection: $font) {
                    Text("明朝体").tag("mincho")
                    Text("ゴシック体").tag("sans")
                }
                Stepper("文字サイズ: \(fontSize)pt", value: $fontSize, in: 12...32, step: 1)
                HStack {
                    Text("行間幅")
                    Slider(value: $lineHeight, in: 1.5...3.0, step: 0.25)
                    Text(String(format: "%.2f", lineHeight))
                        .monospacedDigit()
                        .frame(width: 36)
                        .foregroundStyle(.secondary)
                }
            }

            Section("余白") {
                Stepper("上下: \(marginV)px", value: $marginV, in: 8...48, step: 4)
                Stepper("左右: \(marginH)px", value: $marginH, in: 8...32, step: 4)
            }

            Section("テーマ") {
                Picker("テーマ", selection: $theme) {
                    Text("システム").tag("system")
                    Text("ライト").tag("light")
                    Text("ダーク").tag("dark")
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension SettingsView {
    static var readerFontFamily: String {
        let font = UserDefaults.standard.string(forKey: "readerFont") ?? "mincho"
        return font == "sans"
            ? "\"Hiragino Sans\", \"ヒラギノ角ゴシック\", sans-serif"
            : "\"Hiragino Mincho ProN\", \"ヒラギノ明朝 ProN\", serif"
    }
}
