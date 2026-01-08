# CloudKit Integration Patterns

Learn how BushelCloud uses MistKit for CloudKit Web Services.

## Overview

BushelCloud demonstrates production-ready patterns for using MistKit to interact with CloudKit Web Services using Server-to-Server authentication.

## Server-to-Server Authentication

Initialize ``BushelCloudKitService`` with ECDSA private key:

```swift
let tokenManager = try ServerToServerAuthManager(
    keyID: "your-key-id",
    pemString: pemFileContents
)

let service = try CloudKitService(
    containerIdentifier: "iCloud.com.company.App",
    tokenManager: tokenManager,
    environment: .development,
    database: .public
)
```

Authentication tokens are automatically refreshed by MistKit.

## Batch Operations

CloudKit limits operations to 200 per request. BushelCloud handles this automatically:

```swift
let batches = operations.chunked(into: 200)
for batch in batches {
    let results = try await service.modifyRecords(batch)
    // Handle results...
}
```

See ``SyncEngine/uploadRecords(_:recordType:)`` for the complete implementation.

## Record Creation Pattern

All domain models implement ``CloudKitRecord``:

```swift
protocol CloudKitRecord {
    static var cloudKitRecordType: String { get }
    func toCloudKitFields() -> [String: FieldValue]
    static func from(recordInfo: RecordInfo) -> Self?
}
```

Example implementation:

```swift
extension RestoreImageRecord: CloudKitRecord {
    static var cloudKitRecordType: String { "RestoreImage" }

    func toCloudKitFields() -> [String: FieldValue] {
        [
            "version": .string(version),
            "buildNumber": .string(buildNumber),
            "releaseDate": .date(releaseDate),
            "isPrerelease": FieldValue(booleanValue: isPrerelease),
            // ... more fields
        ]
    }
}
```

## Field Type Conversions

CloudKit field types map to Swift types:

| Swift Type | CloudKit Type | Example |
|------------|---------------|---------|
| `String` | `.string()` | `.string("macOS 14.0")` |
| `Int64` | `.int64()` | `.int64(fileSize)` |
| `Date` | `.date()` | `.date(releaseDate)` |
| `Bool` | `.int64()` | `FieldValue(booleanValue: true)` |
| Reference | `.reference()` | `.reference(Reference(recordName: "RestoreImage-23C71"))` |

**Note**: Booleans are stored as INT64 (0 = false, 1 = true).

## Date Handling

CloudKit dates use **milliseconds since epoch**. MistKit's `FieldValue.date()` handles conversion:

```swift
// MistKit converts automatically
let field: FieldValue = .date(Date())
```

## Reference Fields

Create relationships using record names:

```swift
fields["minimumMacOS"] = .reference(
    FieldValue.Reference(recordName: "RestoreImage-23C71")
)
```

Read references:

```swift
if case .reference(let ref) = fieldValue {
    let recordName = ref.recordName
}
```

## Error Handling

Check for partial failures in batch operations:

```swift
let results = try await service.modifyRecords(operations)
for result in results {
    if result.isError {
        logger.error("Failed: \\(result.serverErrorCode ?? "unknown")")
    }
}
```

## Verbose Mode

Enable verbose logging to see MistKit operations:

```swift
BushelLogger.shared.enableVerbose()
```

This logs:
- API requests and responses
- Batch operation details
- Field mappings and conversions
- Authentication token refresh

## Key Classes

- ``BushelCloudKitService`` - Service wrapper for BushelCloud operations
- ``SyncEngine`` - Upload orchestration
- ``CloudKitFieldMapping`` - Type conversion utilities

## Best Practices

1. **Batch wisely**: Stay under 200 operations per request
2. **Order matters**: Upload dependencies first (SwiftVersion before XcodeVersion)
3. **Handle partials**: Check `RecordInfo.isError` for each result
4. **Use references**: Link related records with CloudKit references
5. **Verbose development**: Use `--verbose` flag during development
