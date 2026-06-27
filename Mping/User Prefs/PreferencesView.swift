import SwiftUI

struct PreferencesView: View {
    var body: some View {
        TabView {
            GeneralPreferencesPane()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            CredentialsPreferencesPane()
                .tabItem {
                    Label("Switch Credentials", systemImage: "key.fill")
                }
        }
        .frame(width: 480)
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
