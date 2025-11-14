# CloudKit Schema Language Quick Reference

**For AI Agents:** This quick reference provides essential CloudKit Schema Language syntax and patterns for reading and modifying `.ckdb` schema files in MistKit projects.

**Source:** Derived from [Apple's CloudKit Schema Language Documentation](https://developer.apple.com/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow) via [sosumi.ai](https://sosumi.ai/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow)

---

## Grammar Overview

```
DEFINE SCHEMA
    [ { create-role | record-type } ";" ] ...

CREATE ROLE %role-name%

RECORD TYPE %type-name% (
    %field-name% data-type [ QUERYABLE | SORTABLE | SEARCHABLE ] [, ...]
    GRANT { READ | CREATE | WRITE } [, ...] TO %role-name%
)
```

## Field Options

| Option | Purpose | Use When |
|--------|---------|----------|
| `QUERYABLE` | Index for equality lookups | Filtering by exact value (`feedURL == "..."`) |
| `SORTABLE` | Index for range searches | Range queries or sorting (`pubDate > date`, `ORDER BY pubDate`) |
| `SEARCHABLE` | Full-text search index | Text search in STRING fields (`title CONTAINS "keyword"`) |

**Note:** Fields can have multiple options (e.g., `QUERYABLE SORTABLE`)

## Data Types

### Primitive Types

| CloudKit Type | Swift Equivalent | Use Case | Example |
|---------------|------------------|----------|---------|
| `STRING` | `String` | Text data | `title STRING` |
| `INT64` | `Int64` | Integers, booleans (0/1) | `usageCount INT64` |
| `DOUBLE` | `Double` | Floating-point numbers | `rating DOUBLE` |
| `TIMESTAMP` | `Date` | Date and time | `pubDate TIMESTAMP` |
| `REFERENCE` | `CKRecord.Reference` | Relationships to other records | `feed REFERENCE` |
| `ASSET` | `CKAsset` | Files, images, binary data | `image ASSET` |
| `LOCATION` | `CLLocation` | Geographic coordinates | `location LOCATION` |
| `BYTES` | `Data` | Binary data | `data BYTES` |

### List Types

```
LIST<primitive-type>
```

Examples:
- `LIST<STRING>` → `[String]`
- `LIST<INT64>` → `[Int64]`
- `LIST<REFERENCE>` → `[CKRecord.Reference]`

### Encrypted Types

```
ENCRYPTED { STRING | INT64 | DOUBLE | BYTES | LOCATION | TIMESTAMP }
```

Example: `ENCRYPTED STRING` for sensitive data

## System Fields (Always Present)

All record types automatically include these fields:

```
"___recordID"        REFERENCE    // Unique record identifier
"___createTime"      TIMESTAMP    // Record creation time
"___modTime"         TIMESTAMP    // Last modification time
"___createdBy"       REFERENCE    // Creator reference
"___modifiedBy"      REFERENCE    // Last modifier reference
"___etag"            STRING       // Conflict resolution tag
```

**Important:** System fields are implicit. Only declare them if adding `QUERYABLE`, `SORTABLE`, or `SEARCHABLE`.

## Permission Grants

### Standard Public Database Pattern

```
GRANT READ, CREATE, WRITE TO "_creator"    // Record creator has full access
GRANT READ, CREATE, WRITE TO "_icloud"     // Authenticated iCloud users
GRANT READ TO "_world"                     // Anyone can read (even unauthenticated)
```

### Permission Types

- `READ` - Query and fetch records
- `CREATE` - Create new records of this type
- `WRITE` - Modify existing records

### Built-in Roles

- `"_creator"` - User who created the record
- `"_icloud"` - Any authenticated iCloud user
- `"_world"` - Anyone, including unauthenticated users

### Custom Roles

```
CREATE ROLE AdminUser;

RECORD TYPE ProtectedData (
    name STRING,
    GRANT READ, WRITE TO AdminUser,
    GRANT READ TO "_world"
);
```

## Naming Rules

**Identifiers must:**
- Start with `a-z` or `A-Z`
- Contain only `a-z`, `A-Z`, `0-9`, `_`
- Use double quotes for reserved words: `grant`, `preferred`, `queryable`, `sortable`, `searchable`
- Use double quotes for system fields starting with `___`

**Examples:**
- ✅ `feedURL`, `feed_url`, `Feed123`
- ❌ `123feed`, `feed-url`, `feed.url`
- ✅ `"grant"` (reserved word)
- ✅ `"___recordID"` (system field)

## Comments

```
// Single-line comment
-- Single-line comment (SQL style)
/* Multi-line
   comment */
```

**Note:** CloudKit doesn't preserve comments when uploading schemas.

## Common Patterns

### Boolean Fields (Use INT64)

CloudKit doesn't have a native boolean type. Use `INT64` with 0 (false) or 1 (true):

```
"isActive"    INT64 QUERYABLE        // 0 = inactive, 1 = active
"isPublished" INT64 QUERYABLE        // 0 = draft, 1 = published
```

### Timestamps for Tracking

```
"createdAt"   TIMESTAMP QUERYABLE SORTABLE    // Creation time
"updatedAt"   TIMESTAMP QUERYABLE SORTABLE    // Last update
"expiresAt"   TIMESTAMP QUERYABLE SORTABLE    // Expiration time
```

### References (Relationships)

```
RECORD TYPE Article (
    "feed"    REFERENCE QUERYABLE,    // Foreign key to Feed record
    "author"  REFERENCE,               // Foreign key to Author record
    ...
);
```

Query pattern: `article.feed == feedRecord.recordID`

### List Fields

```
"tags"        LIST<STRING>           // Multiple tags
"imageURLs"   LIST<STRING>           // Multiple URLs
"attachments" LIST<ASSET>            // Multiple files
"relatedIDs"  LIST<REFERENCE>        // Multiple references
```

### Text Search

```
"title"        STRING SEARCHABLE      // Full-text search
"description"  STRING SEARCHABLE      // Full-text search
"keywords"     STRING SEARCHABLE      // Full-text search
```

Query pattern: `title CONTAINS "search term"`

## MistKit-Specific Notes

### Celestra Example Schema

```
DEFINE SCHEMA

RECORD TYPE Feed (
    "___recordID"            REFERENCE QUERYABLE,
    "feedURL"                STRING QUERYABLE SORTABLE,
    "title"                  STRING SEARCHABLE,
    "description"            STRING,
    "isActive"               INT64 QUERYABLE,
    "lastAttempted"          TIMESTAMP QUERYABLE SORTABLE,
    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
);

RECORD TYPE Article (
    "___recordID"            REFERENCE QUERYABLE,
    "feed"                   REFERENCE QUERYABLE,        // References Feed.___recordID
    "title"                  STRING SEARCHABLE,
    "pubDate"                TIMESTAMP QUERYABLE SORTABLE,
    "guid"                   STRING QUERYABLE SORTABLE,
    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
);
```

### Swift Type Mapping

CloudKit schema fields map to Swift properties:

```swift
// Schema: "title" STRING
var title: String

// Schema: "pubDate" TIMESTAMP
var pubDate: Date

// Schema: "isActive" INT64
var isActive: Bool  // Convert 0/1 to Bool

// Schema: "feed" REFERENCE
var feed: CKRecord.Reference

// Schema: "tags" LIST<STRING>
var tags: [String]
```

## Validation Commands

```bash
# Validate schema syntax
cktool validate-schema schema.ckdb

# Import to development environment (dry run)
cktool import-schema --validate schema.ckdb

# Import to development environment
cktool import-schema schema.ckdb
```

**Environment Variables Required:**
- `CLOUDKIT_CONTAINER_ID` - Your container identifier
- `CLOUDKIT_ENVIRONMENT` - `development` or `production`
- `CLOUDKIT_MANAGEMENT_TOKEN` - Management token from CloudKit Dashboard

## Common Mistakes to Avoid

1. **Don't remove existing fields** - In production, removing fields causes data loss errors
2. **Don't change field types** - Type changes are not allowed after deployment
3. **Don't forget indexes** - Add `QUERYABLE` to fields used in queries
4. **Don't over-index** - Each index increases storage and write costs
5. **Don't use `NUMBER` type** - Use explicit `INT64` or `DOUBLE` instead
6. **Don't forget permissions** - Records without grants are inaccessible
7. **Don't manually reconstruct schemas** - Use `cktool export-schema` to download existing schemas

## Schema Evolution Best Practices

### ✅ Safe Operations

- Add new fields to existing record types
- Add new record types
- Add indexes (`QUERYABLE`, `SORTABLE`, `SEARCHABLE`) to existing fields
- Change permissions (grants)

### ⚠️ Dangerous Operations (Development Only)

- Remove fields from record types
- Change field data types
- Remove record types
- Remove indexes from fields

### 🚫 Never Allowed

- Rename fields (must remove old, add new)
- Change system field types

## Quick Workflow

1. **Export existing schema:**
   ```bash
   cktool export-schema > schema.ckdb
   ```

2. **Edit schema in text editor** (add/modify fields)

3. **Validate changes:**
   ```bash
   cktool validate-schema schema.ckdb
   ```

4. **Test in development:**
   ```bash
   export CLOUDKIT_ENVIRONMENT=development
   cktool import-schema schema.ckdb
   ```

5. **Commit to version control:**
   ```bash
   git add schema.ckdb
   git commit -m "feat: add Article.expiresAt field"
   ```

## See Also

- **Full Documentation:** [Examples/Celestra/AI_SCHEMA_WORKFLOW.md](../../Examples/Celestra/AI_SCHEMA_WORKFLOW.md)
- **Apple Docs Source:** [.claude/docs/sosumi-cloudkit-schema-source.md](sosumi-cloudkit-schema-source.md)
- **Setup Guide:** [Examples/Celestra/CLOUDKIT_SCHEMA_SETUP.md](../../Examples/Celestra/CLOUDKIT_SCHEMA_SETUP.md)
- **Quick Reference:** [Examples/SCHEMA_QUICK_REFERENCE.md](../../Examples/SCHEMA_QUICK_REFERENCE.md)
