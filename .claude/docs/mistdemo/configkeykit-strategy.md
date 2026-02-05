# ConfigKeyKit Extension Strategy

This document outlines the configuration architecture for MistDemo, combining Swift Configuration with a lightweight ConfigKeyKit module.

## Current Implementation

MistDemo uses a two-module approach:
1. **ConfigKeyKit** - Lightweight module containing only reusable configuration key types (no dependencies)
2. **MistDemoConfiguration** - Swift Configuration wrapper in the MistDemo module (requires macOS 15.0+)

## Architecture Decisions

### Module Separation
- ConfigKeyKit remains dependency-free for maximum reusability
- MistDemo module contains the Swift Configuration dependency
- This allows ConfigKeyKit to be used in other projects without forcing Swift Configuration

### Swift Configuration Integration
- Uses `ConfigReader` with provider hierarchy
- Currently supports: Environment variables → Defaults
- Planned: Command-line arguments → Files → Environment → Defaults

## Architecture

### Base Configuration

```swift
import Configuration

/// Base configuration shared across all commands
struct MistDemoConfig {
    let containerID: String
    let apiToken: String
    let environment: CloudKitEnvironment
    let database: CloudKitDatabase
    let webAuthToken: String?
    let keyID: String?
    let privateKeyFile: String?
    let output: OutputFormat
    let pretty: Bool
    let verbose: Bool
    let noRedaction: Bool

    init(reader: ConfigReader) throws {
        containerID = try reader.string(forKey: "container_id")
        apiToken = try reader.string(forKey: "api_token")
        environment = try CloudKitEnvironment(
            rawValue: reader.string(forKey: "environment", default: "development")
        ) ?? .development
        database = try CloudKitDatabase(
            rawValue: reader.string(forKey: "database", default: "public")
        ) ?? .public
        webAuthToken = reader.string(forKey: "web_auth_token")
        keyID = reader.string(forKey: "key_id")
        privateKeyFile = reader.string(forKey: "private_key_file")
        output = try OutputFormat(
            rawValue: reader.string(forKey: "output", default: "json")
        ) ?? .json
        pretty = reader.bool(forKey: "pretty", default: false)
        verbose = reader.bool(forKey: "verbose", default: false)
        noRedaction = reader.bool(forKey: "no_redaction", default: false)
    }
}

enum CloudKitEnvironment: String {
    case development
    case production
}

enum CloudKitDatabase: String {
    case `public`
    case `private`
    case shared
}

enum OutputFormat: String {
    case json
    case table
    case csv
    case yaml
}
```

### Command-Specific Configuration

```swift
/// Configuration specific to the query command
struct QueryConfig {
    let base: MistDemoConfig
    let limit: Int
    let zone: String
    let fields: [String]?
    let sortField: String?
    let sortOrder: SortOrder

    init(reader: ConfigReader) throws {
        base = try MistDemoConfig(reader: reader)

        // Query-specific settings with namespace
        limit = reader.int(forKey: "query.limit", default: 20)
        zone = reader.string(forKey: "query.zone", default: "_defaultZone")
        fields = reader.stringArray(forKey: "query.fields")
        sortField = reader.string(forKey: "query.sort.field")
        sortOrder = try SortOrder(
            rawValue: reader.string(forKey: "query.sort.order", default: "asc")
        ) ?? .ascending
    }
}

enum SortOrder: String {
    case ascending = "asc"
    case descending = "desc"
}
```

### Configuration Reader Setup

