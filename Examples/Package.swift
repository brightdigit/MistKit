// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MistKitExamples",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .executable(name: "MistDemo", targets: ["MistDemo"])
    ],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MistDemo",
            dependencies: [
                .product(name: "MistKit", package: "MistKit"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ]
        )
    ]
)