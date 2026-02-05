# Implementation History and Patterns

> **Note**: This is a detailed reference guide documenting implementation decisions, patterns, and lessons learned. For daily development, see the main [CLAUDE.md](../CLAUDE.md) file.

This document covers key implementation decisions, patterns, and lessons learned during BushelCloud development. Use this as reference when building similar CloudKit demos.

## Data Source Integration Pattern

BushelCloud integrates multiple external data sources. Here's the pattern for adding new sources:

**Step 1: Create Fetcher**
```swift
struct AppleDBFetcher: Sendable {
    func fetch() async throws -> [RestoreImageRecord] {
        // 1. Fetch data from external API
        // 2. Parse and map to domain model
        // 3. Return array of records
    }
}
```

**Step 2: Add to Pipeline**
```swift
// In DataSourcePipeline.swift
private func fetchRestoreImages(options: Options) async throws -> [RestoreImageRecord] {
    async let ipswImages = IPSWFetcher().fetch()
    async let appleDBImages = AppleDBFetcher().fetch()

    var allImages: [RestoreImageRecord] = []
    allImages.append(contentsOf: try await ipswImages)
    allImages.append(contentsOf: try await appleDBImages)

    return deduplicateRestoreImages(allImages)
}
```

**Step 3: Add CLI Option (Optional)**
```swift
struct SyncCommand {
    @Flag(name: .long, help: "Exclude AppleDB.dev as data source")
    var noAppleDB: Bool = false

    private func buildSyncOptions() -> SyncEngine.SyncOptions {
        var pipelineOptions = DataSourcePipeline.Options()
        if noAppleDB {
            pipelineOptions.includeAppleDB = false
        }
        return pipelineOptions
    }
}
```

## Deduplication Strategy

**Build Number as Unique Key:**

Multiple sources provide the same restore images. BushelCloud uses `buildNumber` as the unique key:

```swift
private func deduplicateRestoreImages(_ images: [RestoreImageRecord]) -> [RestoreImageRecord] {
    var uniqueImages: [String: RestoreImageRecord] = [:]

    for image in images {
        let key = image.buildNumber

        if let existing = uniqueImages[key] {
            // Merge records, prefer most complete data
            uniqueImages[key] = mergeRestoreImages(existing, image)
        } else {
            uniqueImages[key] = image
        }
    }

    return Array(uniqueImages.values)
        .sorted { $0.releaseDate > $1.releaseDate }
}
```

**Merge Priority Rules:**
1. **IPSW.me** - Most complete data (has both SHA1 + SHA256)
2. **AppleDB** - Device-specific signing status, comprehensive coverage
3. **MESU** - Authoritative for signing status (freshness detection)
4. **MrMacintosh** - Beta/RC releases, community-maintained

**Merge Logic:**
```swift
private func mergeRestoreImages(
    _ existing: RestoreImageRecord,
    _ new: RestoreImageRecord
) -> RestoreImageRecord {
    var merged = existing

    // Prefer more recent sourceUpdatedAt
    if new.sourceUpdatedAt > existing.sourceUpdatedAt {
        merged = new
    }

    // Backfill missing SHA hashes
    if merged.sha256Hash.isEmpty && !new.sha256Hash.isEmpty {
        merged.sha256Hash = new.sha256Hash
    }
    if merged.sha1Hash.isEmpty && !new.sha1Hash.isEmpty {
        merged.sha1Hash = new.sha1Hash
    }

    // MESU is authoritative for signing status
    if new.source == "MESU" {
        merged.isSigned = new.isSigned
    }

    return merged
}
```

## AppleDB Integration

AppleDB was added to provide comprehensive restore image data with device-specific signing status.

**API Endpoint:**
```swift
let url = URL(string: "https://api.appledb.dev/ios/VirtualMac2,1.json")!
```

**Key Features:**
- Device filtering for VirtualMac variants
- File size parsing (string → Int64)
- Prerelease detection (beta/RC in version string)
- Signing status per device

