// swift-tools-version:5.2

// swiftlint:disable explicit_top_level_acl
// swiftlint:disable prefixed_toplevel_constant
// swiftlint:disable line_length
// swiftlint:disable explicit_acl

import PackageDescription

let package = Package(
  name: "MistKit",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(
      name: "MistKit",
      targets: ["MistKit"]
    ),
    .library(
      name: "MistKitNIO",
      targets: ["MistKitNIO"]
    ),
    .library(
      name: "MistKitVapor",
      targets: ["MistKitVapor"]
    ),
    .library(
      name: "MistKitSwifter",
      targets: ["MistKitSwifter"]
    ),
    .executable(name: "mistdemoc", targets: ["mistdemoc"]),
    .executable(name: "mistdemod", targets: ["mistdemod"])
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.20.0"),
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    .package(url: "https://github.com/brightdigit/Swifter.git", .branch("stable")),
    .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
    .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.16.1"),
//    // dev
//    .package(url: "https://github.com/shibapm/Komondor", from: "1.0.6"), // dev
//    .package(url: "https://github.com/eneko/SourceDocs", from: "1.2.1"), // dev
//    .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.47.0"), // dev
//    .package(url: "https://github.com/realm/SwiftLint", from: "0.41.0"), // dev
//    .package(url: "https://github.com/brightdigit/Rocket", .branch("feature/yams-4.0.0")), // dev
//    .package(url: "https://github.com/mattpolzin/swift-test-codecov", .branch("master")) // dev
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "MistKit",
      dependencies: []
    ),
    .target(name: "MistKitNIO",
            dependencies: [
              "MistKit",
              .product(name: "NIO", package: "swift-nio"),
              .product(name: "NIOHTTP1", package: "swift-nio"),
              .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]),
    .target(name: "MistKitSwifter",
            dependencies: [
              "MistKit",
              .product(name: "Swifter", package: "Swifter")
            ]),
    .target(name: "MistKitVapor",
            dependencies: [
              "MistKit",
              "MistKitNIO",
              .product(name: "Vapor", package: "vapor"),
              .product(name: "Fluent", package: "fluent")
            ]),
    .target(name: "mistdemoc", dependencies: [
      "MistKit",
      "MistKitNIO", "MistKitDemo",
      .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]),
    .target(name: "mistdemod", dependencies: [
      "MistKit", "MistKitVapor", "MistKitDemo",
      .product(name: "Vapor", package: "vapor"),
      .product(name: "Fluent", package: "fluent"),
      .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
    ]),
    .target(name: "MistKitDemo",
            dependencies: ["MistKit"]),
    .testTarget(
      name: "MistKitTests",
      dependencies: ["MistKit"]
    )
  ]
)

#if canImport(PackageConfig)
  import PackageConfig

  let requiredCoverage: Int = 30

  let config = PackageConfiguration([
    "komondor": [
      "pre-push": [
        "swift test --enable-code-coverage --enable-test-discovery",
        "swift run swift-test-codecov .build/debug/codecov/MistKit.json -v \(requiredCoverage)"
      ],
      "pre-commit": [
        "swift test --enable-code-coverage --enable-test-discovery --generate-linuxmain",
        "swift run swiftformat .",
        "swift run swiftlint autocorrect",
        "swift run sourcedocs generate build -cra",
        "git add .",
        "swift run swiftformat --lint .",
        "swift run swiftlint"
      ]
    ]
  ]).write()
#endif
