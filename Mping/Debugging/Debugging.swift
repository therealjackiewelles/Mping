import SwiftUI
import Combine
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

final class DeviceTileEditorSettings: ObservableObject {
    static let shared = DeviceTileEditorSettings()

    @Published var tileWidth: CGFloat = 168.0
    @Published var tileHeight: CGFloat = 108.822
    @Published var tileCornerRadius: CGFloat = 16.0

    @Published var tileHorizontalPadding: CGFloat = 12.0
    @Published var tileTopPadding: CGFloat = 13.209
    @Published var tileBottomPadding: CGFloat = 9.0

    @Published var titleSize: CGFloat = 12.8
    @Published var titleBold: Bool = false
    @Published var titleItalic: Bool = false
    @Published var titleOpacity: CGFloat = 0.98
    @Published var titleTopSpacing: CGFloat = 0.0
    @Published var titleTrailingPadding: CGFloat = 0.0
    @Published var titleMinimumScale: CGFloat = 0.72

    @Published var ipSize: CGFloat = 11.688
    @Published var ipBold: Bool = false
    @Published var ipItalic: Bool = false
    @Published var ipOpacity: CGFloat = 0.82
    @Published var ipTopSpacing: CGFloat = 6.0
    @Published var ipTrailingPadding: CGFloat = 37.0
    @Published var ipMinimumScale: CGFloat = 0.85

    @Published var typeSize: CGFloat = 10.051
    @Published var typeBold: Bool = false
    @Published var typeItalic: Bool = false
    @Published var typeOpacity: CGFloat = 0.66
    @Published var typeTopSpacing: CGFloat = 3.0
    @Published var typeTrailingPadding: CGFloat = 38.0
    @Published var typeIconSize: CGFloat = 11.3
    @Published var typeIconWidth: CGFloat = 12.0
    @Published var typeIconSpacing: CGFloat = 5.0

    @Published var temperatureSize: CGFloat = 11.6
    @Published var temperatureBold: Bool = false
    @Published var temperatureItalic: Bool = false
    @Published var temperatureBoxHorizontalPadding: CGFloat = 7.0
    @Published var temperatureBoxVerticalPadding: CGFloat = 4.0
    @Published var temperatureBoxCornerRadius: CGFloat = 7.0
    @Published var temperatureBoxOpacity: CGFloat = 0.21
    @Published var temperatureBorderOpacity: CGFloat = 0.14

    @Published var pingHeaderSize: CGFloat = 6.5
    @Published var pingHeaderBold: Bool = false
    @Published var pingHeaderItalic: Bool = false
    @Published var pingHeaderOpacity: CGFloat = 0.5

    @Published var pingLabelSize: CGFloat = 5.5
    @Published var pingLabelBold: Bool = false
    @Published var pingLabelItalic: Bool = false
    @Published var pingLabelOpacity: CGFloat = 0.52

    @Published var pingValueSize: CGFloat = 11.8
    @Published var pingValueBold: Bool = false
    @Published var pingValueItalic: Bool = false
    @Published var pingValueOpacity: CGFloat = 0.96

    @Published var pingBoxHorizontalPadding: CGFloat = 7.0
    @Published var pingBoxVerticalPadding: CGFloat = 5.0
    @Published var pingBoxCornerRadius: CGFloat = 7.0
    @Published var pingBoxOpacity: CGFloat = 0.24
    @Published var pingBorderOpacity: CGFloat = 0.16
    @Published var pingBoxVerticalSpacing: CGFloat = 3.0
    @Published var pingColumnWidth: CGFloat = 22.0
    @Published var pingColumnSpacing: CGFloat = 6.0
    @Published var pingColumnVerticalSpacing: CGFloat = 1.0

    @Published var bottomRowSpacing: CGFloat = 7.0
    @Published var bottomRowSpacerMinLength: CGFloat = 4.0

    @Published var statusTrailingPadding: CGFloat = 10.0
    @Published var statusOuterFrameSize: CGFloat = 42.0
    @Published var statusRippleSize: CGFloat = 32.032
    @Published var statusRippleLineWidth: CGFloat = 3.128
    @Published var statusBackgroundSize: CGFloat = 18.641
    @Published var statusBackgroundOpacity: CGFloat = 0.26
    @Published var statusIconSize: CGFloat = 8.431
    @Published var statusIconBorderOpacity: CGFloat = 0.7
    @Published var statusIconBorderWidth: CGFloat = 1.05
    @Published var statusShadowRadius: CGFloat = 6.0

    @Published var selectedShadowRadius: CGFloat = 12.0
    @Published var normalShadowRadius: CGFloat = 7.0
    @Published var selectedShadowYOffset: CGFloat = 7.0
    @Published var normalShadowYOffset: CGFloat = 4.0
    @Published var selectedShadowOpacity: CGFloat = 0.48
    @Published var normalShadowOpacity: CGFloat = 0.3

    @Published var selectedBorderWidth: CGFloat = 1.8
    @Published var normalBorderWidth: CGFloat = 1.05
    @Published var selectedBorderOpacity: CGFloat = 0.98
    @Published var normalBorderOpacity: CGFloat = 0.13
    @Published var selectedGlowWidth: CGFloat = 5.0
    @Published var selectedGlowBlur: CGFloat = 3.0
    @Published var selectedGlowOpacity: CGFloat = 0.3

    private init() { }

    private struct DeviceTileSourceSetting {
        let name: String
        let type: String
    }