**Implementation Files:**
- `AppleDB/AppleDBParser.swift` - API client
- `AppleDB/AppleDBFetcher.swift` - Fetcher pattern implementation
- `AppleDB/Models/AppleDBVersion.swift` - Domain model
- `AppleDB/Models/AppleDBAPITypes.swift` - API response types

## Server-to-Server Authentication Migration

BushelCloud was refactored from API Tokens to S2S Keys to demonstrate enterprise authentication patterns.

**What Changed:**

| Before (API Token) | After (S2S Key) |
|-------------------|-----------------|
| Single token string | Key ID + Private Key (.pem) |
| `APITokenManager` | `ServerToServerAuthManager` |
| `CLOUDKIT_API_TOKEN` env var | `CLOUDKIT_KEY_ID` + `CLOUDKIT_KEY_FILE` |
| `--api-token` flag | `--key-id` + `--key-file` flags |

**Migration Steps:**
1. Generate ECDSA key pair with OpenSSL
2. Register public key in CloudKit Dashboard
3. Update `BushelCloudKitService` to use `ServerToServerAuthManager`
4. Update all commands to accept new parameters
5. Update environment variable handling
6. Update documentation

## Critical Issues Solved

### Issue 1: CloudKit Schema Validation Errors

**Problem:** `cktool validate-schema` failed with parsing error.

**Root Cause:** Schema file missing `DEFINE SCHEMA` header and included system fields.

**Solution:**
```text
# Wrong
RECORD TYPE RestoreImage (
    "__recordID" RECORD ID,  ❌

# Correct
DEFINE SCHEMA  ✅

RECORD TYPE RestoreImage (
    "version" STRING,  ✅
```

**Lesson:** CloudKit auto-adds system fields. Never include them in schema definitions.

### Issue 2: ACCESS_DENIED Errors Despite Correct Permissions

**Problem:** Record creation failed with ACCESS_DENIED even after adding `_creator` permissions.

**Root Cause:** Schema needed BOTH `_creator` AND `_icloud` permissions.

**Solution:**
```text
GRANT READ, CREATE, WRITE TO "_creator",
GRANT READ, CREATE, WRITE TO "_icloud",  ← Both required!
```

**Lesson:** S2S authentication with public database requires permissions for both roles.

### Issue 3: cktool Command Syntax Confusion

**Problem:** Script used invalid cktool commands and flags.

**Incorrect:**
```bash
xcrun cktool list-containers  # ❌ Not a valid command
xcrun cktool validate-schema schema.ckdb  # ❌ Missing --file flag
```

**Correct:**
```bash
xcrun cktool get-teams  # ✅ Valid auth test command
xcrun cktool validate-schema --file schema.ckdb  # ✅ Correct syntax
```

**Lesson:** Always check cktool syntax with `xcrun cktool --help`.

## Token Types Reference

CloudKit uses different tokens for different operations:

| Token Type | Purpose | Used By | How to Get |
|-----------|---------|---------|------------|
| **Management Token** | Schema operations (import/export) | `cktool` | Dashboard → CloudKit Web Services |
| **Server-to-Server Key** | Runtime API operations (server-side) | Your application | Dashboard → Server-to-Server Keys |
| **API Token** | Simpler runtime auth (legacy) | Legacy apps | Dashboard → API Tokens |
| **User Token** | User-specific operations | Web apps | OAuth flow |

**For BushelCloud:**
- Schema setup: **Management Token** (via `cktool save-token`)
- Sync/export: **Server-to-Server Key** (Key ID + .pem file)

## Date Handling with CloudKit

CloudKit dates use **milliseconds since epoch**, not seconds:

```swift
// MistKit handles conversion automatically
fields["releaseDate"] = .date(Date())  // ✅ Converted to milliseconds

// If manually creating timestamp
let milliseconds = Int64(date.timeIntervalSince1970 * 1000)
fields["releaseDate"] = .int64(milliseconds)
```

