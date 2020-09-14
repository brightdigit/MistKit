// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MistKit",
  platforms: [.macOS(.v10_15)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "MistKit",
      targets: ["MistKit"]
    ),
    .library(
      name: "MistKitNIOHTTP1Token",
      targets: ["MistKitNIOHTTP1Token"]
    ),
    .library(
      name: "MistKitVapor",
      targets: ["MistKitVapor"]
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
    // dev
    .package(url: "https://github.com/shibapm/Komondor", from: "1.0.5"),
    .package(url: "https://github.com/eneko/SourceDocs", from: "1.2.1")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "MistKit",
      dependencies: []
    ),
    .target(name: "MistKitNIOHTTP1Token",
            dependencies: [
              "MistKit",
              .product(name: "NIO", package: "swift-nio"),
              .product(name: "NIOHTTP1", package: "swift-nio")
            ]),
    .target(name: "MistKitVapor",
            dependencies: [
              "MistKit", .product(name: "Vapor", package: "vapor")
            ]),
    .target(name: "mistdemoc", dependencies: ["MistKit", "MistKitNIOHTTP1Token", "MistKitDemo",
                                              .product(name: "ArgumentParser", package: "swift-argument-parser")]),
    .target(name: "mistdemod", dependencies: ["MistKit", "MistKitVapor", "MistKitDemo", .product(name: "Vapor", package: "vapor")]),
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

  let config = PackageConfiguration([
    "komondor": [
      "pre-push": "swift test --enable-code-coverage --enable-test-discovery",
      "pre-commit": [
        "swift test --enable-code-coverage --enable-test-discovery --generate-linuxmain",
        "swift run swiftformat .",
        "swift run swiftlint autocorrect",
        "swift run sourcedocs generate build --spm-module MistKit -c -r",
        // "swift run swiftpmls mine",
        "git add .",
        "swift run swiftformat --lint .",
        "swift run swiftlint"
      ]
    ]
  ]).write()
#endif
