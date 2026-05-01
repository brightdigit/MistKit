// swift-tools-version: 6.0

// swiftlint:disable explicit_acl explicit_top_level_acl

import PackageDescription

let package = Package(
    name: "MistDemoApp",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "MistDemoApp", targets: ["MistDemoApp"])
    ],
    targets: [
        .executableTarget(
            name: "MistDemoApp",
            path: "Sources/MistDemoApp"
        )
    ]
)
// swiftlint:enable explicit_acl explicit_top_level_acl
