// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swiftlint:disable explicit_acl explicit_top_level_acl

import PackageDescription

// MARK: - Swift Settings Configuration

// Base Swift settings for all platforms
let swiftSettings: [SwiftSetting] = [
  // Swift 6.2 Upcoming Features (not yet enabled by default)
  // SE-0335: Introduce existential `any`
  .enableUpcomingFeature("ExistentialAny"),
  // SE-0409: Access-level modifiers on import declarations
  .enableUpcomingFeature("InternalImportsByDefault"),
  // SE-0444: Member import visibility (Swift 6.1+)
  .enableUpcomingFeature("MemberImportVisibility"),
  // SE-0413: Typed throws
  .enableUpcomingFeature("FullTypedThrows"),

  // Experimental Features (stable enough for use)
  // SE-0426: BitwiseCopyable protocol
  .enableExperimentalFeature("BitwiseCopyable"),
  // SE-0432: Borrowing and consuming pattern matching for noncopyable types
  .enableExperimentalFeature("BorrowingSwitch"),
  // Extension macros
  .enableExperimentalFeature("ExtensionMacros"),
  // Freestanding expression macros
  .enableExperimentalFeature("FreestandingExpressionMacros"),
  // Init accessors
  .enableExperimentalFeature("InitAccessors"),
  // Isolated any types
  .enableExperimentalFeature("IsolatedAny"),
  // Move-only classes
  .enableExperimentalFeature("MoveOnlyClasses"),
  // Move-only enum deinits
  .enableExperimentalFeature("MoveOnlyEnumDeinits"),
  // SE-0429: Partial consumption of noncopyable values
  .enableExperimentalFeature("MoveOnlyPartialConsumption"),
  // Move-only resilient types
  .enableExperimentalFeature("MoveOnlyResilientTypes"),
  // Move-only tuples
  .enableExperimentalFeature("MoveOnlyTuples"),
  // SE-0427: Noncopyable generics
  .enableExperimentalFeature("NoncopyableGenerics"),
  // One-way closure parameters
  // .enableExperimentalFeature("OneWayClosureParameters"),
  // Raw layout types
  .enableExperimentalFeature("RawLayout"),
  // Reference bindings
  .enableExperimentalFeature("ReferenceBindings"),
  // SE-0430: sending parameter and result values
  .enableExperimentalFeature("SendingArgsAndResults"),
  // Symbol linkage markers
  .enableExperimentalFeature("SymbolLinkageMarkers"),
  // Transferring args and results
  .enableExperimentalFeature("TransferringArgsAndResults"),
  // SE-0393: Value and Type Parameter Packs
  .enableExperimentalFeature("VariadicGenerics"),
  // Warn unsafe reflection
  .enableExperimentalFeature("WarnUnsafeReflection"),

  // Enhanced compiler checking
  // .unsafeFlags([
  //   // Warn about functions with >100 lines
  //   "-Xfrontend", "-warn-long-function-bodies=100",
  //   // Warn about slow type checking expressions
  //   "-Xfrontend", "-warn-long-expression-type-checking=100"
  // ])
]

let package = Package(
  name: "MistKit",
  platforms: [
    .macOS(.v10_15),   // Minimum for swift-crypto
    .iOS(.v13),        // Minimum for swift-crypto
    .tvOS(.v13),       // Minimum for swift-crypto
    .watchOS(.v6),     // Minimum for swift-crypto
    .visionOS(.v1)     // Vision OS already requires newer versions
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
  ],
  dependencies: [
    // Swift OpenAPI Runtime dependencies
    .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.0"),
    .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.2.0"),
    // Crypto library for cross-platform cryptographic operations
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    // Logging library for cross-platform logging
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "MistKit",
      dependencies: [
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
      dependencies: ["MistKit"],
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
