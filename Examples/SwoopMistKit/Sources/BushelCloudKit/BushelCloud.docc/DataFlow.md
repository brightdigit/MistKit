# Data Flow Architecture

Understand how data moves through BushelCloud from external sources to CloudKit.

## Overview

BushelCloud follows a three-phase pipeline architecture to fetch, transform, and upload data to CloudKit.

## Pipeline Phases

### Phase 1: Fetch

The ``DataSourcePipeline`` fetches data from multiple external sources in parallel:

1. **IPSW.me** - macOS restore images via IPSWDownloads library
2. **AppleDB.dev** - Comprehensive restore image database
3. **XcodeReleases.com** - Xcode versions and build info
4. **swift.org** - Swift compiler releases
5. **MESU** - Apple's official software update metadata
6. **Mr. Macintosh** - Community-maintained release archive
7. **VirtualBuddy** - Real-time TSS signing status verification

Each fetcher returns domain-specific records implementing the ``CloudKitRecord`` protocol.

### Phase 2: Transform

Data transformation includes:

- **Deduplication**: Merge duplicate records using build numbers as unique keys
- **Reference Resolution**: Create CloudKit references between related records
- **Field Mapping**: Convert Swift types to CloudKit `FieldValue` types

Key deduplication rules:
- MESU and VirtualBuddy are authoritative for signing status
- AppleDB backfills missing SHA-256 hashes
- Most recent `sourceUpdatedAt` timestamp wins

### Phase 3: Upload

The ``SyncEngine`` uploads records to CloudKit:

1. **Batch Operations**: Records are chunked into 200-operation batches (CloudKit limit)
2. **Dependency Ordering**: Upload in order: SwiftVersion → RestoreImage → XcodeVersion
3. **Error Handling**: Partial failures are logged with CloudKit error details

## Record Relationships

```
SwiftVersion (no dependencies)
    ↑
    | CKReference
    |
RestoreImage (no dependencies)
    ↑
    | CKReference (minimumMacOS, swiftVersion)
    |
XcodeVersion
```

XcodeVersion records reference both RestoreImage (for minimum macOS) and SwiftVersion (for bundled Swift compiler).

## CloudKit Integration

See <doc:CloudKitIntegration> for details on:
- Server-to-Server authentication
- Batch operation handling
- Record creation patterns
- Error handling strategies

## Key Classes

- ``DataSourcePipeline`` - Orchestrates fetching from all sources
- ``SyncEngine`` - Manages CloudKit upload process
- ``BushelCloudKitService`` - Wraps MistKit with BushelCloud-specific operations
- ``CloudKitRecord`` - Protocol for domain models

## Observability

Enable verbose mode to see detailed operation logs:

```bash
bushel-cloud sync --verbose
```

This shows:
- Fetch timing for each source
- Deduplication merge decisions
- CloudKit batch operations
- Field mappings and conversions
