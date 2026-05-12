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

// MARK: - Swift Settings Configuration

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
  .unsafeFlags([
    // Enable concurrency warnings
    "-warn-concurrency",
    // Enable actor data race checks
    "-enable-actor-data-race-checks",
    // Complete strict concurrency checking
    "-strict-concurrency=complete",
    // Enable testing support
    "-enable-testing",
    // Warn about functions with >100 lines
    "-Xfrontend", "-warn-long-function-bodies=100",
    // Warn about slow type checking expressions
    "-Xfrontend", "-warn-long-expression-type-checking=100",
  ]),
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
      name: "ConfigKeyKit",
      dependencies: [],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "MistDemoApp",
      dependencies: [],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "MistDemoKit",
      dependencies: [
        "ConfigKeyKit",
        .product(name: "MistKit", package: "MistKit"),
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
      ],
      swiftSettings: swiftSettings
    ),
    .executableTarget(
      name: "MistDemo",
      dependencies: [
        "MistDemoKit",
        "ConfigKeyKit",
        .product(name: "MistKit", package: "MistKit"),
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "MistDemoTests",
      dependencies: [
        "MistDemoKit",
        "ConfigKeyKit",
        .product(name: "MistKit", package: "MistKit"),
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