```swift
import Configuration
import Foundation

/// Example configuration manager showing hierarchical provider setup
/// Note: This is aspirational architecture. Current MistDemo uses simpler direct approach.
/// See MistDemoConfig.swift for actual implementation.
class ConfigurationManager {
    static let shared = ConfigurationManager()

    private var reader: ConfigReader?

    private init() {}

    /// Load configuration from multiple sources with priority
    func loadConfiguration(
        configFile: String? = nil,
        profile: String? = nil
    ) throws -> ConfigReader {
        // Priority: CLI args > Profile > File > Environment > Defaults

        var providers: [ConfigurationProvider] = []

        // 1. Environment variables (lowest priority)
        providers.append(EnvironmentVariablesProvider())

        // 2. Configuration file
        if let filePath = configFile ?? defaultConfigFile() {
            let url = URL(fileURLWithPath: filePath)
            let provider = try createFileProvider(for: url)
            providers.append(provider)
        }

        // 3. Profile (if specified)
        if let profileName = profile, let filePath = configFile ?? defaultConfigFile() {
            let url = URL(fileURLWithPath: filePath)
            let provider = try createProfileProvider(for: url, profile: profileName)
            providers.append(provider)
        }

        // 4. Command-line arguments (highest priority)
        providers.append(CommandLineArgumentsProvider())

        // Create composite reader
        reader = ConfigReader(providers: providers)
        return reader!
    }

    private func defaultConfigFile() -> String? {
        let searchPaths = [
            "~/.mistdemo/config.json",
            "~/.mistdemo/config.yaml",
            "./.mistdemo.json",
            "./.mistdemo.yaml"
        ]

        for path in searchPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                return expandedPath
            }
        }

        return nil
    }

    private func createFileProvider(for url: URL) throws -> ConfigurationProvider {
        let data = try Data(contentsOf: url)

        switch url.pathExtension {
        case "json":
            let snapshot = try JSONSnapshot(
                data: data,
                providerName: "config-file",
                parsingOptions: []
            )
            return FileProvider(snapshot: snapshot, filePath: url.path)

        case "yaml", "yml":
            let snapshot = try YAMLSnapshot(
                data: data,
                providerName: "config-file",
                parsingOptions: []
            )
            return FileProvider(snapshot: snapshot, filePath: url.path)

        default:
            throw ConfigError.unsupportedFormat(url.pathExtension)
        }
    }

    private func createProfileProvider(
        for url: URL,
        profile: String
    ) throws -> ConfigurationProvider {
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let profiles = json?["profiles"] as? [String: [String: Any]],
              let profileData = profiles[profile] else {
            throw ConfigError.profileNotFound(profile)
        }

        let profileJSON = try JSONSerialization.data(withJSONObject: profileData)
        let snapshot = try JSONSnapshot(
            data: profileJSON,
            providerName: "profile-\(profile)",
            parsingOptions: []
        )

        return FileProvider(snapshot: snapshot, filePath: url.path)
    }
}

enum ConfigError: Error {
    case unsupportedFormat(String)
    case profileNotFound(String)
}
```

## Usage in Commands

### Command Protocol

```swift
import Configuration
import Foundation

/// Configuration-based command pattern using Swift Configuration
protocol MistDemoCommand {
    associatedtype Config

    func loadConfig() throws -> Config
    func execute(with config: Config) async throws
}

extension MistDemoCommand {
    func run() async throws {
        let config = try loadConfig()
        try await execute(with: config)
    }

    func loadConfig() throws -> Config where Config == MistDemoConfig {
        return try MistDemoConfig()
    }
}
```

### Query Command Example

```swift
import Configuration
import Foundation
import MistKit

/// Example: Query command using Swift Configuration
struct QueryCommand: MistDemoCommand {
    func loadConfig() throws -> QueryConfig {
        return try QueryConfig()
    }

    func execute(with config: QueryConfig) async throws {
        let client = try MistKitClient(
            containerID: config.base.containerIdentifier,
            apiToken: config.base.apiToken,
            webAuthToken: config.base.webAuthToken
        )

        let results = try await client.queryRecords(
            recordType: "Note",
            database: config.base.environment.database,
            zone: config.zone,
            filters: config.filters,
            limit: config.limit
        )

        let formatter = OutputFormatter(format: config.base.outputFormat)
        try formatter.print(results)
    }
}

/// Query-specific configuration using Swift Configuration
struct QueryConfig {
    let base: MistDemoConfig
    let zone: String
    let limit: Int
    let filters: [String]

    init() throws {
        let configReader = try MistDemoConfiguration()
        self.base = try MistDemoConfig()

        // Query-specific config with hierarchical resolution
        self.zone = configReader.string(
            forKey: "query.zone",
            default: "_defaultZone"
        ) ?? "_defaultZone"

        self.limit = configReader.int(
            forKey: "query.limit",
            default: 20
        ) ?? 20

        self.filters = configReader.stringArray(
            forKey: "query.filters"
        ) ?? []
    }
}
```

**CLI Usage Examples:**
```bash
# Command-line arguments (highest priority)
mistdemo query --container-identifier iCloud.com.example.App \
               --api-token YOUR_TOKEN \
               --query-zone CustomZone

# Environment variables (fallback)
export CONTAINER_IDENTIFIER="iCloud.com.example.App"
export API_TOKEN="YOUR_TOKEN"
mistdemo query

# Mixed: CLI overrides environment
export API_TOKEN="YOUR_TOKEN"
mistdemo query --container-identifier iCloud.com.example.App
```

## Configuration File Examples

### Hierarchical Configuration

```json
{
  "container_id": "iCloud.com.example.MyApp",
  "api_token": "your-api-token",
  "environment": "development",
  "database": "private",
  "output": "table",
  "pretty": true,

  "query": {
    "limit": 50,
    "zone": "_defaultZone",
    "sort": {
      "field": "createdAt",
      "order": "desc"
    }
  },

  "create": {
    "zone": "_defaultZone"
  },

  "profiles": {
    "production": {
      "environment": "production",
      "database": "public",
      "output": "json",
      "query": {
        "limit": 100
      }
    },
    "testing": {
      "container_id": "iCloud.com.example.MyApp.Testing",
      "database": "private",
      "query": {
        "limit": 10
      }
    }
  }
}
```

