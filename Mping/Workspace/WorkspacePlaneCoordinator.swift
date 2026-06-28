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

struct WorkspacePlaneCoordinator: View {
    @ObservedObject var store: DeviceStore
    let searchText: String
    @State private var activePlane: WorkspacePlane = .overview

    var body: some View {
        ZStack(alignment: .bottom) {
            switch activePlane {
            case .overview:
                WorkspaceView(store: store, searchText: searchText)
            case .stp:
                STPPlaneView(store: store)
            }

            planeSwitcher
                .padding(.bottom, 18)
                .zIndex(1000)
        }
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
