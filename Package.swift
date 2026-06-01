// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "alist-swiftui-mac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "AListCore", targets: ["AListCore"]),
        .executable(name: "AListSwiftUIMac", targets: ["AListSwiftUIMac"])
    ],
    targets: [
        .target(name: "AListCore"),
        .executableTarget(
            name: "AListSwiftUIMac",
            dependencies: ["AListCore"]
        ),
        .testTarget(
            name: "AListCoreTests",
            dependencies: ["AListCore"]
        )
    ]
)
