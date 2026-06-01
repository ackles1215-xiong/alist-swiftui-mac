import Foundation

public final class LogStore: @unchecked Sendable {
    public struct Entry: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let date: Date
        public let message: String

        public init(id: UUID = UUID(), date: Date = Date(), message: String) {
            self.id = id
            self.date = date
            self.message = message
        }
    }

    private let limit: Int
    private var storage: [Entry] = []
    private let lock = NSLock()

    public init(limit: Int = 500) {
        self.limit = max(1, limit)
    }

    public var entries: [Entry] {
        lock.withLock {
            storage
        }
    }

    public func append(_ message: String, date: Date = Date()) {
        lock.withLock {
            storage.append(Entry(date: date, message: message))
            if storage.count > limit {
                storage.removeFirst(storage.count - limit)
            }
        }
    }

    public func clear() {
        lock.withLock {
            storage.removeAll()
        }
    }
}
