import Foundation

public final class SettingsStore {
    private let defaults: UserDefaults
    private let key = "alist.configuration"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() throws -> AListConfiguration {
        guard let data = defaults.data(forKey: key) else {
            return .default()
        }

        return try decoder.decode(AListConfiguration.self, from: data)
    }

    public func save(_ configuration: AListConfiguration) throws {
        let data = try encoder.encode(configuration)
        defaults.set(data, forKey: key)
    }
}
