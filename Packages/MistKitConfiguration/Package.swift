// swift-tools-version: 6.4

// swiftlint:disable explicit_acl explicit_top_level_acl

import PackageDescription

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
]

let package = Package(
  name: "MistKitConfiguration",
  platforms: [
    .macOS(.v15),
    .iOS(.v18),
    .tvOS(.v18),
    .watchOS(.v11),
    .visionOS(.v2),
  ],
  products: [
    .library(name: "MistKitConfiguration", targets: ["MistKitConfiguration"])
  ],
  dependencies: [
    // A local path dependency, not a tagged URL, and deliberately so: a `path:`
    // package takes its identity from the directory name, so pairing it with a
    // sibling that depends on MistKit by `url:` makes SwiftPM resolve two distinct
    // packages and fail with "multiple similar targets 'MistKit', 'MistKitOpenAPI'".
    // Every package inside this monorepo must therefore reach MistKit the same way.
    //
    // ⚠️ This line is a monorepo-local overlay that must NEVER reach the standalone
    // repository. `git subrepo push Packages/MistKitConfiguration` would carry it over
    // and break `brightdigit/MistKitConfiguration`, whose own manifest deliberately
    // carries `.package(url: …MistKit.git, from: "1.0.0-beta.4")` — the form that makes a
    // tag of this package usable downstream. Re-apply the swap after every push, the same
    // never-merged-overlay discipline `Examples/BushelCloud/Package.swift` documents.
    .package(name: "MistKit", path: "../.."),
    // Temporary: ConfigKeyKit#8 (boolean resolution) is on main but not yet tagged.
    // Swap to `from: "<tag>"` once a release carrying that fix exists — MistKitConfiguration
    // PRs targeting main must use only tagged dependencies (`dependency-policy.yml`).
    .package(
      url: "https://github.com/brightdigit/ConfigKeyKit.git",
      branch: "main"
    ),
    .package(
      url: "https://github.com/apple/swift-configuration.git",
      from: "1.0.0",
      traits: ["CommandLineArguments"]
    ),
  ],
  targets: [
    .target(
      name: "MistKitConfiguration",
      dependencies: [
        .product(name: "MistKit", package: "MistKit"),
        .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
        .product(name: "Configuration", package: "swift-configuration"),
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "MistKitConfigurationTests",
      dependencies: ["MistKitConfiguration"],
      swiftSettings: swiftSettings
    ),
  ]
)

// swiftlint:enable explicit_acl explicit_top_level_acl
