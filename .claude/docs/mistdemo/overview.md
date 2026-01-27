# MistDemo Overview

## Architecture

MistDemo is a CLI tool with a subcommand architecture where each CloudKit Web Services operation maps to a dedicated subcommand. The tool demonstrates MistKit's capabilities while providing a practical interface for CloudKit operations.

### Key Design Principles

1. **One Operation, One Subcommand**: Each CloudKit operation (query, create, update, etc.) is a separate subcommand
2. **Consistent Interface**: All subcommands share common global options
3. **Flexible Configuration**: Support for config files, profiles, environment variables, and CLI arguments
4. **Modern Swift**: Built with async/await, Swift Concurrency, and Swift Configuration package
5. **Schema-Driven**: Works with a well-defined `Note` record type

### URL Pattern

All CloudKit Web Services operations follow this pattern:
```
https://api.apple-cloudkit.com/database/{version}/{container}/{environment}/{database}/{operation}
```

Where:
- `version`: API version (e.g., `1`)
- `container`: Container identifier (e.g., `iCloud.com.example.MyApp`)
- `environment`: `development` or `production`
- `database`: `public`, `private`, or `shared`
- `operation`: CloudKit operation (e.g., `records/query`, `zones/list`)

## Global Options

All subcommands accept these global options:

### Required Options

| Option | Short | Environment Variable | Description |
|--------|-------|---------------------|-------------|
| `--container-id` | `-c` | `CLOUDKIT_CONTAINER_ID` | CloudKit container identifier |
| `--api-token` | `-a` | `CLOUDKIT_API_TOKEN` | CloudKit API token |

### Database & Environment

| Option | Short | Environment Variable | Default | Description |
|--------|-------|---------------------|---------|-------------|
| `--environment` | `-e` | `CLOUDKIT_ENVIRONMENT` | `development` | CloudKit environment |
| `--database` | `-d` | `CLOUDKIT_DATABASE` | `public` | Database type |

Valid values:
- **Environment**: `development`, `production`
- **Database**: `public`, `private`, `shared`

### Authentication Options

| Option | Environment Variable | Description |
|--------|---------------------|-------------|
| `--web-auth-token` | `CLOUDKIT_WEBAUTH_TOKEN` | Web authentication token (required for private/shared databases) |
| `--key-id` | `CLOUDKIT_KEY_ID` | Server-to-server key ID |
| `--private-key-file` | `CLOUDKIT_PRIVATE_KEY_FILE` | Path to server-to-server private key |

### Output Options

| Option | Short | Environment Variable | Default | Description |
|--------|-------|---------------------|---------|-------------|
| `--output` | `-o` | `MISTDEMO_OUTPUT` | `json` | Output format |
| `--pretty` | | | `false` | Pretty print output |

Valid output formats: `json`, `table`, `csv`, `yaml`

### Configuration Options

| Option | Environment Variable | Description |
|--------|---------------------|-------------|
| `--config-file` | `MISTDEMO_CONFIG_FILE` | Path to configuration file (JSON/YAML) |
| `--profile` | `MISTDEMO_PROFILE` | Named configuration profile to use |

### Debugging Options

| Option | Short | Description |
|--------|-------|-------------|
| `--verbose` | `-v` | Verbose output with debug information |
| `--no-redaction` | | Disable log redaction for debugging |

## Authentication Overview

MistDemo supports two authentication methods:

### 1. Web Auth Token (User Authentication)
Required for accessing private or shared databases.

```bash
# Obtain token
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token --api-token YOUR_API_TOKEN)

# Use token in commands
mistdemo query --database private
```

See [Authentication Operations](operations-auth.md) for details.

### 2. Server-to-Server Key (Server Authentication)
For server-side applications using key-based authentication.

```bash
mistdemo query \
  --key-id YOUR_KEY_ID \
  --private-key-file path/to/key.pem
```

## Note Record Type Schema

MistDemo works exclusively with the `Note` record type defined in `Examples/MistDemo/schema.ckdb`.

