# Syncing Data to CloudKit

Learn how to fetch data from external sources and upload it to CloudKit.

## Overview

The `sync` command is BushelCloud's primary operation. It fetches macOS restore images, Xcode versions, and Swift compiler versions from multiple sources, then uploads them to CloudKit using Server-to-Server authentication.

## Prerequisites

Before syncing, ensure you've completed <doc:CloudKitSetup> to configure your CloudKit credentials.

## Basic Sync

Run a full sync to CloudKit:

```bash
bushel-cloud sync
```

This performs a three-phase process:

1. **Fetch**: Downloads data from all sources in parallel
2. **Transform**: Deduplicates and resolves references
3. **Upload**: Batches operations and uploads to CloudKit

## Dry Run Mode

Test fetching without uploading to CloudKit:

```bash
bushel-cloud sync --dry-run
```

**Use dry run to**:
- Test external API connectivity
- Preview data before uploading
- Debug data source issues
- Verify deduplication logic

Dry run completes phases 1 and 2 but skips the upload phase.

## Verbose Output

See detailed operation logs:

```bash
bushel-cloud sync --verbose
```

Verbose mode shows:
- Fetch timing for each data source
- Deduplication merge decisions
- CloudKit batch operations
- Field mappings and type conversions
- Authentication token refresh

**Combine with dry run** for development:

```bash
bushel-cloud sync --dry-run --verbose
```

## Data Sources

BushelCloud fetches from seven external sources:

| Source | Data Type | Priority |
|--------|-----------|----------|
| **IPSW.me** | Restore images | Standard |
| **AppleDB.dev** | Restore images | Backfills SHA-256 |
| **MESU** | Restore images | Authoritative for signing |
| **VirtualBuddy** | Restore images | Authoritative for signing |
| **Mr. Macintosh** | Restore images | Historical data |
| **XcodeReleases.com** | Xcode versions | Primary |
| **swift.org** | Swift versions | Official releases |

All fetchers run concurrently. Fetch timing is logged in verbose mode.

## Deduplication

Multiple sources provide overlapping data. BushelCloud merges records using these rules:

**Restore Images**:
- **Unique Key**: Build number (e.g., "23C71")
- **Authoritative Sources**: Signing status from MESU and VirtualBuddy overrides other sources
- **AppleDB Backfill**: SHA-256 hashes filled from AppleDB when missing
- **Timestamp Wins**: Most recent `sourceUpdatedAt` wins for conflicts

**Xcode Versions**:
- **Unique Key**: Build number (e.g., "15C500b")
- **Single Source**: Currently only XcodeReleases.com provides data

**Swift Versions**:
- **Unique Key**: Version string (e.g., "5.9.2")
- **Single Source**: Official swift.org releases

See ``DataSourcePipeline`` for merge implementation details.

## Record Relationships

Records are uploaded in dependency order:

```
1. SwiftVersion (no dependencies)
2. RestoreImage (no dependencies)
3. XcodeVersion (references SwiftVersion and RestoreImage)
```

This ensures CloudKit references are valid when XcodeVersion records are created.

## Batch Operations

CloudKit limits operations to 200 per request. BushelCloud automatically:

1. Chunks operations into batches of 200
2. Uploads each batch sequentially
3. Logs progress for each batch
4. Checks for partial failures

Batch details appear in verbose output.

## Error Handling

**Partial Failures**: If some records fail in a batch, successful records are still created. Failed records are logged with CloudKit error details.

**Network Issues**: Sync will fail fast if external APIs are unreachable. Check verbose output for specific HTTP errors.

**Authentication Errors**: Invalid CloudKit credentials will fail immediately. Verify your API token and private key setup.

## Example Session

```bash
# First time: use dry run with verbose to preview
bushel-cloud sync --dry-run --verbose

# Review output, then sync for real
bushel-cloud sync --verbose

# Check what was uploaded
bushel-cloud list
```

## Production Usage

For production deployments:

1. **Schedule Regular Syncs**: Run daily or weekly via cron/systemd
2. **Monitor Logs**: Capture output for debugging
3. **Use Verbose Initially**: Disable verbose after confirming operations
4. **Check CloudKit Dashboard**: Verify records appear correctly

Example cron job:

```bash
# Daily sync at 3 AM
0 3 * * * /usr/local/bin/bushel-cloud sync >> /var/log/bushel-cloud.log 2>&1
```

## Known Limitations

- **No Duplicate Detection**: Running sync multiple times creates duplicate records
- **No Incremental Sync**: Always fetches all data from sources
- **No Conflict Resolution**: Concurrent syncs may cause conflicts

These are intentional limitations for this demonstration tool.

## Next Steps

- <doc:ExportingData> - Export CloudKit data to JSON
- <doc:CloudKitIntegration> - Understand CloudKit patterns used
- <doc:DataFlow> - Deep dive into the data pipeline

## Key Classes

- ``SyncCommand`` - CLI command implementation
- ``SyncEngine`` - Upload orchestration
- ``DataSourcePipeline`` - Fetch coordination
- ``BushelCloudKitService`` - CloudKit operations wrapper
