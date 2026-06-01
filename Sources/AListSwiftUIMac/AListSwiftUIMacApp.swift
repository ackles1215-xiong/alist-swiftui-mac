import SwiftUI

@main
struct AListSwiftUIMacApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("AList") {
            ContentView(model: model)
                .frame(minWidth: 860, minHeight: 560)
        }
        .windowStyle(.titleBar)

        MenuBarExtra {
            StatusBadge(state: model.state)

            Divider()

            Button("Start AList") {
                model.start()
            }
            .disabled(model.state == .running)

            Button("Stop AList") {
                model.stop()
            }
            .disabled(model.state == .stopped)

            Button("Open Admin") {
                model.openAdmin()
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Label("AList", systemImage: model.state == .running ? "externaldrive.fill.badge.checkmark" : "externaldrive")
        }
    }
}
