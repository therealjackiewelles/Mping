import SwiftUI
import AppKit
import Combine
#if os(macOS)
import UniformTypeIdentifiers
#endif

// MARK: - Device Tile Editor Settings

enum NetgearTopField: String, CaseIterable, Identifiable {
    case deviceName = "Device Name"
    case ipAddress = "IP Address"
    case deviceType = "Device Type"
    var id: String { rawValue }
}

final class DeviceTileEditorSettings: ObservableObject {
    static let shared = DeviceTileEditorSettings()

    @Published var tileWidth: CGFloat = 153.114
    @Published var tileHeight: CGFloat = 83.16
    @Published var tileCornerRadius: CGFloat = 10.034

    @Published var tileHorizontalPadding: CGFloat = 8.169
    @Published var tileTopPadding: CGFloat = 7.158
    @Published var tileBottomPadding: CGFloat = 4.791

    @Published var titleSize: CGFloat = 13.3
    @Published var titleBold: Bool = false
    @Published var titleItalic: Bool = false
    @Published var titleOpacity: CGFloat = 0.98
    @Published var titleTopSpacing: CGFloat = 0.0
    @Published var titleTrailingPadding: CGFloat = 0.0
    @Published var titleMinimumScale: CGFloat = 1.0

    @Published var ipSize: CGFloat = 10.394
    @Published var ipBold: Bool = false
    @Published var ipItalic: Bool = false
    @Published var ipOpacity: CGFloat = 0.482
    @Published var ipTopSpacing: CGFloat = 2.39
    @Published var ipTrailingPadding: CGFloat = 32.193
    @Published var ipMinimumScale: CGFloat = 0.833

    @Published var typeSize: CGFloat = 10.051
    @Published var typeBold: Bool = false
    @Published var typeItalic: Bool = false
    @Published var typeOpacity: CGFloat = 0.446
    @Published var typeTopSpacing: CGFloat = 1.395
    @Published var typeTrailingPadding: CGFloat = 38.0
    @Published var typeIconSize: CGFloat = 11.235
    @Published var typeIconWidth: CGFloat = 12.063
    @Published var typeIconSpacing: CGFloat = 3.008

    @Published var temperatureSize: CGFloat = 11.075
    @Published var temperatureBold: Bool = false
    @Published var temperatureItalic: Bool = false
    @Published var temperatureBoxHorizontalPadding: CGFloat = 7.0
    @Published var temperatureBoxVerticalPadding: CGFloat = 4.0
    @Published var temperatureBoxCornerRadius: CGFloat = 7.0
    @Published var temperatureBoxOpacity: CGFloat = 0.21
    @Published var temperatureBorderOpacity: CGFloat = 0.14

    @Published var pingHeaderSize: CGFloat = 8.253
    @Published var pingHeaderBold: Bool = false
    @Published var pingHeaderItalic: Bool = false
    @Published var pingHeaderOpacity: CGFloat = 0.5

    @Published var pingLabelSize: CGFloat = 5.5
    @Published var pingLabelBold: Bool = false
    @Published var pingLabelItalic: Bool = false
    @Published var pingLabelOpacity: CGFloat = 0.52

    @Published var pingValueSize: CGFloat = 11.075
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

    // Field ordering for netgear tile top section
    @Published var netgearTopFieldOrder: [NetgearTopField] = [.deviceName, .ipAddress, .deviceType]

