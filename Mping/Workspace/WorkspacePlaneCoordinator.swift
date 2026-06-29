import SwiftUI

enum WorkspacePlane: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case stp      = "STP"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "map"
        case .stp:      return "point.3.connected.trianglepath.dotted"
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
                WorkspaceView(store: store, searchText: searchText, visibleDevices: visibleDevices, boxTint: boxTint)
            case .stp:
                STPPlaneView(store: store)
            }

            // Bottom plane switcher (Overview / STP) — always visible.
            planeSwitcher
                .padding(.bottom, 18)
                .zIndex(1000)
        }
        .overlay(alignment: .topLeading) {
            // Primary / Secondary network tab — only shown when redundant pairs exist.
            if store.hasRedundantPairs && activePlane == .overview {
                networkTabPicker
                    .padding(.top, 14)
                    .padding(.leading, 14)
                    .zIndex(1001)
                    .allowsHitTesting(true)
            }
        }
    }

    private var networkTabPicker: some View {
        HStack(spacing: 2) {
            ForEach(RedundantNetworkTab.allCases) { tab in
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
                        activeNetworkTab == tab
                            ? Color.blue.opacity(0.35)
                            : Color.clear,
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
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.45), lineWidth: 1))
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