    private static let sourceSettings: [DeviceTileSourceSetting] = [
        DeviceTileSourceSetting(name: "tileWidth", type: "CGFloat"),
        DeviceTileSourceSetting(name: "tileHeight", type: "CGFloat"),
        DeviceTileSourceSetting(name: "tileCornerRadius", type: "CGFloat"),
        DeviceTileSourceSetting(name: "tileHorizontalPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "tileTopPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "tileBottomPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "titleSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "titleBold", type: "Bool"),
        DeviceTileSourceSetting(name: "titleItalic", type: "Bool"),
        DeviceTileSourceSetting(name: "titleOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "titleTopSpacing", type: "CGFloat"),
        DeviceTileSourceSetting(name: "titleTrailingPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "titleMinimumScale", type: "CGFloat"),
        DeviceTileSourceSetting(name: "ipSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "ipBold", type: "Bool"),
        DeviceTileSourceSetting(name: "ipItalic", type: "Bool"),
        DeviceTileSourceSetting(name: "ipOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "ipTopSpacing", type: "CGFloat"),
        DeviceTileSourceSetting(name: "ipTrailingPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "ipMinimumScale", type: "CGFloat"),
        DeviceTileSourceSetting(name: "typeSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "typeBold", type: "Bool"),
        DeviceTileSourceSetting(name: "typeItalic", type: "Bool"),
        DeviceTileSourceSetting(name: "typeOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "typeTopSpacing", type: "CGFloat"),
        DeviceTileSourceSetting(name: "typeTrailingPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "typeIconSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "typeIconWidth", type: "CGFloat"),
        DeviceTileSourceSetting(name: "typeIconSpacing", type: "CGFloat"),
        DeviceTileSourceSetting(name: "temperatureSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "temperatureBold", type: "Bool"),
        DeviceTileSourceSetting(name: "temperatureItalic", type: "Bool"),
        DeviceTileSourceSetting(name: "temperatureBoxHorizontalPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "temperatureBoxVerticalPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "temperatureBoxCornerRadius", type: "CGFloat"),
        DeviceTileSourceSetting(name: "temperatureBoxOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "temperatureBorderOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingHeaderSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingHeaderBold", type: "Bool"),
        DeviceTileSourceSetting(name: "pingHeaderItalic", type: "Bool"),
        DeviceTileSourceSetting(name: "pingHeaderOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingLabelSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingLabelBold", type: "Bool"),
        DeviceTileSourceSetting(name: "pingLabelItalic", type: "Bool"),
        DeviceTileSourceSetting(name: "pingLabelOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingValueSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingValueBold", type: "Bool"),
        DeviceTileSourceSetting(name: "pingValueItalic", type: "Bool"),
        DeviceTileSourceSetting(name: "pingValueOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingBoxHorizontalPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingBoxVerticalPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingBoxCornerRadius", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingBoxOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingBorderOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingBoxVerticalSpacing", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingColumnWidth", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingColumnSpacing", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingColumnVerticalSpacing", type: "CGFloat"),
        DeviceTileSourceSetting(name: "bottomRowSpacing", type: "CGFloat"),
        DeviceTileSourceSetting(name: "bottomRowSpacerMinLength", type: "CGFloat"),
        DeviceTileSourceSetting(name: "statusTrailingPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "statusOuterFrameSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "statusRippleSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "statusRippleLineWidth", type: "CGFloat"),
        DeviceTileSourceSetting(name: "statusBackgroundSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "statusBackgroundOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "statusIconSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "statusIconBorderOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "statusIconBorderWidth", type: "CGFloat"),
        DeviceTileSourceSetting(name: "statusShadowRadius", type: "CGFloat"),
        DeviceTileSourceSetting(name: "selectedShadowRadius", type: "CGFloat"),
        DeviceTileSourceSetting(name: "normalShadowRadius", type: "CGFloat"),
        DeviceTileSourceSetting(name: "selectedShadowYOffset", type: "CGFloat"),
        DeviceTileSourceSetting(name: "normalShadowYOffset", type: "CGFloat"),
        DeviceTileSourceSetting(name: "selectedShadowOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "normalShadowOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "selectedBorderWidth", type: "CGFloat"),
        DeviceTileSourceSetting(name: "normalBorderWidth", type: "CGFloat"),
        DeviceTileSourceSetting(name: "selectedBorderOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "normalBorderOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "selectedGlowWidth", type: "CGFloat"),
        DeviceTileSourceSetting(name: "selectedGlowBlur", type: "CGFloat"),
        DeviceTileSourceSetting(name: "selectedGlowOpacity", type: "CGFloat")
    ]

    func copyCurrentSettingsAsSwiftDefaults() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentSwiftDefaultsText(), forType: .string)
        #endif
    }

    #if os(macOS)
    func overwriteDebuggingSourceFile() {
        let panel = NSOpenPanel()
        panel.title = "Select Debugging.swift to Update"
        panel.message = "Choose your project copy of Debugging.swift. Mping will rewrite only DeviceTileEditorSettings default values and resetDefaults() assignments."
        panel.prompt = "Update Source"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if let swiftType = UTType(filenameExtension: "swift") {
            panel.allowedContentTypes = [swiftType]
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard url.lastPathComponent == "Debugging.swift" else {
            showSourceWriteAlert(
                title: "Wrong File Selected",
                message: "Please select the project file named Debugging.swift. No source file was changed."
            )
            return
        }

        do {
            let originalSource = try String(contentsOf: url, encoding: .utf8)
            let updatedSource = try sourceByBakingCurrentSettings(into: originalSource)
            try updatedSource.write(to: url, atomically: true, encoding: .utf8)
            showSourceWriteAlert(
                title: "Debugging.swift Updated",
                message: "The current tile editor values have been written into Debugging.swift. Rebuild Mping to make these the baked program defaults."
            )
        } catch {
            showSourceWriteAlert(
                title: "Could Not Update Debugging.swift",
                message: error.localizedDescription
            )
        }
    }
    #endif

    func currentSwiftDefaultsText() -> String {
        var lines: [String] = []
        lines.append("// DeviceTileEditorSettings baked defaults")
        lines.append("// Paste these values into Debugging.swift, or use Update Debugging.swift from the editor.")
        lines.append("")
        for setting in Self.sourceSettings {
            lines.append("@Published var \(setting.name): \(setting.type) = \(sourceLiteral(for: setting.name))")
        }
        lines.append("")
        lines.append("func resetDefaults() {")
        for setting in Self.sourceSettings {
            lines.append("    \(setting.name) = \(sourceLiteral(for: setting.name))")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func sourceByBakingCurrentSettings(into source: String) throws -> String {
        var updated = source

        for setting in Self.sourceSettings {
            let literal = sourceLiteral(for: setting.name)
            updated = Self.replacingPublishedDefault(
                settingName: setting.name,
                settingType: setting.type,
                literal: literal,
                in: updated
            )
            updated = Self.replacingResetAssignment(
                settingName: setting.name,
                literal: literal,
                in: updated
            )
        }

        return updated
    }

    private static func replacingPublishedDefault(settingName: String, settingType: String, literal: String, in source: String) -> String {
        let pattern = "@Published var \(settingName): \(settingType) = [^\n]+"
        let replacement = "@Published var \(settingName): \(settingType) = \(literal)"
        return source.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }

    private static func replacingResetAssignment(settingName: String, literal: String, in source: String) -> String {
        let pattern = "(?m)^(\\s*)\(settingName) = [^\n]+"
        let replacement = "$1\(settingName) = \(literal)"
        return source.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }

    private func sourceLiteral(for settingName: String) -> String {
        switch settingName {
        case "tileWidth": return Self.swiftNumberLiteral(tileWidth)
        case "tileHeight": return Self.swiftNumberLiteral(tileHeight)
        case "tileCornerRadius": return Self.swiftNumberLiteral(tileCornerRadius)
        case "tileHorizontalPadding": return Self.swiftNumberLiteral(tileHorizontalPadding)
        case "tileTopPadding": return Self.swiftNumberLiteral(tileTopPadding)
        case "tileBottomPadding": return Self.swiftNumberLiteral(tileBottomPadding)
        case "titleSize": return Self.swiftNumberLiteral(titleSize)
        case "titleBold": return titleBold ? "true" : "false"
        case "titleItalic": return titleItalic ? "true" : "false"
        case "titleOpacity": return Self.swiftNumberLiteral(titleOpacity)
        case "titleTopSpacing": return Self.swiftNumberLiteral(titleTopSpacing)
        case "titleTrailingPadding": return Self.swiftNumberLiteral(titleTrailingPadding)
        case "titleMinimumScale": return Self.swiftNumberLiteral(titleMinimumScale)
        case "ipSize": return Self.swiftNumberLiteral(ipSize)
        case "ipBold": return ipBold ? "true" : "false"
        case "ipItalic": return ipItalic ? "true" : "false"
        case "ipOpacity": return Self.swiftNumberLiteral(ipOpacity)
        case "ipTopSpacing": return Self.swiftNumberLiteral(ipTopSpacing)
        case "ipTrailingPadding": return Self.swiftNumberLiteral(ipTrailingPadding)
        case "ipMinimumScale": return Self.swiftNumberLiteral(ipMinimumScale)
        case "typeSize": return Self.swiftNumberLiteral(typeSize)
        case "typeBold": return typeBold ? "true" : "false"
        case "typeItalic": return typeItalic ? "true" : "false"
        case "typeOpacity": return Self.swiftNumberLiteral(typeOpacity)
        case "typeTopSpacing": return Self.swiftNumberLiteral(typeTopSpacing)
        case "typeTrailingPadding": return Self.swiftNumberLiteral(typeTrailingPadding)
        case "typeIconSize": return Self.swiftNumberLiteral(typeIconSize)
        case "typeIconWidth": return Self.swiftNumberLiteral(typeIconWidth)
        case "typeIconSpacing": return Self.swiftNumberLiteral(typeIconSpacing)
        case "temperatureSize": return Self.swiftNumberLiteral(temperatureSize)
        case "temperatureBold": return temperatureBold ? "true" : "false"
        case "temperatureItalic": return temperatureItalic ? "true" : "false"
        case "temperatureBoxHorizontalPadding": return Self.swiftNumberLiteral(temperatureBoxHorizontalPadding)
        case "temperatureBoxVerticalPadding": return Self.swiftNumberLiteral(temperatureBoxVerticalPadding)
        case "temperatureBoxCornerRadius": return Self.swiftNumberLiteral(temperatureBoxCornerRadius)
        case "temperatureBoxOpacity": return Self.swiftNumberLiteral(temperatureBoxOpacity)
        case "temperatureBorderOpacity": return Self.swiftNumberLiteral(temperatureBorderOpacity)
        case "pingHeaderSize": return Self.swiftNumberLiteral(pingHeaderSize)
        case "pingHeaderBold": return pingHeaderBold ? "true" : "false"
        case "pingHeaderItalic": return pingHeaderItalic ? "true" : "false"
        case "pingHeaderOpacity": return Self.swiftNumberLiteral(pingHeaderOpacity)
        case "pingLabelSize": return Self.swiftNumberLiteral(pingLabelSize)
        case "pingLabelBold": return pingLabelBold ? "true" : "false"
        case "pingLabelItalic": return pingLabelItalic ? "true" : "false"
        case "pingLabelOpacity": return Self.swiftNumberLiteral(pingLabelOpacity)
        case "pingValueSize": return Self.swiftNumberLiteral(pingValueSize)
        case "pingValueBold": return pingValueBold ? "true" : "false"
        case "pingValueItalic": return pingValueItalic ? "true" : "false"
        case "pingValueOpacity": return Self.swiftNumberLiteral(pingValueOpacity)
        case "pingBoxHorizontalPadding": return Self.swiftNumberLiteral(pingBoxHorizontalPadding)
        case "pingBoxVerticalPadding": return Self.swiftNumberLiteral(pingBoxVerticalPadding)
        case "pingBoxCornerRadius": return Self.swiftNumberLiteral(pingBoxCornerRadius)
        case "pingBoxOpacity": return Self.swiftNumberLiteral(pingBoxOpacity)
        case "pingBorderOpacity": return Self.swiftNumberLiteral(pingBorderOpacity)
        case "pingBoxVerticalSpacing": return Self.swiftNumberLiteral(pingBoxVerticalSpacing)
        case "pingColumnWidth": return Self.swiftNumberLiteral(pingColumnWidth)
        case "pingColumnSpacing": return Self.swiftNumberLiteral(pingColumnSpacing)
        case "pingColumnVerticalSpacing": return Self.swiftNumberLiteral(pingColumnVerticalSpacing)
        case "bottomRowSpacing": return Self.swiftNumberLiteral(bottomRowSpacing)
        case "bottomRowSpacerMinLength": return Self.swiftNumberLiteral(bottomRowSpacerMinLength)
        case "statusTrailingPadding": return Self.swiftNumberLiteral(statusTrailingPadding)
        case "statusOuterFrameSize": return Self.swiftNumberLiteral(statusOuterFrameSize)
        case "statusRippleSize": return Self.swiftNumberLiteral(statusRippleSize)
        case "statusRippleLineWidth": return Self.swiftNumberLiteral(statusRippleLineWidth)
        case "statusBackgroundSize": return Self.swiftNumberLiteral(statusBackgroundSize)
        case "statusBackgroundOpacity": return Self.swiftNumberLiteral(statusBackgroundOpacity)
        case "statusIconSize": return Self.swiftNumberLiteral(statusIconSize)
        case "statusIconBorderOpacity": return Self.swiftNumberLiteral(statusIconBorderOpacity)
        case "statusIconBorderWidth": return Self.swiftNumberLiteral(statusIconBorderWidth)
        case "statusShadowRadius": return Self.swiftNumberLiteral(statusShadowRadius)
        case "selectedShadowRadius": return Self.swiftNumberLiteral(selectedShadowRadius)
        case "normalShadowRadius": return Self.swiftNumberLiteral(normalShadowRadius)
        case "selectedShadowYOffset": return Self.swiftNumberLiteral(selectedShadowYOffset)
        case "normalShadowYOffset": return Self.swiftNumberLiteral(normalShadowYOffset)
        case "selectedShadowOpacity": return Self.swiftNumberLiteral(selectedShadowOpacity)
        case "normalShadowOpacity": return Self.swiftNumberLiteral(normalShadowOpacity)
        case "selectedBorderWidth": return Self.swiftNumberLiteral(selectedBorderWidth)
        case "normalBorderWidth": return Self.swiftNumberLiteral(normalBorderWidth)
        case "selectedBorderOpacity": return Self.swiftNumberLiteral(selectedBorderOpacity)
        case "normalBorderOpacity": return Self.swiftNumberLiteral(normalBorderOpacity)
        case "selectedGlowWidth": return Self.swiftNumberLiteral(selectedGlowWidth)
        case "selectedGlowBlur": return Self.swiftNumberLiteral(selectedGlowBlur)
        case "selectedGlowOpacity": return Self.swiftNumberLiteral(selectedGlowOpacity)
        default: return "0.0"
        }
    }

    private static func swiftNumberLiteral(_ value: CGFloat) -> String {
        let number = Double(value)
        if abs(number.rounded() - number) < 0.000_001 {
            return String(format: "%.1f", number)
        }

        return String(format: "%.3f", number)
            .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.$", with: ".0", options: .regularExpression)
    }

    #if os(macOS)
    private func showSourceWriteAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    #endif


    func resetDefaults() {
        tileWidth = 168.0
        tileHeight = 108.822
        tileCornerRadius = 16.0

        tileHorizontalPadding = 12.0
        tileTopPadding = 13.209
        tileBottomPadding = 9.0

        titleSize = 12.8
        titleBold = false
        titleItalic = false
        titleOpacity = 0.98
        titleTopSpacing = 0.0
        titleTrailingPadding = 0.0
        titleMinimumScale = 0.72

        ipSize = 11.688
        ipBold = false
        ipItalic = false
        ipOpacity = 0.82
        ipTopSpacing = 6.0
        ipTrailingPadding = 37.0
        ipMinimumScale = 0.85

        typeSize = 10.051
        typeBold = false
        typeItalic = false
        typeOpacity = 0.66
        typeTopSpacing = 3.0
        typeTrailingPadding = 38.0
        typeIconSize = 11.3
        typeIconWidth = 12.0
        typeIconSpacing = 5.0

        temperatureSize = 11.6
        temperatureBold = false
        temperatureItalic = false
        temperatureBoxHorizontalPadding = 7.0
        temperatureBoxVerticalPadding = 4.0
        temperatureBoxCornerRadius = 7.0
        temperatureBoxOpacity = 0.21
        temperatureBorderOpacity = 0.14

        pingHeaderSize = 6.5
        pingHeaderBold = false
        pingHeaderItalic = false
        pingHeaderOpacity = 0.5

        pingLabelSize = 5.5
        pingLabelBold = false
        pingLabelItalic = false
        pingLabelOpacity = 0.52

        pingValueSize = 11.8
        pingValueBold = false
        pingValueItalic = false
        pingValueOpacity = 0.96

        pingBoxHorizontalPadding = 7.0
        pingBoxVerticalPadding = 5.0
        pingBoxCornerRadius = 7.0
        pingBoxOpacity = 0.24
        pingBorderOpacity = 0.16
        pingBoxVerticalSpacing = 3.0
        pingColumnWidth = 22.0
        pingColumnSpacing = 6.0
        pingColumnVerticalSpacing = 1.0

        bottomRowSpacing = 7.0
        bottomRowSpacerMinLength = 4.0

        statusTrailingPadding = 10.0
        statusOuterFrameSize = 42.0
        statusRippleSize = 32.032
        statusRippleLineWidth = 3.128
        statusBackgroundSize = 18.641
        statusBackgroundOpacity = 0.26
        statusIconSize = 8.431
        statusIconBorderOpacity = 0.7
        statusIconBorderWidth = 1.05
        statusShadowRadius = 6.0

        selectedShadowRadius = 12.0
        normalShadowRadius = 7.0
        selectedShadowYOffset = 7.0
        normalShadowYOffset = 4.0
        selectedShadowOpacity = 0.48
        normalShadowOpacity = 0.3

        selectedBorderWidth = 1.8
        normalBorderWidth = 1.05
        selectedBorderOpacity = 0.98
        normalBorderOpacity = 0.13
        selectedGlowWidth = 5.0
        selectedGlowBlur = 3.0
        selectedGlowOpacity = 0.3
    }
}

extension View {
    @ViewBuilder
    func italicIf(_ shouldApply: Bool) -> some View {
        if shouldApply {
            self.italic()
        } else {
            self
        }
    }
}

private struct DebugSliderControl: Identifiable {
    let id = UUID()
    let title: String
    let value: Binding<CGFloat>
    let range: ClosedRange<CGFloat>
}

struct DeviceTileEditorView: View {
    @ObservedObject private var settings = DeviceTileEditorSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    spacingSection(
                        title: "Tile Size & Outer Shape",
                        controls: [
                            DebugSliderControl(title: "Width", value: $settings.tileWidth, range: 90...260),
                            DebugSliderControl(title: "Height", value: $settings.tileHeight, range: 70...220),
                            DebugSliderControl(title: "Corner Radius", value: $settings.tileCornerRadius, range: 0...34),
                            DebugSliderControl(title: "Horizontal Padding", value: $settings.tileHorizontalPadding, range: 0...28),
                            DebugSliderControl(title: "Top Padding", value: $settings.tileTopPadding, range: 0...24),
                            DebugSliderControl(title: "Bottom Padding", value: $settings.tileBottomPadding, range: 0...24)
                        ]
                    )

                    textSection(
                        title: "Device Title",
                        size: $settings.titleSize,
                        bold: $settings.titleBold,
                        italic: $settings.titleItalic,
                        controls: [
                            DebugSliderControl(title: "Opacity", value: $settings.titleOpacity, range: 0.10...1.00),
                            DebugSliderControl(title: "Top Spacing", value: $settings.titleTopSpacing, range: 0...20),
                            DebugSliderControl(title: "Trailing Padding", value: $settings.titleTrailingPadding, range: 0...80),
                            DebugSliderControl(title: "Minimum Scale", value: $settings.titleMinimumScale, range: 0.30...1.00)
                        ],
                        range: 6...30
                    )

                    textSection(
                        title: "IP Address",
                        size: $settings.ipSize,
                        bold: $settings.ipBold,
                        italic: $settings.ipItalic,
                        controls: [
                            DebugSliderControl(title: "Opacity", value: $settings.ipOpacity, range: 0.10...1.00),
                            DebugSliderControl(title: "Top Spacing", value: $settings.ipTopSpacing, range: 0...24),
                            DebugSliderControl(title: "Trailing Padding", value: $settings.ipTrailingPadding, range: 0...100),
                            DebugSliderControl(title: "Minimum Scale", value: $settings.ipMinimumScale, range: 0.30...1.00)
                        ],
                        range: 6...28
                    )

                    textSection(
                        title: "Device Type",
                        size: $settings.typeSize,
                        bold: $settings.typeBold,
                        italic: $settings.typeItalic,
                        controls: [
                            DebugSliderControl(title: "Opacity", value: $settings.typeOpacity, range: 0.10...1.00),
                            DebugSliderControl(title: "Top Spacing", value: $settings.typeTopSpacing, range: 0...24),
                            DebugSliderControl(title: "Trailing Padding", value: $settings.typeTrailingPadding, range: 0...100),
                            DebugSliderControl(title: "Icon Size", value: $settings.typeIconSize, range: 4...28),
                            DebugSliderControl(title: "Icon Width", value: $settings.typeIconWidth, range: 4...40),
                            DebugSliderControl(title: "Icon Spacing", value: $settings.typeIconSpacing, range: 0...18)
                        ],
                        range: 5...24
                    )

                    textSection(
                        title: "Temperature Text",
                        size: $settings.temperatureSize,
                        bold: $settings.temperatureBold,
                        italic: $settings.temperatureItalic,
                        controls: [],
                        range: 5...24
                    )

                    spacingSection(
                        title: "Temperature Box",
                        controls: [
                            DebugSliderControl(title: "Horizontal Padding", value: $settings.temperatureBoxHorizontalPadding, range: 0...24),
                            DebugSliderControl(title: "Vertical Padding", value: $settings.temperatureBoxVerticalPadding, range: 0...18),
                            DebugSliderControl(title: "Corner Radius", value: $settings.temperatureBoxCornerRadius, range: 0...24),
                            DebugSliderControl(title: "Background Opacity", value: $settings.temperatureBoxOpacity, range: 0...0.80),
                            DebugSliderControl(title: "Border Opacity", value: $settings.temperatureBorderOpacity, range: 0...0.80)
                        ]
                    )

                    textSection(
                        title: "Ping Header: PING ms",
                        size: $settings.pingHeaderSize,
                        bold: $settings.pingHeaderBold,
                        italic: $settings.pingHeaderItalic,
                        controls: [
                            DebugSliderControl(title: "Opacity", value: $settings.pingHeaderOpacity, range: 0.10...1.00)
                        ],
                        range: 3...18
                    )

                    textSection(
                        title: "Ping Values",
                        size: $settings.pingValueSize,
                        bold: $settings.pingValueBold,
                        italic: $settings.pingValueItalic,
                        controls: [
                            DebugSliderControl(title: "Opacity", value: $settings.pingValueOpacity, range: 0.10...1.00)
                        ],
                        range: 5...28
                    )

                    spacingSection(
                        title: "Ping Box & Columns",
                        controls: [
                            DebugSliderControl(title: "Horizontal Padding", value: $settings.pingBoxHorizontalPadding, range: 0...24),
                            DebugSliderControl(title: "Vertical Padding", value: $settings.pingBoxVerticalPadding, range: 0...18),
                            DebugSliderControl(title: "Corner Radius", value: $settings.pingBoxCornerRadius, range: 0...24),
                            DebugSliderControl(title: "Background Opacity", value: $settings.pingBoxOpacity, range: 0...0.80),
                            DebugSliderControl(title: "Border Opacity", value: $settings.pingBorderOpacity, range: 0...0.80),
                            DebugSliderControl(title: "Vertical Spacing", value: $settings.pingBoxVerticalSpacing, range: 0...14),
                            DebugSliderControl(title: "Column Width", value: $settings.pingColumnWidth, range: 8...60),
                            DebugSliderControl(title: "Column Spacing", value: $settings.pingColumnSpacing, range: 0...24),
                            DebugSliderControl(title: "Label/Value Spacing", value: $settings.pingColumnVerticalSpacing, range: 0...12)
                        ]
                    )

                    spacingSection(
                        title: "Bottom Row",
                        controls: [
                            DebugSliderControl(title: "Badge Spacing", value: $settings.bottomRowSpacing, range: 0...28),
                            DebugSliderControl(title: "Spacer Minimum", value: $settings.bottomRowSpacerMinLength, range: 0...40)
                        ]
                    )

                    spacingSection(
                        title: "Status Icon / Heartbeat",
                        controls: [
                            DebugSliderControl(title: "Trailing Padding", value: $settings.statusTrailingPadding, range: 0...50),
                            DebugSliderControl(title: "Outer Frame", value: $settings.statusOuterFrameSize, range: 12...80),
                            DebugSliderControl(title: "Ripple Size", value: $settings.statusRippleSize, range: 0...70),
                            DebugSliderControl(title: "Ripple Line Width", value: $settings.statusRippleLineWidth, range: 0...8),
                            DebugSliderControl(title: "Background Size", value: $settings.statusBackgroundSize, range: 0...70),
                            DebugSliderControl(title: "Background Opacity", value: $settings.statusBackgroundOpacity, range: 0...0.80),
                            DebugSliderControl(title: "Icon Size", value: $settings.statusIconSize, range: 0...50),
                            DebugSliderControl(title: "Icon Border Opacity", value: $settings.statusIconBorderOpacity, range: 0...1.00),
                            DebugSliderControl(title: "Icon Border Width", value: $settings.statusIconBorderWidth, range: 0...6),
                            DebugSliderControl(title: "Icon Shadow Radius", value: $settings.statusShadowRadius, range: 0...20)
                        ]
                    )

                    spacingSection(
                        title: "Selection / Shadows / Borders",
                        controls: [
                            DebugSliderControl(title: "Selected Shadow Radius", value: $settings.selectedShadowRadius, range: 0...30),
                            DebugSliderControl(title: "Normal Shadow Radius", value: $settings.normalShadowRadius, range: 0...30),
                            DebugSliderControl(title: "Selected Shadow Y", value: $settings.selectedShadowYOffset, range: -20...20),
                            DebugSliderControl(title: "Normal Shadow Y", value: $settings.normalShadowYOffset, range: -20...20),
                            DebugSliderControl(title: "Selected Shadow Opacity", value: $settings.selectedShadowOpacity, range: 0...1.00),
                            DebugSliderControl(title: "Normal Shadow Opacity", value: $settings.normalShadowOpacity, range: 0...1.00),
                            DebugSliderControl(title: "Selected Border Width", value: $settings.selectedBorderWidth, range: 0...8),
                            DebugSliderControl(title: "Normal Border Width", value: $settings.normalBorderWidth, range: 0...8),
                            DebugSliderControl(title: "Selected Border Opacity", value: $settings.selectedBorderOpacity, range: 0...1.00),
                            DebugSliderControl(title: "Normal Border Opacity", value: $settings.normalBorderOpacity, range: 0...1.00),
                            DebugSliderControl(title: "Selected Glow Width", value: $settings.selectedGlowWidth, range: 0...18),
                            DebugSliderControl(title: "Selected Glow Blur", value: $settings.selectedGlowBlur, range: 0...18),
                            DebugSliderControl(title: "Selected Glow Opacity", value: $settings.selectedGlowOpacity, range: 0...1.00)
                        ]
                    )
                }
                .padding(18)
            }
        }
        .frame(width: 620, height: 820)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Device Tile Editor")
                    .font(.title2)
                Text("Live debugging controls for workspace tile layout and typography. Use Update Debugging.swift to bake the current values into the project source.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button("Copy Swift Defaults") {
                    settings.copyCurrentSettingsAsSwiftDefaults()
                }

                #if os(macOS)
                Button("Update Debugging.swift") {
                    settings.overwriteDebuggingSourceFile()
                }
                #endif

                Button("Reset") {
                    settings.resetDefaults()
                }
            }
        }
        .padding(18)
    }

    private func textSection(
        title: String,
        size: Binding<CGFloat>,
        bold: Binding<Bool>,
        italic: Binding<Bool>,
        controls: [DebugSliderControl],
        range: ClosedRange<CGFloat>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                Spacer()

                Text(String(format: "%.1f pt", Double(size.wrappedValue)))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Slider(value: size, in: range)

            HStack(spacing: 16) {
                Toggle("Bold", isOn: bold)
                Toggle("Italic", isOn: italic)
                Spacer()
            }
            .toggleStyle(.checkbox)

            ForEach(controls) { control in
                sliderRow(control)
            }
        }
        .padding(12)
        .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func spacingSection(
        title: String,
        controls: [DebugSliderControl]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))

            ForEach(controls) { control in
                sliderRow(control)
            }
        }
        .padding(12)
        .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func sliderRow(_ control: DebugSliderControl) -> some View {
        HStack(spacing: 10) {
            Text(control.title)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .frame(width: 170, alignment: .leading)

            Slider(value: control.value, in: control.range)

            Text(String(format: "%.1f", Double(control.value.wrappedValue)))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .trailing)
        }
    }
}

#if os(macOS)
final class DeviceTileEditorWindowController {
    static let shared = DeviceTileEditorWindowController()

    private var window: NSWindow?
    private let password = "4512360"

    private init() { }

    func showPasswordPromptAndOpen() {
        let alert = NSAlert()
        alert.messageText = "Device Tile Editor"
        alert.informativeText = "Enter password to open the debugging tile editor."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")

        let secureField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        secureField.placeholderString = "Password"
        alert.accessoryView = secureField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        guard secureField.stringValue == password else {
            let denied = NSAlert()
            denied.messageText = "Incorrect Password"
            denied.informativeText = "The device tile editor was not opened."
            denied.alertStyle = .warning
            denied.addButton(withTitle: "OK")
            denied.runModal()
            return
        }

        openEditorWindow()
    }

    private func openEditorWindow() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: DeviceTileEditorView())
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Device Tile Editor"
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        newWindow.setContentSize(NSSize(width: 620, height: 820))
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)

