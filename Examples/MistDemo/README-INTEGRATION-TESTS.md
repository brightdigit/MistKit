# MistDemo Integration Tests - Issue #199

This document describes the comprehensive integration test suite for the three new CloudKit operations added in issue #199: `lookupZones`, `fetchRecordChanges`, and `uploadAssets`.

## Overview

MistDemo has been enhanced with a proper CLI subcommand architecture and comprehensive integration tests that demonstrate all three new operations working together in realistic workflows.

## Available Commands

```bash
# Show all available subcommands
mistdemo --help

# Get help for a specific command
mistdemo test-integration --help
mistdemo upload-asset --help
mistdemo lookup-zones --help
mistdemo fetch-changes --help
```

## Quick Start

### 1. Deploy CloudKit Schema (One-Time Setup)

Before running integration tests, deploy the schema to CloudKit:

```bash
# Save your CloudKit management token
xcrun cktool save-token

# Import the schema to development environment
xcrun cktool import-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.brightdigit.MistDemo \
  --environment development \
  --file schema.ckdb
```

### 2. Run Integration Tests

```bash
# Basic integration test
swift run mistdemo test-integration --api-token YOUR_TOKEN

# Verbose mode with more records
swift run mistdemo test-integration \
  --api-token YOUR_TOKEN \
  --record-count 20 \
  --verbose

# Skip cleanup to inspect records in CloudKit Console
swift run mistdemo test-integration \
  --api-token YOUR_TOKEN \
  --skip-cleanup
```

## Individual Operation Commands

### Upload Asset

Upload a binary file to CloudKit:

```bash
# Upload a file
swift run mistdemo upload-asset photo.jpg --api-token YOUR_TOKEN

# Upload and create a record
swift run mistdemo upload-asset document.pdf \
  --create-record Document \
  --api-token YOUR_TOKEN
```

**Features:**
- Validates file existence
- Displays upload progress
- Returns asset tokens
- Optionally creates a record with the asset

### Lookup Zones

Fetch detailed information about specific zones:

```bash
# Lookup default zone
swift run mistdemo lookup-zones "_defaultZone" --api-token YOUR_TOKEN

# Lookup multiple zones
swift run mistdemo lookup-zones "Photos,Documents,Articles" --api-token YOUR_TOKEN
```

**Features:**
- Supports comma-separated zone names
- Displays zone capabilities
- Shows owner information

### Fetch Changes

Fetch record changes with incremental sync:

```bash
# Initial fetch
swift run mistdemo fetch-changes --api-token YOUR_TOKEN

# Incremental fetch with sync token
swift run mistdemo fetch-changes \
  --sync-token "abc123..." \
  --api-token YOUR_TOKEN

# Fetch all with automatic pagination
swift run mistdemo fetch-changes --fetch-all --api-token YOUR_TOKEN

# Custom zone and limit
swift run mistdemo fetch-changes \
  --zone MyZone \
  --limit 50 \
  --api-token YOUR_TOKEN
```

**Features:**
- Supports sync tokens for incremental sync
- Automatic pagination with `--fetch-all`
- Displays sync tokens for next fetch
- Shows `moreComing` flag

## Integration Test Suite

The `test-integration` command runs a comprehensive 8-phase workflow:

### Phase 1: Zone Verification
- Uses `lookupZones(zoneIDs: [.defaultZone])`
- Verifies zone exists before testing
- Displays zone capabilities

### Phase 2: Asset Upload
- Generates test PNG image programmatically
- Uploads using `uploadAssets(data:)`
- Configurable size via `--asset-size` (default: 100 KB)

### Phase 3: Create Records with Assets
- Creates N test records (default: 10)
- Each record includes: title, index, image asset, timestamp
- Uses record type: `MistKitIntegrationTest`

### Phase 4: Initial Sync
- Fetches all records with `fetchRecordChanges()`
- Saves sync token
- Verifies test records are included

### Phase 5: Modify Records
- Updates first 3 records
- Adds "modified" boolean field
- Changes title field

### Phase 6: Incremental Sync
- Uses saved sync token
- Fetches only modified records
- Demonstrates incremental sync efficiency

### Phase 7: Final Zone Verification
- Re-verifies zone state
- Ensures operations didn't corrupt zone

### Phase 8: Cleanup
- Deletes all test records
- Skip with `--skip-cleanup` flag
- Partial cleanup on errors

## Command Options

### Common Options

All subcommands support:

```bash
--api-token <token>          # CloudKit API token (or set CLOUDKIT_API_TOKEN env var)
--container-identifier <id>  # Container ID (default: iCloud.com.brightdigit.MistDemo)
--environment <env>          # development or production (default: development)
```

### Test Integration Options

```bash
--record-count <N>    # Number of test records (default: 10)
--asset-size <KB>     # Asset size in KB (default: 100)
--skip-cleanup        # Leave test records in CloudKit
--verbose             # Show detailed progress
```

## CloudKit Schema

The integration tests use a custom record type defined in `schema.ckdb`:

