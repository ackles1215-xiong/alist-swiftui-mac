import XCTest
@testable import AListCore

final class AListCoreTests: XCTestCase {
    func testDefaultConfigurationBuildsLocalAdminURL() throws {
        let configuration = AListConfiguration.default(
            homeDirectory: URL(fileURLWithPath: "/Users/tester")
        )

        XCTAssertEqual(configuration.port, 5244)
        XCTAssertEqual(configuration.adminURL.absoluteString, "http://127.0.0.1:5244")
        XCTAssertEqual(configuration.dataDirectory.path, "/Users/tester/.alist")
    }

    func testConfigurationRejectsInvalidPorts() {
        XCTAssertThrowsError(try AListConfiguration(
            binaryURL: URL(fileURLWithPath: "/usr/local/bin/alist"),
            dataDirectory: URL(fileURLWithPath: "/tmp/alist-data"),
            port: 0
        ))

        XCTAssertThrowsError(try AListConfiguration(
            binaryURL: URL(fileURLWithPath: "/usr/local/bin/alist"),
            dataDirectory: URL(fileURLWithPath: "/tmp/alist-data"),
            port: 70_000
        ))
    }

    func testLaunchConfigurationBuildsServerCommand() throws {
        let configuration = try AListConfiguration(
            binaryURL: URL(fileURLWithPath: "/Applications/AList/alist"),
            dataDirectory: URL(fileURLWithPath: "/Users/tester/AList Data"),
            port: 5244
        )

        let launch = AListLaunchConfiguration(configuration: configuration)

        XCTAssertEqual(launch.executableURL.path, "/Applications/AList/alist")
        XCTAssertEqual(launch.arguments, ["server", "--data", "/Users/tester/AList Data"])
        XCTAssertEqual(launch.environment["ALIST_ADDR"], "127.0.0.1")
        XCTAssertEqual(launch.environment["ALIST_HTTP_PORT"], "5244")
        XCTAssertEqual(launch.workingDirectoryURL.path, "/Users/tester/AList Data")
    }

    func testLogStoreKeepsMostRecentEntries() {
        let store = LogStore(limit: 3)

        store.append("one")
        store.append("two")
        store.append("three")
        store.append("four")

        XCTAssertEqual(store.entries.map(\.message), ["two", "three", "four"])
    }

    func testServiceControllerStartsAndStopsUsingLauncher() throws {
        let process = FakeRunningProcess()
        let launcher = FakeProcessLauncher(process: process)
        let logs = LogStore()
        let controller = AListServiceController(launcher: launcher, logs: logs)
        let configuration = try AListConfiguration(
            binaryURL: URL(fileURLWithPath: "/usr/local/bin/alist"),
            dataDirectory: URL(fileURLWithPath: "/tmp/alist-data"),
            port: 5244
        )

        try controller.start(configuration: configuration)

        XCTAssertEqual(controller.state, .running)
        XCTAssertEqual(launcher.receivedLaunch?.arguments, ["server", "--data", "/tmp/alist-data"])
        XCTAssertEqual(logs.entries.last?.message, "AList started on http://127.0.0.1:5244")

        controller.stop()

        XCTAssertEqual(controller.state, .stopped)
        XCTAssertTrue(process.didTerminate)
    }

    func testSettingsStoreSavesAndLoadsConfiguration() throws {
        let suiteName = "AListCoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = SettingsStore(defaults: defaults)
        let configuration = try AListConfiguration(
            binaryURL: URL(fileURLWithPath: "/opt/alist/alist"),
            dataDirectory: URL(fileURLWithPath: "/Users/tester/AList"),
            port: 4242
        )

        try store.save(configuration)

        XCTAssertEqual(try store.load(), configuration)
    }
}

private final class FakeProcessLauncher: ProcessLaunching {
    let process: FakeRunningProcess
    private(set) var receivedLaunch: AListLaunchConfiguration?

    init(process: FakeRunningProcess) {
        self.process = process
    }

    func launch(_ configuration: AListLaunchConfiguration, output: @escaping @Sendable (String) -> Void) throws -> RunningProcess {
        receivedLaunch = configuration
        output("boot log")
        return process
    }
}

private final class FakeRunningProcess: RunningProcess {
    private(set) var didTerminate = false

    func terminate() {
        didTerminate = true
    }
}
