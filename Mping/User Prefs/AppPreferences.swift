import Foundation
import SwiftUI
import AppKit
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

    @Published var redundantPrimaryTintColor: Color {
        didSet { save() }
    }

    @Published var redundantSecondaryTintColor: Color {
        didSet { save() }
    }

    // Full-opacity versions of the tint colors for use in P/S badge chips on device tiles.
    // Strips the user's box opacity so the badge is always fully visible.
    var redundantPrimaryBadgeColor: Color {
        let rgba = AppPreferences.colorToRGBA(redundantPrimaryTintColor)
        return Color(red: rgba[0], green: rgba[1], blue: rgba[2], opacity: 1.0)
    }

    var redundantSecondaryBadgeColor: Color {
        let rgba = AppPreferences.colorToRGBA(redundantSecondaryTintColor)
        return Color(red: rgba[0], green: rgba[1], blue: rgba[2], opacity: 1.0)
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
        var redundantPrimaryTintRGBA: [Double]?
        var redundantSecondaryTintRGBA: [Double]?
    }

    private static let defaultPrimaryTint  = Color(red: 0.80, green: 0.10, blue: 0.10, opacity: 0.35)
    private static let defaultSecondaryTint = Color(red: 0.10, green: 0.30, blue: 0.85, opacity: 0.35)

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
        redundantPrimaryTintColor   = payload.redundantPrimaryTintRGBA.map(AppPreferences.rgbaToColor) ?? AppPreferences.defaultPrimaryTint
        redundantSecondaryTintColor = payload.redundantSecondaryTintRGBA.map(AppPreferences.rgbaToColor) ?? AppPreferences.defaultSecondaryTint
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
            switchUsername: switchUsername,
            redundantPrimaryTintRGBA:   AppPreferences.colorToRGBA(redundantPrimaryTintColor),
            redundantSecondaryTintRGBA: AppPreferences.colorToRGBA(redundantSecondaryTintColor)
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

    static func colorToRGBA(_ color: Color) -> [Double] {
        guard let ns = NSColor(color).usingColorSpace(.sRGB) else {
            return [1, 0, 0, 0.35]
        }
        return [Double(ns.redComponent), Double(ns.greenComponent), Double(ns.blueComponent), Double(ns.alphaComponent)]
    }

    static func rgbaToColor(_ rgba: [Double]) -> Color {
        guard rgba.count == 4 else { return defaultPrimaryTint }
        return Color(red: rgba[0], green: rgba[1], blue: rgba[2], opacity: rgba[3])
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
                switchUsername: decoded.switchUsername,
                redundantPrimaryTintRGBA:   decoded.redundantPrimaryTintRGBA,
                redundantSecondaryTintRGBA: decoded.redundantSecondaryTintRGBA
            )
        } catch {
            return defaultPayload
        }
    }
}
