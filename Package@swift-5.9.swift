// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swiftlint:disable explicit_acl explicit_top_level_acl

import PackageDescription

let package = Package(
  name: "MistKit",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .visionOS(.v1)
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
    .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.1.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "MistKit",
      dependencies: [
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
        .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
      ]
    ),
    .testTarget(
      name: "MistKitTests",
      dependencies: ["MistKit"]
    ),
  ]
)
// swiftlint:enable explicit_acl explicit_top_level_acl