    // Ping-only tile settings
    @Published var pingOnlyTileHeight: CGFloat = 44.063
    @Published var pingOnlyLatencySize: CGFloat = 10.0
    @Published var pingOnlyIPSize: CGFloat = 10.037
    @Published var pingOnlyBadgeHPadding: CGFloat = 5.0
    @Published var pingOnlyBadgeVPadding: CGFloat = 3.0
    @Published var pingOnlyBadgeCornerRadius: CGFloat = 5.0
    @Published var pingOnlyBadgeSpacing: CGFloat = 6.0
    @Published var pingOnlyHPadding: CGFloat = 8.019
    @Published var pingOnlyVPadding: CGFloat = 7.0

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
        DeviceTileSourceSetting(name: "selectedGlowOpacity", type: "CGFloat"),
        DeviceTileSourceSetting(name: "netgearTopFieldOrder", type: "[NetgearTopField]"),
        DeviceTileSourceSetting(name: "pingOnlyTileHeight", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingOnlyLatencySize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingOnlyIPSize", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingOnlyBadgeHPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingOnlyBadgeVPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingOnlyBadgeCornerRadius", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingOnlyBadgeSpacing", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingOnlyHPadding", type: "CGFloat"),
        DeviceTileSourceSetting(name: "pingOnlyVPadding", type: "CGFloat")
    ]

    func copyCurrentSettingsAsSwiftDefaults() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentSwiftDefaultsText(), forType: .string)
        #endif
    }

    #if os(macOS)
    func overwriteWorkspaceViewSourceFile() {
        let panel = NSOpenPanel()
        panel.title = "Select WorkspaceView.swift to Update"
        panel.message = "Choose your project copy of WorkspaceView.swift. Mping will rewrite only DeviceTileEditorSettings default values and resetDefaults() assignments."
        panel.prompt = "Update Source"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if let swiftType = UTType(filenameExtension: "swift") {
            panel.allowedContentTypes = [swiftType]
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard url.lastPathComponent == "WorkspaceView.swift" else {
            showSourceWriteAlert(
                title: "Wrong File Selected",
                message: "Please select the project file named WorkspaceView.swift. No source file was changed."
            )
            return
        }

        do {
            let originalSource = try String(contentsOf: url, encoding: .utf8)
            let updatedSource = try sourceByBakingCurrentSettings(into: originalSource)
            try updatedSource.write(to: url, atomically: true, encoding: .utf8)
            showSourceWriteAlert(
                title: "WorkspaceView.swift Updated",
                message: "The current tile editor values have been written into WorkspaceView.swift. Rebuild Mping to make these the baked program defaults."
            )
        } catch {
            showSourceWriteAlert(
                title: "Could Not Update WorkspaceView.swift",
                message: error.localizedDescription
            )
        }
    }
    #endif

    func currentSwiftDefaultsText() -> String {
        var lines: [String] = []
        lines.append("// DeviceTileEditorSettings baked defaults")
        lines.append("// Paste these values into WorkspaceView.swift, or use Update WorkspaceView.swift from the editor.")
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
            updated = Self.replacingPublishedDefault(settingName: setting.name, settingType: setting.type, literal: literal, in: updated)
            updated = Self.replacingResetAssignment(settingName: setting.name, literal: literal, in: updated)
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
        case "netgearTopFieldOrder":
            let fieldLiterals = netgearTopFieldOrder.map { f -> String in
                switch f {
                case .deviceName: return ".deviceName"
                case .ipAddress: return ".ipAddress"
                case .deviceType: return ".deviceType"
                }
            }
            return "[\(fieldLiterals.joined(separator: ", "))]"
        case "pingOnlyTileHeight": return Self.swiftNumberLiteral(pingOnlyTileHeight)
        case "pingOnlyLatencySize": return Self.swiftNumberLiteral(pingOnlyLatencySize)
        case "pingOnlyIPSize": return Self.swiftNumberLiteral(pingOnlyIPSize)
        case "pingOnlyBadgeHPadding": return Self.swiftNumberLiteral(pingOnlyBadgeHPadding)
        case "pingOnlyBadgeVPadding": return Self.swiftNumberLiteral(pingOnlyBadgeVPadding)
        case "pingOnlyBadgeCornerRadius": return Self.swiftNumberLiteral(pingOnlyBadgeCornerRadius)
        case "pingOnlyBadgeSpacing": return Self.swiftNumberLiteral(pingOnlyBadgeSpacing)
        case "pingOnlyHPadding": return Self.swiftNumberLiteral(pingOnlyHPadding)
        case "pingOnlyVPadding": return Self.swiftNumberLiteral(pingOnlyVPadding)
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
        tileWidth = 153.114
        tileHeight = 83.16
        tileCornerRadius = 10.034

        tileHorizontalPadding = 8.169
        tileTopPadding = 7.158
        tileBottomPadding = 4.791

        titleSize = 13.3
        titleBold = false
        titleItalic = false
        titleOpacity = 0.98
        titleTopSpacing = 0.0
        titleTrailingPadding = 0.0
        titleMinimumScale = 1.0

        ipSize = 10.394
        ipBold = false
        ipItalic = false
        ipOpacity = 0.482
        ipTopSpacing = 2.39
        ipTrailingPadding = 32.193
        ipMinimumScale = 0.833

        typeSize = 10.051
        typeBold = false
        typeItalic = false
        typeOpacity = 0.446
        typeTopSpacing = 1.395
        typeTrailingPadding = 38.0
        typeIconSize = 11.235
        typeIconWidth = 12.063
        typeIconSpacing = 3.008

        temperatureSize = 11.075
        temperatureBold = false
        temperatureItalic = false
        temperatureBoxHorizontalPadding = 7.0
        temperatureBoxVerticalPadding = 4.0
        temperatureBoxCornerRadius = 7.0
        temperatureBoxOpacity = 0.21
        temperatureBorderOpacity = 0.14

        pingHeaderSize = 8.253
        pingHeaderBold = false
        pingHeaderItalic = false
        pingHeaderOpacity = 0.5

        pingLabelSize = 5.5
        pingLabelBold = false
        pingLabelItalic = false
        pingLabelOpacity = 0.52

        pingValueSize = 11.075
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

        netgearTopFieldOrder = [.deviceName, .deviceType, .ipAddress]
        pingOnlyTileHeight = 44.063
        pingOnlyLatencySize = 10.0
        pingOnlyIPSize = 10.037
        pingOnlyBadgeHPadding = 5.0
        pingOnlyBadgeVPadding = 3.0
        pingOnlyBadgeCornerRadius = 5.0
        pingOnlyBadgeSpacing = 6.0
        pingOnlyHPadding = 8.019
        pingOnlyVPadding = 7.0
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

// MARK: - WorkspaceView

struct WorkspaceView: View {
    @ObservedObject var store: DeviceStore
    @ObservedObject private var preferences = AppPreferences.shared
    var searchText: String = ""
    // Pre-filtered by the active redundant network tab (passed from WorkspacePlaneCoordinator).
    // When there are no redundant pairs this is always store.devices.
    var visibleDevices: [MonitoredDevice]
    var boxTint: Color? = nil
    var isTemperatureMode: Bool = false
    // Viewport state is owned by WorkspacePlaneCoordinator and shared across planes
    // via @Binding so switching planes never resets zoom or pan position.
    @Binding var liveScale: Double
    @Binding var liveOffset: CGSize

    @State private var deviceDragStart: [UUID: CGPoint] = [:]
    @State private var shapeDragStart: [UUID: CGPoint] = [:]
    @State private var selectionStart: CGPoint? = nil
    @State private var selectionCurrent: CGPoint? = nil
    @State private var hoverPoint: CGPoint? = nil
    @State private var resizingShapeID: UUID? = nil
    @State private var shapeResizeStartFrames: [UUID: CGRect] = [:]
    @State private var syncTask: Task<Void, Never>? = nil
    @State private var tileSettingsRevision: Int = 0

    private let canvasSize = CGSize(width: 5000, height: 3000)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.clearSelection()
                    }

                ZStack(alignment: .topLeading) {
                    grid

                    FibreLinksLayer(
                        devicePositions: Dictionary(uniqueKeysWithValues: visibleDevices.map { ($0.id, CGPoint(x: $0.x, y: $0.y)) }),
                        links: store.cachedFibreResults,
                        fibreLabelOffset: store.fibreLabelOffset,
                        setFibreLabelOffset: store.setFibreLabelOffset,
                        showLines: true,
                        showLabels: false,
                        animated: !isTemperatureMode
                    )
                    .equatable()
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .allowsHitTesting(false)

                    ForEach(store.shapes) { shape in
                        WorkspaceShapeView(
                            shape: shape,
                            isSelected: store.selectedShapeIDs.contains(shape.id),
                            tint: boxTint,
                            onResizeStart: {
                                resizingShapeID = shape.id
                                shapeResizeStartFrames[shape.id] = CGRect(
                                    x: shape.x,
                                    y: shape.y,
                                    width: shape.width,
                                    height: shape.height
                                )

                                if !store.selectedShapeIDs.contains(shape.id) {
                                    store.selectOnlyShape(shape.id)
                                }
                            },
                            onResize: { anchor, translation in
                                let startFrame = shapeResizeStartFrames[shape.id] ?? CGRect(
                                    x: shape.x,
                                    y: shape.y,
                                    width: shape.width,
                                    height: shape.height
                                )

                                store.resizeShape(
                                    id: shape.id,
                                    anchor: anchor,
                                    startFrame: startFrame,
                                    translation: translation,
                                    scale: liveScale
                                )
                            },
                            onResizeEnd: {
                                resizingShapeID = nil
                                shapeResizeStartFrames.removeValue(forKey: shape.id)
                            }
                        )
                        .position(
                            x: shape.x + shape.width / 2,
                            y: shape.y + shape.height / 2
                        )
                        .onTapGesture {
                            if isMultiSelectModifierPressed {
                                store.toggleShapeSelection(shape.id)
                            } else {
                                store.selectOnlyShape(shape.id)
                            }
                        }
                        .simultaneousGesture(shapeDragGesture(shape))
                    }

                    ForEach(visibleDevices) { device in
                        MpingMapDeviceTileView(
                            device: device,
                            isSelected: store.selectedDeviceIDs.contains(device.id),
                            shouldShowSecondaryDetail: liveScale >= 0.52,
                            hasAlert: store.deviceIDsWithCurrentAlerts.contains(device.id),
                            isFlashing: store.flashingDeviceIDs.contains(device.id),
                            redundantModeActive: store.redundantModeActive,
                            primaryBadgeColor: preferences.redundantPrimaryBadgeColor,
                            secondaryBadgeColor: preferences.redundantSecondaryBadgeColor,
                            isTemperatureMode: isTemperatureMode,
                            tileSettingsRevision: tileSettingsRevision
                        )
                        .equatable()
                        .opacity(deviceMatchesSearch(device) ? 1.0 : 0.22)
                        .position(x: device.x, y: device.y)
                        .onTapGesture {
                            if isMultiSelectModifierPressed {
                                store.toggleDeviceSelection(device.id)
                            } else if store.selectedDeviceIDs == [device.id] {
                                store.clearSelection()
                            } else {
                                store.selectOnlyDevice(device.id)
                            }
                        }
                        .simultaneousGesture(deviceDragGesture(device))
                    }

                    FibreLinksLayer(
                        devicePositions: Dictionary(uniqueKeysWithValues: visibleDevices.map { ($0.id, CGPoint(x: $0.x, y: $0.y)) }),
                        links: store.cachedFibreResults,
                        fibreLabelOffset: store.fibreLabelOffset,
                        setFibreLabelOffset: store.setFibreLabelOffset,
                        showLines: false,
                        showLabels: true,
                        animated: !isTemperatureMode
                    )
                    .equatable()
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .zIndex(9999)
                }
                .frame(
                    width: canvasSize.width,
                    height: canvasSize.height,
                    alignment: .topLeading
                )
                .scaleEffect(liveScale, anchor: .topLeading)
                .offset(liveOffset)

                if let rect = selectionRect {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.13))
                        .overlay(
                            Rectangle()
                                .stroke(
                                    Color.accentColor.opacity(0.9),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                )
                        )
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .allowsHitTesting(false)
                }

                WorkspaceEventCatcher(
                    isSnapToGridEnabled: store.snapToGridEnabled,
                    gridSize: store.snapGridSize,
                    hasSelection: store.hasSelection,
                    hasClipboardContent: store.hasClipboardContent,
                    onScroll: { delta in
                        let point = hoverPoint ?? CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        applyLiveZoom(delta: delta, around: point)
                    },
                    onRightPan: { delta in
                        liveOffset.width += delta.width
                        liveOffset.height += delta.height
                        scheduleSyncToStore()
                    },
                    onToggleSnapToGrid: {
                        store.snapToGridEnabled.toggle()
                    },
                    onSetGridSize: { size in
                        store.snapGridSize = size
                        store.snapToGridEnabled = true
                    },
                    onCopySelection: {
                        store.copySelection()
                    },
                    onPaste: {
                        store.pasteSelection()
                    },
                    onClearTopologyLinks: {
                        store.clearAllTopologyLinks()
                    },
                    deviceAt: { swiftUIPoint in
                        let scale = liveScale
                        let offset = liveOffset
                        let canvasX = (swiftUIPoint.x - offset.width) / scale
                        let canvasY = (swiftUIPoint.y - offset.height) / scale
                        let halfW = DeviceTileEditorSettings.shared.tileWidth / 2
                        let halfH = DeviceTileEditorSettings.shared.tileHeight / 2
                        return visibleDevices.first {
                            abs(CGFloat($0.x) - canvasX) <= halfW &&
                            abs(CGFloat($0.y) - canvasY) <= halfH
                        }
                    },
                    shapeAt: { swiftUIPoint in
                        let scale = liveScale
                        let offset = liveOffset
                        let canvasX = (swiftUIPoint.x - offset.width) / scale
                        let canvasY = (swiftUIPoint.y - offset.height) / scale
                        let pt = CGPoint(x: canvasX, y: canvasY)
                        return store.shapes.first {
                            CGRect(x: $0.x, y: $0.y, width: $0.width, height: $0.height).contains(pt)
                        }
                    },
                    onSelectionBoxChange: { start, current in
                        selectionStart = start
                        selectionCurrent = current
                    },
                    onSelectionBoxClear: {
                        selectionStart = nil
                        selectionCurrent = nil
                    },
                    onBoxSelectEnd: { start, end in
                        let viewRect = CGRect(
                            x: min(start.x, end.x),
                            y: min(start.y, end.y),
                            width: abs(end.x - start.x),
                            height: abs(end.y - start.y)
                        )
                        let scale = liveScale
                        let offset = liveOffset
                        let worldTopLeft = CGPoint(
                            x: (viewRect.minX - offset.width) / scale,
                            y: (viewRect.minY - offset.height) / scale
                        )
                        let worldBottomRight = CGPoint(
                            x: (viewRect.maxX - offset.width) / scale,
                            y: (viewRect.maxY - offset.height) / scale
                        )
                        let worldRect = CGRect(
                            x: min(worldTopLeft.x, worldBottomRight.x),
                            y: min(worldTopLeft.y, worldBottomRight.y),
                            width: abs(worldBottomRight.x - worldTopLeft.x),
                            height: abs(worldBottomRight.y - worldTopLeft.y)
                        )
                        let selectedDevices = Set(
                            visibleDevices.filter { device in
                                worldRect.intersects(CGRect(x: device.x - 85, y: device.y - 52, width: 170, height: 104))
                            }.map(\.id)
                        )
                        let selectedShapes = Set(
                            store.shapes.filter { shape in
                                worldRect.intersects(CGRect(x: shape.x, y: shape.y, width: shape.width, height: shape.height))
                            }.map(\.id)
                        )
                        store.setSelection(deviceIDs: selectedDevices, shapeIDs: selectedShapes)
                    },
                    onOpenWebInterface: { id in store.openWebInterface(for: id) },
                    onSelectDevice: { id in store.selectOnlyDevice(id) },
                    onCopyDevice: { id in store.selectOnlyDevice(id); store.copySelection() },
                    onCutDevice: { id in store.selectOnlyDevice(id); store.cutSelection() },
                    onDuplicateDevice: { id in
                        store.selectOnlyDevice(id)
                        store.copySelection()
                        store.pasteSelection()
                    },
                    onDeleteDevice: { id in store.selectOnlyDevice(id); store.deleteSelection() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverPoint = location
                case .ended:
                    hoverPoint = nil
                }
            }
            .onChange(of: store.pendingFocusDeviceID) { _, id in
                guard let id,
                      let device = store.devices.first(where: { $0.id == id }) else { return }
                let savedOffset = liveOffset
                let inspectorWidth: CGFloat = store.hasSelection ? store.inspectorWidth : 0
                let visibleWidth = proxy.size.width - inspectorWidth
                let targetOffsetX = visibleWidth / 2 - device.x * liveScale
                let targetOffsetY = proxy.size.height / 2 - device.y * liveScale
                let targetOffset = CGSize(width: targetOffsetX, height: targetOffsetY)
                withAnimation(.easeInOut(duration: 0.55)) {
                    liveOffset = targetOffset
                }
                store.pendingFocusDeviceID = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.55)) {
                        liveOffset = savedOffset
                    }
                }
            }
            .onAppear {
                liveOffset = store.workspaceOffset
                liveScale = store.workspaceScale
            }
            .onReceive(DeviceTileEditorSettings.shared.objectWillChange) { _ in
                tileSettingsRevision += 1
            }
            .clipped()
            .background(Color(red: 0.055, green: 0.055, blue: 0.06))
        }
    }

    private func applyLiveZoom(delta: Double, around point: CGPoint) {
        guard delta != 0 else { return }
        let step = 0.03
        let direction = delta > 0 ? 1.0 : -1.0
        let oldScale = liveScale
        let newScale = min(3.5, max(0.25, oldScale + (step * direction)))
        guard newScale != oldScale else { return }
        let worldX = (point.x - liveOffset.width) / oldScale
        let worldY = (point.y - liveOffset.height) / oldScale
        liveScale = newScale
        liveOffset.width = point.x - (worldX * newScale)
        liveOffset.height = point.y - (worldY * newScale)
        scheduleSyncToStore()
    }

    private func scheduleSyncToStore() {
        syncTask?.cancel()
        syncTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            store.workspaceOffset = liveOffset
            store.workspaceScale = liveScale
        }
    }

    private var isMultiSelectModifierPressed: Bool {
        NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command)
    }

    private var background: some View {
        Rectangle()
            .fill(Color(red: 0.055, green: 0.055, blue: 0.06))
    }

    private var selectionRect: CGRect? {
        guard let start = selectionStart, let current = selectionCurrent else { return nil }

        return CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }

    private var grid: some View {
        Canvas { context, size in
            let spacing: CGFloat = 40
            var path = Path()

            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }

            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }

            context.stroke(path, with: .color(.white.opacity(0.055)), lineWidth: 1)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(false)
    }

    private func deviceDragGesture(_ device: MonitoredDevice) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if !store.selectedDeviceIDs.contains(device.id) {
                    store.selectOnlyDevice(device.id)
                }

                if deviceDragStart.isEmpty && shapeDragStart.isEmpty {
                    store.beginUndoTransaction()
                }

                if deviceDragStart.isEmpty {
                    let deviceIDs = store.selectedDeviceIDs.contains(device.id) ? store.selectedDeviceIDs : [device.id]

                    for id in deviceIDs {
                        if let d = store.devices.first(where: { $0.id == id }) {
                            deviceDragStart[id] = CGPoint(x: d.x, y: d.y)
                        }
                    }
                }

                if shapeDragStart.isEmpty {
                    for id in store.selectedShapeIDs {
                        if let s = store.shapes.first(where: { $0.id == id }) {
                            shapeDragStart[id] = CGPoint(x: s.x, y: s.y)
                        }
                    }
                }

                store.moveSelectedItems(
                    deviceStartPositions: deviceDragStart,
                    shapeStartPositions: shapeDragStart,
                    translation: value.translation,
                    scale: liveScale
                )
            }
            .onEnded { _ in
                store.endUndoTransaction()
                deviceDragStart.removeAll()
                shapeDragStart.removeAll()
            }
    }

    private func shapeDragGesture(_ shape: WorkspaceShape) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if !store.selectedShapeIDs.contains(shape.id) {
                    store.selectOnlyShape(shape.id)
                }

                if deviceDragStart.isEmpty && shapeDragStart.isEmpty {
                    store.beginUndoTransaction()
                }

                if shapeDragStart.isEmpty {
                    let shapeIDs = store.selectedShapeIDs.contains(shape.id) ? store.selectedShapeIDs : [shape.id]

                    for id in shapeIDs {
                        if let s = store.shapes.first(where: { $0.id == id }) {
                            shapeDragStart[id] = CGPoint(x: s.x, y: s.y)
                        }
                    }
                }

                if deviceDragStart.isEmpty {
                    for id in store.selectedDeviceIDs {
                        if let d = store.devices.first(where: { $0.id == id }) {
                            deviceDragStart[id] = CGPoint(x: d.x, y: d.y)
                        }
                    }
                }

                store.moveSelectedItems(
                    deviceStartPositions: deviceDragStart,
                    shapeStartPositions: shapeDragStart,
                    translation: value.translation,
                    scale: liveScale
                )
            }
            .onEnded { _ in
                store.endUndoTransaction()
                deviceDragStart.removeAll()
                shapeDragStart.removeAll()
            }
    }

    private func deviceMatchesSearch(_ device: MonitoredDevice) -> Bool {
        guard !searchText.isEmpty else { return true }
        let q = searchText.lowercased()
        return device.displayName.lowercased().contains(q)
            || device.ipAddress.contains(q)
            || (device.zoneName?.lowercased().contains(q) ?? false)
    }
}


