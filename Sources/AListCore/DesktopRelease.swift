import Foundation

public struct DesktopRelease: Decodable, Equatable, Sendable {
    public let tagName: String
    public let name: String
    public let assets: [DesktopReleaseAsset]

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case assets
    }

    public func preferredMacAppAsset(architecture: String = RuntimeArchitecture.current) -> DesktopReleaseAsset? {
        let normalized = architecture.lowercased()
        let preferredToken = normalized == "arm64" ? "aarch64" : "x64"

        return assets.first { asset in
            asset.name.contains(preferredToken) && asset.name.hasSuffix(".app.tar.gz")
        } ?? assets.first { asset in
            asset.name.hasSuffix(".app.tar.gz")
        }
    }
}

public struct DesktopReleaseAsset: Decodable, Equatable, Sendable {
    public let name: String
    public let downloadURL: URL
    public let size: Int

    private enum CodingKeys: String, CodingKey {
        case name
        case downloadURL = "browser_download_url"
        case size
    }
}

public enum RuntimeArchitecture {
    public static var current: String {
        #if arch(arm64)
        "arm64"
        #elseif arch(x86_64)
        "x86_64"
        #else
        "unknown"
        #endif
    }
}