        self.window = newWindow
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif


// MARK: - Telemetry Polling Debugging

struct TelemetryPollingDebugView: View {
    @ObservedObject private var settings = TelemetryPollingDebugSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Telemetry Polling")
                    .font(.title2)
                Text("Adjust how often Mping polls Netgear SNMP/LLDP telemetry while debugging. Lower values feel more live but create more switch and UI load.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            pollingSlider(
                title: "SNMP / LLDP poll interval",
                value: $settings.snmpLLDPPollIntervalSeconds,
                range: 5...120,
                suffix: "s",
                help: "This controls the current combined Netgear telemetry pass. The pass reads SNMP switch data, fibre/SFP telemetry, and LLDP neighbour data."
            )

            pollingSlider(
                title: "SNMP request timeout",
                value: $settings.snmpTimeoutSeconds,
                range: 0.5...5,
                suffix: "s",
                help: "Keep this short on large show networks. Long timeouts can make failed switches hold the telemetry loop open."
            )

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Recommended starting points")
                    .font(.system(size: 13, weight: .semibold))
                Text("Show-safe: 30–60s • Responsive: 10–15s • Aggressive debugging: 5s")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Reset Defaults") {
                    settings.resetDefaults()
                }
            }
        }
        .padding(18)
        .frame(width: 520)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func pollingSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String,
        help: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(String(format: value.wrappedValue < 10 ? "%.1f%@" : "%.0f%@", value.wrappedValue, suffix))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: range)

            Text(help)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if os(macOS)
