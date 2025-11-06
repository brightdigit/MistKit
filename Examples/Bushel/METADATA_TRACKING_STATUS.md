# Data Source Metadata Tracking - Implementation Status

**Date**: 2025-11-06
**Status**: Implementation complete, debugging CloudKit issue
**Branch**: blog-post-examples-code-bushel

## Objective

Add timestamp tracking for data sources to enable fetch throttling and prevent unnecessary API calls. Track when each source was last fetched and when the source data was last updated.

## What Was Implemented

### 1. DataSourceMetadata Model
**File**: `Sources/BushelImages/Models/DataSourceMetadata.swift`

```swift
public struct DataSourceMetadata: Codable, Sendable {
    public let sourceName: String           // e.g., "appledb.dev", "ipsw.me"
    public let recordTypeName: String       // e.g., "RestoreImage", "XcodeVersion"
    public let lastFetchedAt: Date          // When we fetched from this source
    public let sourceUpdatedAt: Date?       // When source last updated (from HTTP headers)
    public let recordCount: Int             // Number of records retrieved
    public let fetchDurationSeconds: Double // How long the fetch took
    public let lastError: String?           // Last error if fetch failed

    public var recordName: String {
        "metadata-\(sourceName)-\(recordTypeName)"
    }
}
```

**Note**: Originally used `recordType` field name, but renamed to `recordTypeName` to avoid conflict with CloudKit system fields.

### 2. CloudKit Schema
**File**: `schema.ckdb`

Added `DataSourceMetadata` record type:
- `sourceName`: STRING QUERYABLE SORTABLE
- `recordTypeName`: STRING QUERYABLE
- `lastFetchedAt`: TIMESTAMP QUERYABLE SORTABLE
- `sourceUpdatedAt`: TIMESTAMP QUERYABLE SORTABLE
- `recordCount`: INT64
- `fetchDurationSeconds`: DOUBLE
- `lastError`: STRING

**Schema Deployment**:
```bash
xcrun cktool import-schema \
  --team-id MLT7M394S7 \
  --container-id iCloud.com.brightdigit.Bushel \
  --environment development \
  --file schema.ckdb
```

**Manual Dashboard Fix Required**: The `recordName` system field needed to be marked as QUERYABLE in the CloudKit Dashboard (not possible via schema.ckdb).

### 3. RecordBuilder Integration
**File**: `Sources/BushelImages/CloudKit/RecordBuilder.swift`

Added `buildDataSourceMetadataOperation()` method to convert `DataSourceMetadata` to `RecordOperation`.

### 4. CloudKit Service Methods
**File**: `Sources/BushelImages/CloudKit/BushelCloudKitService.swift`

Added methods:
- `syncDataSourceMetadata(_ records: [DataSourceMetadata])`: Sync metadata to CloudKit
- `queryDataSourceMetadata(source: String, recordType: String)`: Query existing metadata
- `parseDataSourceMetadata(from: RecordInfo)`: Parse CloudKit response

### 5. FetchConfiguration System
**File**: `Sources/BushelImages/Models/FetchConfiguration.swift`

Throttling intervals per source:
- AppleDB: 6 hours (21600s)
- MESU: 1 hour (3600s)
- ipsw.me: 12 hours (43200s)
- Mr. Macintosh: 12 hours (43200s)
- TheAppleWiki: 12 hours (43200s)
- xcodereleases.com: 12 hours (43200s)
- swiftversion.net: 12 hours (43200s)

Supports:
- Per-source intervals
- Global interval override via environment variable
- `shouldFetch()` method to check if fetch is allowed

### 6. DataSourcePipeline Integration
**File**: `Sources/BushelImages/DataSources/DataSourcePipeline.swift`

Wrapped all fetcher calls with `fetchWithMetadata()`:
- Queries existing metadata before fetch
- Checks if fetch is allowed based on throttling rules
- Times the fetch operation
- Creates/updates metadata record on success or error
- Syncs metadata to CloudKit

### 7. CLI Flags
**File**: `Sources/BushelImages/Commands/SyncCommand.swift`

Added flags:
- `--force`: Bypass throttling and fetch all sources
- `--min-interval <seconds>`: Override default throttling intervals
- `--source <name>`: Fetch from only one specific source

### 8. StatusCommand
**File**: `Sources/BushelImages/Commands/StatusCommand.swift`

New command: `bushel-images status`

Displays:
- Last fetched time (with "X ago" formatting)
- Source last updated time
- Record count from last fetch
- Next eligible fetch time
- Fetch duration (with `--detailed` flag)
- Errors (with `--errors-only` flag)

### 9. FieldValue Extensions
**File**: `Sources/BushelImages/CloudKit/FieldValueExtensions.swift`

Convenience accessors for `FieldValue` enum:
- `stringValue: String?`
- `int64Value: Int?`
- `doubleValue: Double?`
- `dateValue: Date?`

