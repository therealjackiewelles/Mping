import SwiftUI
import AppKit

enum MpingAlertCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case fibreLoss
    case pingThreshold
    case deviceDisconnect
    case overTemperature

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fibreLoss: return "Fibre Loss"
        case .pingThreshold: return "Ping RTT"
        case .deviceDisconnect: return "Device Disconnect"
        case .overTemperature: return "Over Temperature"
        }
    }

    var systemImage: String {
        switch self {
        case .fibreLoss: return "point.3.connected.trianglepath.dotted"
        case .pingThreshold: return "waveform.path.ecg"
        case .deviceDisconnect: return "network.slash"
        case .overTemperature: return "thermometer.high"
        }
    }
}

enum MpingAlertEventKind: String, Sendable {
    case alert
    case recovery
}

struct MpingAlertEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let category: MpingAlertCategory
    let conditionKey: String
    let deviceID: UUID?
    let deviceName: String
    let location: String
    let detail: String
    let firstTriggeredAt: Date
    var lastUpdatedAt: Date
    var isCurrent: Bool
    var isAcknowledged: Bool
    var kind: MpingAlertEventKind

    init(
        id: UUID = UUID(),
        category: MpingAlertCategory,
        conditionKey: String,
        deviceID: UUID?,
        deviceName: String,
        location: String,
        detail: String,
        firstTriggeredAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        isCurrent: Bool = true,
        isAcknowledged: Bool = false,
        kind: MpingAlertEventKind = .alert
    ) {
        self.id = id
        self.category = category
        self.conditionKey = conditionKey
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.location = location
        self.detail = detail
        self.firstTriggeredAt = firstTriggeredAt
        self.lastUpdatedAt = lastUpdatedAt
        self.isCurrent = isCurrent
        self.isAcknowledged = isAcknowledged
        self.kind = kind
    }
}

extension MpingAlertEvent {
    var isRecovery: Bool { kind == .recovery }
}


struct AlertingSidebarBox: View {
    @ObservedObject var store: DeviceStore
    @Binding var openCategory: MpingAlertCategory?
    let sidebarWidth: CGFloat
    @State private var showingThresholds = false
    @State private var alertPulse = false

    private var sidebarScale: CGFloat {
        min(1.65, max(1.0, sidebarWidth / 230.0))
    }

    private var iconGridSpacing: CGFloat { 9 * sidebarScale }
    private var panelPadding: CGFloat { 12 * sidebarScale }
    private var iconImageSize: CGFloat { 15 * sidebarScale }
    private var iconFrameSize: CGFloat { 22 * sidebarScale }
    private var iconRowPaddingH: CGFloat { 8 * sidebarScale }
    private var iconRowPaddingV: CGFloat { 8 * sidebarScale }
    private var iconCornerRadius: CGFloat { 10 * sidebarScale }
    private var titleSize: CGFloat { 13 * sidebarScale }
    private var shortLabelSize: CGFloat { 10 * sidebarScale }
    private var counterSize: CGFloat { 9 * sidebarScale }
    private var buttonSize: CGFloat { 10 * min(1.35, sidebarScale) }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: iconGridSpacing),
            GridItem(.flexible(), spacing: iconGridSpacing)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10 * sidebarScale) {
            HStack(spacing: 8) {
                Text("Alerting")
                    .font(.system(size: titleSize, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(1)

                Spacer(minLength: 4)

                Button {
                    showingThresholds = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11 * min(1.35, sidebarScale), weight: .black))
                        .frame(width: 18 * min(1.35, sidebarScale), height: 18 * min(1.35, sidebarScale))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.62))
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.07))
                )
                .popover(isPresented: $showingThresholds, arrowEdge: .leading) {
                    AlertThresholdsPopover(store: store)
                }

                Button("Ack All") {
                    store.acknowledgeAlerts()
                }
                .buttonStyle(.plain)
                .font(.system(size: buttonSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .padding(.horizontal, 7 * min(1.35, sidebarScale))
                .padding(.vertical, 4 * min(1.35, sidebarScale))
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.white.opacity(0.07))
                )
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: iconGridSpacing) {
                ForEach(MpingAlertCategory.allCases) { category in
                    AlertIconButton(
                        store: store,
                        category: category,
                        openCategory: $openCategory,
                        sidebarScale: sidebarScale
                    )
                }
            }
            .animation(nil, value: alertPulse)
        }
        .padding(panelPadding)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 112 * sidebarScale, alignment: .top)
        .background(alertingPanelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(hasActiveAlerts ? Color.red.opacity(alertPulse ? 0.55 : 0.20) : Color.white.opacity(0.09), lineWidth: 1)
        )
        .onAppear {
            alertPulse = hasActiveAlerts
        }
        .onChange(of: hasActiveAlerts) { _, isActive in
            if isActive {
                alertPulse = false
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    alertPulse = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.25)) {
                    alertPulse = false
                }
            }
        }
    }


    private var hasActiveAlerts: Bool {
        !store.activeAlertCountByCategory.isEmpty
    }

    private var alertingPanelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.055))

            RoundedRectangle(cornerRadius: 14)
                .fill(Color.red.opacity(hasActiveAlerts ? (alertPulse ? 0.20 : 0.045) : 0.0))
        }
    }
}

