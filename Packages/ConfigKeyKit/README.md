# ConfigKeyKit

A tiny, dependency-free Swift package for defining configuration keys that
resolve consistently across multiple sources (command-line arguments,
environment variables, …).

ConfigKeyKit pairs naturally with [`apple/swift-configuration`][swift-config]
but does **not** depend on it — the package is intentionally Foundation-only
so it can be adopted by any Swift app or library without pulling in a
configuration framework.

## What's inside

A single `ConfigKeyKit` product bundles:

- **Key types** — `ConfigKey`, `OptionalConfigKey`, `ConfigurationKey`, `NamingStyle`, `StandardNamingStyle`, `ConfigKeySource`.
- **CLI scaffolding** — `Command`, `CommandRegistry`, `CommandLineParser`, `ConfigurationParseable`. A lightweight command-dispatch pattern you can ignore if you only need keys.

## Usage

```swift
import ConfigKeyKit

let containerID = ConfigKey<String>(
  "cloudkit.container_id",
  envPrefix: "MYAPP",
  default: "iCloud.com.example.MyApp"
)

containerID.key(for: .commandLine)   // "cloudkit.container_id"
containerID.key(for: .environment)   // "MYAPP_CLOUDKIT_CONTAINER_ID"
containerID.defaultValue             // "iCloud.com.example.MyApp"
```

You then feed those resolved key strings into whatever provider stack you
prefer (Swift Configuration, environment lookup, manual argument parsing, …).

## Pairing with `swift-configuration`

`ConfigKey` resolves a single base key into per-source strings, which slots
neatly into [`swift-configuration`][swift-config]'s provider stack. Each
provider sees the key name it expects (dot-separated for CLI, screaming snake
case for ENV), while your call site stays declarative:

```swift
import Configuration
import ConfigKeyKit

let containerID = ConfigKey<String>(
  "cloudkit.container_id",
  envPrefix: "MYAPP",
  default: "iCloud.com.example.MyApp"
)

let config = ConfigReader(providers: [
  CommandLineArgumentsProvider(),
  EnvironmentVariablesProvider(),
])

extension ConfigReader {
  func string<Value>(for key: ConfigKey<Value>) -> String where Value == String {
    if let cli = key.key(for: .commandLine),
       let value = self.string(forKey: cli) {
      return value
    }
    if let env = key.key(for: .environment),
       let value = self.string(forKey: env) {
      return value
    }
    return key.defaultValue
  }
}

let resolved = config.string(for: containerID)
// Looks up "cloudkit.container_id" on the CLI, falls back to
// "MYAPP_CLOUDKIT_CONTAINER_ID" in the environment, then the default.
```

## Used by

- [MistDemo][mistdemo] — the demo app inside [MistKit][mistkit].
- [BushelCloud][bushelcloud].

## Adding to your `Package.swift`

```swift
.package(url: "https://github.com/brightdigit/ConfigKeyKit.git", from: "1.0.0-beta.1"),
```

```swift
.target(
  name: "MyApp",
  dependencies: [
    .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
  ]
),
```

## License

MIT — see [LICENSE](LICENSE).

[swift-config]: https://github.com/apple/swift-configuration
[mistkit]: https://github.com/brightdigit/MistKit
[mistdemo]: https://github.com/brightdigit/MistKit/tree/main/Examples/MistDemo
[bushelcloud]: https://github.com/brightdigit/BushelCloud