```
RECORD TYPE MistKitIntegrationTest (
    "title"      STRING QUERYABLE SORTABLE SEARCHABLE,
    "index"      INT64 QUERYABLE SORTABLE,
    "image"      ASSET,
    "createdAt"  TIMESTAMP QUERYABLE SORTABLE,
    "modified"   INT64 QUERYABLE,

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
);
```

**Field Descriptions:**
- `title` - Test record title
- `index` - Sequential number for ordering
- `image` - Uploaded test asset
- `createdAt` - Record creation timestamp
- `modified` - Boolean flag (0/1) set during updates

## Example Output

```
================================================================================
🧪 Integration Test Suite: CloudKit Operations
================================================================================
Container: iCloud.com.brightdigit.MistDemo
Environment: development
Database: public
Record Count: 10
Asset Size: 100 KB
================================================================================

📋 Phase 1: Verify zone exists
✅ Found zone: _defaultZone

📤 Phase 2: Upload test assets
✅ Uploaded asset: 102400 bytes

📝 Phase 3: Create records with assets
✅ Created 10 records

🔄 Phase 4: Initial sync (fetch all changes)
✅ Fetched 45 records
   Found 10 of our test records

✏️  Phase 5: Modify some records
✅ Updated 3 records

🔄 Phase 6: Incremental sync (fetch only changes)
✅ Fetched 3 changed records
   Found 3 of our modified records

🔍 Phase 7: Lookup zone details
✅ Zone verification complete

🧹 Phase 8: Cleanup test records
✅ Deleted 10 test records

================================================================================
✅ Integration Test Complete!
================================================================================

Phases Completed:
  ✅ Zone verification with lookupZones
  ✅ Asset upload with uploadAssets
  ✅ Record creation with assets
  ✅ Initial sync with fetchRecordChanges
  ✅ Record modifications
  ✅ Incremental sync with sync token
  ✅ Final zone verification
  ✅ Cleanup completed
```

## Troubleshooting

### Schema Not Found

If you see errors about `MistKitIntegrationTest` not existing:

1. Verify schema was deployed: Check CloudKit Console → Schema
2. Re-import schema using `cktool import-schema`
3. Ensure you're using the correct environment (`--environment development`)

### Authentication Failed

If you see authentication errors:

1. Verify your API token: https://icloud.developer.apple.com/dashboard/
2. Check token has permissions for the container
3. Ensure token hasn't expired
4. Try setting `CLOUDKIT_API_TOKEN` environment variable

### No Records Found

If integration tests report no records found:

1. Records may not be immediately available after creation
2. Try running the test again
3. Use `--skip-cleanup` and check CloudKit Console
4. Verify you're using the correct database (public vs private)

## Architecture

### File Structure

```
Examples/MistDemo/
├── schema.ckdb                           # CloudKit schema
├── Sources/MistDemo/
│   ├── MistDemo.swift                    # Command group + CloudKitCommand protocol
│   ├── Commands/
│   │   ├── Auth.swift                    # Legacy auth server
│   │   ├── UploadAsset.swift            # Upload asset command
│   │   ├── LookupZones.swift            # Lookup zones command
│   │   ├── FetchChanges.swift           # Fetch changes command
│   │   └── TestIntegration.swift        # Integration test command
│   ├── Integration/
│   │   ├── IntegrationTestRunner.swift  # 8-phase test orchestration
│   │   ├── IntegrationTestData.swift    # Test data generation
│   │   └── IntegrationTestError.swift   # Error types
│   ├── Models/
│   ├── Utilities/
│   └── Resources/
```

### CloudKitCommand Protocol

All subcommands conform to the `CloudKitCommand` protocol:

```swift
protocol CloudKitCommand {
    var containerIdentifier: String { get }
    var apiToken: String { get }
    var environment: String { get }
}

extension CloudKitCommand {
    func resolvedApiToken() -> String
    func cloudKitEnvironment() -> MistKit.Environment
}
```

## Testing with Live CloudKit

To test against your own CloudKit container:

1. Create a container at https://icloud.developer.apple.com/
2. Generate an API token
3. Deploy the schema to your container
4. Update the default container ID or use `--container-identifier`
5. Run tests:

```bash
swift run mistdemo test-integration \
  --container-identifier iCloud.com.yourcompany.YourApp \
  --api-token YOUR_TOKEN \
  --environment development
```

## Future Enhancements

Documented in the plan:

1. **Custom Zone Support** - Add `modifyZones` wrapper to test multi-zone scenarios
2. **Pagination Testing** - Create 50+ records to trigger pagination
3. **Error Scenario Testing** - Test invalid zones, corrupted tokens, oversized assets
4. **Concurrent Operations** - Test parallel uploads and modifications
5. **Performance Metrics** - Track timing for each phase
6. **JSON Output** - Machine-readable results for CI/CD integration

## Contributing

When adding new CloudKit operations:

1. Create a subcommand in `Commands/`
2. Implement the `CloudKitCommand` protocol
3. Add to the `MistDemo.configuration.subcommands` array
4. Update integration tests if needed
5. Document usage in this README

## References

- Issue #199: CloudKit API Coverage
- Commit: 1d0b348 - Add lookupZones, fetchRecordChanges, and uploadAssets operations
- Plan: `/Users/leo/.claude/plans/eager-roaming-rainbow.md`
