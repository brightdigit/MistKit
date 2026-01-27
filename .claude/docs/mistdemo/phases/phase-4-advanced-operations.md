# Phase 4: Advanced Operations

**Objective**: Implement advanced features including zone management, user discovery, contact lookup, and enhanced configuration profile support.

## Overview

This final phase adds advanced CloudKit capabilities beyond basic CRUD:
- Zone management (list, lookup, create, delete)
- User discovery by email/phone
- Contact lookup
- Full configuration profile support
- Validation command

## Commands

### 1. list-zones

**File**: `Sources/MistDemo/Commands/ListZonesCommand.swift`

List all zones in the database.

**Implementation:**
```swift
struct ListZonesCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-zones",
        abstract: "List all zones in the database"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var database: String?
    @Option(name: .shortAndLong) var output: String?

    // List-zones-specific options
    @Flag var includeDefault: Bool = false

    func execute(with config: ListZonesConfig) async throws {
        // 1. Create MistKit client
        // 2. List zones
        // 3. Filter out default zone if needed
        // 4. Format and output results
    }
}
```

**Acceptance Criteria:**
- [ ] Lists all custom zones
- [ ] Optionally includes default zone
- [ ] Only works with private/shared databases
- [ ] Calls MistKit client.listZones()
- [ ] Outputs zone information
- [ ] Unit tests
- [ ] Integration test with mock client

### 2. lookup-zones

**File**: `Sources/MistDemo/Commands/LookupZonesCommand.swift`

Lookup specific zones by name.

**Implementation:**
```swift
struct LookupZonesCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "lookup-zones",
        abstract: "Lookup specific zones by name"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var database: String?
    @Option(name: .shortAndLong) var output: String?

    // Lookup-zones-specific options
    @Argument var zoneNames: [String]

    func execute(with config: LookupZonesConfig) async throws {
        // 1. Create MistKit client
        // 2. Lookup zones by names
        // 3. Handle zones not found
        // 4. Format and output results
    }
}
```

**Acceptance Criteria:**
- [ ] Accepts multiple zone names
- [ ] Calls MistKit client.lookupZones()
- [ ] Handles zones not found gracefully
- [ ] Outputs zone details
- [ ] Unit tests
- [ ] Integration test with mock client

### 3. modify-zones

**File**: `Sources/MistDemo/Commands/ModifyZonesCommand.swift`

Create or delete zones.

**Implementation:**
```swift
struct ModifyZonesCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "modify-zones",
        abstract: "Create or delete zones"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option(name: .shortAndLong) var database: String?
    @Option(name: .shortAndLong) var output: String?

    // Modify-zones-specific options
    @Option(name: .shortAndLong) var operationsFile: String?
    @Flag var stdin: Bool = false

    func execute(with config: ModifyZonesConfig) async throws {
        // 1. Load zone operations from file or stdin
        // 2. Validate operations
        // 3. Create MistKit client
        // 4. Execute zone modifications
        // 5. Format and output results
    }
}
```

**Operations File Structure:**
```json
{
  "operations": [
    {
      "type": "create",
      "zoneName": "CustomZone1",
      "atomic": true
    },
    {
      "type": "delete",
      "zoneName": "OldZone"
    }
  ]
}
```

**Acceptance Criteria:**
- [ ] Parses zone operations file
- [ ] Supports create and delete operations
- [ ] Validates zone names
- [ ] Calls MistKit client.modifyZones()
- [ ] Warns about destructive delete operations
- [ ] Outputs results
- [ ] Unit tests for operations parsing
- [ ] Integration test with mock client

### 4. discover

**File**: `Sources/MistDemo/Commands/DiscoverCommand.swift`

Discover user identities by email, phone, or record name.

**Implementation:**
```swift
struct DiscoverCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "discover",
        abstract: "Discover user identities"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option var webAuthToken: String?
    @Option(name: .shortAndLong) var output: String?

    // Discover-specific options
    @Argument var lookupType: LookupType
    @Argument var values: [String]

    enum LookupType: String, ExpressibleByArgument {
        case email
        case phone
        case record
    }

    func execute(with config: DiscoverConfig) async throws {
        // 1. Create MistKit client
        // 2. Discover users by lookup type
        // 3. Handle users not found
        // 4. Format and output results
    }
}
```

**Acceptance Criteria:**
- [ ] Supports email, phone, and record name lookup
- [ ] Requires web auth token
- [ ] Calls MistKit client.discoverUsers()
- [ ] Handles not found gracefully
- [ ] Respects user privacy settings
- [ ] Outputs user information
- [ ] Unit tests
- [ ] Integration test with mock client

### 5. lookup-contacts

**File**: `Sources/MistDemo/Commands/LookupContactsCommand.swift`

Lookup user contacts (requires contacts permission).

**Implementation:**
```swift
struct LookupContactsCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "lookup-contacts",
        abstract: "Lookup user contacts"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option var webAuthToken: String?
    @Option(name: .shortAndLong) var output: String?

    // Lookup-contacts-specific options
    @Option var email: [String] = []
    @Option var phone: [String] = []

    func execute(with config: LookupContactsConfig) async throws {
        // 1. Create MistKit client
        // 2. Lookup contacts
        // 3. Handle permission errors
        // 4. Format and output results
    }
}
```

**Acceptance Criteria:**
- [ ] Accepts email and phone options
- [ ] Requires web auth token
- [ ] Requires contacts permission
- [ ] Calls MistKit client.lookupContacts()
- [ ] Handles permission errors gracefully
- [ ] Outputs contact information
- [ ] Unit tests
- [ ] Integration test with mock client

### 6. validate

**File**: `Sources/MistDemo/Commands/ValidateCommand.swift`