### YAML Configuration

```yaml
container_id: iCloud.com.example.MyApp
api_token: your-api-token
environment: development
database: private
output: table
pretty: true

query:
  limit: 50
  zone: _defaultZone
  sort:
    field: createdAt
    order: desc

create:
  zone: _defaultZone

profiles:
  production:
    environment: production
    database: public
    output: json
    query:
      limit: 100

  testing:
    container_id: iCloud.com.example.MyApp.Testing
    database: private
    query:
      limit: 10
```

## Profile Merging Strategy

Profiles are merged with base configuration:

```swift
extension ConfigReader {
    func mergeProfile(_ profile: String) throws -> ConfigReader {
        // 1. Load base configuration
        let baseValues = self.allValues()

        // 2. Load profile configuration
        guard let profileValues = self.dictionary(forKey: "profiles.\(profile)") else {
            throw ConfigError.profileNotFound(profile)
        }

        // 3. Merge (profile overrides base)
        var merged = baseValues
        for (key, value) in profileValues {
            merged[key] = value
        }

        // 4. Create new reader with merged values
        return ConfigReader(values: merged)
    }
}
```

## Dynamic Resolution

```swift
extension ConfigReader {
    /// Read with fallback chain
    func read<T>(
        _ type: T.Type,
        forKey key: String,
        subcommand: String? = nil,
        default defaultValue: T? = nil
    ) -> T? {
        // Try subcommand-namespaced key first
        if let subcommand = subcommand {
            let namespacedKey = "\(subcommand).\(key)"
            if let value = value(forKey: namespacedKey) as? T {
                return value
            }
        }

        // Try base key
        if let value = value(forKey: key) as? T {
            return value
        }

        // Return default
        return defaultValue
    }
}
```

## Best Practices

### 1. Type Safety

```swift
// Use enums for constrained values
enum OutputFormat: String, CaseIterable {
    case json, table, csv, yaml
}

// Validate at configuration load time
func loadOutputFormat(from reader: ConfigReader) throws -> OutputFormat {
    let value = reader.string(forKey: "output", default: "json")
    guard let format = OutputFormat(rawValue: value) else {
        throw ConfigError.invalidValue(key: "output", value: value,
                                      allowed: OutputFormat.allCases.map(\.rawValue))
    }
    return format
}
```

### 2. Secret Handling

```swift
// Mark secrets and handle redaction
struct MistDemoConfig {
    let apiToken: Secret<String>
    let webAuthToken: Secret<String>?

    var redactedDescription: String {
        """
        MistDemoConfig(
          containerID: \(containerID),
          apiToken: [REDACTED],
          webAuthToken: \(webAuthToken != nil ? "[REDACTED]" : "nil")
        )
        """
    }
}

struct Secret<T> {
    private let value: T

    init(_ value: T) {
        self.value = value
    }

    var revealed: T { value }
}
```

### 3. Validation

```swift
extension MistDemoConfig {
    func validate() throws {
        guard !containerID.isEmpty else {
            throw ConfigError.missingRequired("container_id")
        }

        guard containerID.starts(with: "iCloud.") else {
            throw ConfigError.invalidValue(
                key: "container_id",
                value: containerID,
                reason: "Must start with 'iCloud.'"
            )
        }

        guard !apiToken.revealed.isEmpty else {
            throw ConfigError.missingRequired("api_token")
        }
    }
}
```

### 4. Environment-Specific Defaults

```swift
extension MistDemoConfig {
    static func development() -> MistDemoConfig {
        // Development defaults
    }

    static func production() -> MistDemoConfig {
        // Production defaults with stricter settings
    }
}
```

## Testing Strategy

```swift
import XCTest

class ConfigurationTests: XCTestCase {
    func testLoadConfiguration() throws {
        let json = """
        {
            "container_id": "iCloud.com.example.Test",
            "api_token": "test-token",
            "output": "json"
        }
        """

        let snapshot = try JSONSnapshot(
            data: json.data(using: .utf8)!,
            providerName: "test",
            parsingOptions: []
        )

        let provider = FileProvider(snapshot: snapshot, filePath: "/test")
        let reader = ConfigReader(provider: provider)
        let config = try MistDemoConfig(reader: reader)

        XCTAssertEqual(config.containerID, "iCloud.com.example.Test")
        XCTAssertEqual(config.apiToken.revealed, "test-token")
        XCTAssertEqual(config.output, .json)
    }

    func testProfileMerging() throws {
        // Test profile overrides base configuration
    }

    func testPriorityResolution() throws {
        // Test CLI args > Profile > File > Environment
    }
}
```

## Related Documentation

- **[Configuration](configuration.md)** - User-facing configuration guide
- **[Swift Configuration Guide](https://github.com/apple/swift-configuration)** - Official package documentation
- **[Testing Strategy](testing-strategy.md)** - Testing configuration code
