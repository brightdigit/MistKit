// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swiftlint:disable explicit_acl explicit_top_level_acl file_name

import PackageDescription

// Bare imports in swift-openapi-generator output must stay public; do not apply
// InternalImportsByDefault to the generated MistKitOpenAPI target.
let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("InternalImportsByDefault"),
]

// Swift 6.2 Windows silently aborts emitting MistKitTests past a tip-over size
// (no `error:` / stack dump). Same sources are fine on Windows 6.1/6.3 and every
// other platform. Exclude branch-added test files on Windows only so the 6.2
// matrix entry stays green; coverage remains on Ubuntu/macOS. See
// .claude/docs/research/windows-6.2-ci-failure-462.md.
#if os(Windows)
let mistKitTestsExcludedSources: [String] = [
  "Authentication/Middleware/AuthenticationMiddlewareTests+TokenRotation.swift",
  "Mocks/TokenManagers/MockTokenManagerWithRotation.swift",
  "Mocks/TokenManagers/MockTokenManagerWithRotationFailure.swift",
  "Models/Zones/ZoneMetadataTests+ZoneInfoConversionEdgeCases.swift",
  "CloudKitService/Zones/CloudKitServiceTests.ZoneOwnerWireKey.swift",
  "CloudKitService/Zones/CloudKitServiceTests.ZoneOwnerWireKey+WireFormat.swift",
  "CloudKitService/RecordWrite/CloudKitServiceTests.RecordWriteConvenience+ZoneID.swift",
]
#else
let mistKitTestsExcludedSources: [String] = []
#endif

let package = Package(
  name: "MistKit",
  platforms: [
    .macOS(.v11),
    .iOS(.v14),
    .tvOS(.v14),
    .watchOS(.v7),
    .visionOS(.v1)
    // Note: WASM/WASI support doesn't require explicit platform declaration
    // Use --swift-sdk wasm32-unknown-wasi when building for WASM
  ],
  products: [
    // Products define the executables and libraries a package produces,
    // making them visible to other packages.
    .library(
      name: "MistKit",
      targets: ["MistKit"]
    ),
    .library(
      name: "MistKitOpenAPI",
      targets: ["MistKitOpenAPI"]
    ),
  ],
  dependencies: [
    // Swift OpenAPI Runtime dependencies
    .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.0"),
    .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.2.0"),
    // Crypto library for cross-platform cryptographic operations
    .package(url: "https://github.com/apple/swift-crypto.git", from: "4.0.0"),
    // Logging library for cross-platform logging
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "MistKitOpenAPI",
      dependencies: [
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
      ]
    ),
    .target(
      name: "MistKit",
      dependencies: [
        "MistKitOpenAPI",
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
        // URLSession transport only available on non-WASM platforms
        .product(
          name: "OpenAPIURLSession",
          package: "swift-openapi-urlsession",
          condition: .when(platforms: Platform.without(Platform.wasi))
        ),
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "Logging", package: "swift-log"),
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "MistKitTests",
      dependencies: ["MistKit", "MistKitOpenAPI"],
      exclude: mistKitTestsExcludedSources,
      swiftSettings: swiftSettings
    ),
  ]
)

extension Platform {
  static let all: [Platform] = [
    .macOS, .iOS, .tvOS, .watchOS, .visionOS, .linux, .windows, android, .driverKit, .wasi
  ]

  static func without(_ platform: Platform) -> [Platform] {
    var result = all
    result.removeAll{
    $0 == platform
    }
    return result
  }
}

// swiftlint:enable explicit_acl explicit_top_level_acl
