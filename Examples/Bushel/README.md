# Bushel Demo - CloudKit Data Synchronization

A command-line tool demonstrating MistKit's CloudKit Web Services capabilities by syncing macOS restore images, Xcode versions, and Swift compiler versions to CloudKit.

## Overview

Bushel is a comprehensive demo application showcasing how to use MistKit to:

- Fetch data from multiple sources (ipsw.me, xcodereleases.com, swift.org, MESU, Mr. Macintosh)
- Transform data into CloudKit-compatible record structures
- Batch upload records to CloudKit using the Web Services REST API
- Handle relationships between records using CloudKit References
- Export data for analysis or backup

## What is "Bushel"?

In Apple's virtualization framework, **restore images** are used to boot virtual Macintosh systems. These images are essential for running macOS VMs and are distributed through Apple's software update infrastructure. Bushel collects and organizes information about these images along with related Xcode and Swift versions, making it easier to manage virtualization environments.

## Architecture

### Data Sources

The demo integrates with multiple data sources to gather comprehensive version information:

1. **IPSW.me API** (via [IPSWDownloads](https://github.com/brightdigit/IPSWDownloads))
   - macOS restore images for VirtualMac2,1
   - Build numbers, release dates, signatures, file sizes

2. **XcodeReleases.com**
   - Xcode versions and build numbers
   - Release dates and prerelease status
   - Download URLs and SDK information

3. **Swift.org**
   - Swift compiler versions
   - Release dates and download links
   - Official Swift toolchain information

4. **Apple MESU Catalog** (Mobile Equipment Software Update)
   - Official macOS restore image catalog
   - Asset metadata and checksums

5. **Mr. Macintosh's Restore Image Archive**
   - Historical restore image information
   - Community-maintained release data

### Components

```
BushelImages/
├── DataSources/           # Data fetchers for external APIs
│   ├── IPSWFetcher.swift
│   ├── XcodeReleasesFetcher.swift
│   ├── SwiftVersionFetcher.swift
│   ├── MESUFetcher.swift
│   ├── MrMacintoshFetcher.swift
│   └── DataSourcePipeline.swift
├── Models/                # Data models
│   ├── RestoreImageRecord.swift
│   ├── XcodeVersionRecord.swift
│   └── SwiftVersionRecord.swift
├── CloudKit/              # CloudKit integration
│   ├── BushelCloudKitService.swift
│   ├── RecordBuilder.swift
│   └── SyncEngine.swift
└── Commands/              # CLI commands
    ├── BushelImagesCLI.swift
    ├── SyncCommand.swift
    └── ExportCommand.swift
```

## Features Demonstrated

### MistKit Capabilities

✅ **Public API Usage**
- Uses only public MistKit APIs (no internal OpenAPI types)
- Demonstrates proper abstraction layer design

✅ **Record Operations**
- Creating records with `RecordOperation.create()`
- Batch operations with `modifyRecords()`
- Proper field value mapping with `FieldValue` enum

✅ **Data Type Support**
- Strings, integers, booleans, dates
- CloudKit References (relationships between records)
- Proper date/timestamp conversion (milliseconds since epoch)

✅ **Batch Processing**
- CloudKit's 200-operation-per-request limit handling
- Progress reporting during sync
- Error handling for partial failures

✅ **Authentication**
- API token authentication with `APITokenManager`
- Container and environment configuration

### Swift 6 Best Practices

✅ **Strict Concurrency**
- All types conform to `Sendable`
- Async/await throughout
- No data races

✅ **Modern Error Handling**
- Typed errors with `CloudKitError`
- Proper error propagation with `throws`

✅ **Value Semantics**
- Immutable structs for data models
- No reference types in concurrent contexts

## Usage

### Building

```bash
# From Bushel directory
swift build

# Or from MistKit root
swift build --package-path Examples/Bushel
```

### Running

#### Sync Command

Fetch data from all sources and upload to CloudKit:

```bash
bushel-images sync \
  --container-id "iCloud.com.yourcompany.Bushel" \
  --api-token "your-cloudkit-api-token"
```

#### Export Command

Fetch data and export to JSON file (no CloudKit upload):

```bash
bushel-images export \
  --container-id "iCloud.com.yourcompany.Bushel" \
  --api-token "your-cloudkit-api-token" \
  --output ./bushel-data.json
```

#### Help

```bash
bushel-images --help
bushel-images sync --help
bushel-images export --help
```

### Xcode Setup

See [XCODE_SCHEME_SETUP.md](./XCODE_SCHEME_SETUP.md) for detailed instructions on:
- Configuring the Xcode scheme
- Setting environment variables
- Getting CloudKit credentials
- Debugging tips

## CloudKit Schema

The demo uses three record types with relationships:

```
SwiftVersion
    ↑
    | (reference)
    |
RestoreImage ← XcodeVersion
    ↑              ↑
    | (reference)  |
    |______________|
```

### Record Relationships

- **XcodeVersion → RestoreImage**: Links Xcode to minimum macOS version required
- **XcodeVersion → SwiftVersion**: Links Xcode to included Swift compiler version

### Example Data Flow

1. Fetch Swift 6.0.3 → Create SwiftVersion record
2. Fetch macOS 15.2 restore image → Create RestoreImage record
3. Fetch Xcode 16.2 → Create XcodeVersion record with references to both

## Implementation Highlights

### RecordBuilder Pattern

Shows how to convert domain models to CloudKit records using only public APIs:

```swift
enum RecordBuilder {
    static func buildRestoreImageOperation(
        _ record: RestoreImageRecord
    ) -> RecordOperation {
        var fields: [String: FieldValue] = [
            "version": .string(record.version),
            "buildNumber": .string(record.buildNumber),
            "releaseDate": .date(record.releaseDate),
            "fileSize": .int64(Int(record.fileSize)),
            "isSigned": .boolean(record.isSigned),
            // ... more fields
        ]

        return RecordOperation.create(
            recordType: "RestoreImage",
            recordName: record.recordName,
            fields: fields
        )
    }
}
```

### Batch Processing

Demonstrates efficient CloudKit batch operations:

```swift
private func executeBatchOperations(
    _ operations: [RecordOperation],
    recordType: String
) async throws {
    let batchSize = 200  // CloudKit limit
    let batches = operations.chunked(into: batchSize)

    for (index, batch) in batches.enumerated() {
        print("  Batch \(index + 1)/\(batches.count)...")
        _ = try await service.modifyRecords(batch)
    }
}
```

### Data Source Pipeline

Shows async/await parallel data fetching:

```swift
struct DataSourcePipeline: Sendable {
    func fetchAllData() async throws -> (
        restoreImages: [RestoreImageRecord],
        xcodeVersions: [XcodeVersionRecord],
        swiftVersions: [SwiftVersionRecord]
    ) {
        async let restoreImages = ipswFetcher.fetch()
        async let xcodeVersions = xcodeReleasesFetcher.fetch()
        async let swiftVersions = swiftVersionFetcher.fetch()

        return try await (restoreImages, xcodeVersions, swiftVersions)
    }
}
```

## Requirements

- macOS 14.0+ (for demonstration purposes; MistKit supports macOS 11.0+)
- Swift 6.2+
- Xcode 16.2+ (for development)
- CloudKit container with appropriate schema (see setup below)
- CloudKit API token

## CloudKit Schema Setup

Before running the sync command, you need to set up the CloudKit schema. The schema will be created at the container level, but **Bushel writes all records to the public database** for worldwide accessibility.

You have two options:

### Option 1: Automated Setup (Recommended)

Use `cktool` to automatically import the schema:

```bash
# Save your CloudKit management token
xcrun cktool save-token

# Set environment variables
export CLOUDKIT_CONTAINER_ID="iCloud.com.yourcompany.Bushel"
export CLOUDKIT_TEAM_ID="YOUR_TEAM_ID"

# Run the setup script
cd Examples/Bushel
./Scripts/setup-cloudkit-schema.sh
```

See [CLOUDKIT_SCHEMA_SETUP.md](./CLOUDKIT_SCHEMA_SETUP.md) for detailed instructions.

### Option 2: Manual Setup

Create the record types manually in [CloudKit Dashboard](https://icloud.developer.apple.com/).

See [XCODE_SCHEME_SETUP.md](./XCODE_SCHEME_SETUP.md#cloudkit-schema-setup) for field definitions.

## Dependencies

- **MistKit** - CloudKit Web Services client (local path dependency)
- **IPSWDownloads** - ipsw.me API wrapper
- **SwiftSoup** - HTML parsing for web scraping
- **ArgumentParser** - CLI argument parsing

## Testing Without CloudKit

To test data fetching without a CloudKit container:

1. Use the `export` command instead of `sync`
2. Review the exported JSON to verify data fetching works
3. Set up CloudKit schema when ready for sync

Example:
```bash
bushel-images export --output test-data.json
# No CloudKit credentials needed for export-only mode
```

## Limitations & Future Enhancements

### Current Limitations

- ⚠️ No duplicate detection (will create duplicate records on repeated syncs)
- ⚠️ No incremental sync (always fetches all data)
- ⚠️ No conflict resolution for concurrent updates
- ⚠️ Limited error recovery in batch operations

### Potential Enhancements

- [ ] Add `--update` mode to update existing records instead of creating new ones
- [ ] Implement incremental sync with change tracking
- [ ] Add record deduplication logic
- [ ] Support for querying existing records before sync
- [ ] Progress bar for long-running operations
- [ ] Retry logic for transient network errors
- [ ] Validation of record references before upload
- [ ] Support for CloudKit zones for better organization

## Learning Resources

### MistKit Documentation

- [MistKit Repository](https://github.com/brightdigit/MistKit)
- See main repository's CLAUDE.md for development guidelines

### Apple Documentation

- [CloudKit Web Services Reference](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/)
- [CloudKit Dashboard](https://icloud.developer.apple.com/)

### Related Projects

- [IPSWDownloads](https://github.com/brightdigit/IPSWDownloads) - ipsw.me API client
- [XcodeReleases.com](https://xcodereleases.com/) - Xcode version tracking

## Contributing

This is a demonstration project. For contributions to MistKit itself, please see the main repository.

## License

Same as MistKit - MIT License. See main repository LICENSE file.

## Questions?

For issues specific to this demo:
- Check [XCODE_SCHEME_SETUP.md](./XCODE_SCHEME_SETUP.md) for configuration help
- Review CloudKit Dashboard for schema and authentication issues

For MistKit issues:
- Open an issue in the main MistKit repository
- Include relevant code snippets and error messages
