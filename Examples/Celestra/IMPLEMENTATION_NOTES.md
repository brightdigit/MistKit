# Celestra Implementation Notes

This document captures the design decisions, implementation patterns, and technical details of the Celestra RSS reader example.

## Table of Contents

- [Project Overview](#project-overview)
- [Schema Design Decisions](#schema-design-decisions)
- [Duplicate Detection Strategy](#duplicate-detection-strategy)
- [Data Model Architecture](#data-model-architecture)
- [CloudKit Integration Patterns](#cloudkit-integration-patterns)
- [Comparison with Bushel](#comparison-with-bushel)
- [Future Improvements](#future-improvements)

## Project Overview

**Purpose**: Demonstrate MistKit's CloudKit integration capabilities through a practical RSS feed reader

**Key Goals**:
- Show query filtering and sorting APIs
- Demonstrate Server-to-Server authentication
- Provide a real-world example for developers learning MistKit
- Serve as blog post material for MistKit documentation

**Target Audience**: Developers building CloudKit-backed Swift applications

## Schema Design Decisions

### Design Philosophy

We followed Bushel's schema best practices while keeping Celestra focused on simplicity:

1. **DEFINE SCHEMA Header**: Required by `cktool` for automated schema deployment
2. **No System Fields**: System fields like `__recordID` are automatically managed by CloudKit
3. **INT64 for Booleans**: CloudKit doesn't have native boolean type, use `INT64` (0 = false, 1 = true)
4. **Field Indexing Strategy**: Mark fields as QUERYABLE, SORTABLE, or SEARCHABLE based on usage patterns

### PublicFeed Schema

```text
RECORD TYPE PublicFeed (
    "feedURL"                STRING QUERYABLE SORTABLE,
    "title"                  STRING SEARCHABLE,
    "description"            STRING,
    "totalAttempts"          INT64,
    "successfulAttempts"     INT64,
    "usageCount"             INT64 QUERYABLE SORTABLE,
    "lastAttempted"          TIMESTAMP QUERYABLE SORTABLE,
    "isActive"               INT64 QUERYABLE,
    ...
)
```

**Field Decisions**:

- `feedURL` (QUERYABLE, SORTABLE): Enables querying/sorting by URL
- `title` (SEARCHABLE): Full-text search capability for feed discovery
- `description`: Optional feed description from RSS metadata
- `totalAttempts` / `successfulAttempts`: Track reliability metrics
- `usageCount` (QUERYABLE, SORTABLE): Popularity ranking for filtered queries
- `lastAttempted` (QUERYABLE, SORTABLE): Enable time-based filtering
- `isActive` (QUERYABLE): Allow filtering active/inactive feeds

### PublicArticle Schema

```text
RECORD TYPE PublicArticle (
    "feedRecordName"         STRING QUERYABLE SORTABLE,
    "title"                  STRING SEARCHABLE,
    "link"                   STRING,
    "description"            STRING,
    "author"                 STRING QUERYABLE,
    "pubDate"                TIMESTAMP QUERYABLE SORTABLE,
    "guid"                   STRING QUERYABLE SORTABLE,
    "contentHash"            STRING QUERYABLE,
    "fetchedAt"              TIMESTAMP QUERYABLE SORTABLE,
    "expiresAt"              TIMESTAMP QUERYABLE SORTABLE,
    ...
)
```

**Field Decisions**:

- `feedRecordName` (STRING, QUERYABLE, SORTABLE): Parent reference using string instead of CKReference for simplicity
- `guid` (QUERYABLE, SORTABLE): Enable duplicate detection queries
- `contentHash` (QUERYABLE): SHA256 hash for fallback duplicate detection
- `expiresAt` (QUERYABLE, SORTABLE): TTL-based cleanup (default 30 days)

**Relationship Design**:
- **Choice**: String-based relationships (`feedRecordName`) vs CloudKit references
- **Rationale**: Simpler querying, easier to understand for developers
- **Trade-off**: Manual cascade delete handling, but clearer code patterns

## Duplicate Detection Strategy

### Problem Statement

RSS feeds often republish the same articles. Without deduplication:
- Running `update` multiple times creates duplicate records
- CloudKit storage bloats with redundant data
- Query results contain duplicate entries

### Solution Architecture

**Primary Strategy: GUID-Based Detection**

1. Extract GUIDs from all fetched articles
2. Query CloudKit for existing articles with those GUIDs
3. Filter out articles that already exist
4. Only upload new articles

**Implementation** (UpdateCommand.swift:106-133):

```swift
// Duplicate detection: query existing articles by GUID
if !articles.isEmpty {
    let guids = articles.map { $0.guid }
    let existingArticles = try await service.queryArticlesByGUIDs(
        guids,
        feedRecordName: recordName
    )

    // Create set of existing GUIDs for fast lookup
    let existingGUIDs = Set(existingArticles.map { $0.guid })

    // Filter out duplicates
    let newArticles = articles.filter { !existingGUIDs.contains($0.guid) }

    if duplicateCount > 0 {
        print("   ℹ️  Skipped \(duplicateCount) duplicate(s)")
    }

    // Upload only new articles
    if !newArticles.isEmpty {
        _ = try await service.createArticles(newArticles)
    }
}
```

**Fallback Strategy: Content Hashing**

For articles with unreliable or missing GUIDs:

```swift
// In PublicArticle model
var contentHash: String {
    let content = "\(title)|\(link)|\(guid)"
    let data = Data(content.utf8)
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}
```

**Performance Considerations**:
- Set-based filtering: O(n) lookup time
- Single query per feed update (not per article)
- Batch CloudKit operations for efficiency

### Why This Approach?

**Alternatives Considered**:

1. **Check each GUID individually**
   - ❌ Too many CloudKit API calls
   - ❌ Poor performance with large feeds

2. **Upload all, handle errors**
   - ❌ Wastes CloudKit write quotas
   - ❌ Error handling complexity

3. **Local caching/database**
   - ❌ Adds complexity
   - ❌ Not suitable for command-line tool

**Chosen Solution Benefits**:
- ✅ Minimal CloudKit queries (one per feed)
- ✅ Simple to understand and maintain
- ✅ Efficient Set-based filtering
- ✅ Works well with MistKit's query API

## Data Model Architecture

### Model Design Pattern

**Choice**: Direct field mapping vs Protocol-oriented (CloudKitRecord)

Celestra uses **direct field mapping** for simplicity:

```swift
struct PublicArticle {
    let recordName: String?
    let feedRecordName: String
    let title: String
    // ... other fields

    func toFieldsDict() -> [String: FieldValue] {
        var fields: [String: FieldValue] = [
            "feedRecordName": .string(feedRecordName),
            "title": .string(title),
            // ... map fields
        ]
        return fields
    }

    init(from record: RecordInfo) {
        // Parse RecordInfo back to model
    }
}
```

**Why Not CloudKitRecord Protocol?**
- Celestra has only 2 record types (simple)
- Direct mapping is easier for developers to understand
- Protocol approach (like Bushel) better for 5+ record types

See `BUSHEL_PATTERNS.md` for protocol-oriented alternative.

### Field Type Conversions

**Boolean Fields** (isActive):
```swift
// To CloudKit
fields["isActive"] = .int64(isActive ? 1 : 0)

// From CloudKit
if case .int64(let value) = record.fields["isActive"] {
    self.isActive = value != 0
} else {
    self.isActive = true  // Default
}
```

**Optional Fields** (description):
```swift
// To CloudKit
if let description = description {
    fields["description"] = .string(description)
}

// From CloudKit
if case .string(let value) = record.fields["description"] {
    self.description = value
} else {
    self.description = nil
}
```

## CloudKit Integration Patterns

### Query Filtering Pattern

**Location**: CloudKitService+Celestra.swift:26-53

```swift
func queryFeeds(
    lastAttemptedBefore: Date? = nil,
    minPopularity: Int64? = nil,
    limit: Int = 100
) async throws -> [PublicFeed] {
    var filters: [QueryFilter] = []

    // Date comparison filter
    if let cutoff = lastAttemptedBefore {
        filters.append(.lessThan("lastAttempted", .date(cutoff)))
    }

    // Numeric comparison filter
    if let minPop = minPopularity {
        filters.append(.greaterThanOrEquals("usageCount", .int64(Int(minPop))))
    }

    // Query with filters and sorting
    let records = try await queryRecords(
        recordType: "PublicFeed",
        filters: filters.isEmpty ? nil : filters,
        sortBy: [.descending("usageCount")],
        limit: limit
    )

    return records.map { PublicFeed(from: $0) }
}
```

**Demonstrates**:
- Optional filters pattern
- Date and numeric comparisons
- Query sorting
- Result mapping

### Batch Operations Pattern

**Non-Atomic Operations** with chunking and result tracking:

```swift
func createArticles(_ articles: [PublicArticle]) async throws -> BatchOperationResult {
    guard !articles.isEmpty else {
        return BatchOperationResult()
    }

    // Chunk articles into batches of 200 (CloudKit limit)
    let batches = articles.chunked(into: 200)
    var result = BatchOperationResult()

    for (index, batch) in batches.enumerated() {
        let records = batch.map { article in
            (recordType: "PublicArticle", fields: article.toFieldsDict())
        }

        // Use retry policy for each batch
        let recordInfos = try await retryPolicy.execute {
            try await self.createRecords(records, atomic: false)
        }

        result.appendSuccesses(recordInfos)
    }

    return result
}
```

**Why This Approach?**
- **Non-atomic operations**: If 1 of 100 articles fails, still upload the other 99
- **200-record batches**: Respects CloudKit's batch operation limits
- **Result tracking**: `BatchOperationResult` provides success/failure counts and rates
- **Retry logic**: Each batch operation uses exponential backoff for transient failures
- **Better UX**: Partial success vs total failure, with detailed progress reporting

**BatchOperationResult Structure**:
```swift
struct BatchOperationResult {
    var successfulRecords: [RecordInfo] = []
    var failedRecords: [(article: PublicArticle, error: Error)] = []
    var successRate: Double  // 0-100%
}
```

### Server-to-Server Authentication

**Location**: Celestra.swift (CelestraConfig.createCloudKitService)

```swift
// Read private key from file
let pemString = try String(
    contentsOf: URL(fileURLWithPath: privateKeyPath),
    encoding: .utf8
)

// Create token manager
let tokenManager = try ServerToServerAuthManager(
    keyID: keyID,
    pemString: pemString
)

// Create CloudKit service
let service = try CloudKitService(
    containerIdentifier: containerID,
    tokenManager: tokenManager,
    environment: environment,
    database: .public
)
```

**Security Best Practices**:
- Never commit `.pem` files
- Store keys with restricted permissions (chmod 600)
- Use environment variables for paths
- Different keys for dev/prod

## Comparison with Bushel

### Architecture Similarities

| Aspect | Bushel | Celestra |
|--------|---------|----------|
| **Schema Management** | schema.ckdb + setup script | schema.ckdb + setup script |
| **Authentication** | Server-to-Server (PEM) | Server-to-Server (PEM) |
| **CLI Framework** | ArgumentParser | ArgumentParser |
| **Concurrency** | async/await | async/await |
| **Database** | Public | Public |

### Key Differences

**1. Record Conversion**:
- Bushel: CloudKitRecord protocol (generic, reusable)
- Celestra: Direct field mapping (simple, focused)

**2. Data Sources**:
- Bushel: Multiple external APIs (IPSW, AppleDB, XcodeReleases)
- Celestra: Single source type (RSS feeds via SyndiKit)

**3. Relationships**:
- Bushel: CKReference for type-safe relationships
- Celestra: String-based for simplicity

**4. Deduplication**:
- Bushel: Merge strategies for multiple sources
- Celestra: GUID-based query before upload

### When to Use Each Pattern

**Use Bushel Patterns When**:
- 5+ record types with similar operations
- Complex relationship graphs
- Multiple data sources to merge
- Building a reusable framework

**Use Celestra Patterns When**:
- 2-3 simple record types
- Straightforward relationships
- Single or few data sources
- Focused command-line tool

See `BUSHEL_PATTERNS.md` for detailed comparison.

## Error Handling and Retry Logic

### Implemented Features

**Comprehensive Error Categorization** (CelestraError.swift):

```swift
enum CelestraError: LocalizedError {
    case cloudKitError(CloudKitError)
    case rssFetchFailed(URL, underlying: Error)
    case invalidFeedData(String)
    case quotaExceeded
    case networkUnavailable

    var isRetriable: Bool {
        // Smart retry logic based on error type
    }
}
```

**Exponential Backoff with Jitter** (RetryPolicy.swift):

```swift
struct RetryPolicy {
    let maxAttempts: Int = 3
    let baseDelay: TimeInterval = 1.0
    let maxDelay: TimeInterval = 30.0
    let jitter: Bool = true

    func execute<T>(operation: () async throws -> T) async throws -> T {
        // Implements exponential backoff: 1s, 2s, 4s...
        // With jitter to avoid thundering herd
    }
}
```

**Structured Logging** (CelestraLogger.swift):

```swift
import os

enum CelestraLogger {
    static let cloudkit = Logger(subsystem: "com.brightdigit.Celestra", category: "cloudkit")
    static let rss = Logger(subsystem: "com.brightdigit.Celestra", category: "rss")
    static let operations = Logger(subsystem: "com.brightdigit.Celestra", category: "operations")
    static let errors = Logger(subsystem: "com.brightdigit.Celestra", category: "errors")
}
```

**Integration Points**:
- RSS feed fetching with retry and timeout handling
- CloudKit batch operations with per-batch retry
- Query operations with transient error recovery
- User-facing error messages with recovery suggestions

## Incremental Update System

### Content Change Detection

**Implementation** (UpdateCommand.swift):

```swift
// Separate articles into new vs modified
for article in articles {
    if let existing = existingMap[article.guid] {
        // Check if content changed
        if existing.contentHash != article.contentHash {
            modifiedArticles.append(article.withRecordName(existing.recordName!))
        }
    } else {
        newArticles.append(article)
    }
}

// Create new articles
if !newArticles.isEmpty {
    let result = try await service.createArticles(newArticles)
    print("   ✅ Created \(result.successCount) new article(s)")
}

// Update modified articles
if !modifiedArticles.isEmpty {
    let result = try await service.updateArticles(modifiedArticles)
    print("   🔄 Updated \(result.successCount) modified article(s)")
}
```

**Benefits**:
- Detects content changes using SHA256 contentHash
- Only updates articles when content actually changes
- Reduces unnecessary CloudKit write operations
- Preserves CloudKit metadata (creation date, etc.)

### Update Operations

**New Method** (CloudKitService+Celestra.swift):

```swift
func updateArticles(_ articles: [PublicArticle]) async throws -> BatchOperationResult {
    // Filters articles with recordName
    // Chunks into 200-record batches
    // Uses RecordOperation.update
    // Tracks success/failure per batch
}
```

## Future Improvements

### Potential Enhancements

**1. Rate Limiting** (Recommended):
Add delays between feed fetches to avoid overwhelming feed servers:
```swift
// After each feed update
try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
```

**2. CKReference Relationships** (Optional):
Switch from string-based to proper CloudKit references:
```swift
// Instead of:
fields["feedRecordName"] = .string(feedRecordName)

// Use:
fields["feed"] = .reference(FieldValue.Reference(recordName: feedRecordName))
```

**Trade-off Analysis**:
- **String-based (Current)**:
  - ✅ Simpler querying: `filter: .equals("feedRecordName", .string(name))`
  - ✅ Easier to understand for developers
  - ✅ More explicit relationship handling
  - ❌ Manual cascade delete implementation
  - ❌ No type safety enforcement

- **CKReference-based**:
  - ✅ Type safety and CloudKit validation
  - ✅ Automatic cascade deletes
  - ✅ Better relationship queries
  - ❌ More complex querying
  - ❌ Additional abstraction layer needed

**Decision**: Kept string-based for educational simplicity and explicit code patterns. For production apps handling complex relationship graphs, CKReference is recommended.

**3. Circuit Breaker Pattern**:
For feeds with persistent failures:
```swift
actor CircuitBreaker {
    private var failureCount = 0
    private let threshold = 5

    var isOpen: Bool {
        failureCount >= threshold
    }

    func recordFailure() {
        failureCount += 1
    }
}
```

## Implementation Timeline

**Phase 1** (Completed):
- ✅ Schema design with automated deployment
- ✅ RSS fetching with SyndiKit integration
- ✅ Basic CloudKit operations (create, query, update, delete)
- ✅ CLI with ArgumentParser subcommands

**Phase 2** (Completed):
- ✅ Duplicate detection with GUID-based queries
- ✅ Content hash fallback implementation
- ✅ Schema improvements (description, isActive, contentHash fields)
- ✅ Comprehensive documentation

**Phase 3** (Completed - Task 7):
- ✅ Error handling with comprehensive CelestraError types
- ✅ Retry logic with exponential backoff and jitter
- ✅ Structured logging using os.Logger
- ✅ Batch operations with 200-record chunking
- ✅ BatchOperationResult for success/failure tracking
- ✅ Incremental update system (create + update)
- ✅ Content change detection via contentHash
- ✅ Relationship design documentation

**Phase 4** (Future):
- ⏳ Rate limiting between feed fetches
- ⏳ Circuit breaker pattern for persistent failures
- ⏳ Test suite with mock CloudKit service
- ⏳ Performance monitoring and metrics

## Conclusion

Celestra successfully demonstrates MistKit's core capabilities while maintaining simplicity for educational purposes. The implementation balances real-world practicality with code clarity, making it an effective reference for developers learning CloudKit integration patterns.

For more advanced patterns, see the Bushel example and `BUSHEL_PATTERNS.md`.
