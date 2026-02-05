# MistDemo Documentation

Comprehensive documentation for the MistDemo CLI tool - a demonstration command-line interface for CloudKit Web Services using MistKit.

## Quick Navigation

### Core Documentation

- **[Overview](overview.md)** - Architecture, global options, schema reference, and help system
- **[Configuration](configuration.md)** - Configuration files, profiles, and environment variables
- **[Output Formats](output-formats.md)** - JSON, Table, CSV, and YAML output formats

### Operations Reference

- **[Record Operations](operations-record.md)** - query, create, update, delete, lookup, modify
- **[User Operations](operations-user.md)** - current-user, discover, lookup-contacts
- **[Zone Operations](operations-zone.md)** - list-zones, lookup-zones, modify-zones
- **[Authentication Operations](operations-auth.md)** - auth-token, validate

### Development & Implementation

- **[ConfigKeyKit Strategy](configkeykit-strategy.md)** - Configuration architecture and patterns
- **[Testing Strategy](testing-strategy.md)** - Unit, integration, and E2E testing approach
- **[Error Handling](error-handling.md)** - Error reporting format and recovery

### Implementation Phases

Ready-to-use specifications for GitHub issues:

- **[Phase 1: Core Infrastructure](phases/phase-1-core-infrastructure.md)** - Command protocol, ConfigKeyKit, output formatters
- **[Phase 2: Essential Commands](phases/phase-2-essential-commands.md)** - query, create, current-user, auth-token
- **[Phase 3: CRUD Operations](phases/phase-3-crud-operations.md)** - update, delete, lookup, modify
- **[Phase 4: Advanced Operations](phases/phase-4-advanced-operations.md)** - Zone management, user discovery, profiles

## What is MistDemo?

MistDemo is a command-line tool that demonstrates MistKit's capabilities by providing direct access to CloudKit Web Services operations. It features:

- **Subcommand Architecture**: Each CloudKit operation is a dedicated subcommand
- **Flexible Configuration**: Support for config files, profiles, and environment variables
- **Multiple Output Formats**: JSON, Table, CSV, and YAML
- **Schema-Driven**: Works with the `Note` record type defined in `schema.ckdb`
- **Modern Swift**: Built with async/await, Swift Concurrency, and Swift Configuration

## When to Consult Each Document

### Starting a New Feature?
1. **First**, check the relevant operations doc (record/user/zone/auth)
2. **Then**, review [ConfigKeyKit Strategy](configkeykit-strategy.md) for configuration patterns
3. **Finally**, consult [Testing Strategy](testing-strategy.md) for test requirements

### Implementing Configuration?
1. **Start** with [Configuration](configuration.md) for file formats and profiles
2. **Then** see [ConfigKeyKit Strategy](configkeykit-strategy.md) for code patterns

### Working on Output?
- See [Output Formats](output-formats.md) for format specifications and examples

### Debugging or Error Handling?
- Consult [Error Handling](error-handling.md) for consistent error reporting patterns

### Planning Work?
- Use the [Implementation Phases](#implementation-phases) documents as issue templates

## Quick Reference

### Global Options (All Commands)
```bash
--container-id, -c       # CloudKit container identifier
--api-token, -a          # CloudKit API token
--environment, -e        # development|production
--database, -d           # public|private|shared
--output, -o             # json|table|csv|yaml
--config-file            # Path to config file
--profile                # Named configuration profile
--verbose, -v            # Verbose output
```

### Most Common Commands
```bash
# Query records
mistdemo query --filter "title CONTAINS 'test'" --sort "createdAt:desc"

# Create a record
mistdemo create --field "title:string:My Note" --field "index:int64:1"

# Get web auth token
mistdemo auth-token --api-token YOUR_API_TOKEN

# Verify authentication
mistdemo current-user
```

### Configuration Priority
1. Command-line arguments (highest priority)
2. Profile-specific settings
3. Configuration file defaults
4. Environment variables
5. Built-in defaults (lowest priority)

## Record Type Schema

MistDemo works with the `Note` record type:

| Field | Type | Queryable | Sortable | Description |
|-------|------|-----------|----------|-------------|
| `title` | STRING | ✓ | ✓ | Note title (searchable) |
| `index` | INT64 | ✓ | ✓ | Numeric index |
| `image` | ASSET | | | Optional image asset |
| `createdAt` | TIMESTAMP | ✓ | ✓ | Creation timestamp |
| `modified` | INT64 | ✓ | | Modification counter |

## Related Documentation

- **[MistKit OpenAPI Spec](../../../openapi.yaml)** - CloudKit Web Services API specification
- **[CloudKit Web Services](../webservices.md)** - REST API reference
- **[Swift Configuration Guide](https://github.com/apple/swift-configuration)** - Configuration package docs
- **[Schema Reference](../cloudkit-schema-reference.md)** - CloudKit schema language

## File Organization

```
.claude/docs/mistdemo/
├── README.md                      # This file
├── overview.md                    # Architecture & global options
├── operations-record.md           # Record operations
├── operations-user.md             # User operations
├── operations-zone.md             # Zone operations
├── operations-auth.md             # Auth operations
├── configuration.md               # Configuration management
├── output-formats.md              # Output format reference
├── configkeykit-strategy.md       # ConfigKeyKit extensions
├── testing-strategy.md            # Testing approach
├── error-handling.md              # Error handling
└── phases/
    ├── phase-1-core-infrastructure.md
    ├── phase-2-essential-commands.md
    ├── phase-3-crud-operations.md
    └── phase-4-advanced-operations.md
```