struct MpingMapDeviceTileView: View, Equatable {
    let device: MonitoredDevice
    let isSelected: Bool
    let shouldShowSecondaryDetail: Bool
    let hasAlert: Bool
    let isFlashing: Bool
    let redundantModeActive: Bool
    let primaryBadgeColor: Color
    let secondaryBadgeColor: Color
    var isTemperatureMode: Bool = false
    var tileSettingsRevision: Int = 0

    @ObservedObject private var tileStyle = DeviceTileEditorSettings.shared

    @State private var flashOpacity: Double = 0.0

    static func == (lhs: MpingMapDeviceTileView, rhs: MpingMapDeviceTileView) -> Bool {
        // Custom equality so .equatable() suppresses re-renders during SNMP/LLDP polling.
        // MonitoredDevice is a large struct — comparing it whole would invalidate every tile
        // on every telemetry pass even when nothing visible changed. Only the fields actually
        // rendered on the tile are compared here.
        //
        // lastRTT is rounded to the nearest ms: RTT micro-fluctuations within a 1ms band
        // (e.g. 1.1ms → 1.3ms) are invisible on the tile and would otherwise force a
        // re-render on every ping for every online device.
        //
        // pingRTTHistory, pingLossHistory, jitter, uptime, and SNMP port detail are excluded
        // because they are only shown in the inspector, not on the canvas tile itself.
        //
        // lastSeenOnline is intentionally excluded: it updates to Date() on every successful
        // ping, which would force every online tile to re-render every cycle. The tile only
        // displays lastSeenOnline when status == .offline, and status IS compared here —
        // so the tile re-renders on the online→offline transition that makes the value relevant.
        lhs.device.id == rhs.device.id
            && lhs.device.displayName == rhs.device.displayName
            && lhs.device.ipAddress == rhs.device.ipAddress
            && lhs.device.x == rhs.device.x
            && lhs.device.y == rhs.device.y
            && lhs.device.status == rhs.device.status
            && lhs.device.pingPulseID == rhs.device.pingPulseID
            && lhs.device.lastRTT.map { Int($0.rounded()) } == rhs.device.lastRTT.map { Int($0.rounded()) }
            && lhs.device.deviceType == rhs.device.deviceType
            && lhs.device.switchTelemetry.temperatureCelsius == rhs.device.switchTelemetry.temperatureCelsius
            && lhs.device.verificationState == rhs.device.verificationState
            && lhs.device.zoneName == rhs.device.zoneName
            && lhs.device.switchTelemetry.stpIsRootBridge == rhs.device.switchTelemetry.stpIsRootBridge
            && lhs.device.switchTelemetry.stpBlockedPorts == rhs.device.switchTelemetry.stpBlockedPorts
            && lhs.isSelected == rhs.isSelected
            && lhs.shouldShowSecondaryDetail == rhs.shouldShowSecondaryDetail
            && lhs.hasAlert == rhs.hasAlert
            && lhs.isFlashing == rhs.isFlashing
            && lhs.device.redundancyRole == rhs.device.redundancyRole
            && lhs.redundantModeActive == rhs.redundantModeActive
            && lhs.primaryBadgeColor == rhs.primaryBadgeColor
            && lhs.secondaryBadgeColor == rhs.secondaryBadgeColor
            && lhs.isTemperatureMode == rhs.isTemperatureMode
            && lhs.tileSettingsRevision == rhs.tileSettingsRevision
            && lhs.device.switchTelemetry.temperatureCelsius == rhs.device.switchTelemetry.temperatureCelsius
            && lhs.device.switchTelemetry.temperatureCelsius2 == rhs.device.switchTelemetry.temperatureCelsius2
            && lhs.device.switchTelemetry.fanSpeed1 == rhs.device.switchTelemetry.fanSpeed1
            && lhs.device.switchTelemetry.fanSpeed2 == rhs.device.switchTelemetry.fanSpeed2
    }

