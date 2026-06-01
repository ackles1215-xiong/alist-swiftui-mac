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

    func testBinaryDiscoveryChoosesFirstExistingExecutable() {
        let checker = FakeFileChecker(existingExecutablePaths: [
            "/Applications/AList/alist"
        ])
        let discovery = BinaryDiscovery(
            fileChecker: checker,
            candidates: [
                URL(fileURLWithPath: "/missing/alist"),
                URL(fileURLWithPath: "/Applications/AList/alist"),
                URL(fileURLWithPath: "/usr/local/bin/alist")
            ]
        )

        XCTAssertEqual(discovery.discover()?.path, "/Applications/AList/alist")
    }

    func testDesktopReleaseSelectsPreferredMacAsset() throws {
        let json = """
        {
          "tag_name": "v3.60.0",
          "name": "AList Desktop v3.60.0",
          "assets": [
            {
              "name": "alist-desktop_x64.app.tar.gz",
              "browser_download_url": "https://example.com/x64.tar.gz",
              "size": 86167257
            },
            {
              "name": "alist-desktop_aarch64.app.tar.gz",
              "browser_download_url": "https://example.com/aarch64.tar.gz",
              "size": 79928962
            },
            {
              "name": "alist-desktop_3.60.0_x64.dmg",
              "browser_download_url": "https://example.com/x64.dmg",
              "size": 72297615
            }
          ]
        }
        """.data(using: .utf8)!

        let release = try JSONDecoder().decode(DesktopRelease.self, from: json)
        let asset = release.preferredMacAppAsset(architecture: "arm64")

        XCTAssertEqual(release.tagName, "v3.60.0")
        XCTAssertEqual(release.name, "AList Desktop v3.60.0")
        XCTAssertEqual(asset?.name, "alist-desktop_aarch64.app.tar.gz")
        XCTAssertEqual(asset?.downloadURL.absoluteString, "https://example.com/aarch64.tar.gz")
    }

    func testHealthStatusMapsHTTPResponses() async {
        let healthyChecker = HTTPHealthChecker(transport: FakeHealthTransport(statusCode: 302))
        let failedChecker = HTTPHealthChecker(transport: FakeHealthTransport(error: URLError(.cannotConnectToHost)))
        let url = URL(string: "http://127.0.0.1:5244")!

        await XCTAssertEqualAsync(await healthyChecker.check(url: url), .online)
        await XCTAssertEqualAsync(await failedChecker.check(url: url), .offline)
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

private struct FakeFileChecker: FileChecking {
    let existingExecutablePaths: Set<String>

    func isExecutableFile(at url: URL) -> Bool {
        existingExecutablePaths.contains(url.path)
    }
}

private struct FakeHealthTransport: HealthTransport {
    var statusCode: Int?
    var error: Error?

    func statusCode(for url: URL) async throws -> Int {
        if let error {
            throw error
        }

        return statusCode ?? 500
    }
}

private func XCTAssertEqualAsync<T: Equatable>(
    _ expression1: @autoclosure () async throws -> T,
    _ expression2: @autoclosure () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        let value1 = try await expression1()
        let value2 = try await expression2()
        XCTAssertEqual(value1, value2, file: file, line: line)
    } catch {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
    }
}
