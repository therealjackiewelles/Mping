import SwiftUI

struct DeviceTileView: View {
    let device: MonitoredDevice
    let isSelected: Bool

    @ObservedObject private var settings = DeviceTileEditorSettings.shared

    @State private var pulseScale: CGFloat = 0.45
    @State private var pulseOpacity: Double = 0.0

    var body: some View {
        tileContent
            .padding(.horizontal, settings.tileHorizontalPadding)
            .padding(.top, settings.tileTopPadding)
            .padding(.bottom, settings.tileBottomPadding)
            .frame(width: settings.tileWidth, height: settings.tileHeight)
            .background(tileBackground)
            .overlay(tileBorder)
            .overlay(selectedGlow)
            .shadow(
                color: statusColor.opacity(isSelected ? settings.selectedShadowOpacity : settings.normalShadowOpacity),
                radius: isSelected ? settings.selectedShadowRadius : settings.normalShadowRadius,
                x: 0,
                y: isSelected ? settings.selectedShadowYOffset : settings.normalShadowYOffset
            )
            .overlay(alignment: .topTrailing) {
                heartbeatIndicator
                    .padding(.top, 2)
                    .padding(.trailing, settings.statusTrailingPadding)
            }
            .onChange(of: device.pingPulseID) { _, _ in
                triggerHeartbeat()
            }
            .onAppear {
                if device.pingPulseID > 0 {
                    triggerHeartbeat()
                }
            }
    }

    private var tileContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(device.displayName)
                .font(.system(size: settings.titleSize, weight: settings.titleBold ? .bold : .semibold, design: .rounded))
                .italicIf(settings.titleItalic)
                .foregroundStyle(.white.opacity(settings.titleOpacity))
                .lineLimit(1)
                .minimumScaleFactor(settings.titleMinimumScale)
                .padding(.top, settings.titleTopSpacing)
                .padding(.trailing, settings.titleTrailingPadding)

            Text(device.ipAddress)
                .font(.system(size: settings.ipSize, weight: settings.ipBold ? .bold : .medium, design: .monospaced))
                .italicIf(settings.ipItalic)
                .foregroundStyle(.white.opacity(settings.ipOpacity))
                .lineLimit(1)
                .minimumScaleFactor(settings.ipMinimumScale)
                .padding(.top, settings.ipTopSpacing)
                .padding(.trailing, settings.ipTrailingPadding)

            HStack(spacing: settings.typeIconSpacing) {
                Image(systemName: device.deviceType == .netgearSwitch ? "switch.2" : "desktopcomputer")
                    .font(.system(size: settings.typeIconSize, weight: .semibold, design: .rounded))
                    .frame(width: settings.typeIconWidth)
                    .foregroundStyle(.white.opacity(settings.typeOpacity))

                Text(device.deviceType.label)
                    .font(.system(size: settings.typeSize, weight: settings.typeBold ? .bold : .medium, design: .rounded))
                    .italicIf(settings.typeItalic)
                    .foregroundStyle(.white.opacity(settings.typeOpacity))
                    .lineLimit(1)
            }
            .padding(.top, settings.typeTopSpacing)
            .padding(.trailing, settings.typeTrailingPadding)

            Spacer(minLength: settings.bottomRowSpacerMinLength)

