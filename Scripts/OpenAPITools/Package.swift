// swift-tools-version: 6.0
//
// Standalone tools manifest so `swift-openapi-generator` can be run without
// mise. mise resolves `spm:` tools through api.github.com, which is not
// reachable from Claude Code web sessions; SwiftPM resolves this package over
// plain git, which is. Keeping it in its own manifest means the generator
// never enters the MistKit library's dependency graph, preserving the
// no-build-plugin decision documented in Scripts/generate-openapi.sh.
//
// Version must stay in sync with mise.toml's
// "spm:apple/swift-openapi-generator" pin.
import PackageDescription

// swiftlint:disable:next explicit_top_level_acl explicit_acl
let package = Package(
  name: "OpenAPITools",
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-openapi-generator",
      exact: "1.10.3"
    )
  ]
)
