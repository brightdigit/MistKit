# Phase 3: CRUD Operations

**Objective**: Complete the CRUD (Create, Read, Update, Delete) operations by implementing update, delete, lookup, and modify commands.

## Overview

This phase completes the record manipulation capabilities. After Phase 2 provided query and create, this phase adds:
- Record updates with optimistic locking
- Record deletion
- Batch record lookup
- Batch modify operations (create/update/delete in one request)

## Commands

### 1. update

**File**: `Sources/MistDemo/Commands/UpdateCommand.swift`

Update an existing Note record.

**Implementation:**
```swift
struct UpdateCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an existing Note record"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var database: String?
    @Option(name: .shortAndLong) var output: String?

    // Update-specific options
    @Argument var recordName: String
    @Option var zone: String?
    @Option(name: .shortAndLong) var field: [String] = []
    @Option var changeTag: String?
    @Flag var force: Bool = false
    @Option var jsonFile: String?
    @Flag var stdin: Bool = false

    func execute(with config: UpdateConfig) async throws {
        // 1. Parse fields or load from JSON/stdin
        // 2. Create MistKit client
        // 3. Update record with optional change tag
        // 4. Handle conflicts (retry or force)
        // 5. Format and output result
    }
}
```

**Acceptance Criteria:**
- [ ] Accepts record name as required argument
- [ ] Parses field updates (name:type:value)
- [ ] Supports change tag for optimistic locking
- [ ] Supports --force flag to override conflicts
- [ ] Loads updates from JSON file
- [ ] Reads updates from stdin
- [ ] Calls MistKit client.updateRecord()
- [ ] Handles conflict errors gracefully
- [ ] Outputs updated record
- [ ] Unit tests for field parsing
- [ ] Integration test with mock client
- [ ] Test conflict handling

### 2. delete

**File**: `Sources/MistDemo/Commands/DeleteCommand.swift`

Delete a Note record.

**Implementation:**
```swift
struct DeleteCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a Note record"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var database: String?
    @Option(name: .shortAndLong) var output: String?

    // Delete-specific options
    @Argument var recordName: String
    @Option var zone: String?
    @Option var changeTag: String?
    @Flag var force: Bool = false

    func execute(with config: DeleteConfig) async throws {
        // 1. Create MistKit client
        // 2. Delete record with optional change tag
        // 3. Handle conflicts
        // 4. Output confirmation
    }
}
```

**Acceptance Criteria:**
- [ ] Accepts record name as required argument
- [ ] Supports change tag for optimistic locking
- [ ] Supports --force flag
- [ ] Calls MistKit client.deleteRecord()
- [ ] Handles conflict errors
- [ ] Outputs deletion confirmation
- [ ] Unit tests
- [ ] Integration test with mock client

### 3. lookup

**File**: `Sources/MistDemo/Commands/LookupCommand.swift`

Lookup specific records by name (batch fetch).

**Implementation:**
```swift
struct LookupCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "lookup",
        abstract: "Lookup specific Note records by name"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var database: String?
    @Option(name: .shortAndLong) var output: String?

    // Lookup-specific options
    @Argument var recordNames: [String]
    @Option var zone: String?
    @Option var fields: String?

    func execute(with config: LookupConfig) async throws {
        // 1. Create MistKit client
        // 2. Lookup records by names
        // 3. Handle not found records
        // 4. Format and output results
    }
}
```

**Acceptance Criteria:**
- [ ] Accepts multiple record names
- [ ] Supports field filtering
- [ ] Calls MistKit client.lookupRecords()
- [ ] Handles records not found gracefully
- [ ] Outputs all found records
- [ ] Unit tests
- [ ] Integration test with mock client

### 4. modify

**File**: `Sources/MistDemo/Commands/ModifyCommand.swift`

Perform batch operations (create, update, delete).

**Implementation:**
```swift
struct ModifyCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "modify",
        abstract: "Perform batch operations on records"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var database: String?
    @Option(name: .shortAndLong) var output: String?

    // Modify-specific options
    @Option(name: .shortAndLong) var operationsFile: String?
    @Flag var atomic: Bool = false
    @Flag var stdin: Bool = false

    func execute(with config: ModifyConfig) async throws {
        // 1. Load operations from file or stdin
        // 2. Validate operations
        // 3. Create MistKit client
        // 4. Execute batch modify
        // 5. Handle partial failures (if not atomic)
        // 6. Format and output results
    }
}
```

**Operations File Structure:**
```json
{
  "operations": [
    {
      "type": "create",
      "recordType": "Note",
      "fields": {
        "title": {"value": "New Note"},
        "index": {"value": 1}
      }
    },
    {
      "type": "update",
      "recordType": "Note",
      "recordName": "note_001",
      "fields": {
        "title": {"value": "Updated"}
      }
    },
    {
      "type": "delete",
      "recordType": "Note",
      "recordName": "note_002"
    }
  ]
}
```

