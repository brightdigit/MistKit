# Celestra Implementation Notes

This document captures the design decisions, implementation patterns, and technical details of the Celestra RSS reader example.

## Table of Contents

- [Project Overview](#project-overview)
- [Schema Design Decisions](#schema-design-decisions)
- [Duplicate Detection Strategy](#duplicate-detection-strategy)
- [Data Model Architecture](#data-model-architecture)
- [CloudKit Integration Patterns](#cloudkit-integration-patterns)
- [Comparison with Bushel](#comparison-with-bushel)
- [Web Etiquette Features](#web-etiquette-features)
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
RECORD TYPE Feed (
    "feedURL"                STRING QUERYABLE SORTABLE,
    "title"                  STRING SEARCHABLE,
    "description"            STRING,
    "totalAttempts"          INT64,
    "successfulAttempts"     INT64,
    "usageCount"             INT64 QUERYABLE SORTABLE,
    "lastAttempted"          TIMESTAMP QUERYABLE SORTABLE,
    "isActive"               INT64 QUERYABLE,

    // Web etiquette fields
    "lastModified"           STRING,
    "etag"                   STRING,
    "failureCount"           INT64,
    "lastFailureReason"      STRING,
    "minUpdateInterval"      DOUBLE,
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

**Web Etiquette Fields**:

- `lastModified`: HTTP Last-Modified header for conditional requests
- `etag`: HTTP ETag header for conditional requests
- `failureCount`: Consecutive failure counter for retry tracking
- `lastFailureReason`: Last error message for debugging
- `minUpdateInterval`: Minimum seconds between updates (from RSS `<ttl>` or syndication metadata)

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

## Web Etiquette Features

CelestraCloud demonstrates comprehensive web etiquette best practices using services from the CelestraKit package. These services (`RateLimiter` and `RobotsTxtService`) are maintained in CelestraKit to enable reuse across the Celestra ecosystem.

### Rate Limiting

**Implementation**: Configurable delays between feed fetches to avoid overwhelming feed servers.

**Default Behavior**:
- 2-second delay between different feeds
- 5-second delay when fetching from the same domain
- Respects feed's `minUpdateInterval` when available

**Usage**:
```bash
# Use default 2-second delay
celestra update

# Custom delay (5 seconds)
celestra update --delay 5.0
```

**Technical Details**:
- Uses `RateLimiter` actor from CelestraKit for thread-safe delay tracking
- Per-domain tracking prevents hammering same server
- Async/await pattern ensures non-blocking operation

### Robots.txt Checking

**Implementation**: Fetches and parses robots.txt before accessing feed URLs.

**Behavior**:
- Checks robots.txt once per domain, cached for 24 hours
- Matches User-Agent "Celestra" and wildcard "*" rules
- Defaults to "allow" if robots.txt is unavailable (fail-open approach)
- Can be bypassed for testing with `--skip-robots-check`

**Usage**:
```bash
# Normal operation (checks robots.txt)
celestra update

# Skip robots.txt for local testing
celestra update --skip-robots-check
```

**Technical Details**:
- Uses `RobotsTxtService` actor from CelestraKit
- Parses User-Agent sections, Disallow rules, and Crawl-delay directives
- Network errors default to "allow" rather than blocking feeds

### Conditional HTTP Requests

**Implementation**: Uses If-Modified-Since and If-None-Match headers to save bandwidth.

**Benefits**:
- Reduces data transfer when feeds haven't changed
- Returns 304 Not Modified for unchanged content
- Stores `lastModified` and `etag` headers in Feed records

**Technical Details**:
```swift
// Sends conditional headers
GET /feed.xml HTTP/1.1
If-Modified-Since: Wed, 13 Nov 2024 10:00:00 GMT
If-None-Match: "abc123-etag"
User-Agent: Celestra/1.0 (MistKit RSS Reader; +https://github.com/brightdigit/MistKit)

// Server responds with 304 if unchanged
HTTP/1.1 304 Not Modified
```

**Feed Model Support**:
- `lastModified: String?` - Stores Last-Modified header
- `etag: String?` - Stores ETag header
- Automatically sent on subsequent requests

### Failure Tracking

**Implementation**: Tracks consecutive failures per feed for retry management.

**Feed Model Fields**:
- `failureCount: Int64` - Consecutive failure counter
- `lastFailureReason: String?` - Last error message
- Reset to 0 on successful fetch

**Usage**:
```bash
# Skip feeds with more than 3 consecutive failures
celestra update --max-failures 3
```

**Benefits**:
- Identifies problematic feeds
- Prevents wasting resources on persistently broken feeds
- Provides debugging information via `lastFailureReason`

**Future Enhancement**: Auto-disable feeds after threshold (not yet implemented)

### Custom User-Agent

**Implementation**: Identifies as a polite RSS client with contact information.

**User-Agent String**:
```
Celestra/1.0 (MistKit RSS Reader; +https://github.com/brightdigit/MistKit)
```

**Benefits**:
- Feed publishers can identify traffic source
- Contact URL for questions or concerns
- Follows best practices for web scraping etiquette

### Feed Update Interval Tracking

**Implementation**: Infrastructure to respect feed's requested update frequency.

**Feed Model Field**:
- `minUpdateInterval: TimeInterval?` - Minimum seconds between updates

**Sources** (Priority Order):
1. RSS `<ttl>` tag (minutes)
2. Syndication module `<sy:updatePeriod>` + `<sy:updateFrequency>`
3. HTTP `Cache-Control: max-age` headers
4. Default: No minimum (respect global rate limit only)

**Current Status**:
- ✅ Field exists in Feed model
- ✅ Stored and retrieved from CloudKit
- ✅ Respected by RateLimiter when present
- ✅ Used to skip feeds within update window
- ⏳ RSS parsing not yet implemented (TODO in RSSFetcherService)

**Example Usage**:
```bash
# Feed with minUpdateInterval will be skipped if updated recently
celestra update

# Output:
# [1/5] 📰 Tech News Feed
#    ⏭️  Skipped (update requested in 45 minutes)
```

### Command Examples

```bash
# Basic update with all web etiquette features
celestra update

# Custom rate limit and failure filtering
celestra update --delay 3.0 --max-failures 5

# Update only feeds last attempted before a specific date
celestra update --last-attempted-before 2025-01-01T00:00:00Z

# Combined filters
celestra update \
  --delay 5.0 \
  --max-failures 3 \
  --last-attempted-before 2025-01-01T00:00:00Z \
  --min-popularity 10
```

## Future Improvements

### Potential Enhancements

**1. RSS TTL Parsing** (Recommended):
Parse RSS `<ttl>` and `<sy:updatePeriod>` tags to populate `minUpdateInterval`:
```swift
// In RSSFetcherService.parseUpdateInterval()
if let ttl = feed.ttl {
    return TimeInterval(ttl * 60)  // Convert minutes to seconds
}

if let period = feed.updatePeriod, let frequency = feed.updateFrequency {
    let periodSeconds = periodToSeconds(period)
    return periodSeconds / Double(frequency)
}
```

**Status**: Infrastructure exists, SyndiKit integration needed

**2. Article TTL from Feed Interval**:
Use feed's `minUpdateInterval` to calculate article expiration:
```swift
// Instead of hardcoded 30 days
let ttl = feed.minUpdateInterval ?? (30 * 24 * 60 * 60)
let article = Article(
    // ...
    expiresAt: Date().addingTimeInterval(ttl * 5)  // 5x multiplier
)
```

**Status**: `expiresAt` field exists, calculation logic needs update

**3. Cleanup Command**:
Add command to delete expired articles:
```bash
celestra cleanup-expired
```

**Status**: Schema supports queries, command not implemented

**4. Auto-Disable Failed Feeds**:
Automatically set `isActive = false` after reaching failure threshold:
```swift
if feed.failureCount >= 10 {
    updatedFeed.isActive = false
    print("   🔴 Feed auto-disabled after 10 consecutive failures")
}
```

**Status**: Tracking exists, auto-disable logic not implemented

**5. CKReference Relationships** (Optional):
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

**Phase 3** (Completed):
- ✅ Error handling with comprehensive CelestraError types
- ✅ Structured logging using os.Logger
- ✅ Batch operations with 200-record chunking
- ✅ BatchOperationResult for success/failure tracking
- ✅ Incremental update system (create + update)
- ✅ Content change detection via contentHash
- ✅ Relationship design documentation
- ✅ Web etiquette: Rate limiting with configurable delays
- ✅ Web etiquette: Robots.txt checking and parsing
- ✅ Web etiquette: Conditional HTTP requests (If-Modified-Since/ETag)
- ✅ Web etiquette: Failure tracking for retry management
- ✅ Web etiquette: Custom User-Agent header
- ✅ Feed update interval infrastructure (`minUpdateInterval`)

**Phase 4** (Future):
- ⏳ RSS TTL parsing (`<ttl>`, `<sy:updatePeriod>`)
- ⏳ Article TTL calculated from feed interval
- ⏳ Cleanup command for expired articles
- ⏳ Auto-disable feeds after failure threshold
- ⏳ Test suite with mock CloudKit service
- ⏳ Performance monitoring and metrics

## Conclusion

Celestra successfully demonstrates MistKit's core capabilities while maintaining simplicity for educational purposes. The implementation balances real-world practicality with code clarity, making it an effective reference for developers learning CloudKit integration patterns.

For more advanced patterns, see the Bushel example and `BUSHEL_PATTERNS.md`.
