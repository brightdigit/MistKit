# Bushel Patterns: CloudKit Integration Reference

This document captures the CloudKit integration patterns used in the Bushel example project, serving as a reference for understanding MistKit's capabilities and design approaches.

## Table of Contents

- [Overview](#overview)
- [CloudKitRecord Protocol Pattern](#cloudkitrecord-protocol-pattern)
- [Schema Design Patterns](#schema-design-patterns)
- [Server-to-Server Authentication](#server-to-server-authentication)
- [Batch Operations](#batch-operations)
- [Relationship Handling](#relationship-handling)
- [Data Pipeline Architecture](#data-pipeline-architecture)
- [Celestra vs Bushel Comparison](#celestra-vs-bushel-comparison)

## Overview

Bushel is a production example demonstrating MistKit's CloudKit integration for syncing macOS software version data. It showcases advanced patterns including:

- Protocol-oriented CloudKit record management
- Complex relationship handling between multiple record types
- Parallel data fetching from multiple sources
- Deduplication strategies
- Comprehensive error handling

Location: `Examples/Bushel/`

## CloudKitRecord Protocol Pattern

### The Protocol

Bushel uses a protocol-based approach for CloudKit record conversion:

```swift
protocol CloudKitRecord {
    static var cloudKitRecordType: String { get }
    var recordName: String { get }

    func toCloudKitFields() -> [String: FieldValue]
    static func from(recordInfo: RecordInfo) -> Self?
    static func formatForDisplay(_ recordInfo: RecordInfo) -> String
}
```

### Implementation Example

```swift
struct RestoreImageRecord: CloudKitRecord {
    static var cloudKitRecordType: String { "RestoreImage" }

    var recordName: String {
        "RestoreImage-\(buildNumber)"  // Stable, deterministic ID
    }

    func toCloudKitFields() -> [String: FieldValue] {
        var fields: [String: FieldValue] = [
            "version": .string(version),
            "buildNumber": .string(buildNumber),
            "releaseDate": .date(releaseDate),
            "fileSize": .int64(fileSize),
            "isPrerelease": .boolean(isPrerelease)
        ]

        // Handle optional fields
        if let isSigned {
            fields["isSigned"] = .boolean(isSigned)
        }

        // Handle relationships
        if let minimumMacOSRecordName {
            fields["minimumMacOS"] = .reference(
                FieldValue.Reference(recordName: minimumMacOSRecordName)
            )
        }

        return fields
    }

    static func from(recordInfo: RecordInfo) -> Self? {
        guard let version = recordInfo.fields["version"]?.stringValue,
              let buildNumber = recordInfo.fields["buildNumber"]?.stringValue
        else { return nil }

        let releaseDate = recordInfo.fields["releaseDate"]?.dateValue ?? Date()
        let fileSize = recordInfo.fields["fileSize"]?.int64Value ?? 0

        return RestoreImageRecord(
            version: version,
            buildNumber: buildNumber,
            releaseDate: releaseDate,
            fileSize: fileSize,
            // ... other fields
        )
    }
}
```

### Benefits

1. **Type Safety**: Compiler-enforced conversion methods
2. **Reusability**: Generic CloudKit operations work with any `CloudKitRecord`
3. **Testability**: Easy to unit test conversions independently
4. **Maintainability**: Single source of truth for field mapping

### Generic Sync Pattern

```swift
extension RecordManaging {
    func sync<T: CloudKitRecord>(_ records: [T]) async throws {
        let operations = records.map { record in
            RecordOperation(
                operationType: .forceReplace,
                recordType: T.cloudKitRecordType,
                recordName: record.recordName,
                fields: record.toCloudKitFields()
            )
        }

        try await executeBatchOperations(operations, recordType: T.cloudKitRecordType)
    }
}
```

## Schema Design Patterns

### Schema File Format

```text
DEFINE SCHEMA

RECORD TYPE RestoreImage (
    "version"       STRING QUERYABLE SORTABLE SEARCHABLE,
    "buildNumber"   STRING QUERYABLE SORTABLE,
    "releaseDate"   TIMESTAMP QUERYABLE SORTABLE,
    "fileSize"      INT64,
    "isSigned"      INT64 QUERYABLE,           # Boolean as INT64
    "minimumMacOS"  REFERENCE,                 # Relationship

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"                     # Public read access
);
```

### Key Principles

1. **Always include `DEFINE SCHEMA` header** - Required by `cktool`
2. **Never include system fields** - `__recordID`, `___createTime`, etc. are automatic
3. **Use INT64 for booleans** - CloudKit doesn't have native boolean type
4. **Use REFERENCE for relationships** - Links between record types
5. **Mark query fields appropriately**:
   - `QUERYABLE` - Can filter on this field
   - `SORTABLE` - Can order results by this field
   - `SEARCHABLE` - Enable full-text search

6. **Set appropriate permissions**:
   - `_creator` - Record owner (read/write)
   - `_icloud` - Authenticated iCloud users
   - `_world` - Public (read-only typically)

### Indexing Strategy

```swift
// Fields you'll query on
"buildNumber" STRING QUERYABLE              // WHERE buildNumber = "21A5522h"
"releaseDate" TIMESTAMP QUERYABLE SORTABLE  // ORDER BY releaseDate DESC
"version" STRING SEARCHABLE                 // Full-text search
```

### Automated Schema Deployment

Bushel includes `Scripts/setup-cloudkit-schema.sh`:

```bash
#!/bin/bash
set -euo pipefail

CONTAINER_ID="${CLOUDKIT_CONTAINER_ID}"
MANAGEMENT_TOKEN="${CLOUDKIT_MANAGEMENT_TOKEN}"
ENVIRONMENT="${CLOUDKIT_ENVIRONMENT:-development}"

cktool -t "$MANAGEMENT_TOKEN" \
       -c "$CONTAINER_ID" \
       -e "$ENVIRONMENT" \
       import-schema schema.ckdb
```

## Server-to-Server Authentication

### Setup Process

1. **Generate CloudKit Key** (Apple Developer portal):
   - Navigate to Certificates, Identifiers & Profiles
   - Keys → CloudKit Web Service
   - Download `.p8` file and note Key ID

2. **Secure Key Storage**:
```bash
mkdir -p ~/.cloudkit
chmod 700 ~/.cloudkit
mv AuthKey_*.p8 ~/.cloudkit/bushel-private-key.pem
chmod 600 ~/.cloudkit/bushel-private-key.pem
```

3. **Environment Variables**:
```bash
export CLOUDKIT_KEY_ID="your_key_id_here"
export CLOUDKIT_KEY_FILE="$HOME/.cloudkit/bushel-private-key.pem"
```

### Implementation

```swift
// Read private key from disk
let pemString = try String(
    contentsOfFile: privateKeyPath,
    encoding: .utf8
)

// Create authentication manager
let tokenManager = try ServerToServerAuthManager(
    keyID: keyID,
    pemString: pemString
)

// Create CloudKit service
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.company.App",
    tokenManager: tokenManager,
    environment: .development,
    database: .public
)
```

### Security Best Practices

- ✅ Never commit `.p8` or `.pem` files to version control
- ✅ Store keys with restricted permissions (600)
- ✅ Use environment variables for key paths
- ✅ Use different keys for development vs production
- ✅ Rotate keys periodically
- ❌ Never hardcode keys in source code
- ❌ Never share keys across projects

## Batch Operations

### CloudKit Limits

- **Maximum 200 operations per request**
- **Maximum 400 operations per transaction**
- **Rate limits apply per container**

### Batching Pattern

```swift
func executeBatchOperations(
    _ operations: [RecordOperation],
    recordType: String
) async throws {
    let batchSize = 200
    let batches = operations.chunked(into: batchSize)

    for (index, batch) in batches.enumerated() {
        print("  Batch \(index + 1)/\(batches.count)...")

        let results = try await service.modifyRecords(batch)

        // Handle partial failures
        let successful = results.filter { !$0.isError }
        let failed = results.count - successful.count

        if failed > 0 {
            print("   ⚠️  \(failed) operations failed")

            // Log specific failures
            for result in results where result.isError {
                if let error = result.error {
                    print("   Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
```

### Non-Atomic Operations

```swift
let operations = articles.map { article in
    RecordOperation(
        operationType: .create,
        recordType: "PublicArticle",
        recordName: article.recordName,
        fields: article.toFieldsDict()
    )
}

// Non-atomic: partial success possible
let results = try await service.modifyRecords(operations)

// Check individual results
for (index, result) in results.enumerated() {
    if result.isError {
        print("Article \(index) failed: \(result.error?.localizedDescription ?? "Unknown")")
    }
}
```

## Relationship Handling

### Schema Definition

```text
RECORD TYPE XcodeVersion (
    "version"           STRING QUERYABLE,
    "releaseDate"       TIMESTAMP QUERYABLE SORTABLE,
    "minimumMacOS"      REFERENCE,              # → RestoreImage
    "requiredSwift"     REFERENCE               # → SwiftVersion
);

RECORD TYPE RestoreImage (
    "buildNumber"       STRING QUERYABLE,
    ...
);
```

### Using References in Code

```swift
// Create reference field
let minimumMacOSRef = FieldValue.Reference(
    recordName: "RestoreImage-21A5522h"
)

fields["minimumMacOS"] = .reference(minimumMacOSRef)
```

### Syncing Order (Respecting Dependencies)

```swift
// 1. Sync independent records first
try await sync(swiftVersions)
try await sync(restoreImages)

// 2. Then sync records with dependencies
try await sync(xcodeVersions)  // References swift/restore images
```

### Querying Relationships

```swift
// Query Xcode versions with specific macOS requirement
let filter = QueryFilter.equals(
    "minimumMacOS",
    .reference(FieldValue.Reference(recordName: "RestoreImage-21A5522h"))
)

let results = try await service.queryRecords(
    recordType: "XcodeVersion",
    filters: [filter]
)
```

## Data Pipeline Architecture

### Multi-Source Fetching

```swift
struct DataSourcePipeline: Sendable {
    func fetch(options: Options) async throws -> FetchResult {
        // Parallel fetching with structured concurrency
        async let ipswImages = IPSWFetcher().fetch()
        async let appleDBImages = AppleDBFetcher().fetch()
        async let xcodeVersions = XcodeReleaseFetcher().fetch()

        // Collect all results
        var allImages = try await ipswImages
        allImages.append(contentsOf: try await appleDBImages)

        // Deduplicate and return
        return FetchResult(
            restoreImages: deduplicateRestoreImages(allImages),
            xcodeVersions: try await xcodeVersions,
            swiftVersions: extractSwiftVersions()
        )
    }
}
```

### Individual Fetcher Pattern

```swift
protocol DataSourceFetcher: Sendable {
    associatedtype Record
    func fetch() async throws -> [Record]
}

struct IPSWFetcher: DataSourceFetcher {
    func fetch() async throws -> [RestoreImageRecord] {
        let client = IPSWDownloads(transport: URLSessionTransport())
        let device = try await client.device(withIdentifier: "VirtualMac2,1")

        return device.firmwares.map { firmware in
            RestoreImageRecord(
                version: firmware.version.description,
                buildNumber: firmware.buildid,
                releaseDate: firmware.releasedate,
                fileSize: firmware.filesize,
                isSigned: firmware.signed
            )
        }
    }
}
```

### Deduplication Strategy

```swift
private func deduplicateRestoreImages(
    _ images: [RestoreImageRecord]
) -> [RestoreImageRecord] {
    var uniqueImages: [String: RestoreImageRecord] = [:]

    for image in images {
        let key = image.buildNumber  // Unique identifier

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

private func mergeRestoreImages(
    _ a: RestoreImageRecord,
    _ b: RestoreImageRecord
) -> RestoreImageRecord {
    // Prefer non-nil values
    RestoreImageRecord(
        version: a.version,
        buildNumber: a.buildNumber,
        releaseDate: a.releaseDate,
        fileSize: a.fileSize ?? b.fileSize,
        isSigned: a.isSigned ?? b.isSigned,
        url: a.url ?? b.url
    )
}
```

### Graceful Degradation

```swift
// Don't fail entire sync if one source fails
var allImages: [RestoreImageRecord] = []

do {
    let ipswImages = try await IPSWFetcher().fetch()
    allImages.append(contentsOf: ipswImages)
} catch {
    print("   ⚠️  IPSW fetch failed: \(error)")
}

do {
    let appleDBImages = try await AppleDBFetcher().fetch()
    allImages.append(contentsOf: appleDBImages)
} catch {
    print("   ⚠️  AppleDB fetch failed: \(error)")
}

// Continue with whatever data we got
return deduplicateRestoreImages(allImages)
```

### Metadata Tracking

```swift
struct DataSourceMetadata: CloudKitRecord {
    let sourceName: String
    let recordTypeName: String
    let lastFetchedAt: Date
    let recordCount: Int
    let fetchDurationSeconds: Double
    let lastError: String?

    var recordName: String {
        "metadata-\(sourceName)-\(recordTypeName)"
    }
}

// Check before fetching
private func shouldFetch(
    source: String,
    recordType: String,
    force: Bool
) async -> Bool {
    guard !force else { return true }

    let metadata = try? await cloudKit.queryDataSourceMetadata(
        source: source,
        recordType: recordType
    )

    guard let existing = metadata else { return true }

    let timeSinceLastFetch = Date().timeIntervalSince(existing.lastFetchedAt)
    let minInterval = configuration.minimumInterval(for: source) ?? 3600

    return timeSinceLastFetch >= minInterval
}
```

## Celestra vs Bushel Comparison

### Architecture Similarities

| Aspect | Bushel | Celestra |
|--------|---------|----------|
| **Schema Management** | `schema.ckdb` + setup script | `schema.ckdb` + setup script |
| **Authentication** | Server-to-Server (PEM) | Server-to-Server (PEM) |
| **CLI Framework** | ArgumentParser | ArgumentParser |
| **Concurrency** | async/await | async/await |
| **Database** | Public | Public |
| **Documentation** | Comprehensive | Comprehensive |

### Key Differences

#### 1. Record Conversion Pattern

**Bushel (Protocol-Based):**
```swift
protocol CloudKitRecord {
    func toCloudKitFields() -> [String: FieldValue]
    static func from(recordInfo: RecordInfo) -> Self?
}

struct RestoreImageRecord: CloudKitRecord { ... }

// Generic sync
func sync<T: CloudKitRecord>(_ records: [T]) async throws
```

**Celestra (Direct Mapping):**
```swift
struct PublicArticle {
    func toFieldsDict() -> [String: FieldValue] { ... }
    init(from recordInfo: RecordInfo) { ... }
}

// Specific sync methods
func createArticles(_ articles: [PublicArticle]) async throws
```

**Trade-offs:**
- Bushel: More generic, reusable patterns
- Celestra: Simpler, more direct for single-purpose tool

#### 2. Relationship Handling

**Bushel (CKReference):**
```swift
fields["minimumMacOS"] = .reference(
    FieldValue.Reference(recordName: "RestoreImage-21A5522h")
)
```

**Celestra (String-Based):**
```swift
fields["feedRecordName"] = .string(feedRecordName)
```

**Trade-offs:**
- Bushel: Type-safe relationships, cascade deletes possible
- Celestra: Simpler querying, manual cascade handling

#### 3. Data Pipeline Complexity

**Bushel:**
- Multiple external data sources
- Parallel fetching with `async let`
- Complex deduplication (merge strategies)
- Cross-record relationships (Xcode → Swift, RestoreImage)

**Celestra:**
- Single data source type (RSS feeds)
- Sequential or parallel feed updates
- Simple deduplication (GUID-based)
- Parent-child relationship only (Feed → Articles)

#### 4. Deduplication Strategy

**Bushel:**
```swift
// Merge records from multiple sources
private func mergeRestoreImages(
    _ a: RestoreImageRecord,
    _ b: RestoreImageRecord
) -> RestoreImageRecord {
    // Combine data, prefer most complete
}
```

**Celestra (Recommended):**
```swift
// Query existing before upload
let existingArticles = try await queryArticlesByGUIDs(guids, feedRecordName)
let newArticles = articles.filter { article in
    !existingArticles.contains { $0.guid == article.guid }
}
```

### When to Use Each Pattern

**Use Bushel's Protocol Pattern When:**
- Multiple record types with similar operations
- Building a reusable framework
- Complex relationship graphs
- Need maximum type safety

**Use Celestra's Direct Pattern When:**
- Simple, focused tool
- Single or few record types
- Straightforward relationships
- Prioritizing simplicity

### Common Best Practices (Both Projects)

1. ✅ **Schema-First Design** - Define `schema.ckdb` before coding
2. ✅ **Automated Setup Scripts** - Script schema deployment
3. ✅ **Server-to-Server Auth** - Use PEM keys, not user auth
4. ✅ **Batch Operations** - Respect 200-record limit
5. ✅ **Error Handling** - Graceful degradation
6. ✅ **Documentation** - Comprehensive README and setup guides
7. ✅ **Environment Variables** - Never hardcode credentials
8. ✅ **Structured Concurrency** - Use async/await throughout

## Additional Resources

- **Bushel Source**: `Examples/Bushel/`
- **Celestra Source**: `Examples/Celestra/`
- **MistKit Documentation**: Root README.md
- **CloudKit Web Services**: `.claude/docs/webservices.md`
- **Swift OpenAPI Generator**: `.claude/docs/swift-openapi-generator.md`

## Conclusion

Both Bushel and Celestra demonstrate effective CloudKit integration patterns using MistKit, with different trade-offs based on project complexity and requirements. Use this document as a reference when designing CloudKit-backed applications with MistKit.

For blog posts or tutorials:
- **Beginners**: Start with Celestra's direct approach
- **Advanced**: Explore Bushel's protocol-oriented patterns
- **Production**: Consider adopting patterns from both based on your needs
