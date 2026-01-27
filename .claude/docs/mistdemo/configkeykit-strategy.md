# ConfigKeyKit Extension Strategy

This document outlines the configuration architecture for MistDemo using the Swift Configuration package with ConfigKeyKit-style patterns.

## Overview

MistDemo extends Swift Configuration to support:
1. Hierarchical configuration keys
2. Command-specific configuration
3. Configuration profiles
4. Dynamic resolution with priority
5. Type-safe configuration access

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
import ArgumentParser

protocol MistDemoCommand: AsyncParsableCommand {
    associatedtype Config

    var configFile: String? { get }
    var profile: String? { get }

    func loadConfig() throws -> Config
    func execute(with config: Config) async throws
}

extension MistDemoCommand {
    mutating func run() async throws {
        let config = try loadConfig()
        try await execute(with: config)
    }
}
```

### Query Command Example

```swift
import ArgumentParser

struct QueryCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "query",
        abstract: "Query Note records from CloudKit"
    )

    // Global options
    @Option(name: .long, help: "Path to configuration file")
    var configFile: String?

    @Option(name: .long, help: "Configuration profile to use")
    var profile: String?

    @Option(name: .shortAndLong, help: "Container ID")
    var containerID: String?

    @Option(name: .shortAndLong, help: "API token")
    var apiToken: String?

    @Option(name: .shortAndLong, help: "Database")
    var database: String?

    @Option(name: .shortAndLong, help: "Output format")
    var output: String?

    // Query-specific options
    @Option(name: .long, help: "Zone name")
    var zone: String?

    @Option(name: .long, help: "Filter expression")
    var filter: [String] = []

    @Option(name: .long, help: "Sort field and direction")
    var sort: String?

    @Option(name: .long, help: "Maximum records to return")
    var limit: Int?

    func loadConfig() throws -> QueryConfig {
        let manager = ConfigurationManager.shared
        let reader = try manager.loadConfiguration(
            configFile: configFile,
            profile: profile
        )

        return try QueryConfig(reader: reader)
    }

    func execute(with config: QueryConfig) async throws {
        // Use config values, with CLI overrides
        let containerID = self.containerID ?? config.base.containerID
        let database = self.database.map { CloudKitDatabase(rawValue: $0) ?? .public }
                       ?? config.base.database
        let zone = self.zone ?? config.zone
        let limit = self.limit ?? config.limit

        // Execute query...
        let client = try MistKitClient(
            containerID: containerID,
            apiToken: config.base.apiToken,
            webAuthToken: config.base.webAuthToken
        )

        let results = try await client.queryRecords(
            recordType: "Note",
            database: database,
            zone: zone,
            filters: filter,
            limit: limit
        )

        // Format output
        let formatter = OutputFormatter(format: output ?? config.base.output)
        try formatter.print(results)
    }
}
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
