import SwiftUI
import Combine
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

private struct DebugSliderControl: Identifiable {
    let title: String
    let value: Binding<CGFloat>
    let range: ClosedRange<CGFloat>
    var id: String { title }
}

struct DeviceTileEditorView: View {
    @ObservedObject private var settings = DeviceTileEditorSettings.shared
    @State private var activeTileType: TileEditorType = .netgear
    @State private var previewIsSelected: Bool = false
    @State private var previewThermalMode: Bool = false

    enum TileEditorType: String, CaseIterable, Identifiable {
        case netgear = "Netgear Switch"
        case pingOnly = "Ping Only"
        var id: String { rawValue }
    }

    private var previewNetgearDevice: MonitoredDevice {
        var d = MonitoredDevice(name: "Centre 1", ipAddress: "192.168.1.100", x: 0, y: 0,
                                status: .healthy, lastRTT: 2.4, deviceType: .netgearSwitch)
        d.switchTelemetry.temperatureCelsius = 38.0
        d.switchTelemetry.temperatureCelsius2 = 41.0
        d.switchTelemetry.fanSpeed1 = 1200
        d.switchTelemetry.fanSpeed2 = 1180
        return d
    }

    private var previewPingDevice: MonitoredDevice {
        MonitoredDevice(name: "Gateway Router", ipAddress: "192.168.1.1", x: 0, y: 0,
                        status: .healthy, lastRTT: 1.2, deviceType: .pingOnly)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                previewPanel
                    .frame(width: 270)
                Divider()
                settingsPanel
            }
        }
        .frame(width: 900, height: 820)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Device Tile Editor")
                    .font(.title2)
                Text("Live controls for tile layout and typography. Select a tile type to switch contexts. Use Update WorkspaceView.swift to bake values into source.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button("Copy Swift Defaults") {
                    settings.copyCurrentSettingsAsSwiftDefaults()
                }
                #if os(macOS)
                Button("Update WorkspaceView.swift") {
                    settings.overwriteWorkspaceViewSourceFile()
                }
                #endif
                Button("Reset") {
                    settings.resetDefaults()
                }
            }
        }
        .padding(18)
    }

    // MARK: - Preview Panel

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Tile Type", selection: $activeTileType) {
                ForEach(TileEditorType.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            HStack(spacing: 16) {
                Toggle("Selected", isOn: $previewIsSelected)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                if activeTileType == .netgear {
                    Toggle("Thermal Mode", isOn: $previewThermalMode)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 12))
                }
            }

            ZStack {
                Color(red: 0.055, green: 0.055, blue: 0.06)
                MpingMapDeviceTileView(
                    device: activeTileType == .netgear ? previewNetgearDevice : previewPingDevice,
                    isSelected: previewIsSelected,
                    shouldShowSecondaryDetail: true,
                    hasAlert: false,
                    isFlashing: false,
                    redundantModeActive: false,
                    primaryBadgeColor: .blue,
                    secondaryBadgeColor: .orange,
                    isTemperatureMode: activeTileType == .netgear && previewThermalMode
                )
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            let tileH = activeTileType == .netgear ? settings.tileHeight : settings.pingOnlyTileHeight
            Text("\(Int(settings.tileWidth)) × \(Int(tileH)) pt")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Settings Panel

    private var settingsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if activeTileType == .netgear {
                    netgearSettings
                } else {
                    pingOnlySettings
                }
            }
            .padding(18)
        }
    }

    // MARK: - Netgear Settings

    @ViewBuilder
    private var netgearSettings: some View {
        fieldOrderSection

        spacingSection(title: "Tile Size & Outer Shape", controls: [
            DebugSliderControl(title: "Width", value: $settings.tileWidth, range: 90...260),
            DebugSliderControl(title: "Height", value: $settings.tileHeight, range: 70...220),
            DebugSliderControl(title: "Corner Radius", value: $settings.tileCornerRadius, range: 0...34),
            DebugSliderControl(title: "Horizontal Padding", value: $settings.tileHorizontalPadding, range: 0...28),
            DebugSliderControl(title: "Top Padding", value: $settings.tileTopPadding, range: 0...24),
            DebugSliderControl(title: "Bottom Padding", value: $settings.tileBottomPadding, range: 0...24)
        ])

        textSection(title: "Device Name", size: $settings.titleSize, bold: $settings.titleBold, italic: $settings.titleItalic, controls: [
            DebugSliderControl(title: "Opacity", value: $settings.titleOpacity, range: 0.10...1.00),
            DebugSliderControl(title: "Top Spacing", value: $settings.titleTopSpacing, range: 0...20),
            DebugSliderControl(title: "Trailing Padding", value: $settings.titleTrailingPadding, range: 0...80),
            DebugSliderControl(title: "Minimum Scale", value: $settings.titleMinimumScale, range: 0.30...1.00)
        ], range: 6...30)

        textSection(title: "IP Address", size: $settings.ipSize, bold: $settings.ipBold, italic: $settings.ipItalic, controls: [
            DebugSliderControl(title: "Opacity", value: $settings.ipOpacity, range: 0.10...1.00),
            DebugSliderControl(title: "Top Spacing", value: $settings.ipTopSpacing, range: 0...24),
            DebugSliderControl(title: "Trailing Padding", value: $settings.ipTrailingPadding, range: 0...100),
            DebugSliderControl(title: "Minimum Scale", value: $settings.ipMinimumScale, range: 0.30...1.00)
        ], range: 6...28)

        textSection(title: "Device Type Row", size: $settings.typeSize, bold: $settings.typeBold, italic: $settings.typeItalic, controls: [
            DebugSliderControl(title: "Opacity", value: $settings.typeOpacity, range: 0.10...1.00),
            DebugSliderControl(title: "Top Spacing", value: $settings.typeTopSpacing, range: 0...24),
            DebugSliderControl(title: "Trailing Padding", value: $settings.typeTrailingPadding, range: 0...100),
            DebugSliderControl(title: "Icon Size", value: $settings.typeIconSize, range: 4...28),
            DebugSliderControl(title: "Icon Width", value: $settings.typeIconWidth, range: 4...40),
            DebugSliderControl(title: "Icon Spacing", value: $settings.typeIconSpacing, range: 0...18)
        ], range: 5...24)

        textSection(title: "Temperature Text", size: $settings.temperatureSize, bold: $settings.temperatureBold, italic: $settings.temperatureItalic, controls: [], range: 5...24)

        spacingSection(title: "Temperature Box", controls: [
            DebugSliderControl(title: "Horizontal Padding", value: $settings.temperatureBoxHorizontalPadding, range: 0...24),
            DebugSliderControl(title: "Vertical Padding", value: $settings.temperatureBoxVerticalPadding, range: 0...18),
            DebugSliderControl(title: "Corner Radius", value: $settings.temperatureBoxCornerRadius, range: 0...24),
            DebugSliderControl(title: "Background Opacity", value: $settings.temperatureBoxOpacity, range: 0...0.80),
            DebugSliderControl(title: "Border Opacity", value: $settings.temperatureBorderOpacity, range: 0...0.80)
        ])

        textSection(title: "Ping Header (ms label)", size: $settings.pingHeaderSize, bold: $settings.pingHeaderBold, italic: $settings.pingHeaderItalic, controls: [
            DebugSliderControl(title: "Opacity", value: $settings.pingHeaderOpacity, range: 0.10...1.00)
        ], range: 3...18)

        textSection(title: "Ping Value", size: $settings.pingValueSize, bold: $settings.pingValueBold, italic: $settings.pingValueItalic, controls: [
            DebugSliderControl(title: "Opacity", value: $settings.pingValueOpacity, range: 0.10...1.00)
        ], range: 5...28)

        spacingSection(title: "Ping Box", controls: [
            DebugSliderControl(title: "Horizontal Padding", value: $settings.pingBoxHorizontalPadding, range: 0...24),
            DebugSliderControl(title: "Vertical Padding", value: $settings.pingBoxVerticalPadding, range: 0...18),
            DebugSliderControl(title: "Corner Radius", value: $settings.pingBoxCornerRadius, range: 0...24),
            DebugSliderControl(title: "Background Opacity", value: $settings.pingBoxOpacity, range: 0...0.80),
            DebugSliderControl(title: "Border Opacity", value: $settings.pingBorderOpacity, range: 0...0.80),
            DebugSliderControl(title: "Vertical Spacing", value: $settings.pingBoxVerticalSpacing, range: 0...14),
            DebugSliderControl(title: "Column Width", value: $settings.pingColumnWidth, range: 8...60),
            DebugSliderControl(title: "Column Spacing", value: $settings.pingColumnSpacing, range: 0...24),
            DebugSliderControl(title: "Label/Value Spacing", value: $settings.pingColumnVerticalSpacing, range: 0...12)
        ])

        spacingSection(title: "Bottom Row", controls: [
            DebugSliderControl(title: "Badge Spacing", value: $settings.bottomRowSpacing, range: 0...28),
            DebugSliderControl(title: "Spacer Minimum", value: $settings.bottomRowSpacerMinLength, range: 0...40)
        ])

        spacingSection(title: "Status Icon / Heartbeat", controls: [
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
        ])

        spacingSection(title: "Selection / Shadows / Borders", controls: [
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
        ])
    }

    // MARK: - Ping-Only Settings

    @ViewBuilder
    private var pingOnlySettings: some View {
        spacingSection(title: "Tile Size", controls: [
            DebugSliderControl(title: "Width (shared)", value: $settings.tileWidth, range: 90...260),
            DebugSliderControl(title: "Height", value: $settings.pingOnlyTileHeight, range: 30...120),
            DebugSliderControl(title: "Corner Radius (shared)", value: $settings.tileCornerRadius, range: 0...34),
            DebugSliderControl(title: "Horizontal Padding", value: $settings.pingOnlyHPadding, range: 0...28),
            DebugSliderControl(title: "Vertical Padding", value: $settings.pingOnlyVPadding, range: 0...24)
        ])

        textSection(title: "Device Name (shared titleSize)", size: $settings.titleSize, bold: .constant(true), italic: .constant(false), controls: [], range: 6...24)

        spacingSection(title: "Latency Badge", controls: [
            DebugSliderControl(title: "Font Size", value: $settings.pingOnlyLatencySize, range: 6...24),
            DebugSliderControl(title: "Horizontal Padding", value: $settings.pingOnlyBadgeHPadding, range: 0...16),
            DebugSliderControl(title: "Vertical Padding", value: $settings.pingOnlyBadgeVPadding, range: 0...12),
            DebugSliderControl(title: "Corner Radius", value: $settings.pingOnlyBadgeCornerRadius, range: 0...16),
            DebugSliderControl(title: "Badge → IP Spacing", value: $settings.pingOnlyBadgeSpacing, range: 0...24)
        ])

        spacingSection(title: "IP Address", controls: [
            DebugSliderControl(title: "Font Size", value: $settings.pingOnlyIPSize, range: 6...20)
        ])

        spacingSection(title: "Status Icon (shared settings)", controls: [
            DebugSliderControl(title: "Trailing Padding", value: $settings.statusTrailingPadding, range: 0...50),
            DebugSliderControl(title: "Outer Frame", value: $settings.statusOuterFrameSize, range: 12...80),
            DebugSliderControl(title: "Ripple Size", value: $settings.statusRippleSize, range: 0...70),
            DebugSliderControl(title: "Ripple Line Width", value: $settings.statusRippleLineWidth, range: 0...8),
            DebugSliderControl(title: "Background Size", value: $settings.statusBackgroundSize, range: 0...70),
            DebugSliderControl(title: "Background Opacity", value: $settings.statusBackgroundOpacity, range: 0...0.80),
            DebugSliderControl(title: "Icon Size", value: $settings.statusIconSize, range: 0...50)
        ])

        spacingSection(title: "Selection / Shadows (shared)", controls: [
            DebugSliderControl(title: "Selected Shadow Radius", value: $settings.selectedShadowRadius, range: 0...30),
            DebugSliderControl(title: "Normal Shadow Radius", value: $settings.normalShadowRadius, range: 0...30),
            DebugSliderControl(title: "Selected Border Width", value: $settings.selectedBorderWidth, range: 0...8),
            DebugSliderControl(title: "Normal Border Width", value: $settings.normalBorderWidth, range: 0...8),
            DebugSliderControl(title: "Selected Glow Width", value: $settings.selectedGlowWidth, range: 0...18),
            DebugSliderControl(title: "Selected Glow Blur", value: $settings.selectedGlowBlur, range: 0...18)
        ])
    }

    // MARK: - Field Order Section

    private var fieldOrderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Field Order")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text("Move fields up/down to reorder the tile's top section. The badge row is always pinned to the bottom.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(Array(settings.netgearTopFieldOrder.enumerated()), id: \.element.id) { index, field in
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 14)

                    Image(systemName: netgearFieldIcon(field))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    Text(field.rawValue)
                        .font(.system(size: 12, weight: .regular, design: .rounded))

                    Spacer()

                    HStack(spacing: 0) {
                        Button {
                            guard index > 0 else { return }
                            settings.netgearTopFieldOrder.swapAt(index, index - 1)
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 11, weight: .medium))
                                .frame(width: 28, height: 24)
                        }
                        .disabled(index == 0)
                        .buttonStyle(.borderless)

                        Button {
                            guard index < settings.netgearTopFieldOrder.count - 1 else { return }
                            settings.netgearTopFieldOrder.swapAt(index, index + 1)
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .medium))
                                .frame(width: 28, height: 24)
                        }
                        .disabled(index == settings.netgearTopFieldOrder.count - 1)
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.black.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            HStack(spacing: 8) {
                Text("—")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)

                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .frame(width: 16)

                Text("Ping & Temp Badges — always last")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(12)
        .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func netgearFieldIcon(_ field: NetgearTopField) -> String {
        switch field {
        case .deviceName: return "textformat"
        case .ipAddress: return "network"
        case .deviceType: return "switch.2"
        }
    }

    // MARK: - Section builders

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
                .frame(width: 200, alignment: .leading)

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
        newWindow.setContentSize(NSSize(width: 900, height: 820))
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

    func exportFilteredEntriesAsCSV() {
        let iso = ISO8601DateFormatter()
        var lines = ["Timestamp,Subsystem,Direction,Device,IP Address,Message"]
        for entry in filteredEntries {
            let cols = [
                iso.string(from: entry.timestamp),
                entry.subsystem,
                entry.direction.label,
                entry.displayDeviceName,
                entry.ipAddress ?? "",
                entry.message.replacingOccurrences(of: "\"", with: "\"\"")
            ].map { "\"\($0)\"" }
            lines.append(cols.joined(separator: ","))
        }
        let csv = lines.joined(separator: "\n")

        #if os(macOS)
        let panel = NSSavePanel()
        panel.title = "Export Event Log"
        panel.nameFieldStringValue = "Mping Event Log \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short).replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")).csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        #endif
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

            Button("Export CSV") {
                store.exportFilteredEntriesAsCSV()
            }

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

