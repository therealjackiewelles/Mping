import Foundation
import SwiftUI
import Combine

@MainActor
final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    @Published var sidebarWidth: Double {
        didSet { save() }
    }

    @Published var devicePortsShowDisconnectedPorts: Bool {
        didSet { save() }
    }

    @Published var devicePortsSelectedDeviceID: String? {
        didSet { save() }
    }

    @Published var devicePortsColumnOrder: [String] {
        didSet { save() }
    }

    @Published var devicePortsColumnWidths: [String: Double] {
        didSet { save() }
    }

    @Published var deviceManagerColumnOrder: [String] {
        didSet { save() }
    }

    @Published var deviceManagerColumnWidths: [String: Double] {
        didSet { save() }
    }

    @Published var switchUsername: String {
        didSet { save() }
    }

    private let fileURL: URL

    private struct Payload: Codable {
        var sidebarWidth: Double
        var devicePortsShowDisconnectedPorts: Bool
        var devicePortsSelectedDeviceID: String?
        var devicePortsColumnOrder: [String]?
        var devicePortsColumnWidths: [String: Double]?
        var deviceManagerColumnOrder: [String]?
        var deviceManagerColumnWidths: [String: Double]?
        var switchUsername: String?
    }

    private init() {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        let directory = supportDirectory.appendingPathComponent("Mping", isDirectory: true)
        fileURL = directory.appendingPathComponent("Preferences.json")

        let payload = AppPreferences.loadPayload(from: fileURL)
        sidebarWidth = payload.sidebarWidth
        devicePortsShowDisconnectedPorts = payload.devicePortsShowDisconnectedPorts
        devicePortsSelectedDeviceID = payload.devicePortsSelectedDeviceID
        devicePortsColumnOrder = payload.devicePortsColumnOrder ?? []
        devicePortsColumnWidths = payload.devicePortsColumnWidths ?? [:]
        deviceManagerColumnOrder = payload.deviceManagerColumnOrder ?? []
        deviceManagerColumnWidths = payload.deviceManagerColumnWidths ?? [:]
        switchUsername = payload.switchUsername ?? ""
    }

    func setSidebarWidth(_ width: CGFloat) {
        let clamped = min(420.0, max(210.0, Double(width)))
        if abs(sidebarWidth - clamped) > 0.5 {
            sidebarWidth = clamped
        }
    }

    private func save() {
        let payload = Payload(
            sidebarWidth: min(420.0, max(210.0, sidebarWidth)),
            devicePortsShowDisconnectedPorts: devicePortsShowDisconnectedPorts,
            devicePortsSelectedDeviceID: devicePortsSelectedDeviceID,
            devicePortsColumnOrder: devicePortsColumnOrder,
            devicePortsColumnWidths: devicePortsColumnWidths,
            deviceManagerColumnOrder: deviceManagerColumnOrder,
            deviceManagerColumnWidths: deviceManagerColumnWidths,
            switchUsername: switchUsername
        )

        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(payload)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Mping preferences save failed: \(error)")
        }
    }

    private static func loadPayload(from url: URL) -> Payload {
        let defaultPayload = Payload(
            sidebarWidth: 230.0,
            devicePortsShowDisconnectedPorts: true,
            devicePortsSelectedDeviceID: nil,
            devicePortsColumnOrder: nil,
            devicePortsColumnWidths: nil
        )

        guard let data = try? Data(contentsOf: url) else {
            let legacySidebarWidth = UserDefaults.standard.double(forKey: "mping.sidebarWidth")
            if legacySidebarWidth > 0 {
                return Payload(
                    sidebarWidth: min(420.0, max(210.0, legacySidebarWidth)),
                    devicePortsShowDisconnectedPorts: true,
                    devicePortsSelectedDeviceID: nil,
                    devicePortsColumnOrder: nil,
                    devicePortsColumnWidths: nil
                )
            }
            return defaultPayload
        }

        do {
            let decoded = try JSONDecoder().decode(Payload.self, from: data)
            return Payload(
                sidebarWidth: min(420.0, max(210.0, decoded.sidebarWidth)),
                devicePortsShowDisconnectedPorts: decoded.devicePortsShowDisconnectedPorts,
                devicePortsSelectedDeviceID: decoded.devicePortsSelectedDeviceID,
                devicePortsColumnOrder: decoded.devicePortsColumnOrder,
                devicePortsColumnWidths: decoded.devicePortsColumnWidths,
                deviceManagerColumnOrder: decoded.deviceManagerColumnOrder,
                deviceManagerColumnWidths: decoded.deviceManagerColumnWidths,
                switchUsername: decoded.switchUsername
            )
        } catch {
            return defaultPayload
        }
    }
}