    private var isPingOnly: Bool { device.deviceType == .pingOnly }
    private var tileWidth: CGFloat { tileStyle.tileWidth }
    private var tileHeight: CGFloat { isPingOnly ? tileStyle.pingOnlyTileHeight : tileStyle.tileHeight }
    private var cornerRadius: CGFloat { tileStyle.tileCornerRadius }

    private var statusColor: Color {
        switch device.status {
        case .healthy:
            return Color(red: 0.20, green: 0.72, blue: 0.34)
        case .slow:
            return Color(red: 0.86, green: 0.60, blue: 0.14)
        case .offline:
            return Color(red: 0.76, green: 0.22, blue: 0.20)
        case .unknown:
            return Color(red: 0.40, green: 0.42, blue: 0.46)
        }
    }

    private var tileFillColor: Color {
        switch device.status {
        case .healthy:
            return Color(red: 0.060, green: 0.195, blue: 0.105)
        case .slow:
            return Color(red: 0.225, green: 0.165, blue: 0.055)
        case .offline:
            return Color(red: 0.215, green: 0.060, blue: 0.060)
        case .unknown:
            return Color(red: 0.120, green: 0.125, blue: 0.135)
        }
    }

    private var iconName: String {
        switch device.deviceType {
        case .pingOnly:
            return "network"
        case .netgearSwitch:
            return "switch.2"
        }
    }

    private var shouldShowLastSeen: Bool {
        device.status == .offline || device.verificationState == .offline
    }

    private var latestValidRTT: Double? {
        if let rtt = device.lastRTT, rtt.isFinite, rtt >= 0 { return rtt }
        return device.pingRTTHistory.last(where: { $0.isFinite && $0 >= 0 })
    }

    private var lastSeenDisplayText: String {
        if let t = device.lastSeenOnline { return "Last Seen\n" + Self.lastSeenFormatter.string(from: t) }
        return "Never Seen"
    }