// MARK: - Device Debug

struct DeviceDebugView: View {
    @ObservedObject var store: DeviceStore

    @State private var snapshot: [MonitoredDevice] = []
    @State private var monitoringEnabled: Bool = true
    @State private var lastRefreshed: Date = Date()
    @State private var expandedIDs: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
        }
        .frame(width: 740, height: 840)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { takeSnapshot() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Device Debug")
                    .font(.title2)
                Text("Snapshot of internal monitoring state for all devices. Expand a device to inspect ping engine, verification, telemetry, and interface data.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Button("Refresh") { takeSnapshot() }
                Text("Updated \(timeFormatter.string(from: lastRefreshed))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
    }

    @ViewBuilder
    private var content: some View {
        if snapshot.isEmpty {
            VStack {
                Spacer()
                Text("No devices in workspace")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(snapshot) { device in
                        let id = device.id
                        DeviceDebugRow(
                            device: device,
                            monitoringEnabled: monitoringEnabled,
                            isExpanded: expandedIDs.contains(id),
                            onToggle: {
                                if expandedIDs.contains(id) {
                                    expandedIDs.remove(id)
                                } else {
                                    expandedIDs.insert(id)
                                }
                            }
                        )
                    }
                }
                .padding(18)
            }
        }
    }

    private func takeSnapshot() {
        snapshot = store.devices.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        monitoringEnabled = store.monitoringEnabled
        lastRefreshed = Date()
    }

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f
    }()
}