### Field Specifications

| Field | Type | Queryable | Sortable | Searchable | Description |
|-------|------|-----------|----------|------------|-------------|
| `title` | STRING | ✓ | ✓ | ✓ | Note title text |
| `index` | INT64 | ✓ | ✓ | | Numeric index/ordering |
| `image` | ASSET | | | | Optional image asset reference |
| `createdAt` | TIMESTAMP | ✓ | ✓ | | Creation timestamp |
| `modified` | INT64 | ✓ | | | Modification counter |

### System Fields

All CloudKit records include these system fields:
- `recordName` - Unique record identifier
- `recordType` - Always "Note" for this schema
- `recordChangeTag` - Version tag for optimistic locking
- `created` - System creation timestamp
- `modified` - System modification timestamp

### Field Type Mapping

When using `--field` options:

| Schema Type | CLI Type | Example Value |
|-------------|----------|---------------|
| STRING | `string` | `"My Note Title"` |
| INT64 | `int64` | `42` |
| TIMESTAMP | `timestamp` | `"2024-01-01T00:00:00Z"` |
| ASSET | `asset` | Asset reference (special handling) |

Example:
```bash
mistdemo create \
  --field "title:string:Getting Started" \
  --field "index:int64:1" \
  --field "createdAt:timestamp:2024-01-01T00:00:00Z" \
  --field "modified:int64:0"
```

## Help System

MistDemo provides comprehensive help at multiple levels:

### General Help
```bash
mistdemo --help              # Overview and subcommand list
mistdemo --version           # Version information
```

### Subcommand Help
```bash
mistdemo query --help        # Query command help
mistdemo create --help       # Create command help
mistdemo auth-token --help   # Auth token help
# ... and so on for all subcommands
```

### Help Output Format
Each help message includes:
1. Brief command description
2. Usage syntax
3. Available options with descriptions
4. Environment variable equivalents
5. Examples demonstrating common use cases

## Configuration Priority

Settings are resolved in this order (highest to lowest priority):

1. **Command-line arguments** - Explicit CLI flags
2. **Profile settings** - From `--profile` in config file
3. **Configuration file** - Default values in config file
4. **Environment variables** - System environment
5. **Built-in defaults** - Hardcoded defaults

Example:
```bash
# config.json has: "database": "public"
# Environment has: CLOUDKIT_DATABASE=private
# Command specifies: --database shared

# Result: Uses "shared" (CLI argument wins)
```

See [Configuration](configuration.md) for detailed priority rules.

## Common Patterns

### Query Records
```bash
mistdemo query \
  --filter "title CONTAINS 'test'" \
  --sort "createdAt:desc" \
  --limit 50
```

### Create Record
```bash
mistdemo create \
  --field "title:string:My First Note" \
  --field "index:int64:1"
```

### Authenticated Operations
```bash
# Get auth token first
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token -a YOUR_API_TOKEN)

# Use private database
mistdemo query --database private
```

### Using Configuration Profiles
```bash
# config.json contains "production" profile
mistdemo query --profile production --output table
```

### Batch Operations
```bash
# Create operations file
cat > batch.json <<EOF
{
  "operations": [
    {"type": "create", "recordType": "Note", "fields": {...}},
    {"type": "update", "recordType": "Note", "recordName": "note_001", "fields": {...}},
    {"type": "delete", "recordType": "Note", "recordName": "note_002"}
  ]
}
EOF

# Execute batch
mistdemo modify --operations-file batch.json --atomic
```

## Related Documentation

- **[Record Operations](operations-record.md)** - Detailed record operation commands
- **[User Operations](operations-user.md)** - User and identity operations
- **[Zone Operations](operations-zone.md)** - Zone management commands
- **[Authentication Operations](operations-auth.md)** - Authentication workflows
- **[Configuration](configuration.md)** - Configuration management
- **[Output Formats](output-formats.md)** - Output format specifications
- **[Error Handling](error-handling.md)** - Error reporting and recovery
