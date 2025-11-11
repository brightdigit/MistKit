# AI Agent CloudKit Schema Workflow Guide

**Audience:** Claude Code, AI agents, and developers working with text-based CloudKit schemas in MistKit projects.

**Purpose:** Comprehensive guide for understanding, designing, modifying, and validating CloudKit schemas using text-based `.ckdb` files and command-line tools.

---

## Table of Contents

1. [Understanding .ckdb Files](#understanding-ckdb-files)
2. [Schema Design Decision Framework](#schema-design-decision-framework)
3. [Modifying Schemas with Text Tools](#modifying-schemas-with-text-tools)
4. [Validation and Testing](#validation-and-testing)
5. [Swift Code Generation](#swift-code-generation)
6. [Common Patterns and Examples](#common-patterns-and-examples)

---

## Understanding .ckdb Files

### What is a `.ckdb` File?

A `.ckdb` file is a text-based representation of a CloudKit database schema using the CloudKit Schema Language. It's version-controlled alongside your code and serves as the source of truth for your database structure.

### Basic Structure

Every schema file follows this pattern:

```
DEFINE SCHEMA

[Optional: CREATE ROLE statements]

RECORD TYPE TypeName (
    field-name data-type [options],
    ...
    GRANT permissions TO roles
);

[More RECORD TYPE definitions]
```

### Reading the Celestra Schema

Let's analyze the Celestra RSS reader schema line by line:

**File:** `Examples/Celestra/schema.ckdb`

```
DEFINE SCHEMA
```
**Analysis:** Every schema starts with `DEFINE SCHEMA`. This is required.

```
RECORD TYPE Feed (
    "___recordID"            REFERENCE QUERYABLE,
```
**Analysis:**
- `Feed` is the record type name (analogous to a database table)
- `"___recordID"` is a system field (always present, triple underscore)
- Declared explicitly to add `QUERYABLE` index for efficient lookups
- Type is `REFERENCE` (represents a unique record identifier)

```
    "feedURL"                STRING QUERYABLE SORTABLE,
```
**Analysis:**
- User-defined field storing the RSS feed URL
- Type `STRING` for text data
- `QUERYABLE` - Can filter by exact URL: `feedURL == "https://..."`
- `SORTABLE` - Can sort alphabetically or use range queries
- This is likely a unique identifier, so both indexes make sense

```
    "title"                  STRING SEARCHABLE,
```
**Analysis:**
- Feed title/name
- `SEARCHABLE` enables full-text search: `title CONTAINS "Tech"`
- No `QUERYABLE` because we don't need exact title matching
- Perfect for user search features

```
    "description"            STRING,
```
**Analysis:**
- Feed description, no indexes
- Used only for display, never queried
- No indexes = lower storage cost, faster writes

```
    "totalAttempts"          INT64,
    "successfulAttempts"     INT64,
```
**Analysis:**
- Metrics fields, no indexes needed
- `INT64` for integer counters
- Not queried, just displayed in analytics

```
    "usageCount"             INT64 QUERYABLE SORTABLE,
```
**Analysis:**
- How many times this feed has been used
- `QUERYABLE SORTABLE` enables:
  - Finding feeds by usage: `usageCount > 10`
  - Sorting by popularity: `ORDER BY usageCount DESC`
  - Use case: "Show top 10 most popular feeds"

```
    "lastAttempted"          TIMESTAMP QUERYABLE SORTABLE,
```
**Analysis:**
- Last time this feed was fetched
- `TIMESTAMP` stores date/time
- Indexes enable:
  - Finding stale feeds: `lastAttempted < date`
  - Sorting by freshness: `ORDER BY lastAttempted DESC`
  - Use case: "Find feeds not updated in 24 hours"

```
    "isActive"               INT64 QUERYABLE,
```
**Analysis:**
- Boolean flag (0 = inactive, 1 = active)
- CloudKit doesn't have native boolean, use `INT64`
- `QUERYABLE` enables: `isActive == 1` to find active feeds
- Not `SORTABLE` because sorting boolean doesn't make sense

```
    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
```
**Analysis:**
- Standard public database permissions
- `"_creator"` (record owner) - full access
- `"_icloud"` (authenticated users) - can create/edit their own feeds
- `"_world"` (everyone) - can read all feeds (even unauthenticated)
- Public RSS directory pattern

```
);
```

### Article Record Type Analysis

```
RECORD TYPE Article (
    "___recordID"            REFERENCE QUERYABLE,
    "feed"                   REFERENCE QUERYABLE,
```
**Analysis:**
- `feed` field creates a relationship to the Feed record
- Type `REFERENCE` points to another record's `___recordID`
- `QUERYABLE` enables: `feed == feedRecord.recordID`
- This is a foreign key relationship

```
    "title"                  STRING SEARCHABLE,
    "link"                   STRING,
    "description"            STRING,
```
**Analysis:**
- Article content fields
- Only `title` is searchable (user searches articles by title)
- `link` and `description` are display-only

```
    "author"                 STRING QUERYABLE,
```
**Analysis:**
- Author name as plain string (not reference)
- `QUERYABLE` enables filtering: `author == "John Doe"`
- Use case: "Show all articles by this author"

```
    "pubDate"                TIMESTAMP QUERYABLE SORTABLE,
```
**Analysis:**
- Article publication date
- Critical field for RSS - most queries sort by date
- Enables: `ORDER BY pubDate DESC` (newest first)
- Also range queries: `pubDate > lastFetchDate`

```
    "guid"                   STRING QUERYABLE SORTABLE,
```
**Analysis:**
- Globally Unique Identifier from RSS feed
- `QUERYABLE` for deduplication: "Does this GUID already exist?"
- `SORTABLE` not strictly needed but allows string range queries
- Prevents duplicate article imports

```
    "contentHash"            STRING QUERYABLE,
```
**Analysis:**
- Hash of article content for change detection
- `QUERYABLE` to check: "Has this content changed?"
- Use case: Detecting updated articles

```
    "fetchedAt"              TIMESTAMP QUERYABLE SORTABLE,
    "expiresAt"              TIMESTAMP QUERYABLE SORTABLE,
```
**Analysis:**
- Caching timestamps
- `fetchedAt` - when we downloaded this article
- `expiresAt` - when to consider it stale
- Both queryable/sortable for cache management queries
- Use case: `expiresAt < now()` to find expired articles

### Key Observations

1. **Indexing Strategy:** Only indexed fields that are used in queries
2. **Reference Pattern:** `Article.feed → Feed.___recordID` creates relationship
3. **Boolean Pattern:** Use `INT64` with 0/1 values
4. **Timestamp Pattern:** Track creation, updates, and expiration
5. **Search Pattern:** `SEARCHABLE` on user-facing text fields
6. **Permission Pattern:** Standard public database grants

---

## Schema Design Decision Framework

### Field Type Selection

Use this decision tree when choosing data types:

```
Is it a relationship to another record?
├─ Yes → REFERENCE
└─ No ↓

Is it binary data or a file?
├─ Yes → ASSET (files) or BYTES (small binary data)
└─ No ↓

Is it text?
├─ Yes → STRING
└─ No ↓

Is it a date/time?
├─ Yes → TIMESTAMP
└─ No ↓

Is it a geographic location?
├─ Yes → LOCATION
└─ No ↓

Is it a number?
├─ Integer → INT64
├─ Decimal → DOUBLE
└─ Boolean → INT64 (use 0/1)

Do you need multiple values?
└─ Yes → LIST<type>
```

### Indexing Strategy Decision Framework

For each field, ask:

#### Should it be QUERYABLE?

```
Will you filter records by this field's exact value?
Examples:
  - feedURL == "https://example.com/rss"
  - isActive == 1
  - guid == "article-123"
  - feed == feedRecord.recordID

Answer YES → Add QUERYABLE
Answer NO → Skip indexing
```

**Cost:** Increases storage ~10-20%, slower writes
**Benefit:** Fast equality lookups, required for filtering

#### Should it be SORTABLE?

```
Will you sort records by this field?
OR
Will you use range queries on this field?

Examples:
  - ORDER BY pubDate DESC
  - lastAttempted < date
  - usageCount > 10
  - pubDate BETWEEN startDate AND endDate

Answer YES → Add SORTABLE
Answer NO → Skip
```

**Cost:** Increases storage ~15-25%, slower writes
**Benefit:** Fast sorting and range queries

**Note:** `SORTABLE` implies `QUERYABLE` functionality

#### Should it be SEARCHABLE?

```
Is this a text field that users will search within?
(Full-text search, not exact matching)

Examples:
  - title CONTAINS "Swift"
  - description CONTAINS "tutorial"
  - Content search in articles

Answer YES → Add SEARCHABLE (STRING fields only)
Answer NO → Skip
```

**Cost:** Increases storage ~30-50%, tokenization overhead
**Benefit:** Full-text search with word stemming and relevance

### Common Field Patterns

#### Unique Identifiers

```
"feedURL"    STRING QUERYABLE SORTABLE    // Natural key
"guid"       STRING QUERYABLE SORTABLE    // External ID
"email"      STRING QUERYABLE             // User email
```

**Pattern:** Always `QUERYABLE`, often `SORTABLE` for range scans

#### Timestamps

```
"createdAt"   TIMESTAMP QUERYABLE SORTABLE    // When created
"updatedAt"   TIMESTAMP QUERYABLE SORTABLE    // Last modified
"publishedAt" TIMESTAMP QUERYABLE SORTABLE    // Publication time
"expiresAt"   TIMESTAMP QUERYABLE SORTABLE    // Expiration time
```

**Pattern:** Almost always both `QUERYABLE` and `SORTABLE`

#### Boolean Flags

```
"isActive"    INT64 QUERYABLE    // 0 or 1
"isPublished" INT64 QUERYABLE    // 0 or 1
"isDeleted"   INT64 QUERYABLE    // Soft delete flag
```

**Pattern:** `QUERYABLE` only, never `SORTABLE` (meaningless to sort booleans)

#### Counters and Metrics

```
"viewCount"   INT64 QUERYABLE SORTABLE    // Sortable for "top N"
"likeCount"   INT64 QUERYABLE SORTABLE    // Sortable for popularity
"attempts"    INT64                       // Display only
```

**Pattern:** Index only if used in ranking/filtering

#### Text Content

```
"title"       STRING SEARCHABLE             // User searches
"name"        STRING SEARCHABLE             // User searches
"description" STRING                        // Display only
"notes"       STRING                        // Display only
"body"        STRING SEARCHABLE             // Full text search
```

**Pattern:** `SEARCHABLE` for user-facing search, nothing for display-only

#### References (Foreign Keys)

```
"feed"        REFERENCE QUERYABLE    // Parent relationship
"author"      REFERENCE QUERYABLE    // User reference
"category"    REFERENCE QUERYABLE    // Category reference
```

**Pattern:** Always `QUERYABLE` to filter by relationship

#### Lists

```
"tags"         LIST<STRING>              // Multiple tags (display)
"imageURLs"    LIST<STRING>              // Multiple URLs
"attachments"  LIST<ASSET>               // Multiple files
"relatedFeeds" LIST<REFERENCE> QUERYABLE // References (queryable)
```

**Pattern:** Rarely indexed unless specific query needs

### Permission Strategy

#### Public Database (Celestra Pattern)

```
GRANT READ, CREATE, WRITE TO "_creator"    // Owner has full control
GRANT READ, CREATE, WRITE TO "_icloud"     // Users can create their own
GRANT READ TO "_world"                     // Public read access
```

**Use case:** Public data sharing, RSS directories, blogs

#### Private Database Pattern

```
GRANT READ, CREATE, WRITE TO "_creator"    // Only owner can access
```

**Use case:** Personal data, user preferences, private content

#### Shared Database Pattern

```
CREATE ROLE Editor;

GRANT READ, WRITE TO "_creator"            // Owner can read/write
GRANT READ TO Editor                       // Editors can read
GRANT READ TO "_icloud"                    // Participants can read
```

**Use case:** Collaborative documents, shared projects

#### Admin-Only Pattern

```
CREATE ROLE Admin;

GRANT READ, CREATE, WRITE TO Admin         // Only admins
GRANT READ TO "_icloud"                    // Users can read
```

**Use case:** Configuration data, system settings

---

## Modifying Schemas with Text Tools

### Adding a New Field

**Scenario:** Add a `lastError` field to track fetch failures

```diff
RECORD TYPE Feed (
    "___recordID"            REFERENCE QUERYABLE,
    "feedURL"                STRING QUERYABLE SORTABLE,
    "title"                  STRING SEARCHABLE,
    "description"            STRING,
+   "lastError"              STRING,
    "totalAttempts"          INT64,
    ...
);
```

**Steps:**
1. Open `schema.ckdb` in text editor
2. Add field in appropriate location (group related fields)
3. Choose type (`STRING` for error messages)
4. Decide on indexing (none needed for error display)
5. Save file
6. Validate (see [Validation](#validation-and-testing))

### Adding an Index to Existing Field

**Scenario:** Make `author` sortable for "sort by author" feature

```diff
RECORD TYPE Article (
    "___recordID"            REFERENCE QUERYABLE,
    "feed"                   REFERENCE QUERYABLE,
    "title"                  STRING SEARCHABLE,
    "link"                   STRING,
    "description"            STRING,
-   "author"                 STRING QUERYABLE,
+   "author"                 STRING QUERYABLE SORTABLE,
    ...
);
```

**Impact:** Safe addition, no data loss

### Adding a New Record Type

**Scenario:** Add `Category` record type for feed categorization

```diff
DEFINE SCHEMA

RECORD TYPE Feed (
    ...
);

RECORD TYPE Article (
    ...
);

+RECORD TYPE Category (
+    "___recordID"    REFERENCE QUERYABLE,
+    "name"           STRING QUERYABLE SORTABLE,
+    "description"    STRING,
+    "iconURL"        STRING,
+    "sortOrder"      INT64 QUERYABLE SORTABLE,
+
+    GRANT READ, CREATE, WRITE TO "_creator",
+    GRANT READ, CREATE, WRITE TO "_icloud",
+    GRANT READ TO "_world"
+);
```

**Impact:** Safe addition, no effect on existing data

### Adding a Reference Field

**Scenario:** Add `category` field to `Feed` to link feeds to categories

```diff
RECORD TYPE Feed (
    "___recordID"            REFERENCE QUERYABLE,
+   "category"               REFERENCE QUERYABLE,
    "feedURL"                STRING QUERYABLE SORTABLE,
    ...
);
```

**Considerations:**
- Existing `Feed` records will have `NULL` category
- Update application code to handle optional references
- Set default category for existing records via code

### Modifying Permissions

**Scenario:** Add a Moderator role with special permissions

```diff
DEFINE SCHEMA

+CREATE ROLE Moderator;

RECORD TYPE Feed (
    "___recordID"            REFERENCE QUERYABLE,
    ...
    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
+   GRANT READ, WRITE TO Moderator,
    GRANT READ TO "_world"
);
```

**Impact:** Safe change, modifies access control only

### What You CANNOT Do

#### ❌ Remove Fields (Production)

```diff
RECORD TYPE Feed (
    "___recordID"            REFERENCE QUERYABLE,
    "feedURL"                STRING QUERYABLE SORTABLE,
-   "oldField"               STRING,    // ❌ Error: Data loss in production
    ...
);
```

**Error:** CloudKit rejects schema changes that cause data loss in production

**Workaround:** Deprecate field by removing it from code but leaving in schema

#### ❌ Change Field Types

```diff
RECORD TYPE Feed (
-   "usageCount"    INT64 QUERYABLE SORTABLE,
+   "usageCount"    DOUBLE QUERYABLE SORTABLE,    // ❌ Error: Cannot change type
    ...
);
```

**Error:** Type changes are never allowed

**Workaround:** Add new field, migrate data, deprecate old field

#### ❌ Rename Fields

```diff
RECORD TYPE Feed (
-   "feedURL"    STRING QUERYABLE SORTABLE,
+   "url"        STRING QUERYABLE SORTABLE,    // ❌ This is remove + add
    ...
);
```

**Error:** Renaming = removing old field + adding new field (data loss)

**Workaround:** Add new field, copy data via code, keep old field in schema

---

## Validation and Testing

### Step 1: Syntax Validation

Validate schema file syntax before attempting import:

```bash
cktool validate-schema schema.ckdb
```

**Expected output (success):**
```
Schema validation successful
```

**Example error:**
```
Error: Line 15: Unexpected token 'QUERYABL' (typo)
Expected: QUERYABLE, SORTABLE, SEARCHABLE, or field separator
```

### Step 2: Environment Setup

Set required environment variables:

```bash
export CLOUDKIT_CONTAINER_ID="iCloud.com.yourcompany.app"
export CLOUDKIT_ENVIRONMENT="development"  # or "production"
export CLOUDKIT_MANAGEMENT_TOKEN="your_management_token_here"
```

**Get Management Token:**
1. Go to CloudKit Dashboard (https://icloud.developer.apple.com/dashboard)
2. Select your container
3. Go to "API Tokens" section
4. Click "CloudKit API Token" → Create management token
5. Copy token (starts with long alphanumeric string)

### Step 3: Import to Development

Always test in development environment first:

```bash
# Ensure development environment
export CLOUDKIT_ENVIRONMENT="development"

# Import schema
cktool import-schema schema.ckdb
```

**Expected output (success):**
```
Importing schema to container: iCloud.com.yourcompany.app
Environment: development
✓ Schema imported successfully
```

**Example error (data loss):**
```
Error: Cannot remove field 'oldField' from record type 'Feed'
This would result in data loss in existing records
Schema import aborted
```

### Step 4: Verify Schema in Dashboard

1. Open CloudKit Dashboard
2. Select your container
3. Select "Development" environment
4. Go to "Schema" → "Record Types"
5. Verify your changes appear correctly

### Step 5: Test with Real Data

Create test records using cktool or MistKit:

```swift
// Test creating a record with new schema
let feed = Feed()
feed.feedURL = "https://example.com/rss"
feed.title = "Test Feed"
feed.category = categoryReference  // New field

try await mistKit.save(feed)
```

### Validation Checklist

- [ ] Syntax validation passes (`cktool validate-schema`)
- [ ] Environment variables are set correctly
- [ ] Import to development succeeds
- [ ] Schema appears correctly in dashboard
- [ ] Can create new records with new fields
- [ ] Can query using new indexes
- [ ] Existing data still accessible
- [ ] No unexpected errors in logs
- [ ] Swift code compiles with new schema
- [ ] Tests pass with new schema

### Common Validation Errors

#### Error: Invalid field type

```
Error: Unknown data type 'BOOLEAN'
```

**Fix:** Use `INT64` instead of `BOOLEAN`

#### Error: Invalid index option

```
Error: SEARCHABLE option not allowed on INT64 fields
```

**Fix:** `SEARCHABLE` only works with `STRING` fields

#### Error: Missing permission grant

```
Warning: Record type 'Feed' has no permission grants
Records will be inaccessible
```

**Fix:** Add at least one `GRANT` statement

#### Error: Invalid identifier

```
Error: Identifier 'feed-url' contains invalid character '-'
```

**Fix:** Use underscores: `feed_url` or camelCase: `feedURL`

#### Error: Missing quotes on system field

```
Error: Unexpected token '___recordID'
```

**Fix:** Add double quotes: `"___recordID"`

---

## Swift Code Generation

### Mapping Schema to Swift Models

CloudKit schema fields map to Swift properties with type conversions:

#### Basic Type Mapping

```swift
// Schema → Swift

// STRING → String
"title" STRING
var title: String

// INT64 → Int64 or Bool
"usageCount" INT64
var usageCount: Int64

"isActive" INT64  // Boolean pattern
var isActive: Bool  // Convert in code (0 = false, 1 = true)

// DOUBLE → Double
"rating" DOUBLE
var rating: Double

// TIMESTAMP → Date
"pubDate" TIMESTAMP
var pubDate: Date

// REFERENCE → CKRecord.Reference
"feed" REFERENCE
var feed: CKRecord.Reference

// ASSET → CKAsset
"image" ASSET
var image: CKAsset

// LOCATION → CLLocation
"location" LOCATION
var location: CLLocation

// BYTES → Data
"data" BYTES
var data: Data

// LIST<T> → [T]
"tags" LIST<STRING>
var tags: [String]

"attachments" LIST<ASSET>
var attachments: [CKAsset]
```

### Celestra Swift Model Example

```swift
import Foundation
import CloudKit

struct Feed: Codable, Sendable {
    // System fields (optional to include in model)
    var recordID: CKRecord.ID?
    var createdAt: Date?
    var modifiedAt: Date?

    // Schema fields
    var feedURL: String
    var title: String
    var description: String?
    var totalAttempts: Int64
    var successfulAttempts: Int64
    var usageCount: Int64
    var lastAttempted: Date?
    var isActive: Bool  // Stored as INT64 in CloudKit

    // Computed property for recordName
    var recordName: String? {
        recordID?.recordName
    }
}

// Extension for CloudKit conversion
extension Feed {
    init(record: CKRecord) throws {
        self.recordID = record.recordID
        self.createdAt = record.creationDate
        self.modifiedAt = record.modificationDate

        guard let feedURL = record["feedURL"] as? String else {
            throw ConversionError.missingRequiredField("feedURL")
        }
        self.feedURL = feedURL

        guard let title = record["title"] as? String else {
            throw ConversionError.missingRequiredField("title")
        }
        self.title = title

        self.description = record["description"] as? String
        self.totalAttempts = record["totalAttempts"] as? Int64 ?? 0
        self.successfulAttempts = record["successfulAttempts"] as? Int64 ?? 0
        self.usageCount = record["usageCount"] as? Int64 ?? 0
        self.lastAttempted = record["lastAttempted"] as? Date

        // Convert INT64 (0/1) to Bool
        let isActiveInt = record["isActive"] as? Int64 ?? 1
        self.isActive = isActiveInt == 1
    }

    func toCKRecord() -> CKRecord {
        let record = recordID.map { CKRecord(recordType: "Feed", recordID: $0) }
            ?? CKRecord(recordType: "Feed")

        record["feedURL"] = feedURL as CKRecordValue
        record["title"] = title as CKRecordValue
        record["description"] = description as CKRecordValue?
        record["totalAttempts"] = totalAttempts as CKRecordValue
        record["successfulAttempts"] = successfulAttempts as CKRecordValue
        record["usageCount"] = usageCount as CKRecordValue
        record["lastAttempted"] = lastAttempted as CKRecordValue?

        // Convert Bool to INT64 (0/1)
        record["isActive"] = (isActive ? 1 : 0) as CKRecordValue

        return record
    }
}
```

### Article Model with Reference

```swift
struct Article: Codable, Sendable {
    var recordID: CKRecord.ID?
    var feed: CKRecord.Reference  // Reference to Feed record
    var title: String
    var link: String?
    var description: String?
    var author: String?
    var pubDate: Date?
    var guid: String
    var contentHash: String?
    var fetchedAt: Date?
    var expiresAt: Date?
}

extension Article {
    init(record: CKRecord) throws {
        self.recordID = record.recordID

        guard let feed = record["feed"] as? CKRecord.Reference else {
            throw ConversionError.missingRequiredField("feed")
        }
        self.feed = feed

        guard let title = record["title"] as? String else {
            throw ConversionError.missingRequiredField("title")
        }
        self.title = title

        guard let guid = record["guid"] as? String else {
            throw ConversionError.missingRequiredField("guid")
        }
        self.guid = guid

        self.link = record["link"] as? String
        self.description = record["description"] as? String
        self.author = record["author"] as? String
        self.pubDate = record["pubDate"] as? Date
        self.contentHash = record["contentHash"] as? String
        self.fetchedAt = record["fetchedAt"] as? Date
        self.expiresAt = record["expiresAt"] as? Date
    }

    func toCKRecord() -> CKRecord {
        let record = recordID.map { CKRecord(recordType: "Article", recordID: $0) }
            ?? CKRecord(recordType: "Article")

        record["feed"] = feed as CKRecordValue
        record["title"] = title as CKRecordValue
        record["link"] = link as CKRecordValue?
        record["description"] = description as CKRecordValue?
        record["author"] = author as CKRecordValue?
        record["pubDate"] = pubDate as CKRecordValue?
        record["guid"] = guid as CKRecordValue
        record["contentHash"] = contentHash as CKRecordValue?
        record["fetchedAt"] = fetchedAt as CKRecordValue?
        record["expiresAt"] = expiresAt as CKRecordValue?

        return record
    }
}
```

### Querying with MistKit

```swift
// Query articles by feed reference
let feedReference = CKRecord.Reference(
    recordID: feed.recordID!,
    action: .none
)

let predicate = NSPredicate(format: "feed == %@", feedReference)
let query = CKQuery(recordType: "Article", predicate: predicate)
query.sortDescriptors = [NSSortDescriptor(key: "pubDate", ascending: false)]

let articles = try await mistKit.performQuery(query)
    .map { try Article(record: $0) }

// Query active feeds
let activePredicate = NSPredicate(format: "isActive == 1")
let activeQuery = CKQuery(recordType: "Feed", predicate: activePredicate)

let activeFeeds = try await mistKit.performQuery(activeQuery)
    .map { try Feed(record: $0) }

// Full-text search in titles
let searchPredicate = NSPredicate(format: "title CONTAINS[cd] %@", "Swift")
let searchQuery = CKQuery(recordType: "Article", predicate: searchPredicate)

let searchResults = try await mistKit.performQuery(searchQuery)
    .map { try Article(record: $0) }
```

---

## Common Patterns and Examples

### Pattern: Timestamped Entities

```
RECORD TYPE Post (
    "___recordID"    REFERENCE QUERYABLE,
    "title"          STRING SEARCHABLE,
    "content"        STRING,
    "createdAt"      TIMESTAMP QUERYABLE SORTABLE,
    "updatedAt"      TIMESTAMP QUERYABLE SORTABLE,
    "publishedAt"    TIMESTAMP QUERYABLE SORTABLE,

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ TO "_world"
);
```

### Pattern: Soft Delete

```
RECORD TYPE Document (
    "___recordID"    REFERENCE QUERYABLE,
    "title"          STRING SEARCHABLE,
    "content"        STRING,
    "isDeleted"      INT64 QUERYABLE,  // 0 = active, 1 = deleted
    "deletedAt"      TIMESTAMP QUERYABLE SORTABLE,

    GRANT READ, CREATE, WRITE TO "_creator"
);
```

Query for active documents:
```swift
let predicate = NSPredicate(format: "isDeleted == 0")
```

### Pattern: Hierarchical Data

```
RECORD TYPE Category (
    "___recordID"    REFERENCE QUERYABLE,
    "name"           STRING QUERYABLE SORTABLE,
    "parent"         REFERENCE QUERYABLE,  // Self-reference
    "sortOrder"      INT64 QUERYABLE SORTABLE,

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ TO "_world"
);
```

### Pattern: Tagged Content

```
RECORD TYPE Article (
    "___recordID"    REFERENCE QUERYABLE,
    "title"          STRING SEARCHABLE,
    "content"        STRING,
    "tags"           LIST<STRING>,  // Simple tags

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ TO "_world"
);
```

### Pattern: User Profiles

```
RECORD TYPE UserProfile (
    "___recordID"    REFERENCE QUERYABLE,
    "username"       STRING QUERYABLE SORTABLE,
    "email"          STRING QUERYABLE,
    "displayName"    STRING SEARCHABLE,
    "avatarURL"      STRING,
    "bio"            STRING,
    "createdAt"      TIMESTAMP QUERYABLE SORTABLE,
    "lastSeenAt"     TIMESTAMP QUERYABLE SORTABLE,

    GRANT READ, WRITE TO "_creator",
    GRANT READ TO "_icloud"
);
```

---

## See Also

- **Quick Reference:** [.claude/docs/cloudkit-schema-reference.md](../../.claude/docs/cloudkit-schema-reference.md)
- **Setup Guide:** [CLOUDKIT_SCHEMA_SETUP.md](CLOUDKIT_SCHEMA_SETUP.md)
- **Apple Documentation:** [.claude/docs/sosumi-cloudkit-schema-source.md](../../.claude/docs/sosumi-cloudkit-schema-source.md)
- **Celestra README:** [README.md](README.md)
- **Task Master Integration:** [.taskmaster/docs/schema-design-workflow.md](../../.taskmaster/docs/schema-design-workflow.md)
