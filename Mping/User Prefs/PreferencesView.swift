import SwiftUI

struct PreferencesView: View {
    var deviceStore: DeviceStore

    var body: some View {
        TabView {
            GeneralPreferencesPane()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            NetworkRoutingPane(deviceStore: deviceStore)
                .tabItem {
                    Label("Network Routing", systemImage: "network")
                }

            RedundantNetworksPreferencesPane()
                .tabItem {
                    Label("Redundant Networks", systemImage: "arrow.triangle.2.circlepath")
                }

            CredentialsPreferencesPane()
                .tabItem {
                    Label("Switch Credentials", systemImage: "key.fill")
                }
        }
        .frame(width: 520)
    }
}

// MARK: - General

private struct GeneralPreferencesPane: View {
    @ObservedObject private var preferences = AppPreferences.shared
    @AppStorage("mping.showMinimap") private var showMinimap: Bool = true
    @AppStorage("mping.monitoringEnabled") private var monitoringEnabled: Bool = true
    @AppStorage("mping.clearTopologyLinksOnBoot") private var clearTopologyLinksOnBoot: Bool = true

    var body: some View {
        Form {
            Section("Workspace") {
                Toggle("Show Minimap on launch", isOn: $showMinimap)
                Toggle("Enable monitoring on launch", isOn: $monitoringEnabled)
                Toggle("Clear topology links on boot", isOn: $clearTopologyLinksOnBoot)
            }
        }
        .formStyle(.grouped)
        .frame(minHeight: 200)
        .padding()
    }
}

// MARK: - Switch Credentials

private struct CredentialsPreferencesPane: View {
    @ObservedObject private var preferences = AppPreferences.shared

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var saved: Bool = false
    @State private var passwordsMatch: Bool = true
    @State private var hasExistingPassword: Bool = false

    var body: some View {
        Form {
            Section {
                TextField("Username", text: $username)
                    .textContentType(.username)

                SecureField("Password", text: $password)
                    .textContentType(.password)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.password)

                if !passwordsMatch {
                    Text("Passwords do not match.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Switch Web Interface Login")
            } footer: {
                Text("These credentials are used when opening a switch's web interface via right-click. The username is saved to your preferences file. The password is stored securely in your macOS Keychain and never written to disk in plain text.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Button("Apply") {
                        apply()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(username.isEmpty || password.isEmpty)

                    if hasExistingPassword {
                        Button("Clear Credentials", role: .destructive) {
                            clear()
                        }
                    }

                    Spacer()

                    if saved {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 13, weight: .medium))
                            .transition(.opacity)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minHeight: 280)
        .padding()
        .onAppear { load() }
    }

    private func load() {
        username = preferences.switchUsername
        hasExistingPassword = KeychainHelper.load(account: "switchPassword") != nil
    }

    private func apply() {
        guard !password.isEmpty else { return }
        guard password == confirmPassword else {
            passwordsMatch = false
            return
        }
        passwordsMatch = true
        preferences.switchUsername = username
        KeychainHelper.save(account: "switchPassword", password: password)
        hasExistingPassword = true
        password = ""
        confirmPassword = ""
        withAnimation {
            saved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saved = false }
        }
    }

    private func clear() {
        preferences.switchUsername = ""
        KeychainHelper.delete(account: "switchPassword")
        username = ""
        password = ""
        confirmPassword = ""
        hasExistingPassword = false
    }
}

// MARK: - Redundant Networks

private struct RedundantNetworksPreferencesPane: View {
    @ObservedObject private var preferences = AppPreferences.shared

