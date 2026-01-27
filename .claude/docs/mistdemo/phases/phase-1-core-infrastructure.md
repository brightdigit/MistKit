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

### 2. ConfigKeyKit Extensions

**File**: `Sources/MistDemo/Configuration/ConfigurationManager.swift`

Implement Swift Configuration integration:

```swift
class ConfigurationManager {
    static let shared = ConfigurationManager()

    func loadConfiguration(
        configFile: String?,
        profile: String?
    ) throws -> ConfigReader
}
```

**Features:**
- [x] JSON configuration file support (JSONSnapshot, default trait)
- [x] YAML configuration file support (YAMLSnapshot, requires "YAML" trait)
- [x] Environment variable provider (core functionality)
- [x] Command-line arguments provider (requires "CommandLineArguments" trait)
- [x] Profile merging
- [x] Priority resolution (CLI > Profile > File > Environment > Defaults)

**Files:**
- `Sources/MistDemo/Configuration/ConfigurationManager.swift`
- `Sources/MistDemo/Configuration/MistDemoConfig.swift`
- `Sources/MistDemo/Configuration/ConfigError.swift`

**Acceptance Criteria:**
- [ ] Load JSON configuration files
- [ ] Load YAML configuration files
- [ ] Read environment variables
- [ ] Merge profiles with base configuration
- [ ] Resolve configuration priority correctly
- [ ] Handle missing configuration gracefully
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

Update `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    .package(
        url: "https://github.com/apple/swift-configuration",
        from: "1.0.0",
        traits: [.defaults, "CommandLineArguments", "YAML"]
    ),
    .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
    .package(path: "../.."),  // MistKit
],
targets: [
    .executableTarget(
        name: "MistDemo",
        dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "Configuration", package: "swift-configuration"),
            .product(name: "Logging", package: "swift-log"),
            "MistKit",
        ]
    ),
]
```

## File Structure

```
Sources/MistDemo/
├── MistDemo.swift              # Main entry point
├── Commands/
│   └── CommandProtocol.swift   # Base command protocol
├── Configuration/
│   ├── ConfigurationManager.swift
│   ├── MistDemoConfig.swift
│   └── ConfigError.swift
├── Output/
│   ├── OutputFormatter.swift   # Protocol
│   ├── JSONFormatter.swift
│   ├── TableFormatter.swift
│   ├── CSVFormatter.swift
│   └── YAMLFormatter.swift
└── Errors/
    └── MistDemoError.swift

Tests/MistDemoTests/
├── Configuration/
│   ├── ConfigurationManagerTests.swift
│   ├── ProfileMergingTests.swift
│   └── PriorityResolutionTests.swift
└── Output/
    ├── JSONFormatterTests.swift
    ├── TableFormatterTests.swift
    ├── CSVFormatterTests.swift
    └── YAMLFormatterTests.swift
```

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
