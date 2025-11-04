// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MistDemo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "mistdemo", targets: ["MistDemo"])
    ],
    dependencies: [
        .package(path: "../.."),  // MistKit
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "MistDemo",
            dependencies: [
                .product(name: "MistKit", package: "MistKit"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
