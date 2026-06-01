import Foundation

public protocol FileChecking {
    func isExecutableFile(at url: URL) -> Bool
}

public struct LocalFileChecker: FileChecking {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func isExecutableFile(at url: URL) -> Bool {
        fileManager.isExecutableFile(atPath: url.path)
    }
}

public struct BinaryDiscovery {
    private let fileChecker: FileChecking
    private let candidates: [URL]

    public init(
        fileChecker: FileChecking = LocalFileChecker(),
        candidates: [URL] = BinaryDiscovery.defaultCandidates()
    ) {
        self.fileChecker = fileChecker
        self.candidates = candidates
    }

    public func discover() -> URL? {
        candidates.first { candidate in
            fileChecker.isExecutableFile(at: candidate)
        }
    }

    public static func defaultCandidates(bundle: Bundle = .main) -> [URL] {
        var urls: [URL] = []

        if let bundled = bundle.url(forResource: "alist", withExtension: nil) {
            urls.append(bundled)
        }

        urls.append(contentsOf: [
            URL(fileURLWithPath: "/opt/homebrew/bin/alist"),
            URL(fileURLWithPath: "/usr/local/bin/alist"),
            URL(fileURLWithPath: "/Applications/alist-desktop.app/Contents/MacOS/alist"),
            URL(fileURLWithPath: "/Applications/AList.app/Contents/MacOS/alist")
        ])

        return urls
    }
}
