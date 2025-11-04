// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bushel",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "bushel-images", targets: ["BushelImages"])
    ],
    dependencies: [
        .package(path: "../.."),
        .package(url: "https://github.com/brightdigit/IPSWDownloads.git", from: "1.0.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "BushelImages",
            dependencies: [
                .product(name: "MistKit", package: "MistKit"),
                .product(name: "IPSWDownloads", package: "IPSWDownloads"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
