import AListCore
import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var state: AListServiceState = .stopped
    @Published private(set) var logs: [LogStore.Entry] = []
    @Published var binaryPath: String
    @Published var dataDirectoryPath: String
    @Published var portText: String
    @Published var errorMessage: String?

    private let settingsStore: SettingsStore
    private let service: AListServiceController

    init(
        settingsStore: SettingsStore = SettingsStore(),
        service: AListServiceController = AListServiceController()
    ) {
        self.settingsStore = settingsStore
        self.service = service

        let configuration = (try? settingsStore.load()) ?? .default()
        binaryPath = configuration.binaryURL.path
        dataDirectoryPath = configuration.dataDirectory.path
        portText = String(configuration.port)
        state = service.state
        logs = service.logEntries
    }

    var adminURLText: String {
        guard let configuration = try? currentConfiguration() else {
            return "Invalid configuration"
        }

        return configuration.adminURL.absoluteString
    }

    func start() {
        do {
            let configuration = try currentConfiguration()
            try settingsStore.save(configuration)
            try service.start(configuration: configuration)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        refresh()
    }

    func stop() {
        service.stop()
        refresh()
    }

    func openAdmin() {
        guard let url = try? currentConfiguration().adminURL else {
            errorMessage = "The current port is invalid."
            return
        }

        NSWorkspace.shared.open(url)
    }

    func chooseBinary() {
        let panel = NSOpenPanel()
        panel.title = "Choose AList Binary"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            binaryPath = url.path
        }
    }

    func chooseDataDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Choose AList Data Directory"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            dataDirectoryPath = url.path
        }
    }

    func clearLogs() {
        service.clearLogs()
        refresh()
    }

    func refresh() {
        state = service.state
        logs = service.logEntries
    }

    private func currentConfiguration() throws -> AListConfiguration {
        let port = Int(portText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return try AListConfiguration(
            binaryURL: URL(fileURLWithPath: binaryPath),
            dataDirectory: URL(fileURLWithPath: dataDirectoryPath, isDirectory: true),
            port: port
        )
    }
}
