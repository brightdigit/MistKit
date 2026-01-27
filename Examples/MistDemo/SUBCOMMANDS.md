# MistDemo Subcommand System Architecture

## Overview
MistDemo CLI tool with subcommands mapping directly to CloudKit Web Services operations. Each subcommand represents a single CloudKit operation with its own configuration options.

## Global Options
All subcommands accept these global options:
- `--container-id` / `-c` - CloudKit container identifier (env: `CLOUDKIT_CONTAINER_ID`)
- `--api-token` / `-a` - CloudKit API token (env: `CLOUDKIT_API_TOKEN`)
- `--environment` / `-e` - CloudKit environment: development|production (env: `CLOUDKIT_ENVIRONMENT`)
- `--database` / `-d` - Database type: public|private|shared (env: `CLOUDKIT_DATABASE`)
- `--web-auth-token` - Web authentication token for private/shared databases (env: `CLOUDKIT_WEBAUTH_TOKEN`)
- `--key-id` - Server-to-server key ID (env: `CLOUDKIT_KEY_ID`)
- `--private-key-file` - Path to server-to-server private key (env: `CLOUDKIT_PRIVATE_KEY_FILE`)
- `--output` / `-o` - Output format: json|table|csv|yaml (default: json)
- `--pretty` - Pretty print output (default: false)
- `--config-file` - Path to configuration file (JSON/YAML)
- `--profile` - Named configuration profile to use
- `--verbose` / `-v` - Verbose output with debug information
- `--no-redaction` - Disable log redaction for debugging

## Record Operations

MistDemo works with the `Note` record type defined in `schema.ckdb`. This record type has the following fields:
- `title` (STRING) - Queryable, sortable, searchable
- `index` (INT64) - Queryable, sortable
- `image` (ASSET) - Optional asset reference
- `createdAt` (TIMESTAMP) - Queryable, sortable
- `modified` (INT64) - Queryable

### `mistdemo query`
Query Note records from CloudKit with filtering and sorting.

```bash
mistdemo query [options]
```

**Options:**
- `--zone` - Zone name (default: _defaultZone)
- `--filter` - Query filter expression (can be repeated)
- `--sort` - Sort field and direction (e.g., "createdAt:desc")
- `--limit` - Maximum records to return (1-200, default: 20)
- `--offset` - Pagination offset
- `--fields` - Comma-separated list of fields to return
- `--continuation-marker` - Pagination continuation marker

**Examples:**
```bash
# Query all Note records
mistdemo query

# Query with filters
mistdemo query \
  --filter "title CONTAINS 'test'" \
  --filter "index > 10" \
  --sort "createdAt:desc" \
  --limit 50

# Query specific fields only
mistdemo query --fields "title,index,createdAt"

# Sort by index
mistdemo query --sort "index:asc"
```

### `mistdemo create`
Create a new Note record in CloudKit.

```bash
mistdemo create [options]
```

**Options:**
- `--zone` - Zone name (default: _defaultZone)
- `--record-name` - Custom record name (optional, auto-generated if not provided)
- `--field` / `-f` - Field in format "name:type:value" (can be repeated)
- `--json-file` - Path to JSON file containing record data
- `--stdin` - Read record data from stdin

**Field Types:**
- `string` - Text value (for `title`)
- `int64` - Integer value (for `index`, `modified`)
- `timestamp` - ISO8601 date string (for `createdAt`)
- `asset` - Asset reference (for `image`)

**Examples:**
```bash
# Create a simple record
mistdemo create \
  --field "title:string:My Note" \
  --field "index:int64:1" \
  --field "modified:int64:0"

# Create with custom record name and all fields
mistdemo create \
  --record-name "note_001" \
  --field "title:string:Getting Started with CloudKit" \
  --field "index:int64:42" \
  --field "createdAt:timestamp:2024-01-01T00:00:00Z" \
  --field "modified:int64:0"

# Create from JSON file
mistdemo create --json-file testitem.json

# Create from stdin
echo '{"title": {"value": "Test"}, "index": {"value": 1}}' | mistdemo create --stdin
```

