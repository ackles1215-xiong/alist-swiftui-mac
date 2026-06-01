import Foundation

public struct AListWebDAVProfile: Codable, Equatable, Sendable {
    public var username: String
    public var password: String

    public init(username: String = "", password: String = "") {
        self.username = username
        self.password = password
    }
}

public extension AListConfiguration {
    var webDAVURL: URL {
        adminURL.appendingPathComponent("dav", isDirectory: true)
    }
}