## Current Status: Debugging CloudKit Error

### The Problem

When attempting to create `DataSourceMetadata` records, CloudKit returns:
```json
{
  "recordName": "metadata-swiftversion.net-SwiftVersion",
  "reason": "Invalid value, [FIELD] type [TYPE].",
  "serverErrorCode": "BAD_REQUEST"
}
```

**The actual field name and type are redacted in the output**, making it difficult to identify the issue.

### What We Know

1. ✅ **Schema exists**: `DataSourceMetadata` record type is properly created in CloudKit
2. ✅ **Manual creation works**: User successfully created a test record via CloudKit Dashboard
3. ✅ **recordName is queryable**: Marked as QUERYABLE in Dashboard (required for MistKit queries)
4. ✅ **Build succeeds**: All code compiles without errors
5. ❌ **Programmatic creation fails**: MistKit's `modifyRecords()` fails with "Invalid value" error

### Attempted Fixes

1. ✅ Renamed `recordType` → `recordTypeName` to avoid system field conflicts
2. ✅ Re-imported schema to CloudKit
3. ✅ Made `recordName` queryable in Dashboard
4. ❌ Still getting "Invalid value" error on create

### The Mystery

Since manual record creation works but programmatic creation fails, the issue is likely:
- A data type mismatch in how we're sending the data
- A field value format issue (dates, integers, etc.)
- A MistKit serialization problem

### Commands to Reproduce

```bash
# Export current working directory
cd /Users/leo/Documents/Projects/MistKit-Bushel/Examples/Bushel

# Set credentials
export CLOUDKIT_KEY_ID=3e76ace055d2e3881a4e9c862dd1119ea85717bd743c1c8c15d95b2280cd93ab
export CLOUDKIT_KEY_FILE='/Users/leo/Library/Mobile Documents/com~apple~CloudDocs/Keys/bushel-cloudkit.pem'

# Build
swift build

# Test metadata tracking (will fail with CloudKit error)
.build/debug/bushel-images sync --source=swiftversion.net --verbose 2>&1 | grep -A 20 "DataSourceMetadata"

# Check status (will also fail querying metadata)
.build/debug/bushel-images status
```

## CRITICAL ISSUE: MistKit Logging Redaction

**MistKit's logging is too aggressive with KEY_ID_REDACTED replacement.** The error messages from CloudKit show:
```json
{
  "KEY_ID_REDACTED": "metadata-swiftversion.net-SwiftVersion",
  "reason": "Invalid value, KEY_ID_REDACTED type KEY_ID_REDACTED.",
  "KEY_ID_REDACTED": "BAD_REQUEST"
}
```

This makes debugging impossible because we cannot see:
- Which field is causing the error
- What type CloudKit expected
- The actual field names in error responses

**ACTION REQUIRED**: Remove or make configurable the KEY_ID_REDACTED replacement in MistKit logging. Error messages need to show actual field names to be debuggable.

## Next Steps to Debug

### Option 1: Capture Request Payload
Add debug logging to see the actual JSON being sent to CloudKit. The MistKit verbose output shows headers but not the request body.

### Option 2: Compare Manual vs Programmatic
In CloudKit Dashboard:
1. View the manually created test record
2. Export its JSON representation
3. Compare field types/formats with what we're sending programmatically

### Option 3: Test Individual Fields
Create minimal test records with only:
- Required fields first (sourceName, recordTypeName, lastFetchedAt, recordCount, fetchDurationSeconds)
- Then add optional fields one by one to identify the problematic field

### Option 4: Check MistKit Date Serialization
Dates might be serialized incorrectly. Check if MistKit expects:
- ISO 8601 strings
- Unix timestamps (milliseconds vs seconds)
- CloudKit-specific date format

### Option 5: Test with cktool
Try creating a record using `cktool create-record` with the exact values we're using, to see if it's a MistKit issue or our data.

## Related Files

- Conversation export: `Examples/Bushel/2025-11-06-caveat-the-messages-below-were-generated-by-the-u.txt`
- Schema file: `schema.ckdb`
- All source files under: `Sources/BushelImages/`

## Environment

- CloudKit Container: `iCloud.com.brightdigit.Bushel`
- Environment: `development`
- Team ID: `MLT7M394S7` (BRIGHT DIGIT LLC)
- Database: `public`
- Auth: Server-to-Server (ECDSA key authentication)

## Key Insights

1. The field name conflict with `recordType` was a red herring - renaming to `recordTypeName` didn't fix the issue
2. The error message redaction makes debugging very difficult
3. Manual record creation proves the schema is correct
4. The issue is in how data is being serialized/sent, not the schema definition
5. CloudKit's "Invalid value" error is frustratingly vague without seeing which field/type is wrong