### `mistdemo update`
Update an existing Note record in CloudKit.

```bash
mistdemo update <record-name> [options]
```

**Options:**
- `--zone` - Zone name (default: _defaultZone)
- `--field` / `-f` - Field to update in format "name:type:value"
- `--change-tag` - Record change tag for optimistic locking
- `--force` - Force update, ignoring conflicts
- `--json-file` - Path to JSON file containing updates
- `--stdin` - Read updates from stdin

**Examples:**
```bash
# Update a single field
mistdemo update note_001 \
  --field "title:string:Updated Title"

# Update multiple fields with change tag
mistdemo update note_001 \
  --field "title:string:Updated Title" \
  --field "index:int64:100" \
  --field "modified:int64:1" \
  --change-tag "abc123"

# Force update from JSON
mistdemo update note_001 --json-file updates.json --force
```

### `mistdemo delete`
Delete a Note record from CloudKit.

```bash
mistdemo delete <record-name> [options]
```

**Options:**
- `--zone` - Zone name (default: _defaultZone)
- `--change-tag` - Record change tag for optimistic locking
- `--force` - Force delete, ignoring conflicts

**Examples:**
```bash
# Delete a record
mistdemo delete note_001

# Delete with change tag
mistdemo delete note_old --change-tag "xyz789"

# Force delete
mistdemo delete temp_note --force
```

### `mistdemo lookup`
Lookup specific Note records by their record names.

```bash
mistdemo lookup <record-names...> [options]
```

**Options:**
- `--zone` - Zone name (default: _defaultZone)
- `--fields` - Comma-separated list of fields to return

**Examples:**
```bash
# Lookup a single record
mistdemo lookup note_001

# Lookup multiple records
mistdemo lookup note_001 note_002 note_003

# Lookup with specific fields
mistdemo lookup note_001 --fields "title,index,createdAt"
```

### `mistdemo modify`
Perform batch operations (create, update, delete) in a single request.

```bash
mistdemo modify --operations-file <file> [options]
```

**Options:**
- `--operations-file` / `-f` - Path to JSON file with operations
- `--atomic` - Make all operations atomic (all succeed or all fail)
- `--stdin` - Read operations from stdin

**Operations File Format:**
```json
{
  "operations": [
    {
      "type": "create",
      "recordType": "Note",
      "fields": {
        "title": {"value": "New Note"},
        "index": {"value": 1},
        "modified": {"value": 0}
      }
    },
    {
      "type": "update",
      "recordType": "Note",
      "recordName": "note_001",
      "fields": {
        "title": {"value": "Updated Title"},
        "modified": {"value": 1}
      }
    },
    {
      "type": "delete",
      "recordType": "Note",
      "recordName": "note_old"
    }
  ]
}
```

**Examples:**
```bash
# Batch modify from file
mistdemo modify --operations-file batch.json

# Atomic batch operations
mistdemo modify --operations-file updates.json --atomic

# Pipe operations from another command
generate-operations | mistdemo modify --stdin
```

## User Operations

### `mistdemo current-user`
Get information about the currently authenticated user.

```bash
mistdemo current-user [options]
```

**Options:**
- `--fields` - Specific user fields to retrieve

**Examples:**
```bash
# Get current user info
mistdemo current-user

# Get specific fields
mistdemo current-user --fields "userRecordName,firstName,lastName"
```

### `mistdemo discover`
Discover user identities by email or phone.

```bash
mistdemo discover <lookup-type> <values...> [options]
```

**Lookup Types:**
- `email` - Lookup by email addresses
- `phone` - Lookup by phone numbers
- `record` - Lookup by user record names

**Examples:**
```bash
# Discover by email
mistdemo discover email user@example.com

# Discover multiple emails
mistdemo discover email user1@example.com user2@example.com

# Discover by phone
mistdemo discover phone "+1234567890"

# Discover by user record names
mistdemo discover record _abc123 _def456
```