Validate current authentication credentials.

**Implementation:**
```swift
struct ValidateCommand: MistDemoCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate authentication credentials"
    )

    // Global options
    @Option var configFile: String?
    @Option var profile: String?
    @Option(name: .shortAndLong) var containerID: String?
    @Option(name: .shortAndLong) var apiToken: String?
    @Option var webAuthToken: String?
    @Option(name: .shortAndLong) var output: String?

    // Validate-specific options
    @Flag var testQuery: Bool = false

    func execute(with config: ValidateConfig) async throws {
        // 1. Validate credentials are present
        // 2. Optionally perform test query
        // 3. Output validation result
        // 4. Exit with appropriate code
    }
}
```

**Acceptance Criteria:**
- [ ] Validates credentials present
- [ ] Optionally performs test query
- [ ] Returns appropriate exit codes
- [ ] Outputs validation result
- [ ] Unit tests
- [ ] Integration test with mock client

## Enhanced Configuration Support

### Full Profile Implementation

**File**: `Sources/MistDemo/Configuration/ProfileManager.swift`

```swift
struct ProfileManager {
    static func loadProfile(
        named profileName: String,
        from fileURL: URL
    ) throws -> [String: Any]

    static func mergeProfile(
        _ profileData: [String: Any],
        with baseConfig: [String: Any]
    ) -> [String: Any]

    static func listProfiles(
        from fileURL: URL
    ) throws -> [String]
}
```

**Acceptance Criteria:**
- [ ] Load profiles from JSON/YAML
- [ ] Merge profiles with base configuration
- [ ] List available profiles
- [ ] Validate profile structure
- [ ] Unit tests for profile operations

### Profile-Specific Defaults

Allow profiles to specify command-specific defaults:

```json
{
  "container_id": "iCloud.com.example.MyApp",

  "profiles": {
    "production": {
      "environment": "production",
      "database": "public",
      "query": {
        "limit": 100,
        "output": "json"
      },
      "create": {
        "zone": "ProductionZone"
      }
    }
  }
}
```

## File Structure

```
Sources/MistDemo/Commands/
├── ListZonesCommand.swift
├── LookupZonesCommand.swift
├── ModifyZonesCommand.swift
├── DiscoverCommand.swift
├── LookupContactsCommand.swift
└── ValidateCommand.swift

Sources/MistDemo/Configuration/
└── ProfileManager.swift

Sources/MistDemo/Operations/
└── ZoneOperationsParser.swift

Tests/MistDemoTests/Commands/
├── ListZonesCommandTests.swift
├── LookupZonesCommandTests.swift
├── ModifyZonesCommandTests.swift
├── DiscoverCommandTests.swift
├── LookupContactsCommandTests.swift
└── ValidateCommandTests.swift

Tests/MistDemoTests/Configuration/
└── ProfileManagerTests.swift
```

## Testing Requirements

### Unit Tests
- [ ] Zone operations parsing
- [ ] User lookup type validation
- [ ] Profile loading and merging
- [ ] Credential validation
- [ ] Contact permission handling

### Integration Tests
- [ ] List zones with mock client
- [ ] Modify zones with mock client
- [ ] Discover users with mock client
- [ ] Lookup contacts with mock client
- [ ] Validate with test query
- [ ] Profile configuration loading

### End-to-End Examples
- [ ] Example: Create and manage zones
- [ ] Example: Discover users for sharing
- [ ] Example: Validate credentials workflow
- [ ] Example: Use production profile

## Implementation Order

1. **validate** - Simple, useful for all workflows
2. **list-zones** / **lookup-zones** - Simpler zone operations
3. **modify-zones** - More complex zone operations
4. **discover** - User discovery
5. **lookup-contacts** - Contact lookup
6. **Profile enhancements** - Full profile support

## Dependencies

**Blocked By:**
- Phase 1 (core infrastructure)
- Phase 2 (essential commands)
- Phase 3 (CRUD operations)

**Blocks:** None (final phase)

## Estimated Complexity

**Medium**

**Key Challenges:**
- Zone operations (limited to private/shared databases)
- User privacy and permission handling
- Contact lookup permission flow
- Profile command-specific defaults

## Definition of Done

- [ ] All six commands implemented
- [ ] Full profile support implemented
- [ ] Unit tests pass with >85% coverage
- [ ] Integration tests pass
- [ ] Help text comprehensive
- [ ] Examples documented
- [ ] Code review complete
- [ ] All MistDemo features complete

## Common Workflows

### Zone Management
```bash
# Create zones
cat > zones.json <<EOF
{
  "operations": [
    {"type": "create", "zoneName": "ProjectData"},
    {"type": "create", "zoneName": "UserSettings"}
  ]
}
EOF

mistdemo modify-zones --operations-file zones.json --database private

# List zones
mistdemo list-zones --database private

# Use custom zone
mistdemo create --zone "ProjectData" --database private \
  --field "title:string:In Custom Zone"
```

### User Discovery for Sharing
```bash
# Discover users
mistdemo discover email alice@example.com bob@example.com > users.json

# Extract user record names
jq -r '.users[].userRecordName' users.json > share_with.txt
```

### Production Profile
```bash
# config.json has production profile
mistdemo query --profile production

# Profile sets: environment=production, database=public, output=json
```

## Related Documentation

- [Zone Operations](../operations-zone.md) - Zone management commands
- [User Operations](../operations-user.md) - User discovery and contacts
- [Authentication Operations](../operations-auth.md) - Validation
- [Configuration](../configuration.md) - Profile management
- [Error Handling](../error-handling.md) - Error scenarios
- [Testing Strategy](../testing-strategy.md) - Testing patterns