**Acceptance Criteria:**
- [ ] Parses operations file (JSON)
- [ ] Validates operation types
- [ ] Supports create, update, delete operations
- [ ] Supports --atomic flag for all-or-nothing
- [ ] Reads operations from stdin
- [ ] Calls MistKit client.modifyRecords()
- [ ] Handles partial failures gracefully
- [ ] Outputs results for each operation
- [ ] Unit tests for operations parsing
- [ ] Integration test with mock client
- [ ] Test atomic vs non-atomic behavior

## Shared Components

### Configuration Types

**File**: `Sources/MistDemo/Configuration/CommandConfigs.swift` (extend)

```swift
struct UpdateConfig {
    let base: MistDemoConfig
    let recordName: String
    let zone: String
    let fields: [Field]
    let changeTag: String?
    let force: Bool
}

struct DeleteConfig {
    let base: MistDemoConfig
    let recordName: String
    let zone: String
    let changeTag: String?
    let force: Bool
}

struct LookupConfig {
    let base: MistDemoConfig
    let recordNames: [String]
    let zone: String
    let fields: [String]?
}

struct ModifyConfig {
    let base: MistDemoConfig
    let operations: [RecordOperation]
    let atomic: Bool
}

enum RecordOperation {
    case create(recordType: String, fields: [String: Any])
    case update(recordType: String, recordName: String, fields: [String: Any], changeTag: String?)
    case delete(recordType: String, recordName: String, changeTag: String?)
}
```

### Operations Parser

**File**: `Sources/MistDemo/Operations/OperationsParser.swift`

```swift
struct OperationsParser {
    static func parse(from fileURL: URL) throws -> [RecordOperation]
    static func parse(from jsonString: String) throws -> [RecordOperation]
    static func validate(_ operations: [RecordOperation]) throws
}
```

## File Structure

```
Sources/MistDemo/Commands/
├── UpdateCommand.swift
├── DeleteCommand.swift
├── LookupCommand.swift
└── ModifyCommand.swift

Sources/MistDemo/Operations/
└── OperationsParser.swift

Tests/MistDemoTests/Commands/
├── UpdateCommandTests.swift
├── DeleteCommandTests.swift
├── LookupCommandTests.swift
└── ModifyCommandTests.swift

Tests/MistDemoTests/Operations/
└── OperationsParserTests.swift
```

## Testing Requirements

### Unit Tests
- [ ] Update field parsing
- [ ] Delete with change tag
- [ ] Lookup multiple records
- [ ] Operations file parsing
- [ ] Operations validation
- [ ] Atomic flag behavior

### Integration Tests
- [ ] Update with mock client
- [ ] Delete with mock client
- [ ] Lookup with mock client
- [ ] Modify batch operations
- [ ] Conflict handling (update/delete)
- [ ] Partial failure handling (modify)

### End-to-End Examples
- [ ] Example: Update with optimistic locking
- [ ] Example: Bulk delete
- [ ] Example: Batch modify operations
- [ ] Example: Atomic batch update

## Implementation Order

1. **delete** - Simplest, single record operation
2. **update** - Similar to create, adds conflict handling
3. **lookup** - Batch fetch, simpler than modify
4. **modify** - Most complex, batch operations

## Dependencies

**Blocked By:**
- Phase 1 (core infrastructure)
- Phase 2 (essential commands - reuse patterns)

**Blocks:**
- Phase 4 (advanced operations)

## Estimated Complexity

**Medium**

**Key Challenges:**
- Optimistic locking conflict handling
- Operations file parsing and validation
- Atomic vs non-atomic batch operations
- Partial failure reporting

## Definition of Done

- [ ] All four commands implemented
- [ ] Unit tests pass with >85% coverage
- [ ] Integration tests pass
- [ ] Conflict handling tested
- [ ] Batch operations tested
- [ ] Help text comprehensive
- [ ] Examples documented
- [ ] Code review complete

## Common Workflows

### Update with Verification
```bash
# Get current record
mistdemo lookup note_001 > current.json

# Extract change tag
CHANGE_TAG=$(jq -r '.records[0].recordChangeTag' current.json)

# Update with optimistic locking
mistdemo update note_001 \
  --field "title:string:Updated" \
  --change-tag "$CHANGE_TAG"
```

### Batch Delete
```bash
# Query records to delete
mistdemo query --filter "index < 10" > to_delete.json

# Extract record names
jq -r '.records[].recordName' to_delete.json | \
  xargs -I {} mistdemo delete {}
```

### Atomic Batch Modify
```bash
cat > batch.json <<EOF
{
  "operations": [
    {"type": "create", "recordType": "Note", "fields": {...}},
    {"type": "update", "recordType": "Note", "recordName": "note_001", "fields": {...}},
    {"type": "delete", "recordType": "Note", "recordName": "note_002"}
  ]
}
EOF

mistdemo modify --operations-file batch.json --atomic
```

## Related Documentation

- [Record Operations](../operations-record.md) - Command specifications
- [Error Handling](../error-handling.md) - Conflict error handling
- [Configuration](../configuration.md) - Configuration management
- [Testing Strategy](../testing-strategy.md) - Testing patterns
