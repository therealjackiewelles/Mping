import SwiftUI

enum WorkspacePlane: String, CaseIterable, Identifiable {
    case overview     = "Overview"
    case stp          = "STP"
    case temperatures = "Temperatures"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview:     return "map"
        case .stp:          return "point.3.connected.trianglepath.dotted"
        case .temperatures: return "thermometer.medium"
        }
    }
}

// Which network to display when redundant pairs exist.
enum RedundantNetworkTab: String, CaseIterable, Identifiable {
    case primary   = "Primary"
    case secondary = "Secondary"
    var id: String { rawValue }
}

struct WorkspacePlaneCoordinator: View {
    @ObservedObject var store: DeviceStore
    @ObservedObject private var preferences = AppPreferences.shared
    let searchText: String
    @State private var activePlane: WorkspacePlane = .overview
    @State private var activeNetworkTab: RedundantNetworkTab = .primary
    // Shared viewport — owned here so switching planes never resets zoom/pan.
    @State private var sharedScale: Double
    @State private var sharedOffset: CGSize

    init(store: DeviceStore, searchText: String) {
        _store = ObservedObject(wrappedValue: store)
        self.searchText = searchText
        _sharedScale = State(initialValue: store.workspaceScale)
        _sharedOffset = State(initialValue: store.workspaceOffset)
    }

    // Devices visible on the current network tab.
    private var visibleDevices: [MonitoredDevice] {
        guard store.hasRedundantPairs else { return store.devices }
        switch activeNetworkTab {
        case .primary:
            return store.devices.filter { $0.redundancyRole == .none || $0.redundancyRole == .primary }
        case .secondary:
            return store.devices.filter { $0.redundancyRole == .secondary }
        }
    }

    // Tint applied to location boxes based on the active network tab.
    private var boxTint: Color? {
        guard store.hasRedundantPairs else { return nil }
        return activeNetworkTab == .primary
            ? preferences.redundantPrimaryTintColor
            : preferences.redundantSecondaryTintColor
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            switch activePlane {
            case .overview:
                WorkspaceView(store: store, searchText: searchText, visibleDevices: visibleDevices,
                              boxTint: boxTint, liveScale: $sharedScale, liveOffset: $sharedOffset)
            case .stp:
                STPPlaneView(store: store)
            case .temperatures:
                WorkspaceView(store: store, searchText: searchText, visibleDevices: visibleDevices,
                              boxTint: boxTint, isTemperatureMode: true,
                              liveScale: $sharedScale, liveOffset: $sharedOffset)
            }

            // Bottom plane switcher — always visible.
            planeSwitcher
                .padding(.bottom, 18)
                .zIndex(1000)
        }
        .onChange(of: store.pendingFocusDeviceID) { _, id in
            guard let id,
                  let device = store.devices.first(where: { $0.id == id }),
                  store.hasRedundantPairs else { return }
            let targetTab: RedundantNetworkTab = device.redundancyRole == .secondary ? .secondary : .primary
            guard targetTab != activeNetworkTab else { return }
            let originalTab = activeNetworkTab
            withAnimation(.easeInOut(duration: 0.15)) { activeNetworkTab = targetTab }
            // Mirror the workspace scroll-back: restore the original tab after the same delay.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.55)) { activeNetworkTab = originalTab }
            }
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
                // Primary / Secondary network tab — shown on all planes when redundant pairs exist.
                if store.hasRedundantPairs {
                    networkTabPicker
                        .allowsHitTesting(true)
                }

                // Fibre topology HUD — only on overview.
                if activePlane == .overview {
                    FibreTopologyHUD(store: store)
                        .allowsHitTesting(false)
                }
            }
            .padding(.top, 14)
            .padding(.leading, 14)
            .zIndex(1001)
        }
    }

    private var activeTabColor: Color {
        activeNetworkTab == .primary
            ? preferences.redundantPrimaryBadgeColor.opacity(0.50)
            : preferences.redundantSecondaryBadgeColor.opacity(0.50)
    }

    private var networkTabPicker: some View {
        HStack(spacing: 2) {
            ForEach(RedundantNetworkTab.allCases) { tab in
                let tabColor = tab == .primary
                    ? preferences.redundantPrimaryBadgeColor.opacity(0.50)
                    : preferences.redundantSecondaryBadgeColor.opacity(0.50)
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeNetworkTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab == .primary ? "network" : "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(
                        activeNetworkTab == tab ? tabColor : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .foregroundStyle(activeNetworkTab == tab ? .white : .white.opacity(0.50))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(activeTabColor, lineWidth: 1))
    }

    private var planeSwitcher: some View {
        HStack(spacing: 2) {
            ForEach(WorkspacePlane.allCases) { plane in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activePlane = plane
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: plane.icon)
                            .font(.system(size: 11, weight: .medium))
                        Text(plane.rawValue)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        activePlane == plane
                            ? Color.white.opacity(0.18)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .foregroundStyle(activePlane == plane ? .white : .white.opacity(0.45))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}