private struct AlertIconButton: View {
    @ObservedObject var store: DeviceStore
    let category: MpingAlertCategory
    @Binding var openCategory: MpingAlertCategory?
    let sidebarScale: CGFloat

    private var count: Int { store.newAlertCount(for: category) }
    private var isActive: Bool { count > 0 }
    private var clampedScale: CGFloat { min(1.65, max(1.0, sidebarScale)) }

    var body: some View {
        Button {
            openCategory = category
        } label: {
            VStack(alignment: .leading, spacing: 5 * clampedScale) {
                HStack(alignment: .center, spacing: 6 * clampedScale) {
                    Image(systemName: category.systemImage)
                        .font(.system(size: 15 * clampedScale, weight: .bold))
                        .frame(width: 22 * clampedScale, height: 22 * clampedScale)
                        .foregroundStyle(isActive ? .red : .white.opacity(0.28))
                        .layoutPriority(0)

                    Spacer(minLength: 2 * clampedScale)

                    if count > 0 {
                        Text(formattedCount)
                            .font(.system(size: 9 * clampedScale, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .padding(.horizontal, 5 * clampedScale)
                            .padding(.vertical, 2 * clampedScale)
                            .background(Capsule().fill(Color.red.opacity(0.88)))
                            .layoutPriority(0)
                    }
                }

                Text(categoryShortLabel)
                    .font(.system(size: 10 * clampedScale, weight: .bold, design: .rounded))
                    .foregroundStyle(isActive ? .white.opacity(0.94) : .white.opacity(0.36))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(2)
            }
            .frame(maxWidth: .infinity, minHeight: 44 * clampedScale, alignment: .leading)
            .padding(.horizontal, 8 * clampedScale)
            .padding(.vertical, 8 * clampedScale)
            .background(
                RoundedRectangle(cornerRadius: 10 * clampedScale)
                    .fill(isActive ? Color.red.opacity(0.16) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10 * clampedScale)
                    .stroke(isActive ? Color.red.opacity(0.50) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: Binding(
            get: { openCategory == category },
            set: { isPresented in
                if !isPresented { openCategory = nil }
            }
        ), arrowEdge: .leading) {
            AlertCategoryPopover(store: store, category: category, dismiss: { openCategory = nil })
        }
    }

    private var formattedCount: String {
        count > 100 ? ">100" : "\(count)"
    }

    private var categoryShortLabel: String {
        switch category {
        case .fibreLoss: return "Fibre"
        case .pingThreshold: return "Ping"
        case .deviceDisconnect: return "Offline"
        case .overTemperature: return "Temp"
        }
    }
}

private struct AlertCategoryPopover: View {
    @ObservedObject var store: DeviceStore
    let category: MpingAlertCategory
    var dismiss: (() -> Void)? = nil

    @State private var displayedRowLimit = 200

    private let pageSize = 200

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    private var activeCount: Int { store.newAlertCount(for: category) }
    private var hasCurrentAlerts: Bool { activeCount > 0 }

    private var formattedActiveCount: String {
        activeCount > 100 ? ">100" : "\(activeCount)"
    }

    var body: some View {
        let rows = store.alerts(for: category)
        let visibleRows = Array(rows.prefix(displayedRowLimit))
        let hiddenRowCount = max(0, rows.count - visibleRows.count)
        let layout = AlertTableColumnLayout(rows: visibleRows)
        let tableWidth = layout.totalWidth
        let popoverWidth = min(max(tableWidth + 48, 640), preferredMaximumPopoverWidth)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .foregroundStyle(hasCurrentAlerts ? .red : .secondary)
                Text(category.label)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                Spacer()
                Text("\(formattedActiveCount) current · \(rows.count) total")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                Button("Acknowledge All") {
                    store.acknowledgeAlerts(category: category)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(hasCurrentAlerts ? .white.opacity(0.72) : .white.opacity(0.45))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.white.opacity(hasCurrentAlerts ? 0.08 : 0.045))
                )
            }

            Divider()

            ScrollView(.horizontal, showsIndicators: tableWidth > popoverWidth - 28) {
                VStack(alignment: .leading, spacing: 6) {
                    AlertTableHeader(layout: layout)

                    ScrollView {
                        LazyVStack(spacing: 5) {
                            if rows.isEmpty {
                                Text("No alerts recorded.")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .frame(width: tableWidth, alignment: .leading)
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(Array(visibleRows.enumerated()), id: \.element.id) { index, alert in
                                    AlertTableRow(alert: alert, timeFormatter: timeFormatter, layout: layout, isAlternate: index.isMultiple(of: 2)) {
                                        if let id = alert.deviceID {
                                            store.focusDevice(id)
                                            dismiss?()
                                        }
                                    }
                                }

                                if hiddenRowCount > 0 {
                                    AlertHistoryLoadMoreRow(
                                        hiddenRowCount: hiddenRowCount,
                                        pageSize: pageSize,
                                        showMore: {
                                            displayedRowLimit += pageSize
                                        },
                                        showAll: {
                                            displayedRowLimit = rows.count
                                        }
                                    )
                                    .frame(width: tableWidth)
                                }
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    .frame(minHeight: 120, maxHeight: 300)
                }
                .frame(width: tableWidth, alignment: .leading)
            }
        }
        .padding(14)
        .frame(width: popoverWidth)
    }

    private var preferredMaximumPopoverWidth: CGFloat {
        if let screenWidth = NSScreen.main?.visibleFrame.width {
            return max(640, screenWidth * 0.88)
        }
        return 1180
    }
}

private struct AlertHistoryLoadMoreRow: View {
    let hiddenRowCount: Int
    let pageSize: Int
    let showMore: () -> Void
    let showAll: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("\(hiddenRowCount) older alerts hidden for performance")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()

            Button("Show \(min(pageSize, hiddenRowCount)) More", action: showMore)
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.white.opacity(0.08))
                )

            Button("Show All", action: showAll)
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.white.opacity(0.055))
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.065), lineWidth: 1)
        )
    }
}

