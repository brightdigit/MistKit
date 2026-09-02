// swift-tools-version: 6.2

// swiftlint:disable explicit_acl explicit_top_level_acl

import PackageDescription

// MARK: - AsyncAlgorithms wasi gating
//
// AsyncAlgorithms 1.0.x's Locking.swift references pthread_mutex_*. The Swift 6.2
// wasm32-unknown-wasip1 SDK doesn't ship libwasi-emulated-pthread.a, so linking
// fails. Swift 6.3+ wasi SDKs link cleanly. Gate the wasi exclusion to 6.2 only;
// the `#else` self-deletes when the floor moves to 6.3.

#if compiler(>=6.3)
let asyncAlgorithmsCondition: TargetDependencyCondition? = nil
#else
let asyncAlgorithmsCondition: TargetDependencyCondition? = .when(
  platforms: Platform.without(.wasi)
)
#endif

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("InternalImportsByDefault"),
]

let package = Package(
  name: "MistDemo",
  platforms: [
    .macOS(.v15),
    .iOS(.v18),
    .tvOS(.v18),
    .watchOS(.v11),
    .visionOS(.v2),
  ],
  products: [
    .executable(name: "mistdemo", targets: ["MistDemo"]),
    .library(name: "MistDemoApp", targets: ["MistDemoApp"]),
  ],
  dependencies: [
    .package(name: "MistKit", path: "../.."),
    // Monorepo dogfood overlay — publishable consumers use a tagged `from:` once
    // MistKitConfiguration is released.
    .package(path: "../../Packages/MistKitConfiguration"),
    .package(url: "https://github.com/brightdigit/ConfigKeyKit.git", from: "1.0.0-beta.3"),
    .package(
      url: "https://github.com/hummingbird-project/hummingbird.git",
      from: "2.0.0"
    ),
    .package(
      url: "https://github.com/apple/swift-configuration",
      from: "1.0.0",
      traits: ["CommandLineArguments"]
    ),
    .package(
      url: "https://github.com/swift-server/swift-service-lifecycle.git",
      from: "2.0.0"
    ),
    .package(
      url: "https://github.com/apple/swift-async-algorithms.git",
      from: "1.0.0"
    ),
  ],
  targets: [
    .target(
      name: "MistDemoApp",
      dependencies: ["MistDemoKit"],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "MistDemoKit",
      dependencies: [
        .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
        .product(name: "MistKit", package: "MistKit"),
        .product(name: "MistKitConfiguration", package: "MistKitConfiguration"),
        .product(
          name: "Hummingbird",
          package: "hummingbird",
          condition: .when(platforms: [
            .macOS, .iOS, .tvOS, .visionOS, .macCatalyst, .linux,
          ])
        ),
        .product(name: "Configuration", package: "swift-configuration"),
        .product(
          name: "UnixSignals",
          package: "swift-service-lifecycle"
        ),
        .product(
          name: "AsyncAlgorithms",
          package: "swift-async-algorithms",
          condition: asyncAlgorithmsCondition
        ),
      ],
      resources: [
        .copy("Resources/index.html"),
        .copy("Resources/styles.css"),
        .copy("Resources/js"),
      ],
      swiftSettings: swiftSettings
    ),
    .executableTarget(
      name: "MistDemo",
      dependencies: [
        "MistDemoKit",
        .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
        .product(name: "MistKit", package: "MistKit"),
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "MistDemoTests",
      dependencies: [
        "MistDemoKit",
        .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
        .product(name: "MistKit", package: "MistKit"),
        .product(name: "MistKitConfiguration", package: "MistKitConfiguration"),
        .product(
          name: "Hummingbird",
          package: "hummingbird",
          condition: .when(platforms: [
            .macOS, .iOS, .tvOS, .visionOS, .macCatalyst, .linux,
          ])
        ),
        .product(
          name: "HummingbirdTesting",
          package: "hummingbird",
          condition: .when(platforms: [
            .macOS, .iOS, .tvOS, .visionOS, .macCatalyst, .linux,
          ])
        ),
        .product(
          name: "AsyncAlgorithms",
          package: "swift-async-algorithms",
          condition: asyncAlgorithmsCondition
        ),
      ],
      swiftSettings: swiftSettings
    ),
  ]
)

extension Platform {
  static let all: [Platform] = [
    .macOS, .iOS, .tvOS, .watchOS, .visionOS, .macCatalyst,
    .linux, .windows, .android, .driverKit, .wasi,
  ]

  static func without(_ platform: Platform) -> [Platform] {
    var result = all
    result.removeAll { $0 == platform }
    return result
  }
}

// swiftlint:enable explicit_acl explicit_top_level_acl