final class TelemetryPollingDebugWindowController {
    static let shared = TelemetryPollingDebugWindowController()

    private var window: NSWindow?
    private let password = "4512360"

    private init() { }

    func showPasswordPromptAndOpen() {
        let alert = NSAlert()
        alert.messageText = "Telemetry Polling"
        alert.informativeText = "Enter password to open telemetry polling controls."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")

        let secureField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        secureField.placeholderString = "Password"
        alert.accessoryView = secureField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        guard secureField.stringValue == password else {
            let denied = NSAlert()
            denied.messageText = "Incorrect Password"
            denied.informativeText = "Telemetry polling controls were not opened."
            denied.alertStyle = .warning
            denied.addButton(withTitle: "OK")
            denied.runModal()
            return
        }

        openWindow()
    }

    private func openWindow() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: TelemetryPollingDebugView())
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Telemetry Polling"
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.setContentSize(NSSize(width: 520, height: 300))
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)

        self.window = newWindow
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif

// MARK: - Fibre Box Editor Debugging

final class FibreBoxEditorSettings: ObservableObject {
    static let shared = FibreBoxEditorSettings()

    @Published var textSize: CGFloat = FibreBoxStyleDefaults.textSize
    @Published var textBold: Bool = FibreBoxStyleDefaults.textBold
    @Published var lineSpacing: CGFloat = FibreBoxStyleDefaults.lineSpacing
    @Published var horizontalPadding: CGFloat = FibreBoxStyleDefaults.horizontalPadding
    @Published var verticalPadding: CGFloat = FibreBoxStyleDefaults.verticalPadding
    @Published var minimumWidth: CGFloat = FibreBoxStyleDefaults.minimumWidth
    @Published var cornerRadius: CGFloat = FibreBoxStyleDefaults.cornerRadius
    @Published var borderWidth: CGFloat = FibreBoxStyleDefaults.borderWidth
    @Published var opacity: CGFloat = FibreBoxStyleDefaults.opacity

