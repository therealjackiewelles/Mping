import SwiftUI

@main
struct MpingApp: App {
    @StateObject private var store = DeviceStore()
    @StateObject private var preferences = AppPreferences.shared
    @State private var showingDeviceView = false
    @State private var showingDevicePortsView = false

    var body: some Scene {
        WindowGroup {
            ContentView(store: store, showingDeviceView: $showingDeviceView, showingDevicePortsView: $showingDevicePortsView)
                .environmentObject(preferences)
                .preferredColorScheme(.dark)
        }
        .commands {
            MpingMenuCommands(store: store, showingDeviceView: $showingDeviceView, showingDevicePortsView: $showingDevicePortsView)
        }

        Settings {
            PreferencesView()
        }
    }
}

private struct MpingMenuCommands: Commands {
    @ObservedObject var store: DeviceStore
    @Binding var showingDeviceView: Bool
    @Binding var showingDevicePortsView: Bool

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Workspace") {
                store.newWorkspace()
            }
            .keyboardShortcut("n", modifiers: [.command])
        }

        CommandGroup(after: .newItem) {
            Button("Open Workspace…") {
                store.openWorkspace()
            }
            .keyboardShortcut("o", modifiers: [.command])
        }

        CommandGroup(replacing: .saveItem) {
            Button(store.hasUnsavedChanges ? "Save *" : "Save") {
                store.save()
            }
            .keyboardShortcut("s", modifiers: [.command])

            Button("Save As…") {
                store.saveWorkspaceAs()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }

        CommandGroup(replacing: .undoRedo) {
            Button("Undo") {
                store.undo()
            }
            .keyboardShortcut("z", modifiers: [.command])
            .disabled(!store.canUndo)

            Button("Redo") {
                store.redo()
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(!store.canRedo)
        }

        CommandGroup(replacing: .pasteboard) {
            Button("Cut") {
                store.cutSelection()
            }
            .keyboardShortcut("x", modifiers: [.command])
            .disabled(!store.hasSelection)

            Button("Copy") {
                store.copySelection()
            }
            .keyboardShortcut("c", modifiers: [.command])
            .disabled(!store.hasSelection)

            Button("Paste") {
                store.pasteSelection()
            }
            .keyboardShortcut("v", modifiers: [.command])

            Divider()

            Button("Delete") {
                store.deleteSelection()
            }
            .keyboardShortcut(.delete, modifiers: [.command])
            .disabled(!store.hasSelection)
        }

        CommandMenu("Devices") {
            Button("Add Device") {
                store.addDevice()
            }
            .keyboardShortcut("d", modifiers: [.command])

            Button("Add Box") {
                store.addShape()
            }
            .keyboardShortcut("b", modifiers: [.command])

            Divider()

            Button("Device Manager") {
                showingDeviceView = true
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Button("Device Ports") {
                showingDevicePortsView = true
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
        }

        CommandMenu("Debugging") {
            Button("Device Tile Editor") {
                DeviceTileEditorWindowController.shared.showPasswordPromptAndOpen()
            }
            .keyboardShortcut("t", modifiers: [.command, .option])

            Button("Fibre Box Editor") {
                FibreBoxEditorWindowController.shared.showPasswordPromptAndOpen()
            }
            .keyboardShortcut("f", modifiers: [.command, .option])

            Button("Telemetry Polling") {
                TelemetryPollingDebugWindowController.shared.showPasswordPromptAndOpen()
            }
            .keyboardShortcut("p", modifiers: [.command, .option])

            Button("Console Output") {
                ConsoleOutputWindowController.shared.showPasswordPromptAndOpen()
            }
            .keyboardShortcut("c", modifiers: [.command, .option])

            Divider()

            Button("Device Debug") {
                DeviceDebugWindowController.shared.configure(store: store)
                DeviceDebugWindowController.shared.showPasswordPromptAndOpen()
            }
            .keyboardShortcut("d", modifiers: [.command, .option])
        }
    }
}
