# MistKitConfiguration

[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FMistKitConfiguration%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/brightdigit/MistKitConfiguration)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrightdigit%2FMistKitConfiguration%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/brightdigit/MistKitConfiguration)
[![License](https://img.shields.io/github/license/brightdigit/MistKitConfiguration)](LICENSE)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/brightdigit/MistKitConfiguration/MistKitConfiguration.yml?label=actions&logo=github&?branch=main)](https://github.com/brightdigit/MistKitConfiguration/actions)
[![Codecov](https://img.shields.io/codecov/c/github/brightdigit/MistKitConfiguration)](https://codecov.io/gh/brightdigit/MistKitConfiguration)
[![Documentation](https://img.shields.io/badge/docc-read_documentation-blue)](https://swiftpackageindex.com/brightdigit/MistKitConfiguration/documentation)

The CloudKit credential configuration glue shared by [MistKit][mistkit]'s server-side
applications: read a container ID, key ID and private key from the command line or the
environment, validate them before they reach the network, and build a `CloudKitService`.

MistKit itself stays configuration-framework-free — the dependency arrow points one way,
into MistKit, so adopting this package never changes MistKit's own surface.

## What's inside

- **Raw → validated → service.** `CloudKitConfiguration` (all fields optional, reading
  never throws) → `validated()` → `ValidatedCloudKitConfiguration` → `makeCloudKitService()`.
- **Format validation you would otherwise discover at request time.** `KeyIDValidator`
  (64 hex characters) and `PEMValidator` (header, footer, base64 body), reachable
  standalone.
- **Keys and plumbing.** `CloudKitConfigurationKeys` parameterized by container default
  and environment prefix, a `readCloudKitConfiguration(keys:)` seam on any
  `ConfigValueReading`, and `ConfigurationSources` for the provider stack.

## Errors are identifiable, not prose

Nothing in this package conforms to `LocalizedError`. It throws structured, `Equatable`
enums and leaves every user-facing string to you — because only your application knows
which flag or environment variable supplied the value, and what advice to give.

```swift
do {
  let service = try configuration.validated().makeCloudKitService()
} catch let error as CloudKitConfigurationError {
  switch error {
  case .missing(let field):
    throw MyError.missingRequired(keys[field].key(for: .environment) ?? "")
  case .invalidKeyID(.incorrectLength(let actual)):
    throw MyError.badKeyID("expected \(KeyIDValidator.expectedLength), got \(actual)")
  default:
    throw MyError.configuration(String(describing: error))
  }
}
```

`CloudKitConfigurationField` names the offending field rather than a key string, because
the same field is spelled differently by different applications.

## Usage

```swift
import Configuration
import MistKitConfiguration

let keys = CloudKitConfigurationKeys(defaultContainerID: "iCloud.com.example.MyApp")

let reader = ConfigurationSources.makeConfigReader(
  secretCommandLineFlags: keys.secretCommandLineFlags
)

let service = try reader
  .readCloudKitConfiguration(keys: keys)
  .validated()
  .makeCloudKitService()
```

That resolves `--cloudkit-container-id` / `CLOUDKIT_CONTAINER_ID`, `--cloudkit-key-id` /
`CLOUDKIT_KEY_ID`, `--cloudkit-private-key[-path]` and `--cloudkit-environment`, with the
command line taking precedence over the environment.

The redaction list is **derived** from each key's `isSecret`, so it cannot drift from the
keys themselves — the drift that previously let a private key passed by flag be logged in
the clear.

## Used by

- [BushelCloud][bushelcloud] and [CelestraCloud][celestracloud].
- [MistDemo][mistdemo], inside [MistKit][mistkit].

## Adding to your `Package.swift`

```swift
.package(url: "https://github.com/brightdigit/MistKitConfiguration.git", from: "1.0.0-beta.1"),
```

```swift
.target(
  name: "MyApp",
  dependencies: [
    .product(name: "MistKitConfiguration", package: "MistKitConfiguration")
  ]
),
```

## License

MIT — see [LICENSE](LICENSE).

[mistkit]: https://github.com/brightdigit/MistKit
[mistdemo]: https://github.com/brightdigit/MistKit/tree/main/Examples/MistDemo
[bushelcloud]: https://github.com/brightdigit/BushelCloud
[celestracloud]: https://github.com/brightdigit/CelestraCloud