private struct AlertThresholdsPopover: View {
    @ObservedObject var store: DeviceStore

    private var fibreLossStepperValue: Binding<Double> {
        Binding(
            get: { -store.fibreLossAlertThresholdDb },
            set: { store.fibreLossAlertThresholdDb = min(30.0, max(0.10, abs($0))) }
        )
    }

    private var fibreLossMagnitudeValue: Binding<Double> {
        Binding(
            get: { store.fibreLossAlertThresholdDb },
            set: { store.fibreLossAlertThresholdDb = min(30.0, max(0.10, abs($0))) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                Text("Alert Thresholds")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                Spacer()
                Button("Reset") {
                    store.resetAlertThresholdsToDefaults()
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            }

            Divider()
                .opacity(0.7)

            CompactAlertThresholdControl(
                title: "RTT",
                suffix: "ms",
                value: $store.pingAlertThresholdMilliseconds,
                range: 1...5000,
                step: 1,
                decimals: 0
            )

            CompactAlertThresholdControl(
                title: "Switch Temp",
                suffix: "°C",
                value: $store.switchTemperatureAlertThresholdCelsius,
                range: 20...120,
                step: 1,
                decimals: 0
            )

            CompactAlertThresholdControl(
                title: "SFP Temp",
                suffix: "°C",
                value: $store.sfpTemperatureAlertThresholdCelsius,
                range: 20...120,
                step: 1,
                decimals: 0
            )

            CompactAlertThresholdControl(
                title: "Fibre Loss",
                prefix: "-",
                suffix: "db",
                value: fibreLossMagnitudeValue,
                stepperValue: fibreLossStepperValue,
                range: 0.10...30.00,
                step: 0.01,
                decimals: 2
            )

            CompactAlertThresholdControl(
                title: "Jitter",
                suffix: "ms",
                value: $store.jitterAlertThresholdMilliseconds,
                range: 0.5...20.0,
                step: 0.5,
                decimals: 1
            )

            Text("Jitter guide (AVB/Milan): < 0.5 ms excellent · 0.5–2 ms normal · > 2 ms elevated · > 5 ms critical. Alert default: 2.0 ms.")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Saved locally. Changes re-check current monitoring state.")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(10)
        .frame(width: 285)
    }
}

private struct CompactAlertThresholdControl: View {
    let title: String
    var prefix: String = ""
    let suffix: String
    @Binding var value: Double
    var stepperValue: Binding<Double>? = nil
    let range: ClosedRange<Double>
    let step: Double
    let decimals: Int

    private var textBinding: Binding<String> {
        Binding(
            get: {
                if decimals == 0 {
                    return String(format: "%.0f", value)
                } else {
                    return String(format: "%.*f", decimals, value)
                }
            },
            set: { newValue in
                let cleaned = newValue
                    .replacingOccurrences(of: ",", with: ".")
                    .replacingOccurrences(of: "+", with: "")
                    .replacingOccurrences(of: "-", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard let parsed = Double(cleaned) else { return }
                let clamped = min(range.upperBound, max(range.lowerBound, abs(parsed)))
                value = decimals == 0 ? clamped.rounded() : clamped
            }
        )
    }

    private var activeStepperValue: Binding<Double> {
        stepperValue ?? Binding(
            get: { value },
            set: { newValue in
                let clamped = min(range.upperBound, max(range.lowerBound, abs(newValue)))
                value = decimals == 0 ? clamped.rounded() : clamped
            }
        )
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .frame(width: 78, alignment: .leading)

            HStack(spacing: 2) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }

                TextField("", text: textBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(width: decimals == 0 ? 42 : 52)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.black.opacity(0.18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                Text(suffix)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .frame(width: 22, alignment: .leading)
            }
            .frame(width: 86, alignment: .trailing)

            Stepper("", value: activeStepperValue, in: stepperRange, step: step)
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 62, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.065), lineWidth: 1)
        )
    }