### `mistdemo lookup-contacts`
Lookup user contacts (requires contacts permission).

```bash
mistdemo lookup-contacts [options]
```

**Options:**
- `--email` - Email addresses to lookup (can be repeated)
- `--phone` - Phone numbers to lookup (can be repeated)

**Examples:**
```bash
# Lookup contacts by email
mistdemo lookup-contacts --email user@example.com

# Lookup multiple contacts
mistdemo lookup-contacts \
  --email user1@example.com \
  --email user2@example.com \
  --phone "+1234567890"
```

## Zone Operations

### `mistdemo list-zones`
List all zones in the database.

```bash
mistdemo list-zones [options]
```

**Options:**
- `--include-default` - Include the default zone in results

**Examples:**
```bash
# List all zones
mistdemo list-zones

# List including default zone
mistdemo list-zones --include-default
```

### `mistdemo lookup-zones`
Lookup specific zones by name.

```bash
mistdemo lookup-zones <zone-names...> [options]
```

**Examples:**
```bash
# Lookup a single zone
mistdemo lookup-zones CustomZone1

# Lookup multiple zones
mistdemo lookup-zones CustomZone1 CustomZone2 SharedZone
```

### `mistdemo modify-zones`
Create, update, or delete zones.

```bash
mistdemo modify-zones --operations-file <file> [options]
```

**Options:**
- `--operations-file` / `-f` - Path to JSON file with zone operations
- `--stdin` - Read operations from stdin

**Operations File Format:**
```json
{
  "operations": [
    {
      "type": "create",
      "zoneName": "CustomZone1"
    },
    {
      "type": "delete",
      "zoneName": "OldZone"
    }
  ]
}
```

## Authentication Operations

### `mistdemo auth-token`
Obtain a web authentication token by signing in with Apple ID. Outputs the token to stdout.

**Requires:** `--api-token` or `CLOUDKIT_API_TOKEN` environment variable

```bash
mistdemo auth-token [options]
```

**Options:**
- `--port` / `-p` - Local server port (default: 8080)
- `--host` - Local server host (default: 127.0.0.1)
- `--no-browser` - Don't open browser automatically
- `--api-token` / `-a` - CloudKit API token (required, or set `CLOUDKIT_API_TOKEN`)

**Examples:**
```bash
# Get web auth token (outputs to stdout)
mistdemo auth-token --api-token YOUR_API_TOKEN

# Save token to environment variable
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token --api-token YOUR_API_TOKEN)

# Save token to file
mistdemo auth-token --api-token YOUR_API_TOKEN > ~/.mistdemo/token.txt

# Custom port
mistdemo auth-token --api-token YOUR_API_TOKEN --port 3000

# Don't open browser automatically
mistdemo auth-token --api-token YOUR_API_TOKEN --no-browser
```

**Note:** The token is output to stdout. You can redirect it to a file, set it as an environment variable, or use it directly in scripts. The token is required for accessing private or shared databases.

### `mistdemo validate`
Validate current authentication credentials.

```bash
mistdemo validate [options]
```

**Options:**
- `--test-query` - Perform a test query to validate

**Examples:**
```bash
# Validate credentials
mistdemo validate

# Validate with test query
mistdemo validate --test-query
```

## Configuration Management

### Configuration Files
MistDemo supports JSON and YAML configuration files using Swift Configuration package:
- **JSON**: Uses `JSONSnapshot` (default trait, included automatically)
- **YAML**: Uses `YAMLSnapshot` (requires `"YAML"` trait)
- **Environment Variables**: Uses `EnvironmentVariablesProvider` (core functionality, no trait needed)
- **Command Line Arguments**: Uses `CommandLineArgumentsProvider` (requires `"CommandLineArguments"` trait)

Add the dependency to your `Package.swift`:
```swift
.package(
    url: "https://github.com/apple/swift-configuration",
    from: "1.0.0",
    traits: [.defaults, "CommandLineArguments", "YAML"]  // JSON (default) + CommandLineArguments + YAML support
)
```

