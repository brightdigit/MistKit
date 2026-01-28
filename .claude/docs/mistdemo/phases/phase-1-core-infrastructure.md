# Phase 1: Core Infrastructure

**Objective**: Establish the foundational architecture for MistDemo including command protocol, configuration management, and output formatting.

## Overview

This phase builds the infrastructure that all subcommands will depend on. No user-facing commands are implemented yet—this phase focuses on the plumbing.

## Components

### 1. Command Protocol

**File**: `Sources/MistDemo/Commands/CommandProtocol.swift`

Define the base protocol that all subcommands implement:

```swift
import ArgumentParser

protocol MistDemoCommand: AsyncParsableCommand {
    associatedtype Config

    var configFile: String? { get }
    var profile: String? { get }

    func loadConfig() throws -> Config
    func execute(with config: Config) async throws
}
```

**Acceptance Criteria:**
- [ ] Protocol defined with associated type
- [ ] Async execution support
- [ ] Configuration loading hooks
- [ ] Unit tests for protocol conformance

### 2. Configuration Management with Swift Configuration

**Implementation Status**: ✅ Partially Complete

Implemented Swift Configuration integration using Apple's official configuration library:

**Completed Features:**
- [x] Environment variable provider (EnvironmentVariablesProvider)
- [x] In-memory defaults provider (InMemoryProvider)
- [x] Hierarchical resolution (Environment > Defaults)
- [x] Type-safe configuration with ConfigReader
- [x] MistDemoConfiguration wrapper for clean API
- [x] Automatic key transformation (dots to underscores for env vars)
- [x] Secret handling for sensitive values

**Files Implemented:**
- `Sources/MistDemo/Configuration/MistDemoConfiguration.swift` - Swift Configuration wrapper
- `Sources/MistDemo/Configuration/MistDemoConfig.swift` - Configuration data model
- `Sources/ConfigKeyKit/` - Reusable configuration key types

**Pending Features:**
- [ ] Command-line arguments provider (requires CommandLineArgumentsProvider)
- [ ] JSON configuration file support (requires FileProvider with JSONSnapshot)
- [ ] YAML configuration file support (requires FileProvider with YAMLSnapshot)
- [ ] Profile merging and selection
- [ ] Full priority resolution (CLI > Profile > File > Environment > Defaults)

**Note**: Requires macOS 15.0+ due to Swift Configuration dependency.

**Acceptance Criteria:**
- [ ] Load JSON configuration files
- [ ] Load YAML configuration files
- [x] Read environment variables
- [ ] Merge profiles with base configuration
- [x] Resolve configuration priority correctly (for implemented providers)
- [x] Handle missing configuration gracefully
- [ ] Unit tests for all configuration sources
- [ ] Integration tests for priority resolution

### 3. Output Formatters

**Files**: `Sources/MistDemo/Output/*.swift`

Implement output formatters for all supported formats:

#### JSONFormatter
```swift
struct JSONFormatter: OutputFormatter {
    let pretty: Bool

    func format<T: Encodable>(_ value: T) throws -> String
}
```

#### TableFormatter
```swift
struct TableFormatter: OutputFormatter {
    func format<T: Encodable>(_ value: T) throws -> String
}
```

#### CSVFormatter
```swift
struct CSVFormatter: OutputFormatter {
    func format<T: Encodable>(_ value: T) throws -> String
}
```

#### YAMLFormatter
```swift
struct YAMLFormatter: OutputFormatter {
    func format<T: Encodable>(_ value: T) throws -> String
}
```

**Acceptance Criteria:**
- [ ] JSON formatter with pretty-print option
- [ ] Table formatter with aligned columns
- [ ] CSV formatter RFC 4180 compliant
- [ ] YAML formatter
- [ ] Common protocol for all formatters
- [ ] Handle nested structures
- [ ] Unit tests for each formatter
- [ ] Examples of each output format

### 4. Error Handling

**File**: `Sources/MistDemo/Errors/MistDemoError.swift`