    private var stepperRange: ClosedRange<Double> {
        if stepperValue == nil { return range }
        return -range.upperBound ... -range.lowerBound
    }
}

private struct AlertTableColumnLayout {
    let time: CGFloat = 76
    let device: CGFloat
    let location: CGFloat
    let acknowledged: CGFloat = 112
    let event: CGFloat
    let spacing: CGFloat = 8
    let horizontalPadding: CGFloat = 16

    init(rows: [MpingAlertEvent]) {
        let longestDevice = rows.map { $0.deviceName.count }.max() ?? 12
        let longestLocation = rows.map { $0.location.count }.max() ?? 9
        let longestDetail = rows.map { $0.detail.count }.max() ?? 20

        device = Self.width(forCharacters: longestDevice, minimum: 150, maximum: 320)
        location = Self.width(forCharacters: longestLocation, minimum: 100, maximum: 240)
        event = Self.width(forCharacters: longestDetail, minimum: 260, maximum: 620)
    }

    var totalWidth: CGFloat {
        time + device + location + acknowledged + event + (spacing * 4) + horizontalPadding
    }

    private static func width(forCharacters count: Int, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        let estimated = CGFloat(count) * 7.2 + 24
        return min(maximum, max(minimum, estimated))
    }
}

private struct AlertTableHeader: View {
    let layout: AlertTableColumnLayout

    var body: some View {
        HStack(spacing: layout.spacing) {
            Text("Time")
                .frame(width: layout.time, alignment: .leading)
            Text("Device / Link")
                .frame(width: layout.device, alignment: .leading)
            Text("Port / IP")
                .frame(width: layout.location, alignment: .leading)
            Text("Acknowledged")
                .frame(width: layout.acknowledged, alignment: .leading)
            Text("Event")
                .frame(width: layout.event, alignment: .leading)
        }
        .font(.system(size: 10, weight: .black, design: .rounded))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .frame(width: layout.totalWidth, alignment: .leading)
    }
}

private struct AlertTableRow: View {
    let alert: MpingAlertEvent
    let timeFormatter: DateFormatter
    let layout: AlertTableColumnLayout
    var isAlternate: Bool = false
    var onTap: (() -> Void)? = nil

    private var isNew: Bool {
        alert.kind == .alert && !alert.isAcknowledged
    }

    private var acknowledgedLabel: String {
        if alert.kind == .recovery { return "OK" }
        return alert.isAcknowledged ? "Yes" : "No"
    }

    private var rowFill: Color {
        if isNew { return Color.red.opacity(isAlternate ? 0.38 : 0.52) }
        return Color.white.opacity(isAlternate ? 0.025 : 0.055)
    }

    private var rowStroke: Color {
        isNew ? Color.red.opacity(isAlternate ? 0.55 : 0.75) : Color.white.opacity(0.07)
    }

