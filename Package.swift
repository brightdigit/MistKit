// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MistKit",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MistKit",
            targets: ["MistKit"]),
      .library(
          name: "MistKitAuth",
          targets: ["MistKitAuth"]),
      .executable(name: "mist", targets: ["mist"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
      .package(url: "https://github.com/apple/swift-nio.git", from: "2.20.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MistKit",
            dependencies: []),
      .target(name: "MistKitAuth",
              dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")]),
      .target(name: "mist", dependencies: ["MistKit","MistKitAuth"]),
        .testTarget(
            name: "MistKitTests",
            dependencies: ["MistKit"]),
    ]
)
