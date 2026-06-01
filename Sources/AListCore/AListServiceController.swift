import Foundation

public enum AListServiceState: Equatable, Sendable {
    case stopped
    case running
    case failed(String)
}

public protocol RunningProcess: AnyObject {
    func terminate()
}

public protocol ProcessLaunching {
    func launch(
        _ configuration: AListLaunchConfiguration,
        output: @escaping @Sendable (String) -> Void
    ) throws -> RunningProcess
}

public final class AListServiceController {
    public private(set) var state: AListServiceState = .stopped

    private let launcher: ProcessLaunching
    private let logs: LogStore
    private var process: RunningProcess?

    public init(launcher: ProcessLaunching = FoundationProcessLauncher(), logs: LogStore = LogStore()) {
        self.launcher = launcher
        self.logs = logs
    }

    public var logEntries: [LogStore.Entry] {
        logs.entries
    }

    public func start(configuration: AListConfiguration) throws {
        guard process == nil else { return }

        let launchConfiguration = AListLaunchConfiguration(configuration: configuration)

        do {
            let runningProcess = try launcher.launch(launchConfiguration) { [logs] line in
                logs.append(line)
            }
            process = runningProcess
            state = .running
            logs.append("AList started on \(configuration.adminURL.absoluteString)")
        } catch {
            state = .failed(error.localizedDescription)
            logs.append("Failed to start AList: \(error.localizedDescription)")
            throw error
        }
    }

    public func stop() {
        process?.terminate()
        process = nil
        state = .stopped
        logs.append("AList stopped")
    }

    public func clearLogs() {
        logs.clear()
    }
}

public final class FoundationProcessLauncher: ProcessLaunching {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func launch(
        _ configuration: AListLaunchConfiguration,
        output: @escaping @Sendable (String) -> Void
    ) throws -> RunningProcess {
        guard fileManager.fileExists(atPath: configuration.executableURL.path) else {
            throw AListProcessError.missingBinary(configuration.executableURL.path)
        }

        try fileManager.createDirectory(
            at: configuration.workingDirectoryURL,
            withIntermediateDirectories: true
        )

        let process = Process()
        process.executableURL = configuration.executableURL
        process.arguments = configuration.arguments
        process.currentDirectoryURL = configuration.workingDirectoryURL
        process.environment = ProcessInfo.processInfo.environment.merging(configuration.environment) { _, new in
            new
        }

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        attach(pipe: outputPipe, output: output)
        attach(pipe: errorPipe, output: output)

        try process.run()
        return FoundationRunningProcess(process: process, pipes: [outputPipe, errorPipe])
    }

    private func attach(pipe: Pipe, output: @escaping @Sendable (String) -> Void) {
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else {
                return
            }

            for line in text.split(whereSeparator: \.isNewline) {
                output(String(line))
            }
        }
    }
}

private final class FoundationRunningProcess: RunningProcess {
    private let process: Process
    private let pipes: [Pipe]

    init(process: Process, pipes: [Pipe]) {
        self.process = process
        self.pipes = pipes
    }

    func terminate() {
        for pipe in pipes {
            pipe.fileHandleForReading.readabilityHandler = nil
        }

        if process.isRunning {
            process.terminate()
        }
    }
}

public enum AListProcessError: Error, Equatable, LocalizedError {
    case missingBinary(String)

    public var errorDescription: String? {
        switch self {
        case .missingBinary(let path):
            "AList binary was not found at \(path)."
        }
    }
}