    var body: some View {
        HStack(spacing: layout.spacing) {
            Text(timeFormatter.string(from: alert.firstTriggeredAt))
                .frame(width: layout.time, alignment: .leading)
                .monospacedDigit()

            Text(alert.deviceName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .frame(width: layout.device, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)

            Text(alert.location)
                .frame(width: layout.location, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)

            Text(acknowledgedLabel)
                .frame(width: layout.acknowledged, alignment: .leading)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(isNew ? .white : .white.opacity(0.58))

            Text(alert.detail)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .frame(width: layout.event, alignment: .leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 11, weight: .regular, design: .rounded))
        .foregroundStyle(isNew ? .white : .white.opacity(0.58))
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(width: layout.totalWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(rowFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(rowStroke, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

// MARK: - Alert History Box

struct AlertHistoryBox: View {
    @ObservedObject var store: DeviceStore
    let sidebarWidth: CGFloat
    @State private var showingFullHistory = false

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private var recentAlerts: [MpingAlertEvent] {
        Array(store.cachedSortedAlerts.prefix(10))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if recentAlerts.isEmpty {
                Text("No alerts recorded this session.")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.30))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 2) {
                    ForEach(recentAlerts) { alert in
                        historyRow(alert)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { showingFullHistory = true }
        .popover(isPresented: $showingFullHistory, arrowEdge: .leading) {
            AlertFullHistoryPopover(store: store, dismiss: { showingFullHistory = false })
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("History")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.70))
            Spacer()
            Text("\(store.cachedSortedAlerts.count) total")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.28))
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.22))
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 7)
    }

    private func historyRow(_ alert: MpingAlertEvent) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(rowDotColor(alert))
                .frame(width: 5, height: 5)
                .fixedSize()

            Text(timeFormatter.string(from: alert.firstTriggeredAt))
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.30))
                .monospacedDigit()
                .fixedSize()

            Image(systemName: alert.category.systemImage)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(categoryColor(alert.category).opacity(0.60))
                .fixedSize()

            Text(alert.deviceName.isEmpty ? alert.location : alert.deviceName)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(alert.kind == .alert && !alert.isAcknowledged ? .white.opacity(0.88) : .white.opacity(0.42))
                .lineLimit(1)
                .truncationMode(.middle)
                .layoutPriority(1)

            Text(alert.detail)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.30))
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(rowBackground(alert))
        )
    }

    private func rowDotColor(_ alert: MpingAlertEvent) -> Color {
        if alert.kind == .recovery { return .green.opacity(0.80) }
        if alert.isAcknowledged { return .white.opacity(0.18) }
        return .red.opacity(0.85)
    }

    private func rowBackground(_ alert: MpingAlertEvent) -> Color {
        if alert.kind == .recovery { return .green.opacity(0.06) }
        if alert.isAcknowledged { return .white.opacity(0.03) }
        return .red.opacity(0.08)
    }

    private func categoryColor(_ category: MpingAlertCategory) -> Color {
        switch category {
        case .deviceDisconnect: return .red
        case .fibreLoss: return .orange
        case .overTemperature: return .orange
        case .pingThreshold: return .yellow
        }
    }
}

// MARK: - Full History Popover

private struct AlertFullHistoryPopover: View {
    @ObservedObject var store: DeviceStore
    var dismiss: (() -> Void)? = nil
    @State private var displayedRowLimit = 200

    private let pageSize = 200
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private var allRows: [MpingAlertEvent] { store.cachedSortedAlerts }
    private var visibleRows: [MpingAlertEvent] { Array(allRows.prefix(displayedRowLimit)) }
    private var hiddenCount: Int { max(0, allRows.count - visibleRows.count) }

