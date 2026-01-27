# Phase 2: Essential Commands

**Objective**: Implement the most commonly used commands for immediate usability: query, create, current-user, and auth-token.

## Overview

This phase delivers the core functionality needed for basic MistDemo usage. After this phase, users can:
- Authenticate and obtain web auth tokens
- Verify their identity
- Query records
- Create new records

## Commands

### 1. auth-token

**File**: `Sources/MistDemo/Commands/AuthTokenCommand.swift`

Obtain web authentication token via browser flow.

**Implementation:**
```swift
struct AuthTokenCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth-token",
        abstract: "Obtain a web authentication token"
    )

    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var port: Int = 8080
    @Option var host: String = "127.0.0.1"
    @Flag var noBrowser: Bool = false

    func execute() async throws {
        // 1. Start local HTTP server
        // 2. Open browser to CloudKit auth URL
        // 3. Wait for callback with token
        // 4. Output token to stdout
        // 5. Shutdown server
    }
}
```

**Acceptance Criteria:**
- [ ] Starts local HTTP server on specified port
- [ ] Opens browser to CloudKit auth URL (unless `--no-browser`)
- [ ] Receives auth callback with token
- [ ] Outputs token to stdout
- [ ] Handles timeout gracefully
- [ ] Handles port conflicts
- [ ] Unit tests with mock server
- [ ] Integration test with mock auth flow

### 2. current-user

**File**: `Sources/MistDemo/Commands/CurrentUserCommand.swift`

Get information about authenticated user.

**Implementation:**
```swift
struct CurrentUserCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "current-user",
        abstract: "Get current user information"
    )

    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var database: String?
    @Option var webAuthToken: String?
    @Option(name: .shortAndLong) var output: String?
    @Option var fields: String?

    func execute(with config: CurrentUserConfig) async throws {
        // 1. Create MistKit client
        // 2. Call current-user endpoint
        // 3. Format and output result
    }
}
```

**Acceptance Criteria:**
- [ ] Loads configuration properly
- [ ] Calls MistKit client.currentUser()
- [ ] Supports field filtering
- [ ] Outputs in all formats
- [ ] Handles authentication errors
- [ ] Unit tests with mock client
- [ ] Integration test

### 3. query

**File**: `Sources/MistDemo/Commands/QueryCommand.swift`

Query Note records with filtering and sorting.

**Implementation:**
```swift
struct QueryCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "query",
        abstract: "Query Note records from CloudKit"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var database: String?
    @Option(name: .shortAndLong) var output: String?

    // Query-specific options
    @Option var zone: String?
    @Option var filter: [String] = []
    @Option var sort: String?
    @Option var limit: Int?
    @Option var offset: Int?
    @Option var fields: String?
    @Option var continuationMarker: String?

    func execute(with config: QueryConfig) async throws {
        // 1. Parse filters and sort options
        // 2. Create MistKit client
        // 3. Execute query
        // 4. Format and output results
    }
}
```

**Acceptance Criteria:**
- [ ] Parses multiple filter expressions
- [ ] Parses sort field and direction
- [ ] Validates limit (1-200)
- [ ] Supports field selection
- [ ] Handles continuation markers
- [ ] Calls MistKit client.queryRecords()
- [ ] Outputs in all formats
- [ ] Handles errors gracefully
- [ ] Unit tests for parsing
- [ ] Integration test with mock data

### 4. create

**File**: `Sources/MistDemo/Commands/CreateCommand.swift`

Create a new Note record.

**Implementation:**
```swift
struct CreateCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new Note record"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var database: String?
    @Option(name: .shortAndLong) var output: String?

    // Create-specific options
    @Option var zone: String?
    @Option var recordName: String?
    @Option(name: .shortAndLong) var field: [String] = []
    @Option var jsonFile: String?
    @Flag var stdin: Bool = false

    func execute(with config: CreateConfig) async throws {
        // 1. Parse fields or load from JSON/stdin
        // 2. Validate field types
        // 3. Create MistKit client
        // 4. Create record
        // 5. Format and output result
    }
}
```