**config.json:**
```json
{
  "container_id": "iCloud.com.example.MyApp",
  "api_token": "your-api-token",
  "environment": "development",
  "database": "private",
  "output": "table",
  "profiles": {
    "production": {
      "environment": "production",
      "database": "public"
    },
    "testing": {
      "environment": "development",
      "container_id": "iCloud.com.example.MyApp.Testing"
    }
  }
}
```

**config.yaml:**
```yaml
container_id: iCloud.com.example.MyApp
api_token: your-api-token
environment: development
database: private
output: table

profiles:
  production:
    environment: production
    database: public
  testing:
    environment: development
    container_id: iCloud.com.example.MyApp.Testing
```

### Using Profiles
```bash
# Use production profile
mistdemo query --profile production

# Use testing profile with override
mistdemo create --profile testing --database private
```

### Environment Variables
All configuration can be set via environment variables:
```bash
export CLOUDKIT_CONTAINER_ID="iCloud.com.example.MyApp"
export CLOUDKIT_API_TOKEN="your-api-token"
export CLOUDKIT_ENVIRONMENT="development"
export CLOUDKIT_DATABASE="private"
export CLOUDKIT_WEBAUTH_TOKEN="web-auth-token"
export MISTDEMO_OUTPUT="table"
export MISTDEMO_CONFIG_FILE="~/.mistdemo/config.json"
export MISTDEMO_PROFILE="production"
```

## Output Formats

### JSON (default)
```json
{
  "records": [
    {
      "recordName": "note_001",
      "recordType": "Note",
      "fields": {
        "title": {"value": "My Note"},
        "index": {"value": 1},
        "createdAt": {"value": "2024-01-01T00:00:00Z"},
        "modified": {"value": 0}
      }
    }
  ]
}
```

### Table
```
┌───────────────┬──────────┬──────────────┬───────┐
│ Record Name   │ Type     │ Title        │ Index │
├───────────────┼──────────┼──────────────┼───────┤
│ note_001      │ Note     │ My Note      │ 1     │
└───────────────┴──────────┴──────────────┴───────┘
```

### CSV
```csv
record_name,record_type,title,index
note_001,Note,My Note,1
```

### YAML
```yaml
records:
  - recordName: note_001
    recordType: Note
    fields:
      title:
        value: My Note
      index:
        value: 1
```

## ConfigKeyKit Extension Strategy

ConfigKeyKit will be extended to support subcommand-specific configurations:

### 1. Hierarchical Configuration Keys
```swift
// Base configuration
struct MistDemoConfig: ConfigurationSet {
    @ConfigKey("container.id", env: "CLOUDKIT_CONTAINER_ID")
    var containerID: String
    
    @ConfigKey("api.token", env: "CLOUDKIT_API_TOKEN", secret: true)
    var apiToken: String
    
    @ConfigKey("environment", env: "CLOUDKIT_ENVIRONMENT", default: "development")
    var environment: String
    
    @ConfigKey("database", env: "CLOUDKIT_DATABASE", default: "public")
    var database: String
}

// Subcommand-specific configuration
struct QueryConfig: ConfigurationSet {
    @ConfigKey("query.limit", env: "MISTDEMO_QUERY_LIMIT", default: 20)
    var limit: Int
    
    @ConfigKey("query.zone", env: "MISTDEMO_QUERY_ZONE", default: "_defaultZone")
    var zone: String
    
    @OptionalConfigKey("query.fields", env: "MISTDEMO_QUERY_FIELDS")
    var fields: String?
    
    @ConfigKey("query.sort.field", env: "MISTDEMO_QUERY_SORT_FIELD")
    var sortField: String?
    
    @ConfigKey("query.sort.order", env: "MISTDEMO_QUERY_SORT_ORDER", default: "asc")
    var sortOrder: String
}
```

### 2. Command-Specific Configuration Loading
```swift
protocol Command {
    associatedtype Config: ConfigurationSet
    
    var config: Config { get }
    func execute() async throws
}

struct QueryCommand: Command {
    let config: QueryConfig
    
    init() {
        // Load base config and merge with query-specific config
        let baseConfig = MistDemoConfig()
        self.config = QueryConfig(parent: baseConfig)
    }
}
```