    var body: some View {
        let layout = AlertTableColumnLayout(rows: visibleRows)
        let tableWidth = layout.totalWidth + 130 + layout.spacing + 6
        let popoverWidth = min(max(tableWidth + 48, 680), preferredMaxWidth)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                Text("Alert History")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                Spacer()
                Text("\(allRows.filter { $0.kind == .alert && !$0.isAcknowledged }.count) active · \(allRows.count) total")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Button("Acknowledge All") {
                    store.acknowledgeAlerts()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.07)))
            }

            Divider()

            ScrollView(.horizontal, showsIndicators: tableWidth > popoverWidth - 28) {
                VStack(alignment: .leading, spacing: 6) {
                    fullHistoryHeader(layout: layout)

                    ScrollView {
                        LazyVStack(spacing: 3) {
                            if visibleRows.isEmpty {
                                Text("No alerts recorded this session.")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .frame(width: tableWidth, alignment: .leading)
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(Array(visibleRows.enumerated()), id: \.element.id) { index, alert in
                                    fullHistoryRow(alert, layout: layout, isAlternate: index.isMultiple(of: 2))
                                }
                                if hiddenCount > 0 {
                                    AlertHistoryLoadMoreRow(
                                        hiddenRowCount: hiddenCount,
                                        pageSize: pageSize,
                                        showMore: { displayedRowLimit += pageSize },
                                        showAll: { displayedRowLimit = allRows.count }
                                    )
                                    .frame(width: tableWidth)
                                }
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    .frame(minHeight: 120, maxHeight: 400)
                }
                .frame(width: tableWidth, alignment: .leading)
            }
        }
        .padding(14)
        .frame(width: popoverWidth)
    }

    private func fullHistoryHeader(layout: AlertTableColumnLayout) -> some View {
        HStack(spacing: layout.spacing) {
            Text("Time")
                .frame(width: layout.time, alignment: .leading)
            Text("Category")
                .frame(width: 130, alignment: .leading)
            Text("Device / Link")
                .frame(width: layout.device, alignment: .leading)
            Text("Port / IP")
                .frame(width: layout.location, alignment: .leading)
            Text("Acknowledged")
                .frame(width: layout.acknowledged, alignment: .leading)
            Text("Event")
                .frame(width: layout.event, alignment: .leading)
        }
        .font(.system(size: 10, weight: .black, design: .rounded))
        .foregroundStyle(.secondary)
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .frame(width: layout.totalWidth + 130 + layout.spacing + 6, alignment: .leading)
    }

    private func fullHistoryRow(_ alert: MpingAlertEvent, layout: AlertTableColumnLayout, isAlternate: Bool = false) -> some View {
        FullHistoryRow(alert: alert, layout: layout, timeFormatter: timeFormatter, isAlternate: isAlternate) {
            if let id = alert.deviceID {
                store.focusDevice(id)
                dismiss?()
            }
        }
    }

    private var preferredMaxWidth: CGFloat {
        if let w = NSScreen.main?.visibleFrame.width { return max(680, w * 0.88) }
        return 1280
    }
}

private struct FullHistoryRow: View {
    let alert: MpingAlertEvent
    let layout: AlertTableColumnLayout
    let timeFormatter: DateFormatter
    var isAlternate: Bool = false
    var onTap: (() -> Void)? = nil

    private var isNew: Bool { alert.kind == .alert && !alert.isAcknowledged }
    private var isRecovery: Bool { alert.kind == .recovery }

    private var rowFill: Color {
        if isNew { return Color.red.opacity(isAlternate ? 0.38 : 0.52) }
        if isRecovery { return Color.green.opacity(isAlternate ? 0.06 : 0.10) }
        return Color.white.opacity(isAlternate ? 0.025 : 0.055)
    }

    private var rowStroke: Color {
        if isNew { return Color.red.opacity(isAlternate ? 0.55 : 0.75) }
        if isRecovery { return Color.green.opacity(0.30) }
        return Color.white.opacity(0.07)
    }

    private var rowWidth: CGFloat { layout.totalWidth + 130 + layout.spacing + 6 }

    var body: some View {
        HStack(spacing: layout.spacing) {
            Text(timeFormatter.string(from: alert.firstTriggeredAt))
                .frame(width: layout.time, alignment: .leading)
                .monospacedDigit()

            categoryCell

            Text(alert.deviceName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .frame(width: layout.device, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)

            Text(alert.location)
                .frame(width: layout.location, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)

            ackedCell

            Text(alert.detail)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .frame(width: layout.event, alignment: .leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 11, weight: .regular, design: .rounded))
        .foregroundStyle(isNew ? .white : .white.opacity(0.55))
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, 4)
        .frame(width: rowWidth, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(rowFill))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(rowStroke, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    private var categoryCell: some View {
        HStack(spacing: 4) {
            Image(systemName: alert.category.systemImage)
                .font(.system(size: 10))
            Text(alert.category.label)
                .lineLimit(1)
        }
        .frame(width: 130, alignment: .leading)
    }

    private var ackedCell: some View {
        let label: String = isRecovery ? "OK" : (alert.isAcknowledged ? "Yes" : "No")
        return Text(label)
            .frame(width: layout.acknowledged, alignment: .leading)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(isNew ? .white : .white.opacity(0.55))
    }
}
