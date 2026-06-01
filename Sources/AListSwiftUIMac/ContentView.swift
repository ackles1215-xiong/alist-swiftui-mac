import AListCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("AList")
                        .font(.system(size: 30, weight: .semibold))

                    StatusBadge(state: model.state)
                    Label(healthTitle, systemImage: healthImage)
                        .foregroundStyle(healthColor)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Admin")
                        .font(.headline)
                    Text(model.adminURLText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        model.start()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.state == .running)

                    Button {
                        model.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .disabled(model.state == .stopped)

                    Button {
                        model.openAdmin()
                    } label: {
                        Label("Open Admin", systemImage: "safari")
                    }

                    Button {
                        model.selectedSection = .admin
                    } label: {
                        Label("Show Embedded", systemImage: "macwindow")
                    }
                }
                .controlSize(.large)
            }
            .padding(24)
            .frame(minWidth: 240, alignment: .leading)
        } detail: {
            VStack(spacing: 0) {
                Picker("Section", selection: $model.selectedSection) {
                    ForEach(AppModel.DetailSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top], 24)

                switch model.selectedSection {
                case .control:
                    settingsSection
                case .admin:
                    adminSection
                case .logs:
                    logsSection
                case .webdav:
                    webDAVSection
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            model.refresh()
            if model.state == .running {
                model.updateHealth()
            } else {
                model.resetHealth()
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Service Settings")
                    .font(.title2.weight(.semibold))
                Spacer()
                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Text("Binary")
                        .foregroundStyle(.secondary)
                    TextField("Path to alist", text: $model.binaryPath)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        model.autoDetectBinary()
                    } label: {
                        Image(systemName: "scope")
                    }
                    .help("Auto-detect AList binary")
                    Button {
                        model.chooseBinary()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .help("Choose AList binary")
                }

                GridRow {
                    Text("Data")
                        .foregroundStyle(.secondary)
                    TextField("AList data directory", text: $model.dataDirectoryPath)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        model.chooseDataDirectory()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .help("Choose data directory")
                }

                GridRow {
                    Text("Port")
                        .foregroundStyle(.secondary)
                    TextField("5244", text: $model.portText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 140)
                    Spacer()
                }
            }
        }
        .padding(24)
    }

    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Embedded Admin")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    model.openAdmin()
                } label: {
                    Label("Open in Browser", systemImage: "safari")
                }
            }

            WebAdminView(url: model.adminURL)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(24)
    }

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Logs")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    model.clearLogs()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if model.logs.isEmpty {
                        Text("No logs yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.logs) { entry in
                            Text(entry.message)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(12)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(24)
    }

    private var webDAVSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Infuse WebDAV")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    model.copyToClipboard(model.infuseConnectionSummary)
                } label: {
                    Label("Copy All", systemImage: "doc.on.doc")
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Group {
                    LabeledContent("Server") {
                        Text(model.webDAVURLText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    LabeledContent("Username") {
                        TextField("Infuse username", text: $model.webDAVUsername)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 240)
                    }
                    LabeledContent("Password") {
                        SecureField("Infuse password", text: $model.webDAVPassword)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 240)
                    }
                }
                .labelsHidden()

                HStack(spacing: 12) {
                    Button {
                        model.copyToClipboard(model.webDAVURLText)
                    } label: {
                        Label("Copy URL", systemImage: "link")
                    }

                    Button {
                        model.copyToClipboard(model.webDAVUsername)
                    } label: {
                        Label("Copy Username", systemImage: "person")
                    }

                    Button {
                        model.copyToClipboard(model.webDAVPassword)
                    } label: {
                        Label("Copy Password", systemImage: "key")
                    }

                    Button {
                        try? model.saveWebDAVProfile()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }
            }

            Text("Use the server URL, username, and password directly in Infuse. The path is always `/dav/` on the current AList port.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }

    private var healthTitle: String {
        switch model.healthStatus {
        case .unknown:
            "Health unknown"
        case .online:
            "Admin online"
        case .offline:
            "Admin offline"
        }
    }

    private var healthImage: String {
        switch model.healthStatus {
        case .unknown:
            "questionmark.circle"
        case .online:
            "network"
        case .offline:
            "wifi.exclamationmark"
        }
    }

    private var healthColor: Color {
        switch model.healthStatus {
        case .unknown:
            .secondary
        case .online:
            .green
        case .offline:
            .orange
        }
    }
}