### 3. Configuration Profiles
```swift
extension ConfigKeyKit {
    struct Profile {
        let name: String
        let overrides: [String: Any]
        
        func apply<T: ConfigurationSet>(to config: T) -> T {
            // Apply profile overrides to configuration
        }
    }
    
    static func loadProfile(named: String, from file: URL) -> Profile {
        // Load profile from JSON/YAML file
    }
}
```

### 4. Dynamic Configuration Resolution
```swift
extension ConfigKey {
    // Support for subcommand namespacing
    init(_ key: String, 
         subcommand: String? = nil,
         env: String? = nil,
         default: Value? = nil) {
        let fullKey = subcommand.map { "\($0).\(key)" } ?? key
        // Initialize with namespaced key
    }
}

// Usage
struct CreateConfig: ConfigurationSet {
    @ConfigKey("zone", subcommand: "create", env: "MISTDEMO_CREATE_ZONE")
    var zone: String
}
```

### 5. Configuration File Support
```swift
import Configuration

extension ConfigurationSet {
    static func load(from file: URL) throws -> Self {
        let provider: ConfigurationProvider
        
        switch file.pathExtension {
        case "json":
            // Uses JSONSnapshot (default trait, included automatically)
            let snapshot = try JSONSnapshot(
                data: try Data(contentsOf: file),
                providerName: "config-file",
                parsingOptions: []
            )
            provider = FileProvider(snapshot: snapshot, filePath: file.path)
        case "yaml", "yml":
            // Uses YAMLSnapshot (requires "YAML" trait enabled)
            let snapshot = try YAMLSnapshot(
                data: try Data(contentsOf: file),
                providerName: "config-file",
                parsingOptions: []
            )
            provider = FileProvider(snapshot: snapshot, filePath: file.path)
        default:
            throw ConfigError.unsupportedFormat
        }
        
        let reader = ConfigReader(provider: provider)
        // Read configuration values using reader
        // Example: reader.string(forKey: "container_id")
        // ...
    }
}

// Environment variables (no trait needed)
let envProvider = EnvironmentVariablesProvider()
let envConfig = ConfigReader(provider: envProvider)

// Command line arguments (requires "CommandLineArguments" trait)
let cliProvider = CommandLineArgumentsProvider()
let cliConfig = ConfigReader(provider: cliProvider)
```

## Implementation Priority

1. **Phase 1 - Core Infrastructure**
   - Command protocol and router
   - ConfigKeyKit extensions
   - Output formatters

2. **Phase 2 - Essential Commands**
   - `query` - Most commonly used operation
   - `create` - Basic record creation
   - `current-user` - Authentication verification
   - `auth-token` - Obtain web authentication token

3. **Phase 3 - CRUD Operations**
   - `update` - Record updates
   - `delete` - Record deletion
   - `lookup` - Batch record lookup
   - `modify` - Batch operations

4. **Phase 4 - Advanced Operations**
   - `list-zones` - Zone management
   - `discover` - User discovery
   - `lookup-contacts` - Contact lookup
   - Configuration profiles and file support

## Testing Strategy

Each subcommand should have:
1. Unit tests for command parsing and configuration
2. Integration tests with mock CloudKit responses
3. End-to-end tests with real CloudKit (in CI)
4. Example scripts demonstrating common use cases

## Error Handling

Consistent error reporting across all subcommands:
```
Error: CloudKit operation failed
  Operation: query
  Record Type: Note
  Status: 400 Bad Request
  Reason: Invalid filter expression
  Details: Unknown field 'invalidField' in filter. Valid fields: title, index, createdAt, modified, image

Try 'mistdemo query --help' for more information.
```

## Help System

Each subcommand provides comprehensive help:
```bash
mistdemo --help              # General help
mistdemo query --help         # Query command help
mistdemo create --help        # Create command help
mistdemo --version           # Version information
```