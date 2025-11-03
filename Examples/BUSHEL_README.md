# Bushel - CloudKit Version History Tool

A command-line tool for managing software version history using CloudKit, powered by MistKit.

## Features

- Add new versions with semantic versioning support
- List versions with filtering options
- Show detailed version information
- Update existing version records
- Delete versions from CloudKit
- Configuration file and environment variable support
- JSON and YAML configuration formats

## Installation

```bash
cd Examples
swift build -c release --product Bushel
```

The compiled binary will be at `.build/release/Bushel`.

## Configuration

Bushel can be configured using environment variables or a JSON configuration file.

### Environment Variables

```bash
export CLOUDKIT_CONTAINER_ID="iCloud.com.example.app"
export CLOUDKIT_ENVIRONMENT="development"  # or "production"
export CLOUDKIT_DATABASE="private"         # or "public" or "shared"
export CLOUDKIT_API_TOKEN="your-api-token"
# OR
export CLOUDKIT_SERVER_KEY="your-server-key"
```

### Configuration File

Create a `bushel-config.json` file:

```json
{
  "containerIdentifier": "iCloud.com.example.app",
  "environment": "development",
  "database": "private",
  "apiToken": "your-api-token-here",
  "serverToServerKey": null
}
```

Use with: `bushel --config bushel-config.json <command>`

## Usage

### Add a Version

```bash
# Add a new version
bushel add --version 1.2.3 --notes "Bug fixes and improvements"

# Add with build number and commit
bushel add --version 2.0.0 \
  --notes "Major release with new features" \
  --build-number 42 \
  --commit-hash abc123

# Add as draft
bushel add --version 2.1.0-beta.1 \
  --notes "Beta release for testing" \
  --status draft
```

### List Versions

```bash
# List all released versions
bushel list

# List with specific status
bushel list --status draft
bushel list --status deprecated

# Include prerelease versions
bushel list --include-prerelease
```

### Show Version Details

```bash
# Show details for a specific version
bushel show 1.2.3
```

### Update a Version

```bash
# Update release notes
bushel update 1.2.3 --notes "Updated release notes"

# Change status
bushel update 1.2.3 --status deprecated

# Update build number
bushel update 1.2.3 --build-number 43
```

### Delete a Version

```bash
# Delete with confirmation prompt
bushel delete 1.2.3

# Force delete without confirmation
bushel delete 1.2.3 --force
```

## CloudKit Schema Setup

Before using Bushel, you need to set up the CloudKit schema. See [BUSHEL_SCHEMA.md](BUSHEL_SCHEMA.md) for detailed instructions on:

1. Creating the `Version` record type in CloudKit Dashboard
2. Adding and configuring all required fields
3. Setting up indexes for efficient querying
4. Configuring security and permissions

## Semantic Versioning

Bushel follows [Semantic Versioning 2.0.0](https://semver.org/):

- **Format**: `MAJOR.MINOR.PATCH[-PRERELEASE]`
- **Example**: `1.2.3`, `2.0.0-beta.1`, `1.0.0-rc.2`

Components:
- **MAJOR**: Incompatible API changes
- **MINOR**: Backwards-compatible functionality
- **PATCH**: Backwards-compatible bug fixes
- **PRERELEASE**: Optional (e.g., alpha, beta, rc.1)

## Architecture

Bushel is built using:

- **MistKit**: CloudKit Web Services client
- **ArgumentParser**: Command-line interface
- **Swift Concurrency**: Async/await throughout
- **Sendable Types**: Thread-safe by design

### Project Structure

```
Bushel/
├── Bushel.swift              # Main CLI entry point
├── Commands/                 # Command implementations
│   ├── Add.swift
│   ├── List.swift
│   ├── Show.swift
│   ├── Update.swift
│   └── Delete.swift
├── Models/                   # Data models
│   ├── Version.swift
│   └── VersionParser.swift
└── Configuration/            # Configuration management
    └── BushelConfiguration.swift
```

## Development

### Building

```bash
cd Examples
swift build --target Bushel
```

### Running Tests

```bash
cd Examples
swift test --filter BushelTests
```

### Code Style

The project follows:
- SwiftLint rules from parent project
- Type contents order: lifecycle, public types, properties, methods
- Explicit ACLs on all declarations
- Sendable conformance for all public types

## Troubleshooting

### Missing Container Identifier

**Error**: `Missing CloudKit container identifier`

**Solution**: Set `CLOUDKIT_CONTAINER_ID` environment variable or provide a config file.

### Authentication Errors

**Error**: `Missing authentication`

**Solution**: Provide either `CLOUDKIT_API_TOKEN` or `CLOUDKIT_SERVER_KEY`.

### Invalid Version Format

**Error**: Version parsing fails

**Solution**: Ensure version follows semantic versioning format: `X.Y.Z` or `X.Y.Z-prerelease`

## Examples

### Complete Workflow

```bash
# 1. Configure environment
export CLOUDKIT_CONTAINER_ID="iCloud.com.example.app"
export CLOUDKIT_API_TOKEN="your-token"

# 2. Add a new release
bushel add --version 1.0.0 --notes "Initial release"

# 3. List all versions
bushel list

# 4. Show specific version
bushel show 1.0.0

# 5. Add a beta version
bushel add --version 1.1.0-beta.1 \
  --notes "Beta testing" \
  --status draft

# 6. Update and release
bushel update 1.1.0-beta.1 --status released

# 7. Deprecate old version
bushel update 1.0.0 --status deprecated
```

## License

See [LICENSE](../LICENSE) in the parent repository.

## Contributing

Contributions welcome! Please follow the code style and include tests for new features.