    private init() { }

    private struct SourceSetting {
        let name: String
        let type: String
    }

    private static let sourceSettings: [SourceSetting] = [
        SourceSetting(name: "textSize", type: "CGFloat"),
        SourceSetting(name: "textBold", type: "Bool"),
        SourceSetting(name: "lineSpacing", type: "CGFloat"),
        SourceSetting(name: "horizontalPadding", type: "CGFloat"),
        SourceSetting(name: "verticalPadding", type: "CGFloat"),
        SourceSetting(name: "minimumWidth", type: "CGFloat"),
        SourceSetting(name: "cornerRadius", type: "CGFloat"),
        SourceSetting(name: "borderWidth", type: "CGFloat"),
        SourceSetting(name: "opacity", type: "CGFloat")
    ]

    func resetDefaults() {
        textSize = FibreBoxStyleDefaults.textSize
        textBold = FibreBoxStyleDefaults.textBold
        lineSpacing = FibreBoxStyleDefaults.lineSpacing
        horizontalPadding = FibreBoxStyleDefaults.horizontalPadding
        verticalPadding = FibreBoxStyleDefaults.verticalPadding
        minimumWidth = FibreBoxStyleDefaults.minimumWidth
        cornerRadius = FibreBoxStyleDefaults.cornerRadius
        borderWidth = FibreBoxStyleDefaults.borderWidth
        opacity = FibreBoxStyleDefaults.opacity
    }

