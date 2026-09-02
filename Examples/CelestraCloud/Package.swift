// swift-tools-version: 6.4

// swiftlint:disable explicit_acl explicit_top_level_acl

import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("InternalImportsByDefault"),
]

let package = Package(
  name: "CelestraCloud",
  platforms: [
    .macOS(.v26),
    .iOS(.v26),
    .tvOS(.v26),
    .watchOS(.v26),
    .visionOS(.v26)
  ],
  products: [
    .executable(name: "celestra-cloud", targets: ["CelestraCloud"]),
    .library(name: "CelestraCloudKit", targets: ["CelestraCloudKit"])
  ],
  dependencies: [
    .package(name: "MistKit", path: "../.."),
    // Monorepo dogfood overlay — publishable consumers use a tagged `from:` once
    // MistKitConfiguration is released. Same never-merged discipline as the MistKit line.
    .package(path: "../../Packages/MistKitConfiguration"),
    .package(url: "https://github.com/brightdigit/ConfigKeyKit.git", from: "1.0.0-beta.3"),
    .package(url: "https://github.com/brightdigit/CelestraKit.git", from: "0.0.3"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(
      url: "https://github.com/apple/swift-configuration.git",
      from: "1.0.0",
      traits: ["CommandLineArguments"]
    )
  ],
  targets: [
    .target(
      name: "CelestraCloudKit",
      dependencies: [
        .product(name: "MistKit", package: "MistKit"),
        .product(name: "MistKitConfiguration", package: "MistKitConfiguration"),
        .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
        .product(name: "CelestraKit", package: "CelestraKit"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "Configuration", package: "swift-configuration")
      ],
      swiftSettings: swiftSettings
    ),
    .executableTarget(
      name: "CelestraCloud",
      dependencies: [
        .target(name: "CelestraCloudKit"),
        .product(name: "MistKitConfiguration", package: "MistKitConfiguration"),
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "CelestraCloudTests",
      dependencies: [
        .target(name: "CelestraCloud"),
        .target(name: "CelestraCloudKit"),
        .product(name: "MistKit", package: "MistKit"),
        .product(name: "CelestraKit", package: "CelestraKit")
      ],
      swiftSettings: swiftSettings
    )
  ]
)
// swiftlint:enable explicit_acl explicit_top_level_acl