private struct DeviceDebugRow: View {
    let device: MonitoredDevice
    let monitoringEnabled: Bool
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    pingSection
                    if !device.verificationFailures.isEmpty { verificationSection }
                    identitySection
                    if device.sourceInterfaceName != nil || device.sourceIPAddress != nil { interfaceSection }
                    if device.deviceType == .netgearSwitch { snmpSection }
                    if device.deviceType == .netgearSwitch { stpSection }
                    if !device.switchTelemetry.lldpNeighbours.isEmpty || !device.switchTelemetry.devicePorts.isEmpty { topologySection }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(.black.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(statusColor.opacity(isExpanded ? 0.30 : 0.12), lineWidth: 1)
        )
    }

    private var headerRow: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 12)

                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor.opacity(0.6), radius: 3)

                Text(device.displayName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                Text(device.ipAddress)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(verificationStateLabel)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.06), in: Capsule())

                Text(device.status.label.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.15), in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sections

    private var pingSection: some View {
        debugSection(title: "Ping & Monitoring") {
            row("Monitoring Active",     value: monitoringEnabled ? "Yes" : "No", valueColor: monitoringEnabled ? .green : .secondary)
            row("Status",                value: device.status.label, valueColor: statusColor)
            row("Verification State",    value: verificationStateLabel)
            row("Ping Pulse ID",         value: "\(device.pingPulseID)")
            row("Last RTT",              value: device.lastRTT.map { String(format: "%.3f ms", $0) } ?? "—")
            row("Min RTT",               value: device.minimumRTT.map { String(format: "%.3f ms", $0) } ?? "—")
            row("Avg RTT",               value: device.averageRTT.map { String(format: "%.3f ms", $0) } ?? "—")
            row("Max RTT",               value: device.maximumRTT.map { String(format: "%.3f ms", $0) } ?? "—")
            row("RTT History Samples",   value: "\(device.pingRTTHistory.count)")
            row("Last Checked",          value: device.lastChecked.map { timeFormatter.string(from: $0) } ?? "Never")
            row("Last Seen Online",      value: device.lastSeenOnline.map { timeFormatter.string(from: $0) } ?? "Never Seen")
        }
    }

    private var verificationSection: some View {
        debugSection(title: "Recent Verification Failures (\(device.verificationFailures.count))") {
            ForEach(Array(device.verificationFailures.enumerated()), id: \.offset) { index, failure in
                row(
                    "#\(index + 1)  \(timeFormatter.string(from: failure.timestamp))",
                    value: "Timeout \(failure.timeoutMilliseconds) ms  •  \(failure.sourceDisplayText)"
                )
            }
        }
    }

    private var identitySection: some View {
        debugSection(title: "Identity") {
            row("Display Name",   value: device.displayName)
            row("Stored Name",    value: device.name)
            row("Name Source",    value: device.nameSource.label)
            if let discovered = device.discoveredName {
                row("Discovered Name", value: discovered)
            }
            row("Device Type",    value: device.deviceType.label)
            row("IP Address",     value: device.ipAddress)
            row("Device ID",      value: device.id.uuidString, mono: true)
        }
    }

    private var interfaceSection: some View {
        debugSection(title: "Source Interface") {
            row("Interface Name", value: device.sourceInterfaceName ?? "Auto")
            row("Source IP",      value: device.sourceIPAddress ?? "Auto")
        }
    }

    private var snmpSection: some View {
        debugSection(title: "SNMP / Telemetry") {
            row("Community",       value: device.snmpCommunity)
            row("Last SNMP Poll",  value: device.switchTelemetry.lastSNMPChecked.map { timeFormatter.string(from: $0) } ?? "Never")
            row("SNMP Status",     value: device.switchTelemetry.snmpStatusText ?? "—")
            row("Temperature",     value: device.switchTelemetry.temperatureCelsius.map { String(format: "%.1f°C", $0) } ?? "—")
            row("Fibre Ports",     value: "\(device.switchTelemetry.fibrePorts.count)")
        }
    }

    private var stpSection: some View {
        debugSection(title: "STP / RSTP") {
            row("STP Monitoring",    value: device.snmpMonitoringEnabled ? "Active" : "Disabled")
            row("Root Bridge",       value: device.switchTelemetry.stpIsRootBridge ? "Yes — this switch is root" : "No",
                valueColor: device.switchTelemetry.stpIsRootBridge ? .yellow : .primary)
            if let ownMAC = device.switchTelemetry.stpRootBridgeID {
                row(
                    device.switchTelemetry.stpIsRootBridge ? "Root Bridge MAC" : "Own Chassis MAC",
                    value: ownMAC,
                    mono: true
                )
            }

            let blocked = device.switchTelemetry.stpBlockedPorts
            if blocked.isEmpty {
                row("Blocking Ports",  value: "None — all ports forwarding")
            } else {
                row("Blocking Ports",  value: blocked.map { "0/\($0)" }.joined(separator: ", "),
                    valueColor: .orange)
            }

            let upPorts   = device.switchTelemetry.devicePorts.filter { $0.isUp }.count
            let totalPorts = device.switchTelemetry.devicePorts.count
            row("Ports Up",          value: "\(upPorts) / \(totalPorts)")
        }
    }

    private var topologySection: some View {
        debugSection(title: "Topology") {
            row("LLDP Neighbours", value: "\(device.switchTelemetry.lldpNeighbours.count)")
            row("Device Ports",    value: "\(device.switchTelemetry.devicePorts.count)")
            let upCount = device.switchTelemetry.devicePorts.filter { $0.isUp }.count
            row("Ports Up",        value: "\(upCount) / \(device.switchTelemetry.devicePorts.count)")
        }
    }

    // MARK: - Helpers

    private func debugSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func row(_ label: String, value: String, valueColor: Color = .primary, mono: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 170, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: mono ? .regular : .medium, design: mono ? .monospaced : .rounded))
                .foregroundStyle(valueColor)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var statusColor: Color {
        switch device.status {
        case .healthy: return .green
        case .slow:    return .yellow
        case .offline: return .red
        case .unknown: return .gray
        }
    }

    private var verificationStateLabel: String {
        switch device.verificationState {
        case .online:           return "Online"
        case .verifyingOffline: return "Verifying Offline"
        case .offline:          return "Offline"
        case .verifyingOnline:  return "Verifying Online"
        }
    }

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f
    }()
}

#if os(macOS)
final class DeviceDebugWindowController {
    static let shared = DeviceDebugWindowController()

    private var window: NSWindow?
    private weak var store: DeviceStore?
    private let password = "4512360"

    private init() { }

    func configure(store: DeviceStore) {
        self.store = store
    }

    func showPasswordPromptAndOpen() {
        let alert = NSAlert()
        alert.messageText = "Device Debug"
        alert.informativeText = "Enter password to open the device debug view."
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
            denied.informativeText = "The device debug view was not opened."
            denied.alertStyle = .warning
            denied.addButton(withTitle: "OK")
            denied.runModal()
            return
        }

        openWindow()
    }

    private func openWindow() {
        guard let store else { return }

        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: DeviceDebugView(store: store))
        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Device Debug"
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        newWindow.setContentSize(NSSize(width: 740, height: 840))
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)

        self.window = newWindow
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif

// MARK: - Console Output Debugging

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