Define error types and formatting:

```swift
enum MistDemoError: Error {
    case authenticationFailed(String)
    case invalidQuery(String, details: [String: Any])
    case recordNotFound(String)
    case configurationError(String)
    case networkError(Error)

    var errorOutput: String  // JSON format for stderr
}
```

**Acceptance Criteria:**
- [ ] Comprehensive error types
- [ ] JSON error output format
- [ ] Error codes
- [ ] Actionable suggestions
- [ ] Unit tests for error formatting

## Package Dependencies

Current `Package.swift` configuration:

```swift
platforms: [
    .macOS(.v15)  // Required for Swift Configuration
],
dependencies: [
    .package(path: "../.."),  // MistKit
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-configuration", from: "1.0.0")
],
targets: [
    .target(
        name: "ConfigKeyKit",
        dependencies: []  // Lightweight, no dependencies
    ),
    .executableTarget(
        name: "MistDemo",
        dependencies: [
            "ConfigKeyKit",
            .product(name: "MistKit", package: "MistKit"),
            .product(name: "Hummingbird", package: "hummingbird"),
            .product(name: "Configuration", package: "swift-configuration")
        ]
    )
]
```

**Note**: ArgumentParser was removed in favor of direct Swift Configuration usage.

## File Structure

**Current Implementation:**
```
Sources/
├── ConfigKeyKit/               # Reusable configuration key types
│   ├── ConfigKey.swift
│   ├── ConfigurationKey.swift
│   └── OptionalConfigKey.swift
└── MistDemo/
    ├── MistDemo.swift          # Main entry point
    ├── Configuration/
    │   ├── MistDemoConfiguration.swift  # Swift Configuration wrapper
    │   └── MistDemoConfig.swift         # Configuration data model
    ├── Utilities/
    │   ├── AuthenticationHelper.swift   # Authentication setup logic
    │   └── AuthenticationResult.swift   # Auth result model
    └── Errors/
        └── AuthenticationError.swift    # Authentication errors

Tests/MistDemoTests/
├── Configuration/
│   └── (Tests pending)
└── Utilities/
    └── (Tests pending)
```

**Pending Implementation:**
- Command protocol structure
- Output formatters (JSON, Table, CSV, YAML)
- Comprehensive error handling
- Test coverage

## Testing Requirements

### Unit Tests
- [ ] Configuration loading from JSON
- [ ] Configuration loading from YAML
- [ ] Environment variable reading
- [ ] Profile merging logic
- [ ] Priority resolution
- [ ] Each output formatter
- [ ] Error formatting

### Integration Tests
- [ ] Full configuration stack (file + env + CLI)
- [ ] Output formatter with real data structures

## Implementation Order

1. **Command Protocol** - Foundation for all commands
2. **Configuration Manager** - Load and merge configuration
3. **Output Formatters** - JSON first, then Table, CSV, YAML
4. **Error Handling** - Consistent error reporting

## Dependencies

**Blocks:**
- Phase 2 (requires command infrastructure)
- Phase 3 (requires command infrastructure)
- Phase 4 (requires command infrastructure)

**Blocked By:** None

## Estimated Complexity

**High** - This is the architectural foundation. Getting it right is critical.

**Key Challenges:**
- Swift Configuration API integration
- Configuration priority resolution
- Table formatter column alignment
- Error handling consistency

## Definition of Done

- [ ] All components implemented
- [ ] Unit tests pass with >90% coverage
- [ ] Integration tests pass
- [ ] Documentation updated
- [ ] Code review complete
- [ ] Examples added for each formatter

## Related Documentation

- [ConfigKeyKit Strategy](../configkeykit-strategy.md) - Implementation patterns
- [Configuration](../configuration.md) - User-facing configuration guide
- [Output Formats](../output-formats.md) - Format specifications
- [Error Handling](../error-handling.md) - Error format reference
- [Testing Strategy](../testing-strategy.md) - Testing approach
