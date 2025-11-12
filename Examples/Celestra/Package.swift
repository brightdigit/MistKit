// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Celestra",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "celestra", targets: ["Celestra"])
    ],
    dependencies: [
        .package(path: "../.."),  // MistKit
        .package(url: "https://github.com/brightdigit/SyndiKit.git", from: "0.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Celestra",
            dependencies: [
                .product(name: "MistKit", package: "MistKit"),
                .product(name: "SyndiKit", package: "SyndiKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log")
            ]
        )
    ]
)