    private static let lastSeenFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f
    }()

    private var latencyText: String {
        if shouldShowLastSeen { return lastSeenDisplayText }
        if let rtt = latestValidRTT {
            return rtt < 10 ? String(format: "%.1f", rtt) : "\(Int(rtt.rounded()))"
        }
        return "—"
    }

    private var pingMinText: String {
        formattedPingValue(device.minimumRTT)
    }

    private var pingAvgText: String {
        formattedPingValue(device.averageRTT)
    }

    private var pingMaxText: String {
        formattedPingValue(device.maximumRTT)
    }

    private func formattedPingValue(_ value: Double?) -> String {
        guard device.status != .offline else { return "—" }
        guard let value else { return "—" }

        if value < 10 {
            return String(format: "%.1f", value)
        }

        return "\(Int(value.rounded()))"
    }

    private var temperatureText: String {
        guard device.deviceType == .netgearSwitch else {
            return "—°C"
        }

        guard let temp = device.switchTelemetry.temperatureCelsius else {
            return "—°C"
        }

        return "\(Int(temp.rounded()))°C"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tileFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: isSelected ? tileStyle.selectedBorderWidth : tileStyle.normalBorderWidth)
                )
                .overlay(selectionGlow)
                .shadow(
                    color: .black.opacity(isSelected ? tileStyle.selectedShadowOpacity : tileStyle.normalShadowOpacity),
                    radius: isSelected ? tileStyle.selectedShadowRadius : tileStyle.normalShadowRadius,
                    x: 0,
                    y: isSelected ? tileStyle.selectedShadowYOffset : tileStyle.normalShadowYOffset
                )
                .shadow(color: statusColor.opacity(statusGlowOpacity), radius: statusGlowRadius, x: 0, y: 0)

            Group {
                if isPingOnly {
                    pingOnlyContent
                        .padding(.horizontal, tileStyle.pingOnlyHPadding)
                        .padding(.vertical, tileStyle.pingOnlyVPadding)
                } else {
                    tileContent
                        .padding(.horizontal, tileStyle.tileHorizontalPadding)
                        .padding(.top, tileStyle.tileTopPadding)
                        .padding(.bottom, tileStyle.tileBottomPadding)
                }
            }

            if isTemperatureMode {
                thermalIndicator
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, tileStyle.statusTrailingPadding)
                    .allowsHitTesting(false)
            } else {
                heartbeatIndicator
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, tileStyle.statusTrailingPadding)
                    .allowsHitTesting(false)
            }

            if hasAlert {
                PulsingBorderView(
                    color: NSColor.systemYellow,
                    lineWidth: 2.5,
                    cornerRadius: cornerRadius,
                    minOpacity: 0.10,
                    maxOpacity: 0.85,
                    duration: 1.4
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
        }
        .frame(width: tileWidth, height: tileHeight)
        .overlay(alignment: .leading) {
            if let zone = device.zoneName, !zone.isEmpty {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(zoneColor(for: zone))
                    .frame(width: 3)
                    .padding(.vertical, 6)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(flashOpacity))
                .allowsHitTesting(false)
        )
        .onAppear {
            // When the tab switches to show this device the tile is born with isFlashing
            // already true, so onChange never fires. Kick the animation manually here.
            if isFlashing {
                withAnimation(.easeInOut(duration: 0.3).repeatCount(10, autoreverses: true)) {
                    flashOpacity = 0.55
                }
            }
        }
        .onChange(of: isFlashing) { _, flashing in
            if flashing {
                withAnimation(.easeInOut(duration: 0.3).repeatCount(10, autoreverses: true)) {
                    flashOpacity = 0.55
                }
            } else {
                withAnimation(.easeOut(duration: 0.25)) {
                    flashOpacity = 0.0
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 3) {
                if device.redundancyRole != .none {
                    Text(device.redundancyRole == .primary ? "P" : "S")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            device.redundancyRole == .primary ? primaryBadgeColor : secondaryBadgeColor,
                            in: RoundedRectangle(cornerRadius: 3, style: .continuous)
                        )
                }
                if device.switchTelemetry.stpIsRootBridge {
                    Text("ROOT")
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.yellow, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                }
            }
            .padding(.top, 5)
            .padding(.trailing, 5)
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .animation(.easeOut(duration: 0.16), value: isSelected)
        .animation(.easeOut(duration: 0.16), value: device.status)
        .help(helpText)
    }

    private var helpText: String {
        if shouldShowTemperatureBadge {
            return "\(device.displayName) · Ping: \(device.status.label) · \(latencyText) · Temp: \(temperatureText)"
        }

        return "\(device.displayName) · Ping: \(device.status.label) · \(latencyText)"
    }

    private var tileContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(tileStyle.netgearTopFieldOrder) { field in
                switch field {
                case .deviceName:
                    Text(device.displayName)
                        .font(.system(size: tileStyle.titleSize, weight: tileStyle.titleBold ? .semibold : .regular, design: .rounded))
                        .italicIf(tileStyle.titleItalic)
                        .foregroundStyle(.white.opacity(tileStyle.titleOpacity))
                        .lineLimit(1)
                        .minimumScaleFactor(tileStyle.titleMinimumScale)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, tileStyle.titleTrailingPadding)
                        .padding(.top, tileStyle.titleTopSpacing)
                case .ipAddress:
                    Text(device.ipAddress)
                        .font(.system(size: tileStyle.ipSize, weight: tileStyle.ipBold ? .semibold : .regular, design: .rounded))
                        .italicIf(tileStyle.ipItalic)
                        .foregroundStyle(.white.opacity(tileStyle.ipOpacity))
                        .lineLimit(1)
                        .minimumScaleFactor(tileStyle.ipMinimumScale)
                        .truncationMode(.middle)
                        .padding(.top, tileStyle.ipTopSpacing)
                        .padding(.trailing, tileStyle.ipTrailingPadding)
                case .deviceType:
                    if shouldShowSecondaryDetail {
                        HStack(spacing: tileStyle.typeIconSpacing) {
                            Image(systemName: iconName)
                                .font(.system(size: tileStyle.typeIconSize, weight: .regular))
                                .foregroundStyle(.white.opacity(tileStyle.typeOpacity))
                                .frame(width: tileStyle.typeIconWidth)
                            Text(device.deviceType.label)
                                .font(.system(size: tileStyle.typeSize, weight: tileStyle.typeBold ? .semibold : .regular, design: .rounded))
                                .italicIf(tileStyle.typeItalic)
                                .foregroundStyle(.white.opacity(tileStyle.typeOpacity))
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                                .truncationMode(.tail)
                        }
                        .padding(.top, tileStyle.typeTopSpacing)
                        .padding(.trailing, tileStyle.typeTrailingPadding)
                    }
                }
            }

            Spacer(minLength: 0)

            if isTemperatureMode {
                thermalContent
            } else {
                HStack(alignment: .bottom, spacing: tileStyle.bottomRowSpacing) {
                    pingBadge

                    if shouldShowTemperatureBadge {
                        Spacer(minLength: tileStyle.bottomRowSpacerMinLength)
                        tempBadge
                    }
                }
            }
        }
    }

    private var pingOnlyContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(device.displayName)
                .font(.system(size: tileStyle.titleSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, tileStyle.statusOuterFrameSize * 0.6)

            Spacer(minLength: 0)

            HStack(spacing: tileStyle.pingOnlyBadgeSpacing) {
                Text(latencyText)
                    .font(.system(size: tileStyle.pingOnlyLatencySize, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .padding(.horizontal, tileStyle.pingOnlyBadgeHPadding)
                    .padding(.vertical, tileStyle.pingOnlyBadgeVPadding)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: tileStyle.pingOnlyBadgeCornerRadius, style: .continuous))

                Text(device.ipAddress)
                    .font(.system(size: tileStyle.pingOnlyIPSize, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.50))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentColor.opacity(tileStyle.selectedBorderOpacity)
        }

        return Color.white.opacity(tileStyle.normalBorderOpacity)
    }

    private var statusGlowOpacity: Double {
        switch device.status {
        case .healthy:
            return 0.22
        case .slow:
            return 0.28
        case .offline:
            return 0.30
        case .unknown:
            return 0.10
        }
    }

    private var statusGlowRadius: CGFloat {
        switch device.status {
        case .unknown:
            return 2
        default:
            return 7
        }
    }

    @ViewBuilder
    private var selectionGlow: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.accentColor.opacity(tileStyle.selectedGlowOpacity), lineWidth: tileStyle.selectedGlowWidth)
                .blur(radius: tileStyle.selectedGlowBlur)
        }
    }

    private var heartbeatIndicator: some View {
        ZStack {
            PingRippleLayerView(
                color: statusColor,
                rippleSize: tileStyle.statusRippleSize,
                lineWidth: tileStyle.statusRippleLineWidth,
                startOpacity: device.status == .offline ? 0.42 : 0.84,
                pulseID: device.pingPulseID
            )

            Circle()
                .fill(Color.black.opacity(tileStyle.statusBackgroundOpacity))
                .frame(width: tileStyle.statusBackgroundSize, height: tileStyle.statusBackgroundSize)

            Circle()
                .fill(statusColor)
                .frame(width: tileStyle.statusIconSize, height: tileStyle.statusIconSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(tileStyle.statusIconBorderOpacity), lineWidth: tileStyle.statusIconBorderWidth)
                )
                .shadow(color: statusColor.opacity(0.78), radius: tileStyle.statusShadowRadius, x: 0, y: 0)
        }
        .frame(width: tileStyle.statusOuterFrameSize, height: tileStyle.statusOuterFrameSize)
        .accessibilityLabel("Ping status \(device.status.label)")
    }

    // MARK: - Temperature mode

    private var hottestTemp: Double? {
        [device.switchTelemetry.temperatureCelsius,
         device.switchTelemetry.temperatureCelsius2].compactMap { $0 }.max()
    }

    private var thermalStatusColor: Color {
        guard let t = hottestTemp else { return Color(red: 0.40, green: 0.42, blue: 0.46) }
        if t >= 60 { return Color(red: 0.76, green: 0.22, blue: 0.20) }
        if t >= 45 { return Color(red: 0.86, green: 0.60, blue: 0.14) }
        return Color(red: 0.20, green: 0.72, blue: 0.34)
    }

    private func tempLabel(_ value: Double?) -> String {
        guard let v = value else { return "--" }
        return String(format: "%.0f°", v)
    }

    private func fanLabel(_ rpm: Int?) -> String {
        guard let r = rpm else { return "---" }
        return "\(r)"
    }

    // Replaces the ping ripple in temperature mode — static thermometer dot coloured by heat.
    private var thermalIndicator: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(tileStyle.statusBackgroundOpacity))
                .frame(width: tileStyle.statusBackgroundSize, height: tileStyle.statusBackgroundSize)

            Circle()
                .fill(thermalStatusColor)
                .frame(width: tileStyle.statusIconSize, height: tileStyle.statusIconSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(tileStyle.statusIconBorderOpacity), lineWidth: tileStyle.statusIconBorderWidth)
                )
                .shadow(color: thermalStatusColor.opacity(0.78), radius: tileStyle.statusShadowRadius, x: 0, y: 0)

            Image(systemName: "thermometer.medium")
                .font(.system(size: tileStyle.statusIconSize * 0.55, weight: .medium))
                .foregroundStyle(.white.opacity(0.90))
        }
        .frame(width: tileStyle.statusOuterFrameSize, height: tileStyle.statusOuterFrameSize)
    }

    // Replaces the ping badge row in temperature mode.
    private var thermalContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Temperature sensors
            HStack(spacing: 6) {
                Label(tempLabel(device.switchTelemetry.temperatureCelsius), systemImage: "thermometer.medium")
                    .font(.system(size: tileStyle.temperatureSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(sensorColor(device.switchTelemetry.temperatureCelsius))
                    .monospacedDigit()

                if device.switchTelemetry.temperatureCelsius2 != nil || device.deviceType == .netgearSwitch {
                    Text("·")
                        .foregroundStyle(.white.opacity(0.30))
                    Label(tempLabel(device.switchTelemetry.temperatureCelsius2), systemImage: "thermometer.medium")
                        .font(.system(size: tileStyle.temperatureSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(sensorColor(device.switchTelemetry.temperatureCelsius2))
                        .monospacedDigit()
                }
            }

            // Fan speeds
            if device.deviceType == .netgearSwitch {
                HStack(spacing: 6) {
                    Label(fanLabel(device.switchTelemetry.fanSpeed1), systemImage: "fan")
                        .font(.system(size: tileStyle.temperatureSize - 1, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .monospacedDigit()

                    Text("·")
                        .foregroundStyle(.white.opacity(0.30))

                    Label(fanLabel(device.switchTelemetry.fanSpeed2), systemImage: "fan")
                        .font(.system(size: tileStyle.temperatureSize - 1, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .monospacedDigit()
                }
            }
        }
        .padding(.horizontal, tileStyle.temperatureBoxHorizontalPadding)
        .padding(.vertical, tileStyle.temperatureBoxVerticalPadding)
        .background(.black.opacity(tileStyle.temperatureBoxOpacity),
                    in: RoundedRectangle(cornerRadius: tileStyle.temperatureBoxCornerRadius, style: .continuous))
    }

    private func sensorColor(_ temp: Double?) -> Color {
        guard let t = temp else { return .white.opacity(0.45) }
        if t >= 60 { return Color(red: 0.95, green: 0.35, blue: 0.30) }
        if t >= 45 { return Color(red: 0.95, green: 0.78, blue: 0.28) }
        return .white.opacity(0.88)
    }

    private var shouldShowTemperatureBadge: Bool {
        device.deviceType == .netgearSwitch
    }

    private var tempBadge: some View {
        Text(temperatureText)
            .font(.system(size: tileStyle.temperatureSize, weight: tileStyle.temperatureBold ? .semibold : .regular, design: .rounded))
            .italicIf(tileStyle.temperatureItalic)
            .foregroundStyle(temperatureColor)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, tileStyle.temperatureBoxHorizontalPadding)
            .padding(.vertical, tileStyle.temperatureBoxVerticalPadding)
            .background(.black.opacity(tileStyle.temperatureBoxOpacity), in: RoundedRectangle(cornerRadius: tileStyle.temperatureBoxCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: tileStyle.temperatureBoxCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(tileStyle.temperatureBorderOpacity), lineWidth: 1)
            )
    }

    private var pingBadge: some View {
        Group {
            if shouldShowLastSeen {
                Text(latencyText)
                    .font(.system(size: max(7, tileStyle.pingValueSize * 0.78), weight: tileStyle.pingValueBold ? .semibold : .regular, design: .monospaced))
                    .italicIf(tileStyle.pingValueItalic)
                    .foregroundStyle(.white.opacity(tileStyle.pingValueOpacity))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.58)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(latencyText)
                        .font(.system(size: tileStyle.pingValueSize, weight: tileStyle.pingValueBold ? .semibold : .regular, design: .rounded))
                        .italicIf(tileStyle.pingValueItalic)
                        .foregroundStyle(.white.opacity(tileStyle.pingValueOpacity))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("ms")
                        .font(.system(size: tileStyle.pingHeaderSize, weight: tileStyle.pingHeaderBold ? .semibold : .regular, design: .rounded))
                        .italicIf(tileStyle.pingHeaderItalic)
                        .foregroundStyle(.white.opacity(tileStyle.pingHeaderOpacity))
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, tileStyle.pingBoxHorizontalPadding)
        .padding(.vertical, tileStyle.pingBoxVerticalPadding)
        .background(.black.opacity(tileStyle.pingBoxOpacity), in: RoundedRectangle(cornerRadius: tileStyle.pingBoxCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: tileStyle.pingBoxCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(tileStyle.pingBorderOpacity), lineWidth: 1)
        )
        .accessibilityLabel("Ping latency \(latencyText)")
    }

    private static let zoneColors: [Color] = [.cyan, .purple, .orange, .mint, .pink, .indigo, .yellow, .teal]

    private func zoneColor(for name: String) -> Color {
        Self.zoneColors[abs(name.hashValue) % Self.zoneColors.count]
    }

    private var temperatureColor: Color {
        guard device.deviceType == .netgearSwitch else {
            return .white.opacity(0.36)
        }

        guard let temp = device.switchTelemetry.temperatureCelsius else {
            return .white.opacity(0.46)
        }

        if temp >= 70 { return Color(red: 1.00, green: 0.30, blue: 0.26) }
        if temp >= 55 { return Color(red: 1.00, green: 0.66, blue: 0.18) }
        return Color(red: 0.34, green: 0.86, blue: 0.44)
    }
}

struct FibreTopologyHUD: View {
    @ObservedObject var store: DeviceStore

    private var links: [FibreLossResult] {
        store.cachedFibreResults
    }

    private var liveCount: Int {
        links.filter { !$0.isMissing }.count
    }

    private var totalCount: Int {
        links.count
    }

    private var lldpCount: Int {
        store.devices.reduce(0) { $0 + $1.switchTelemetry.lldpNeighbours.count }
    }

    private var sfpCount: Int {
        store.devices.reduce(0) { $0 + $1.switchTelemetry.fibrePorts.count }
    }

    private var linkLabel: String {
        totalCount == 0 ? "Links: 0" : "Links: \(liveCount)/\(totalCount)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Fibre Topology")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("\(linkLabel)   LLDP: \(lldpCount)   SFP: \(sfpCount)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            if links.isEmpty && lldpCount > 0 {
                Text("LLDP seen — rename Mping devices to match LLDP system names to draw links")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.orange.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 290, alignment: .leading)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

private struct WorkspaceEventCatcher: NSViewRepresentable {
    let isSnapToGridEnabled: Bool
    let gridSize: CGFloat
    let hasSelection: Bool
    let hasClipboardContent: Bool
    let onScroll: (Double) -> Void
    let onRightPan: (CGSize) -> Void
    let onToggleSnapToGrid: () -> Void
    let onSetGridSize: (CGFloat) -> Void
    let onCopySelection: () -> Void
    let onPaste: () -> Void
    var onClearTopologyLinks: (() -> Void)?
    var deviceAt: ((CGPoint) -> MonitoredDevice?)?
    var shapeAt: ((CGPoint) -> WorkspaceShape?)?
    var onSelectionBoxChange: ((CGPoint, CGPoint) -> Void)?
    var onSelectionBoxClear: (() -> Void)?
    var onBoxSelectEnd: ((CGPoint, CGPoint) -> Void)?
    var onOpenWebInterface: ((UUID) -> Void)?
    var onSelectDevice: ((UUID) -> Void)?
    var onCopyDevice: ((UUID) -> Void)?
    var onCutDevice: ((UUID) -> Void)?
    var onDuplicateDevice: ((UUID) -> Void)?
    var onDeleteDevice: ((UUID) -> Void)?

    func makeNSView(context: Context) -> WorkspaceEventNSView {
        let view = WorkspaceEventNSView()
        apply(to: view)
        return view
    }

    func updateNSView(_ nsView: WorkspaceEventNSView, context: Context) {
        apply(to: nsView)
    }

    private func apply(to view: WorkspaceEventNSView) {
        view.isSnapToGridEnabled = isSnapToGridEnabled
        view.gridSize = gridSize
        view.hasSelection = hasSelection
        view.hasClipboardContent = hasClipboardContent
        view.onClearTopologyLinks = onClearTopologyLinks
        view.onScroll = onScroll
        view.onRightPan = onRightPan
        view.onToggleSnapToGrid = onToggleSnapToGrid
        view.onSetGridSize = onSetGridSize
        view.onCopySelection = onCopySelection
        view.onPaste = onPaste
        view.deviceAt = deviceAt
        view.shapeAt = shapeAt
        view.onSelectionBoxChange = onSelectionBoxChange
        view.onSelectionBoxClear = onSelectionBoxClear
        view.onBoxSelectEnd = onBoxSelectEnd
        view.onOpenWebInterface = onOpenWebInterface
        view.onSelectDevice = onSelectDevice
        view.onCopyDevice = onCopyDevice
        view.onCutDevice = onCutDevice
        view.onDuplicateDevice = onDuplicateDevice
        view.onDeleteDevice = onDeleteDevice
    }

    final class WorkspaceEventNSView: NSView {
        var isSnapToGridEnabled: Bool = false
        var gridSize: CGFloat = 40
        var hasSelection: Bool = false
        var hasClipboardContent: Bool = false
        var onScroll: ((Double) -> Void)?
        var onRightPan: ((CGSize) -> Void)?
        var onToggleSnapToGrid: (() -> Void)?
        var onSetGridSize: ((CGFloat) -> Void)?
        var onCopySelection: (() -> Void)?
        var onPaste: (() -> Void)?
        var onClearTopologyLinks: (() -> Void)?
        var deviceAt: ((CGPoint) -> MonitoredDevice?)?
        var shapeAt: ((CGPoint) -> WorkspaceShape?)?
        var onSelectionBoxChange: ((CGPoint, CGPoint) -> Void)?
        var onSelectionBoxClear: (() -> Void)?
        var onBoxSelectEnd: ((CGPoint, CGPoint) -> Void)?
        var onOpenWebInterface: ((UUID) -> Void)?
        var onSelectDevice: ((UUID) -> Void)?
        var onCopyDevice: ((UUID) -> Void)?
        var onCutDevice: ((UUID) -> Void)?
        var onDuplicateDevice: ((UUID) -> Void)?
        var onDeleteDevice: ((UUID) -> Void)?

        private var monitor: Any?
        private var lastRightPoint: NSPoint?
        private var rightMouseDownEvent: NSEvent?
        private var didRightDrag = false
        private var menuTargets: [MenuActionTarget] = []

        // Left-drag selection box state (tracked in monitor to avoid SwiftUI DragGesture stuck issues)
        private var leftDragStartWindow: NSPoint? = nil
        private var leftDragThresholdMet = false

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            if window != nil {
                installMonitor()
            } else {
                removeMonitor()
            }
        }

        deinit {
            removeMonitor()
        }

        private func installMonitor() {
            removeMonitor()

            monitor = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp,
                            .rightMouseDown, .rightMouseDragged, .rightMouseUp, .scrollWheel]
            ) { [weak self] event in
                guard let self, let window = self.window else { return event }
                guard event.window === window else { return event }

                let inBlockedPanel = PanelInteractionRegistry.isPointInsideBlockedPanel(event.locationInWindow)

                // Right-mouse and scroll handling
                if event.type == .scrollWheel {
                    guard !inBlockedPanel else { return event }
                    let localPoint = self.convert(event.locationInWindow, from: nil)
                    guard self.bounds.contains(localPoint) else { return event }
                    self.onScroll?(event.scrollingDeltaY)
                    return nil
                }

                if event.type == .rightMouseDown || event.type == .rightMouseDragged || event.type == .rightMouseUp {
                    if inBlockedPanel {
                        self.lastRightPoint = nil
                        self.rightMouseDownEvent = nil
                        self.didRightDrag = false
                        return event
                    }
                    let localPoint = self.convert(event.locationInWindow, from: nil)
                    guard self.bounds.contains(localPoint) else {
                        self.lastRightPoint = nil
                        self.rightMouseDownEvent = nil
                        self.didRightDrag = false
                        return event
                    }

                    switch event.type {
                    case .rightMouseDown:
                        // Make window key before consuming the event. If we don't, the
                        // window was non-key when the NSMenu ran, so AppKit has nowhere to
                        // restore key status after menu close — leaving the window
                        // permanently non-key and silently dropping all SwiftUI gestures.
                        self.window?.makeKey()
                        self.lastRightPoint = event.locationInWindow
                        self.rightMouseDownEvent = event
                        self.didRightDrag = false
                        return nil

                    case .rightMouseDragged:
                        let current = event.locationInWindow
                        if let down = self.rightMouseDownEvent {
                            let dx = current.x - down.locationInWindow.x
                            let dy = current.y - down.locationInWindow.y
                            if abs(dx) > 3 || abs(dy) > 3 { self.didRightDrag = true }
                        }
                        if let last = self.lastRightPoint {
                            self.onRightPan?(CGSize(width: current.x - last.x, height: last.y - current.y))
                        }
                        self.lastRightPoint = current
                        return nil

                    case .rightMouseUp:
                        // Defer menu show so NSMenu's modal event loop never nests inside
                        // this monitor callback, which would leave SwiftUI gesture recognisers
                        // waiting for a leftMouseUp that the menu already consumed.
                        let shouldShowMenu = !self.didRightDrag && self.rightMouseDownEvent != nil
                        let pendingEvent = self.rightMouseDownEvent
                        self.lastRightPoint = nil
                        self.rightMouseDownEvent = nil
                        self.didRightDrag = false
                        if shouldShowMenu, let pendingEvent {
                            DispatchQueue.main.async { [weak self] in
                                self?.showWorkspaceMenu(for: pendingEvent)
                            }
                        }
                        return nil

                    default: return event
                    }
                }

                // Left-mouse handling — tracked here to drive the selection box without
                // a SwiftUI DragGesture on the background. A SwiftUI DragGesture on the
                // background is the component that gets stuck after NSMenu's modal loop:
                // it receives a leftMouseDown from AppKit's state restoration on menu
                // close but never gets the matching leftMouseUp, blocking all subsequent
                // clicks. By owning this in the monitor we sidestep that entirely.
                if event.type == .leftMouseDown || event.type == .leftMouseDragged || event.type == .leftMouseUp {
                    guard !inBlockedPanel else { return event }
                    let localPoint = self.convert(event.locationInWindow, from: nil)
                    guard self.bounds.contains(localPoint) else {
                        if event.type == .leftMouseDown {
                            self.leftDragStartWindow = nil
                            self.leftDragThresholdMet = false
                        }
                        return event
                    }
                    let swiftUIPoint = CGPoint(x: localPoint.x, y: self.bounds.height - localPoint.y)

                    switch event.type {
                    case .leftMouseDown:
                        // Ensure window is key on every left click. A titleless NSWindow
                        // may not regain key status automatically after an NSMenu is shown
                        // while the window was non-key — SwiftUI silently drops all
                        // gesture events (tap, drag) on non-key windows.
                        if self.window?.isKeyWindow == false { self.window?.makeKey() }
                        // Only track for selection box if click is on empty canvas
                        let onDevice = self.deviceAt?(swiftUIPoint) != nil
                        let onShape = self.shapeAt?(swiftUIPoint) != nil
                        if onDevice || onShape {
                            self.leftDragStartWindow = nil
                            self.leftDragThresholdMet = false
                        } else {
                            self.leftDragStartWindow = event.locationInWindow
                            self.leftDragThresholdMet = false
                        }
                        return event

                    case .leftMouseDragged:
                        guard let start = self.leftDragStartWindow else { return event }
                        let current = event.locationInWindow
                        let dx = current.x - start.x
                        let dy = current.y - start.y
                        if !self.leftDragThresholdMet && (abs(dx) > 4 || abs(dy) > 4) {
                            self.leftDragThresholdMet = true
                        }
                        if self.leftDragThresholdMet {
                            let startLocal = self.convert(start, from: nil)
                            let swiftUIStart = CGPoint(x: startLocal.x, y: self.bounds.height - startLocal.y)
                            self.onSelectionBoxChange?(swiftUIStart, swiftUIPoint)
                        }
                        return event

                    case .leftMouseUp:
                        guard let start = self.leftDragStartWindow else { return event }
                        let thresholdMet = self.leftDragThresholdMet
                        self.leftDragStartWindow = nil
                        self.leftDragThresholdMet = false
                        self.onSelectionBoxClear?()
                        if thresholdMet {
                            let startLocal = self.convert(start, from: nil)
                            let swiftUIStart = CGPoint(x: startLocal.x, y: self.bounds.height - startLocal.y)
                            self.onBoxSelectEnd?(swiftUIStart, swiftUIPoint)
                        }
                        return event

                    default: return event
                    }
                }

                return event
            }
        }

        private func showWorkspaceMenu(for event: NSEvent) {
            menuTargets.removeAll()

            let localPoint = convert(event.locationInWindow, from: nil)
            let swiftUIPoint = CGPoint(x: localPoint.x, y: bounds.height - localPoint.y)

            if let device = deviceAt?(swiftUIPoint) {
                showDeviceMenu(for: device, with: event)
            } else {
                showCanvasMenu(for: event)
            }

            // After NSMenu's synchronous modal event loop, AppKit may have demoted our
            // window's key/main status. Restore it so the next click lands on the
            // workspace rather than whatever is behind it.
            window?.makeKeyAndOrderFront(nil)
        }

        private func showDeviceMenu(for device: MonitoredDevice, with event: NSEvent) {
            let menu = NSMenu()

            addMenuItem(
                to: menu,
                title: "Open Web Interface",
                isEnabled: !device.effectiveWebInterfacePath.isEmpty,
                action: { [weak self] in self?.onOpenWebInterface?(device.id) }
            )

            menu.addItem(.separator())

            addMenuItem(to: menu, title: "Select",
                action: { [weak self] in self?.onSelectDevice?(device.id) }
            )

            menu.addItem(.separator())

            addMenuItem(to: menu, title: "Copy",
                action: { [weak self] in self?.onCopyDevice?(device.id) }
            )

            addMenuItem(to: menu, title: "Cut",
                action: { [weak self] in self?.onCutDevice?(device.id) }
            )

            addMenuItem(to: menu, title: "Duplicate",
                action: { [weak self] in self?.onDuplicateDevice?(device.id) }
            )

            menu.addItem(.separator())

            addMenuItem(to: menu, title: "Paste",
                isEnabled: hasClipboardContent,
                action: { [weak self] in self?.onPaste?() }
            )

            menu.addItem(.separator())

            let deleteItem = NSMenuItem(title: "Delete", action: nil, keyEquivalent: "")
            deleteItem.attributedTitle = NSAttributedString(
                string: "Delete",
                attributes: [.foregroundColor: NSColor.systemRed]
            )
            let deleteTarget = MenuActionTarget { [weak self] in self?.onDeleteDevice?(device.id) }
            menuTargets.append(deleteTarget)
            deleteItem.target = deleteTarget
            deleteItem.action = #selector(MenuActionTarget.runMenuAction)
            menu.addItem(deleteItem)

            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }

        private func showCanvasMenu(for event: NSEvent) {
            let menu = NSMenu()

            addMenuItem(
                to: menu,
                title: "Snap to Grid",
                state: isSnapToGridEnabled ? .on : .off,
                action: { [weak self] in self?.onToggleSnapToGrid?() }
            )

            let gridMenu = NSMenu()
            for size in [20, 40, 80] as [CGFloat] {
                addMenuItem(
                    to: gridMenu,
                    title: "\(Int(size)) px",
                    state: Int(gridSize) == Int(size) ? .on : .off,
                    action: { [weak self] in self?.onSetGridSize?(size) }
                )
            }

            let gridItem = NSMenuItem(title: "Grid Size", action: nil, keyEquivalent: "")
            menu.setSubmenu(gridMenu, for: gridItem)
            menu.addItem(gridItem)
            menu.addItem(.separator())

            addMenuItem(
                to: menu,
                title: "Copy Selection",
                isEnabled: hasSelection,
                action: { [weak self] in self?.onCopySelection?() }
            )

            addMenuItem(
                to: menu,
                title: "Paste",
                action: { [weak self] in self?.onPaste?() }
            )

            menu.addItem(.separator())

            addMenuItem(
                to: menu,
                title: "Clear All Topology Links",
                action: { [weak self] in self?.onClearTopologyLinks?() }
            )

            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }

        private func addMenuItem(
            to menu: NSMenu,
            title: String,
            state: NSControl.StateValue = .off,
            isEnabled: Bool = true,
            action: @escaping () -> Void
        ) {
            let target = MenuActionTarget(action: action)
            menuTargets.append(target)

            let item = NSMenuItem(title: title, action: #selector(MenuActionTarget.runMenuAction), keyEquivalent: "")
            item.target = target
            item.state = state
            item.isEnabled = isEnabled
            menu.addItem(item)
        }

        private func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil
        }
    }
}

private final class MenuActionTarget: NSObject {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    @objc func runMenuAction() {
        action()
    }
}