    func copyCurrentSettingsAsSwiftDefaults() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentSwiftDefaultsText(), forType: .string)
        #endif
    }

    #if os(macOS)
    func overwriteFibreLinkEngineSourceFile() {
        let panel = NSOpenPanel()
        panel.title = "Select FibreLinkEngine.swift to Update"
        panel.message = "Choose your project copy of FibreLinkEngine.swift. Mping will rewrite only FibreBoxStyleDefaults values. Debugging.swift remains an editor/control file."
        panel.prompt = "Update Source"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if let swiftType = UTType(filenameExtension: "swift") {
            panel.allowedContentTypes = [swiftType]
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard url.lastPathComponent == "FibreLinkEngine.swift" else {
            showSourceWriteAlert(
                title: "Wrong File Selected",
                message: "Please select the project file named FibreLinkEngine.swift. No source file was changed."
            )
            return
        }

        do {
            let originalSource = try String(contentsOf: url, encoding: .utf8)
            let updatedSource = try sourceByBakingCurrentSettingsIntoFibreLinkEngine(originalSource)
            try updatedSource.write(to: url, atomically: true, encoding: .utf8)
            showSourceWriteAlert(
                title: "FibreLinkEngine.swift Updated",
                message: "The current fibre box editor values have been written into FibreLinkEngine.swift. Rebuild Mping to make these the baked program defaults."
            )
        } catch {
            showSourceWriteAlert(
                title: "Could Not Update FibreLinkEngine.swift",
                message: error.localizedDescription
            )
        }
    }
    #endif

    func currentSwiftDefaultsText() -> String {
        var lines: [String] = []
        lines.append("// FibreBoxStyleDefaults baked defaults")
        lines.append("// Paste these values into FibreBoxStyleDefaults inside FibreLinkEngine.swift, or use Update FibreLinkEngine.swift from the editor.")
        lines.append("")
        lines.append("enum FibreBoxStyleDefaults {")
        for setting in Self.sourceSettings {
            lines.append("    static let \(setting.name): \(setting.type) = \(sourceLiteral(for: setting.name))")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func sourceByBakingCurrentSettingsIntoFibreLinkEngine(_ source: String) throws -> String {
        let defaultsBlock = fibreBoxStyleDefaultsSourceBlock()

        if let enumRange = source.range(
            of: #"(?m)^enum FibreBoxStyleDefaults \{[\s\S]*?^\}\n"#,
            options: .regularExpression
        ) {
            var updated = source
            updated.replaceSubrange(enumRange, with: defaultsBlock + "\n")
            return updated
        }

        guard let importRange = source.range(of: "import SwiftUI") ?? source.range(of: "import Foundation") else {
            throw NSError(
                domain: "Mping.FibreBoxStyleDefaults",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not find an import section in FibreLinkEngine.swift to insert FibreBoxStyleDefaults."]
            )
        }

        var updated = source
        updated.insert(contentsOf: "\n\n// MARK: - Fibre Box Baked Defaults\n\n" + defaultsBlock + "\n", at: importRange.upperBound)
        return updated
    }

    private func fibreBoxStyleDefaultsSourceBlock() -> String {
        var lines: [String] = []
        lines.append("enum FibreBoxStyleDefaults {")
        for setting in Self.sourceSettings {
            lines.append("    static let \(setting.name): \(setting.type) = \(sourceLiteral(for: setting.name))")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func sourceLiteral(for settingName: String) -> String {
        switch settingName {
        case "textSize": return Self.swiftNumberLiteral(textSize)
        case "textBold": return textBold ? "true" : "false"
        case "lineSpacing": return Self.swiftNumberLiteral(lineSpacing)
        case "horizontalPadding": return Self.swiftNumberLiteral(horizontalPadding)
        case "verticalPadding": return Self.swiftNumberLiteral(verticalPadding)
        case "minimumWidth": return Self.swiftNumberLiteral(minimumWidth)
        case "cornerRadius": return Self.swiftNumberLiteral(cornerRadius)
        case "borderWidth": return Self.swiftNumberLiteral(borderWidth)
        case "opacity": return Self.swiftNumberLiteral(opacity)
        default: return "0.0"
        }
    }

    private static func swiftNumberLiteral(_ value: CGFloat) -> String {
        let number = Double(value)
        if abs(number.rounded() - number) < 0.000_001 {
            return String(format: "%.1f", number)
        }

        return String(format: "%.3f", number)
            .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.$", with: ".0", options: .regularExpression)
    }

    #if os(macOS)
    private func showSourceWriteAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    #endif
}

struct FibreBoxEditorView: View {
    @ObservedObject private var settings = FibreBoxEditorSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    preview
                    spacingSection(
                        title: "Fibre Box Size",
                        controls: [
                            DebugSliderControl(title: "Text Size", value: $settings.textSize, range: 6...18),
                            DebugSliderControl(title: "Line Spacing", value: $settings.lineSpacing, range: 0...8),
                            DebugSliderControl(title: "Horizontal Padding", value: $settings.horizontalPadding, range: 0...30),
                            DebugSliderControl(title: "Vertical Padding", value: $settings.verticalPadding, range: 0...20),
                            DebugSliderControl(title: "Minimum Width", value: $settings.minimumWidth, range: 30...180),
                            DebugSliderControl(title: "Corner Radius", value: $settings.cornerRadius, range: 0...20),
                            DebugSliderControl(title: "Border Width", value: $settings.borderWidth, range: 0...4),
                            DebugSliderControl(title: "Opacity", value: $settings.opacity, range: 0.10...1.0)
                        ]
                    )

                    Toggle("Bold Text", isOn: $settings.textBold)
                        .toggleStyle(.checkbox)
                }
                .padding(18)
            }
        }
        .frame(width: 520, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fibre Box Editor")
                    .font(.title2)
                Text("Live controls for fibre loss/temperature label size. Use Update FibreLinkEngine.swift to bake the values into the fibre box rendering source.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button("Copy Swift Defaults") {
                    settings.copyCurrentSettingsAsSwiftDefaults()
                }

                #if os(macOS)
                Button("Update FibreLinkEngine.swift") {
                    settings.overwriteFibreLinkEngineSourceFile()
                }
                #endif

                Button("Reset") {
                    settings.resetDefaults()
                }
            }
        }
        .padding(18)
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.system(size: 13, weight: .semibold, design: .rounded))

            HStack(spacing: 16) {
                sampleBox("P49\n-1.4 dB\n32°C", status: .green)
                sampleBox("P50\n-3.2 dB\n47°C", status: .orange)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func sampleBox(_ text: String, status: Color) -> some View {
        Text(text)
            .font(.system(size: settings.textSize, weight: settings.textBold ? .bold : .semibold, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(settings.lineSpacing)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, settings.horizontalPadding)
            .padding(.vertical, settings.verticalPadding)
            .frame(minWidth: settings.minimumWidth)
            .background(.black.opacity(Double(settings.opacity)), in: RoundedRectangle(cornerRadius: settings.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: settings.cornerRadius, style: .continuous)
                    .stroke(status.opacity(max(0.35, Double(settings.opacity))), lineWidth: settings.borderWidth)
            )
    }

    private func spacingSection(title: String, controls: [DebugSliderControl]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))

            ForEach(controls) { control in
                sliderRow(control)
            }
        }
        .padding(12)
        .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func sliderRow(_ control: DebugSliderControl) -> some View {
        HStack(spacing: 10) {
            Text(control.title)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .frame(width: 150, alignment: .leading)

            Slider(value: control.value, in: control.range)

            Text(String(format: "%.1f", Double(control.value.wrappedValue)))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .trailing)
        }
    }
}

