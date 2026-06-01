import Foundation

public struct AListLaunchConfiguration: Equatable, Sendable {
    public let executableURL: URL
    public let arguments: [String]
    public let environment: [String: String]
    public let workingDirectoryURL: URL

    public init(configuration: AListConfiguration) {
        executableURL = configuration.binaryURL
        arguments = [
            "server",
            "--data",
            configuration.dataDirectory.path
        ]
        environment = [
            "ALIST_ADDR": "127.0.0.1",
            "ALIST_HTTP_PORT": String(configuration.port)
        ]
        workingDirectoryURL = configuration.dataDirectory
    }
}
