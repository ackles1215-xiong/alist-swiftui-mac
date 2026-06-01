import Foundation

public struct AListConfiguration: Codable, Equatable, Sendable {
    public let binaryURL: URL
    public let dataDirectory: URL
    public let port: Int

    public init(binaryURL: URL, dataDirectory: URL, port: Int) throws {
        guard (1...65_535).contains(port) else {
            throw AListConfigurationError.invalidPort(port)
        }

        self.binaryURL = binaryURL
        self.dataDirectory = dataDirectory
        self.port = port
    }

    public static func `default`(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> AListConfiguration {
        let fallbackBinary = BinaryDiscovery().discover() ?? URL(fileURLWithPath: "/usr/local/bin/alist")
        let dataDirectory = homeDirectory.appendingPathComponent(".alist", isDirectory: true)
        return try! AListConfiguration(
            binaryURL: fallbackBinary,
            dataDirectory: dataDirectory,
            port: 5_244
        )
    }

    public var adminURL: URL {
        URL(string: "http://127.0.0.1:\(port)")!
    }
}

public enum AListConfigurationError: Error, Equatable, LocalizedError {
    case invalidPort(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidPort(let port):
            "Port \(port) is outside the valid range 1...65535."
        }
    }
}
