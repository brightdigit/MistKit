# Swift Configuration Reference for MistDemo

## Overview

MistDemo uses [Swift Configuration](https://github.com/apple/swift-configuration) (v1.0.0+) for hierarchical configuration management. This replaced ArgumentParser during Phase 1 (issue #212) to provide a more flexible, cross-platform configuration system.

**Why Swift Configuration?**
- Native support for multiple configuration sources (CLI, environment, files, defaults)
- Hierarchical resolution with clear priority ordering
- Cross-platform compatibility (macOS, Linux, Windows)
- Type-safe configuration reading with native Swift types
- Built-in secret handling for sensitive values

## Provider Hierarchy

MistDemo uses hierarchical provider resolution with the following priority order (highest to lowest):

```
CLI Arguments → Environment Variables → Defaults
```

When a configuration key is requested, Swift Configuration checks each provider in order and returns the first match found.

### Current Implementation

**Implemented Providers:**
1. **CLI Arguments** (Highest priority) - `CommandLineArgumentsProvider` with automatic key transformation
2. **Environment Variables** - `EnvironmentVariablesProvider` with automatic key transformation
3. **Defaults** - `InMemoryProvider` with fallback values

**Available Providers:**
- JSON configuration files via `FileProvider` with `JSONSnapshot` 
- YAML configuration files via `FileProvider` with `YAMLSnapshot`
- Profile-based configuration merging

**Note:** The `CommandLineArgumentsProvider` requires the `CommandLineArguments` trait to be enabled in Package.swift. This is automatically enabled in MistDemo via:
```swift
.package(
    url: "https://github.com/apple/swift-configuration", 
    from: "1.0.0", 
    traits: ["CommandLineArguments"]
)
```

## Key Naming Conventions

Swift Configuration uses different naming conventions for different sources:

| Swift Key | CLI Flag | Environment Variable |
|-----------|----------|---------------------|
| `container.identifier` | `--container-identifier` | `CONTAINER_IDENTIFIER` |
| `api.token` | `--api-token` | `API_TOKEN` |
| `web.auth.token` | `--web-auth-token` | `WEB_AUTH_TOKEN` |
| `environment` | `--environment` | `ENVIRONMENT` |
| `database` | `--database` | `DATABASE` |
| `output.format` | `--output-format` | `OUTPUT_FORMAT` |
| `query.limit` | `--query-limit` | `QUERY_LIMIT` |
| `query.zone` | `--query-zone` | `QUERY_ZONE` |

**Key Transformation Rules:**
- **Dot notation** (`.`) in Swift keys → **Kebab-case** (`-`) for CLI flags
- **Dot notation** (`.`) in Swift keys → **SNAKE_CASE with underscores** (`_`) for environment variables
- All environment variables are UPPERCASE
- CLI flags use lowercase with hyphens

## Common Patterns

### Reading Configuration

```swift
import Configuration

// Create configuration reader
let config = try MistDemoConfiguration()

// Read string value with default
let containerID = config.string(
    forKey: "container.identifier",
    default: "iCloud.com.example.App"
) ?? "iCloud.com.example.App"

// Read required string value
guard let apiToken = config.string(forKey: "api.token") else {
    throw ConfigError.missingRequired("api.token")
}

// Read boolean flag
let verbose = config.bool(forKey: "verbose", default: false) ?? false

// Read integer value
let limit = config.int(forKey: "query.limit", default: 20) ?? 20

// Read string array
let filters = config.stringArray(forKey: "query.filters") ?? []
```

### Namespaced Configuration Readers

For command-specific configuration, use namespaced readers:

```swift
struct QueryConfig {
    let base: MistDemoConfig
    let zone: String
    let limit: Int
    let sortField: String?

    init() throws {
        let configReader = try MistDemoConfiguration()
        self.base = try MistDemoConfig()

        // Query-specific config with namespace
        self.zone = configReader.string(
            forKey: "query.zone",
            default: "_defaultZone"
        ) ?? "_defaultZone"

        self.limit = configReader.int(
            forKey: "query.limit",
            default: 20
        ) ?? 20

        self.sortField = configReader.string(forKey: "query.sort.field")
    }
}
```

### Secret Handling

Swift Configuration provides built-in `Secret<T>` type for sensitive values:

```swift
import Configuration

struct MistDemoConfig {
    let apiToken: Secret<String>
    let webAuthToken: Secret<String>?

    init() throws {
        let config = try MistDemoConfiguration()

        // Read secrets - automatically redacted in logs
        guard let token = config.secret(forKey: "api.token") else {
            throw ConfigError.missingRequired("api.token")
        }
        self.apiToken = token

        self.webAuthToken = config.secret(forKey: "web.auth.token")
    }

    // Access secret value when needed
    func authenticate() async throws {
        let client = try MistKitClient(apiToken: apiToken.value)
        // ...
    }
}
```

## Migration from ArgumentParser

MistDemo migrated from ArgumentParser to Swift Configuration during Phase 1. Here's a comparison:

| Feature | ArgumentParser | Swift Configuration |
|---------|----------------|---------------------|
| **Command definition** | `@main struct MyCommand: AsyncParsableCommand` | Direct `@main async` with manual config |
| **Required option** | `@Option(name: .long) var apiToken: String` | `config.string(forKey: "api.token")` |
| **Optional option** | `@Option var output: String?` | `config.string(forKey: "output")` |
| **Flag** | `@Flag var verbose: Bool = false` | `config.bool(forKey: "verbose", default: false)` |
| **Default value** | `@Option var limit: Int = 20` | `config.int(forKey: "limit", default: 20)` |
| **Array option** | `@Option var filters: [String] = []` | `config.stringArray(forKey: "filters") ?? []` |
| **Subcommands** | `@main struct CLI: ParsableCommand { @OptionGroup var options }` | Manual routing via command name |
| **Help text** | `static let configuration = CommandConfiguration(abstract: "...")` | Manual help implementation |
| **Validation** | `mutating func validate() throws` | Validate in `init()` |
| **Execution** | `mutating func run() async throws` | Direct `async main()` |

### ArgumentParser Example

```swift
import ArgumentParser

@main
struct QueryCommand: AsyncParsableCommand {
    @Option(name: .long, help: "Container identifier")
    var containerID: String

    @Option(name: .long, help: "API token")
    var apiToken: String

    @Flag(help: "Enable verbose output")
    var verbose: Bool = false

    @Option(name: .long, help: "Maximum records")
    var limit: Int = 20

    mutating func run() async throws {
        // Implementation
    }
}
```

### Swift Configuration Equivalent

```swift
import Configuration

@main
struct QueryCommand {
    static func main() async throws {
        let config = try QueryConfig()
        try await execute(with: config)
    }

    static func execute(with config: QueryConfig) async throws {
        // Implementation
    }
}

struct QueryConfig {
    let containerID: String
    let apiToken: String
    let verbose: Bool
    let limit: Int

    init() throws {
        let reader = try MistDemoConfiguration()

        guard let containerID = reader.string(forKey: "container.identifier") else {
            throw ConfigError.missingRequired("container.identifier")
        }
        self.containerID = containerID

        guard let apiToken = reader.string(forKey: "api.token") else {
            throw ConfigError.missingRequired("api.token")
        }
        self.apiToken = apiToken

        self.verbose = reader.bool(forKey: "verbose", default: false) ?? false
        self.limit = reader.int(forKey: "limit", default: 20) ?? 20
    }
}
```

## Trait Requirements

To use Swift Configuration with CLI argument parsing, add the package dependency and enable the trait in `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MistDemo",
    platforms: [
        .macOS(.v15)  // Required for Swift Configuration
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-configuration", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MistDemo",
            dependencies: [
                .product(name: "Configuration", package: "swift-configuration")
            ]
        )
    ]
)
```

**Note**: `CommandLineArgumentsProvider` is available as a trait that can be enabled for enhanced CLI parsing. MistDemo currently uses manual argument parsing but may migrate to this provider in the future.

## Troubleshooting

### Key Not Found

**Problem**: Configuration key returns `nil` even though it's set.

**Solution**: Check key name transformation:
- CLI: `--container-identifier` → Key: `"container.identifier"`
- ENV: `CONTAINER_IDENTIFIER` → Key: `"container.identifier"`

### Environment Variable Not Working

**Problem**: Environment variable isn't being read.

**Solution**: Ensure the variable name matches the key transformation:
```bash
# Wrong
export container.identifier="iCloud.com.example.App"

# Correct
export CONTAINER_IDENTIFIER="iCloud.com.example.App"
```

### Type Conversion Fails

**Problem**: `config.int(forKey:)` returns `nil` for valid number.

**Solution**: Check the value is a valid integer string. Swift Configuration performs type conversion automatically but requires valid input:
```bash
# Wrong
--limit abc

# Correct
--limit 20
```

### CLI Arguments Not Recognized

**Problem**: Command-line flags aren't being parsed.

**Solution**: Verify the exact flag format:
```bash
# Wrong (uses =)
mistdemo --container-identifier=iCloud.com.example.App

# Correct (uses space)
mistdemo --container-identifier iCloud.com.example.App

# Also correct (short form if defined)
mistdemo -c iCloud.com.example.App
```

### Priority Order Confusion

**Problem**: Environment variable overrides CLI argument.

**Solution**: Verify provider order in configuration setup. CLI arguments should be added last (highest priority):
```swift
// Correct order (CLI has highest priority)
let providers: [ConfigurationProvider] = [
    InMemoryProvider(defaults),     // Lowest
    EnvironmentVariablesProvider(), // Middle
    CommandLineArgumentsProvider()  // Highest
]
```

## Full Documentation Links

- **Official Package**: [apple/swift-configuration](https://github.com/apple/swift-configuration)
- **Package Index**: [Swift Configuration 1.0.0 Documentation](https://swiftpackageindex.com/apple/swift-configuration/1.0.0/documentation/configuration)
- **Local Reference**: [.claude/docs/https_-swiftpackageindex.com-apple-swift-configuration-1.0.0-documentation-configuration.md](../.claude/docs/https_-swiftpackageindex.com-apple-swift-configuration-1.0.0-documentation-configuration.md)
- **MistDemo Implementation**: `Examples/MistDemo/Sources/MistDemo/Configuration/MistDemoConfig.swift`
- **ConfigKeyKit Strategy**: [configkeykit-strategy.md](./configkeykit-strategy.md)

## Related Issues

- **#212** (CLOSED): Initial ArgumentParser to Swift Configuration migration
- **#217** (CLOSED): Configuration implementation completion
- **#221** (OPEN): Performance optimization for manual argument parsing
- **#222** (OPEN): Refactor hardcoded argument name mappings

## See Also

- [Phase 1: Core Infrastructure](./phases/phase-1-core-infrastructure.md) - Architecture overview
- [ConfigKeyKit Strategy](./configkeykit-strategy.md) - Configuration patterns and examples
- [Configuration Guide](./configuration.md) - User-facing configuration documentation
