import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum HealthStatus: Equatable, Sendable {
    case unknown
    case online
    case offline
}

public protocol HealthChecking: Sendable {
    func check(url: URL) async -> HealthStatus
}

public protocol HealthTransport: Sendable {
    func statusCode(for url: URL) async throws -> Int
}

public struct HTTPHealthChecker: HealthChecking {
    private let transport: HealthTransport

    public init(transport: HealthTransport = URLSessionHealthTransport()) {
        self.transport = transport
    }

    public func check(url: URL) async -> HealthStatus {
        do {
            let statusCode = try await transport.statusCode(for: url)
            return (200..<400).contains(statusCode) ? .online : .offline
        } catch {
            return .offline
        }
    }
}

public struct URLSessionHealthTransport: HealthTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func statusCode(for url: URL) async throws -> Int {
        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        let (_, response) = try await session.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode ?? 0
    }
}
