import AListCore
import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    enum DetailSection: String, CaseIterable, Identifiable {
        case control = "Control"
        case admin = "Admin"
        case logs = "Logs"
        case webdav = "WebDAV"

        var id: String { rawValue }
    }

    @Published private(set) var state: AListServiceState = .stopped
    @Published private(set) var healthStatus: HealthStatus = .unknown
    @Published private(set) var logs: [LogStore.Entry] = []
    @Published var binaryPath: String
    @Published var dataDirectoryPath: String
    @Published var portText: String
    @Published var webDAVUsername: String
    @Published var webDAVPassword: String
    @Published var errorMessage: String?
    @Published var selectedSection: DetailSection = .control

    private let settingsStore: SettingsStore
    private let service: AListServiceController
    private let healthChecker: any HealthChecking

    init(
        settingsStore: SettingsStore = SettingsStore(),
        service: AListServiceController = AListServiceController(),
        healthChecker: any HealthChecking = HTTPHealthChecker()
    ) {
        self.settingsStore = settingsStore
        self.service = service
        self.healthChecker = healthChecker

        let configuration = (try? settingsStore.load()) ?? .default()
        let webDAVProfile = (try? settingsStore.loadWebDAVProfile()) ?? AListWebDAVProfile()
        binaryPath = configuration.binaryURL.path
        dataDirectoryPath = configuration.dataDirectory.path
        portText = String(configuration.port)
        webDAVUsername = webDAVProfile.username
        webDAVPassword = webDAVProfile.password
        state = service.state
        logs = service.logEntries
    }

    var adminURL: URL? {
        try? currentConfiguration().adminURL
    }

    var adminURLText: String {
        guard let configuration = try? currentConfiguration() else {
            return "Invalid configuration"
        }

        return configuration.adminURL.absoluteString
    }

    var webDAVURLText: String {
        guard let configuration = try? currentConfiguration() else {
            return "Invalid configuration"
        }

        return configuration.webDAVURL.absoluteString
    }

    var infuseConnectionSummary: String {
        """
        Server: \(webDAVURLText)
        Username: \(webDAVUsername)
        Password: \(webDAVPassword)
        """
    }

    func start() {
        do {
            let configuration = try currentConfiguration()
            try settingsStore.save(configuration)
            try saveWebDAVProfile()
            try service.start(configuration: configuration)
            errorMessage = nil
            selectedSection = .admin
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

    func saveWebDAVProfile() throws {
        try settingsStore.save(AListWebDAVProfile(username: webDAVUsername, password: webDAVPassword))
    }

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func autoDetectBinary() {
        guard let url = BinaryDiscovery().discover() else {
            errorMessage = "No executable AList binary was found."
            return
        }

        binaryPath = url.path
        errorMessage = nil
    }

    func updateHealth() {
        guard let url = adminURL else {
            healthStatus = .unknown
            return
        }

        let healthChecker = healthChecker
        Task {
            let status = await healthChecker.check(url: url)
            await MainActor.run {
                self.healthStatus = status
            }
        }
    }

    func resetHealth() {
        healthStatus = .unknown
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