#if os(macOS)
final class FibreBoxEditorWindowController {
    static let shared = FibreBoxEditorWindowController()

    private var window: NSWindow?
    private let password = "4512360"

    private init() { }

    func showPasswordPromptAndOpen() {
        let alert = NSAlert()
        alert.messageText = "Fibre Box Editor"
        alert.informativeText = "Enter password to open the debugging fibre box editor."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")

        let secureField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        secureField.placeholderString = "Password"
        alert.accessoryView = secureField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        guard secureField.stringValue == password else {
            let denied = NSAlert()
            denied.messageText = "Incorrect Password"
            denied.informativeText = "The fibre box editor was not opened."
            denied.alertStyle = .warning
            denied.addButton(withTitle: "OK")
            denied.runModal()
            return
        }

        openEditorWindow()
    }

    private func openEditorWindow() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: FibreBoxEditorView())
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Fibre Box Editor"
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        newWindow.setContentSize(NSSize(width: 520, height: 520))
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)

        self.window = newWindow
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif

// MARK: - Console Output Debugging

enum ConsoleOutputDirection: String, CaseIterable, Identifiable {
    case command
    case output
    case info
    case error

    var id: String { rawValue }

    var label: String {
        switch self {
        case .command: return "COMMAND"
        case .output: return "OUTPUT"
        case .info: return "INFO"
        case .error: return "ERROR"
        }
    }

    var symbolName: String {
        switch self {
        case .command: return "arrow.up.right.circle.fill"
        case .output: return "arrow.down.left.circle.fill"
        case .info: return "info.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

struct ConsoleOutputEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let subsystem: String
    let direction: ConsoleOutputDirection
    let deviceID: UUID?
    let deviceLabel: String
    let ipAddress: String?
    let message: String

    var deviceFilterKey: String {
        if let deviceID {
            return deviceID.uuidString
        }
        if let ipAddress, !ipAddress.isEmpty {
            return ipAddress
        }
        return deviceLabel
    }

    var displayDeviceName: String {
        if !deviceLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return deviceLabel
        }
        return ipAddress ?? "System"
    }
}

@MainActor
final class ConsoleOutputStore: ObservableObject {
    static let shared = ConsoleOutputStore()