    var body: some View {
        Form {
            Section {
                Text("When Redundant Mode is active, each tile is given a colour tint to indicate which network plane it belongs to. Choose the tint colours below.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: { Text("Tile Tint Colours") }

            Section {
                ColorPicker("Primary network", selection: $preferences.redundantPrimaryTintColor, supportsOpacity: true)
                ColorPicker("Secondary network", selection: $preferences.redundantSecondaryTintColor, supportsOpacity: true)

                HStack(spacing: 8) {
                    Button("Reset to defaults") {
                        preferences.redundantPrimaryTintColor   = Color(red: 0.80, green: 0.10, blue: 0.10, opacity: 0.35)
                        preferences.redundantSecondaryTintColor = Color(red: 0.10, green: 0.30, blue: 0.85, opacity: 0.35)
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .padding(.top, 4)
            } header: { Text("Colours") }

            Section {
                HStack(spacing: 12) {
                    tilePreview(label: "Primary", color: preferences.redundantPrimaryTintColor)
                    tilePreview(label: "Secondary", color: preferences.redundantSecondaryTintColor)
                    Spacer()
                }
            } header: { Text("Preview") }
        }
        .formStyle(.grouped)
        .frame(minHeight: 320)
        .padding()
    }

    private func tilePreview(label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 0.060, green: 0.195, blue: 0.105))
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.green.opacity(0.6), lineWidth: 1.5)
            }
            .frame(width: 90, height: 52)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Network Routing

private struct NetworkRoutingPane: View {
    @ObservedObject var deviceStore: DeviceStore
    @State private var routeStatus: RouteStatus = .unknown
    @State private var isWorking = false

    enum RouteStatus { case unknown, copied, error(String) }

    private var routeTargets: [(ip: String, interfaceName: String)] {
        deviceStore.devicesWithExplicitNIC()
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When two NICs are connected to separate networks sharing the same subnet (e.g. 192.168.16.0/21), macOS may drop SNMP replies that arrive on the \"wrong\" interface due to reverse-path filtering.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Applying static host routes tells macOS exactly which NIC to use for each device, so replies are accepted on the correct interface.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Important: remove routes before disconnecting a NIC. Static routes pointing to a disconnected interface cause all traffic for those devices to fail until the routes are removed.")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Clicking Apply or Remove copies the commands to your clipboard and opens Terminal. Press ⌘V then Return in Terminal to run them. You will be prompted for your admin password there.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: { Text("Dual-NIC Static Routes") }

            Section {
                if routeTargets.isEmpty {
                    Text("No devices have an explicit NIC configured. Set a specific Ping NIC per device in the inspector to enable static routing.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(routeTargets, id: \.ip) { target in
                        HStack {
                            Text(target.ip).font(.system(size: 11, design: .monospaced))
                            Spacer()
                            Text("→ \(target.interfaceName)").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: { Text("Devices with explicit NIC (\(routeTargets.count))") }

            Section {
                HStack(spacing: 12) {
                    Button(isWorking ? "Working…" : "Apply Routes") {
                        applyRoutes()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(routeTargets.isEmpty || isWorking)

                    Button("Remove Routes") {
                        removeRoutes()
                    }
                    .buttonStyle(.bordered)
                    .disabled(routeTargets.isEmpty || isWorking)

                    Spacer()

                    switch routeStatus {
                    case .unknown: EmptyView()
                    case .copied:
                        Label("Copied — paste in Terminal with ⌘V and press Return", systemImage: "doc.on.clipboard")
                            .foregroundStyle(.green).font(.system(size: 11, weight: .medium))
                    case .error:
                        EmptyView()
                    }
                }

                if case .error(let msg) = routeStatus {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Error", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.system(size: 11, weight: .semibold))
                            Spacer()
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(msg, forType: .string)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Text(msg)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.red.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.20), lineWidth: 1))
                }

                Button("Copy apply commands") {
                    let cmds = routeTargets.map { "sudo route add -host \($0.ip) -interface \($0.interfaceName)" }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(cmds.joined(separator: "\n"), forType: .string)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

                Text("Routes reset on reboot — re-apply after each restart.")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            } header: { Text("Actions") }
        }
        .formStyle(.grouped)
        .frame(minHeight: 380)
        .padding()
    }

    private func applyRoutes() {
        // Delete before adding so stale routes from a previous application don't
        // conflict if NIC assignments have changed since the last run.
        let removes = routeTargets.map { "route delete -host \($0.ip)" }
        let adds    = routeTargets.map { "route add -host \($0.ip) -interface \($0.interfaceName)" }
        executeInTerminal(commands: removes + adds)
    }

    private func removeRoutes() {
        let commands = routeTargets.map { "route delete -host \($0.ip)" }
        executeInTerminal(commands: commands)
    }

    private func executeInTerminal(commands: [String]) {
        isWorking = true
        NetworkRoutingEngine.run(commands: commands) { result in
            isWorking = false
            switch result {
            case .success:
                routeStatus = .copied
            case .failure(let e):
                routeStatus = .error(e.localizedDescription)
            }
        }
    }
}

// MARK: - Routing Engine

enum NetworkRoutingEngine {
    // Copies the route commands to the clipboard and opens Terminal.
    // All AppleScript/osascript `do script` approaches fail with -600 because macOS
    // auto-denies Automation permission when NSAppleEventsUsageDescription is absent
    // from Info.plist. The clipboard approach requires no special permissions at all.
    static func run(commands: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard !commands.isEmpty else { completion(.success(())); return }

        let commandString = commands.map { "sudo \($0)" }.joined(separator: " && ")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(commandString, forType: .string)

        let terminalURL = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
        NSWorkspace.shared.openApplication(at: terminalURL,
                                           configuration: NSWorkspace.OpenConfiguration()) { _, error in
            DispatchQueue.main.async {
                if let error { completion(.failure(error)) } else { completion(.success(())) }
            }
        }
    }
}