**Field Parser:**
```swift
struct Field {
    let name: String
    let type: FieldType
    let value: String

    static func parse(_ input: String) throws -> Field {
        // Parse "name:type:value" format
    }
}

enum FieldType: String {
    case string
    case int64
    case timestamp
    case asset
}
```

**Acceptance Criteria:**
- [ ] Parses field definitions (name:type:value)
- [ ] Validates field types match schema
- [ ] Loads fields from JSON file
- [ ] Reads fields from stdin
- [ ] Generates record name if not provided
- [ ] Calls MistKit client.createRecord()
- [ ] Outputs created record
- [ ] Handles validation errors
- [ ] Unit tests for field parsing
- [ ] Integration test with mock client

## Shared Components

### Configuration Types

**File**: `Sources/MistDemo/Configuration/CommandConfigs.swift`

```swift
struct AuthTokenConfig {
    let apiToken: String
    let port: Int
    let host: String
    let noBrowser: Bool
}

struct CurrentUserConfig {
    let base: MistDemoConfig
    let fields: [String]?
}

struct QueryConfig {
    let base: MistDemoConfig
    let zone: String
    let filters: [String]
    let sort: (field: String, order: SortOrder)?
    let limit: Int
    let offset: Int
    let fields: [String]?
    let continuationMarker: String?
}

struct CreateConfig {
    let base: MistDemoConfig
    let zone: String
    let recordName: String?
    let fields: [Field]
}
```

### MistKit Client Integration

**File**: `Sources/MistDemo/CloudKit/MistKitClientFactory.swift`

```swift
struct MistKitClientFactory {
    static func create(from config: MistDemoConfig) throws -> MistKitClient {
        return try MistKitClient(
            containerID: config.containerID,
            apiToken: config.apiToken,
            webAuthToken: config.webAuthToken,
            keyID: config.keyID,
            privateKeyFile: config.privateKeyFile,
            environment: config.environment
        )
    }
}
```

## File Structure

```
Sources/MistDemo/Commands/
├── AuthTokenCommand.swift
├── CurrentUserCommand.swift
├── QueryCommand.swift
└── CreateCommand.swift

Sources/MistDemo/Configuration/
└── CommandConfigs.swift

Sources/MistDemo/CloudKit/
└── MistKitClientFactory.swift

Tests/MistDemoTests/Commands/
├── AuthTokenCommandTests.swift
├── CurrentUserCommandTests.swift
├── QueryCommandTests.swift
└── CreateCommandTests.swift
```

## Testing Requirements

### Unit Tests
- [ ] Field parsing (create command)
- [ ] Filter parsing (query command)
- [ ] Sort parsing (query command)
- [ ] Limit validation (query command)
- [ ] Configuration loading for each command

### Integration Tests
- [ ] auth-token flow with mock server
- [ ] current-user with mock client
- [ ] query with mock data
- [ ] create with mock client

### End-to-End Examples
- [ ] Example script: Get auth token
- [ ] Example script: Query records
- [ ] Example script: Create record
- [ ] Example script: Verify authentication

## Implementation Order

1. **auth-token** - Required for other commands' testing
2. **current-user** - Simple command, validates auth
3. **query** - Most complex, most useful
4. **create** - Builds on query patterns

## Dependencies

**Blocked By:**
- Phase 1 (core infrastructure)

**Blocks:**
- Phase 3 (CRUD operations)
- Phase 4 (advanced operations)

## Estimated Complexity

**Medium-High**

**Key Challenges:**
- auth-token local server implementation
- Field parsing and validation
- Filter expression parsing
- Pagination support

## Definition of Done

- [ ] All four commands implemented
- [ ] Unit tests pass with >85% coverage
- [ ] Integration tests pass
- [ ] Help text comprehensive
- [ ] Examples documented
- [ ] Code review complete
- [ ] Users can perform basic CloudKit operations

## Related Documentation

- [Record Operations](../operations-record.md) - query and create commands
- [User Operations](../operations-user.md) - current-user command
- [Authentication Operations](../operations-auth.md) - auth-token command
- [Configuration](../configuration.md) - Configuration management
- [Error Handling](../error-handling.md) - Error scenarios
- [Testing Strategy](../testing-strategy.md) - Testing patterns