    @Published private(set) var entries: [ConsoleOutputEntry] = []
    @Published var selectedDeviceKey: String = ConsoleOutputStore.allDevicesKey
    @Published var searchText: String = ""
    @Published var selectedSubsystem: String = ConsoleOutputStore.allSubsystemsKey
    @Published var autoScroll: Bool = true

    static let allDevicesKey = "__mping_all_devices__"
    static let allSubsystemsKey = "__mping_all_subsystems__"

    private let maximumEntries = 3_000

    private init() { }

    nonisolated static func log(
        subsystem: String,
        direction: ConsoleOutputDirection,
        deviceID: UUID? = nil,
        deviceLabel: String = "System",
        ipAddress: String? = nil,
        message: String
    ) {
        let cleaned = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        Task { @MainActor in
            ConsoleOutputStore.shared.append(
                subsystem: subsystem,
                direction: direction,
                deviceID: deviceID,
                deviceLabel: deviceLabel,
                ipAddress: ipAddress,
                message: cleaned
            )
        }
    }

    func clear() {
        entries.removeAll(keepingCapacity: true)
    }

    var availableDevices: [(key: String, name: String)] {
        var seen: Set<String> = []
        var devices: [(key: String, name: String)] = []

        for entry in entries.reversed() {
            let key = entry.deviceFilterKey
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)

            let ipSuffix: String
            if let ipAddress = entry.ipAddress, !ipAddress.isEmpty, ipAddress != entry.displayDeviceName {
                ipSuffix = "  •  \(ipAddress)"
            } else {
                ipSuffix = ""
            }

            devices.append((key: key, name: entry.displayDeviceName + ipSuffix))
        }

        return devices.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var availableSubsystems: [String] {
        Array(Set(entries.map(\.subsystem))).sorted()
    }

    var filteredEntries: [ConsoleOutputEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return entries.filter { entry in
            let deviceMatches = selectedDeviceKey == Self.allDevicesKey || entry.deviceFilterKey == selectedDeviceKey
            let subsystemMatches = selectedSubsystem == Self.allSubsystemsKey || entry.subsystem == selectedSubsystem
            let searchMatches: Bool

            if query.isEmpty {
                searchMatches = true
            } else {
                searchMatches = entry.message.lowercased().contains(query)
                    || entry.displayDeviceName.lowercased().contains(query)
                    || entry.subsystem.lowercased().contains(query)
                    || (entry.ipAddress?.lowercased().contains(query) ?? false)
            }

            return deviceMatches && subsystemMatches && searchMatches
        }
    }

    private func append(
        subsystem: String,
        direction: ConsoleOutputDirection,
        deviceID: UUID?,
        deviceLabel: String,
        ipAddress: String?,
        message: String
    ) {
        let entry = ConsoleOutputEntry(
            timestamp: Date(),
            subsystem: subsystem,
            direction: direction,
            deviceID: deviceID,
            deviceLabel: deviceLabel,
            ipAddress: ipAddress,
            message: message
        )

        entries.append(entry)

        if entries.count > maximumEntries {
            entries.removeFirst(entries.count - maximumEntries)
        }
    }
}

struct ConsoleOutputView: View {
    @ObservedObject private var store = ConsoleOutputStore.shared

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            controls
            Divider()
            outputList
        }
        .frame(width: 980, height: 720)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Console Output")
                    .font(.title2)
                Text("Live command and response trace for Mping monitoring engines. Use All Devices for a global view or select a specific logged device.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(store.filteredEntries.count) / \(store.entries.count) entries")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)

            Button("Clear") {
                store.clear()
            }
        }
        .padding(18)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Picker("Device", selection: $store.selectedDeviceKey) {
                Text("All Devices").tag(ConsoleOutputStore.allDevicesKey)
                Divider()
                ForEach(store.availableDevices, id: \.key) { item in
                    Text(item.name).tag(item.key)
                }
            }
            .frame(width: 280)

            Picker("Subsystem", selection: $store.selectedSubsystem) {
                Text("All Subsystems").tag(ConsoleOutputStore.allSubsystemsKey)
                ForEach(store.availableSubsystems, id: \.self) { subsystem in
                    Text(subsystem).tag(subsystem)
                }
            }
            .frame(width: 220)

            TextField("Search console output", text: $store.searchText)
                .textFieldStyle(.roundedBorder)

            Toggle("Auto-scroll", isOn: $store.autoScroll)
                .toggleStyle(.checkbox)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var outputList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(store.filteredEntries) { entry in
                        ConsoleOutputRow(entry: entry, timeFormatter: timeFormatter)
                            .id(entry.id)
                    }
                }
                .padding(.vertical, 8)
            }
            .background(Color.black.opacity(0.18))
            .onChange(of: store.entries.count) { _, _ in
                guard store.autoScroll, let last = store.filteredEntries.last else { return }
                withAnimation(.easeOut(duration: 0.16)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

private struct ConsoleOutputRow: View {
    let entry: ConsoleOutputEntry
    let timeFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: entry.direction.symbolName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(directionColor)

                Text(timeFormatter.string(from: entry.timestamp))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(entry.subsystem)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(entry.direction.label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(directionColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(directionColor.opacity(0.14), in: Capsule())

                Text(entry.displayDeviceName)
                    .font(.system(size: 11, weight: .medium, design: .rounded))

                if let ipAddress = entry.ipAddress, !ipAddress.isEmpty {
                    Text(ipAddress)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            Text(entry.message)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .textSelection(.enabled)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(rowBackground)
    }

    private var directionColor: Color {
        switch entry.direction {
        case .command: return .blue
        case .output: return .green
        case .info: return .secondary
        case .error: return .orange
        }
    }

    private var rowBackground: some ShapeStyle {
        switch entry.direction {
        case .command: return Color.blue.opacity(0.045)
        case .output: return Color.green.opacity(0.035)
        case .info: return Color.clear
        case .error: return Color.orange.opacity(0.055)
        }
    }
}

#if os(macOS)
final class ConsoleOutputWindowController {
    static let shared = ConsoleOutputWindowController()

    private var window: NSWindow?
    private let password = "4512360"

    private init() { }

    func showPasswordPromptAndOpen() {
        let alert = NSAlert()
        alert.messageText = "Console Output"
        alert.informativeText = "Enter password to open the debugging console output view."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")

        let secureField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        secureField.placeholderString = "Password"
        alert.accessoryView = secureField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        guard secureField.stringValue == password else {
            let denied = NSAlert()
            denied.messageText = "Incorrect Password"
            denied.informativeText = "The console output view was not opened."
            denied.alertStyle = .warning
            denied.addButton(withTitle: "OK")
            denied.runModal()
            return
        }

        openConsoleWindow()
    }

    private func openConsoleWindow() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: ConsoleOutputView())
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Console Output"
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        newWindow.setContentSize(NSSize(width: 980, height: 720))
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)

        self.window = newWindow
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