            HStack(alignment: .bottom, spacing: settings.bottomRowSpacing) {
                pingBadge

                Spacer(minLength: settings.bottomRowSpacerMinLength)

                if shouldShowTemperatureBadge {
                    temperatureBadge
                }
            }
        }
    }

    private var pingBadge: some View {
        Text(rttText)
            .font(.system(size: settings.pingValueSize, weight: settings.pingValueBold ? .bold : .semibold, design: .monospaced))
            .italicIf(settings.pingValueItalic)
            .foregroundStyle(.white.opacity(settings.pingValueOpacity))
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .padding(.horizontal, settings.pingBoxHorizontalPadding)
            .padding(.vertical, settings.pingBoxVerticalPadding)
            .background(.white.opacity(settings.pingBoxOpacity), in: RoundedRectangle(cornerRadius: settings.pingBoxCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: settings.pingBoxCornerRadius, style: .continuous)
                    .stroke(.white.opacity(settings.pingBorderOpacity), lineWidth: 1)
            )
    }

    private var shouldShowTemperatureBadge: Bool {
        device.deviceType == .netgearSwitch && device.switchTelemetry.temperatureCelsius != nil
    }

    private var temperatureBadge: some View {
        Text(device.temperatureDisplayText)
            .font(.system(size: settings.temperatureSize, weight: settings.temperatureBold ? .bold : .semibold, design: .rounded))
            .italicIf(settings.temperatureItalic)
            .foregroundStyle(temperatureColor)
            .lineLimit(1)
            .padding(.horizontal, settings.temperatureBoxHorizontalPadding)
            .padding(.vertical, settings.temperatureBoxVerticalPadding)
            .background(temperatureColor.opacity(settings.temperatureBoxOpacity), in: RoundedRectangle(cornerRadius: settings.temperatureBoxCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: settings.temperatureBoxCornerRadius, style: .continuous)
                    .stroke(temperatureColor.opacity(settings.temperatureBorderOpacity), lineWidth: 1)
            )
    }

    private var heartbeatIndicator: some View {
        ZStack {
            Circle()
                .stroke(statusColor.opacity(pulseOpacity), lineWidth: settings.statusRippleLineWidth)
                .frame(width: settings.statusRippleSize, height: settings.statusRippleSize)
                .scaleEffect(pulseScale)

            Circle()
                .fill(.black.opacity(settings.statusBackgroundOpacity))
                .frame(width: settings.statusBackgroundSize, height: settings.statusBackgroundSize)

            Circle()
                .fill(device.isPinging ? statusColor : Color.gray.opacity(0.35))
                .frame(width: settings.statusIconSize, height: settings.statusIconSize)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(settings.statusIconBorderOpacity), lineWidth: settings.statusIconBorderWidth)
                )
                .shadow(color: statusColor.opacity(0.55), radius: settings.statusShadowRadius)
        }
        .frame(width: settings.statusOuterFrameSize, height: settings.statusOuterFrameSize)
        .allowsHitTesting(false)
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: settings.tileCornerRadius, style: .continuous)
            .fill(tileFill)
    }

    private var tileBorder: some View {
        RoundedRectangle(cornerRadius: settings.tileCornerRadius, style: .continuous)
            .stroke(
                isSelected ? Color.white.opacity(settings.selectedBorderOpacity) : statusColor.opacity(settings.normalBorderOpacity),
                lineWidth: isSelected ? settings.selectedBorderWidth : settings.normalBorderWidth
            )
    }

    @ViewBuilder
    private var selectedGlow: some View {
        if isSelected && settings.selectedGlowWidth > 0 && settings.selectedGlowOpacity > 0 {
            RoundedRectangle(cornerRadius: settings.tileCornerRadius, style: .continuous)
                .stroke(statusColor.opacity(settings.selectedGlowOpacity), lineWidth: settings.selectedGlowWidth)
                .blur(radius: settings.selectedGlowBlur)
        }
    }

    private func triggerHeartbeat() {
        pulseScale = 0.45
        pulseOpacity = 0.85

        withAnimation(.easeOut(duration: 0.65)) {
            pulseScale = 1.65
            pulseOpacity = 0.0
        }
    }

    private var tileFill: Color {
        switch device.status {
        case .healthy:
            return Color(red: 0.06, green: 0.20, blue: 0.12)
        case .slow:
            return Color(red: 0.23, green: 0.17, blue: 0.05)
        case .offline:
            return Color(red: 0.22, green: 0.06, blue: 0.06)
        case .unknown:
            return Color(red: 0.12, green: 0.12, blue: 0.13)
        }
    }

    private var statusColor: Color {
        switch device.status {
        case .healthy:
            return .green
        case .slow:
            return .yellow
        case .offline:
            return .red
        case .unknown:
            return .gray
        }
    }

    private var temperatureColor: Color {
        guard let temp = device.switchTelemetry.temperatureCelsius else { return .gray }
        if temp >= 70 { return .red }
        if temp >= 55 { return .orange }
        return .green
    }

    private var rttText: String {
        if device.status == .offline {
            guard let lastSeenOnline = device.lastSeenOnline else {
                return "Never Seen"
            }

            return "Last seen " + Self.lastSeenFormatter.string(from: lastSeenOnline)
        }

        if let rtt = device.lastRTT {
            return String(format: "%.1f ms", rtt)
        }

        return "No RTT"
    }

    private static let lastSeenFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
