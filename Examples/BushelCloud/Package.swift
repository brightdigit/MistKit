// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swiftlint:disable explicit_acl explicit_top_level_acl

import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("InternalImportsByDefault"),
]

let package = Package(
    name: "BushelCloud",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "BushelCloudKit", targets: ["BushelCloudKit"]),
        .executable(name: "bushel-cloud", targets: ["BushelCloudCLI"])
    ],
    dependencies: [
        // Local path: BushelCloud develops as Examples/BushelCloud inside the
        // MistKit repo, so ../.. resolves to the parent MistKit checkout. On main
        // this is a tagged remote release; this one-line overlay is reapplied when
        // the branch is recreated from main (never merged, so it never conflicts).
        .package(name: "MistKit", path: "../.."),
        // Monorepo dogfood overlay — publishable consumers use a tagged `from:` once
        // MistKitConfiguration is released.
        .package(path: "../../Packages/MistKitConfiguration"),
        .package(url: "https://github.com/brightdigit/ConfigKeyKit.git", from: "1.0.0-beta.3"),
        .package(url: "https://github.com/brightdigit/BushelKit.git", from: "3.0.0-alpha.4"),
        .package(url: "https://github.com/brightdigit/IPSWDownloads.git", from: "1.0.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(
            url: "https://github.com/apple/swift-configuration.git",
            from: "1.0.0",
            traits: ["CommandLineArguments"]
        )
    ],
    targets: [
        .target(
            name: "BushelCloudKit",
            dependencies: [
                .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
                .product(name: "MistKit", package: "MistKit"),
                .product(name: "MistKitConfiguration", package: "MistKitConfiguration"),
                .product(name: "BushelLogging", package: "BushelKit"),
                .product(name: "BushelFoundation", package: "BushelKit"),
                .product(name: "BushelUtilities", package: "BushelKit"),
                .product(name: "BushelVirtualBuddy", package: "BushelKit"),
                .product(name: "IPSWDownloads", package: "IPSWDownloads"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "Configuration", package: "swift-configuration")
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "BushelCloudCLI",
            dependencies: [
                .target(name: "BushelCloudKit"),
                .product(name: "MistKitConfiguration", package: "MistKitConfiguration"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "BushelCloudKitTests",
            dependencies: [
                .target(name: "BushelCloudKit"),
                .product(name: "MistKitConfiguration", package: "MistKitConfiguration"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)
// swiftlint:enable explicit_acl explicit_top_level_acl