## Boolean Fields in CloudKit

CloudKit has no native boolean type. Use INT64 with 0/1:

**Schema:**
```text
"isSigned"      INT64 QUERYABLE,
"isPrerelease"  INT64 QUERYABLE,
```

**Swift code:**
```swift
fields["isSigned"] = .int64(record.isSigned ? 1 : 0)
fields["isPrerelease"] = .int64(record.isPrerelease ? 1 : 0)
```

**Reading back:**
```swift
if case .int64(let value) = fields["isSigned"] {
    let isSigned = value == 1
}
```

## Batch Operation Optimization

CloudKit limits: **200 operations per request**

**Efficient batching:**
```swift
let batchSize = 200
let batches = operations.chunked(into: batchSize)

for (index, batch) in batches.enumerated() {
    print("Batch \(index + 1)/\(batches.count)...")
    let results = try await service.modifyRecords(batch)

    // Process results immediately
    for result in results {
        if result.recordType == "Unknown" {
            // Handle error
        }
    }
}
```

**Don't batch too small:** Each request has overhead. Use full 200-operation batches when possible.

## Reference Field Ordering

Upload order matters for records with references:

```text
SwiftVersion (no dependencies)
    ↓
RestoreImage (no dependencies)
    ↓
XcodeVersion (references both)
```

**Correct upload order:**
```swift
// 1. Records with no dependencies first
try await syncSwiftVersions()
try await syncRestoreImages()

// 2. Records with references last
try await syncXcodeVersions()  // References uploaded records
```

**Wrong order causes:** `VALIDATING_REFERENCE_ERROR`

## Error Handling Best Practices

**Check for partial failures:**
```swift
let results = try await service.modifyRecords(batch)
let errors = results.filter { $0.recordType == "Unknown" }

if !errors.isEmpty {
    for error in errors {
        print("Failed: \(error.recordName ?? "unknown")")
        print("Reason: \(error.reason ?? "N/A")")
    }
}
```

**Common recoverable errors:**
- `VALIDATING_REFERENCE_ERROR` - Retry after uploading referenced records
- `CONFLICT` - Use `.forceReplace` instead of `.create`
- `QUOTA_EXCEEDED` - Reduce batch size or wait

**Non-recoverable errors:**
- `ACCESS_DENIED` - Fix schema permissions
- `AUTHENTICATION_FAILED` - Fix key ID/PEM file

## Lessons for Future Demos

When building similar CloudKit demos (e.g., Celestra):

**1. Start with S2S Keys from the beginning**
- More secure and production-ready
- Better demonstrates enterprise patterns

**2. Schema setup first**
- Create schema with `DEFINE SCHEMA` header
- Include both `_creator` and `_icloud` permissions
- Test with cktool before app development

**3. Use the DataSourcePipeline pattern**
- Parallel fetching with `async let`
- Deduplication by unique key
- Merge priority rules for conflict resolution

**4. Reusable patterns from BushelCloud:**
- `BushelCloudKitService` wrapper pattern
- `CloudKitRecord` protocol for models
- CLI structure with swift-argument-parser
- Environment variable handling
- Batch operation chunking

**5. Documentation structure:**
- README for user-facing quick start
- CLAUDE.md for development context
- DocC for comprehensive tutorials
- No separate Documentation/ directory

## Common Pitfalls to Avoid

**❌ Don't:**
- Commit .pem files to git
- Use system fields in schema
- Grant permissions to only one role
- Upload references before referenced records
- Batch operations larger than 200
- Assume boolean type exists in CloudKit
- Use seconds for timestamps (use milliseconds)

**✅ Do:**
- Use environment variables for credentials
- Start schema with `DEFINE SCHEMA`
- Grant to both `_creator` and `_icloud`
- Upload in dependency order
- Chunk operations to 200 max
- Use INT64 (0/1) for booleans
- Let MistKit handle date conversion
