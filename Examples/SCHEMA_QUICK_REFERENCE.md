# CloudKit Schema Quick Reference

One-page cheat sheet for CloudKit Schema Language (.ckdb files)

---

## Basic Syntax

```
DEFINE SCHEMA

RECORD TYPE TypeName (
    "fieldName"  DataType  [QUERYABLE] [SORTABLE] [SEARCHABLE],
    GRANT READ, CREATE, WRITE TO "role"
);
```

## Data Types

| CloudKit | Swift | Example |
|----------|-------|---------|
| `STRING` | `String` | `"title" STRING` |
| `INT64` | `Int64` or `Bool` | `"count" INT64` |
| `DOUBLE` | `Double` | `"rating" DOUBLE` |
| `TIMESTAMP` | `Date` | `"pubDate" TIMESTAMP` |
| `REFERENCE` | `CKRecord.Reference` | `"feed" REFERENCE` |
| `ASSET` | `CKAsset` | `"image" ASSET` |
| `LOCATION` | `CLLocation` | `"location" LOCATION` |
| `BYTES` | `Data` | `"data" BYTES` |
| `LIST<type>` | `[Type]` | `"tags" LIST<STRING>` |

## Field Options

| Option | Use When | Example |
|--------|----------|---------|
| `QUERYABLE` | Filtering by exact value | `feedURL == "..."` |
| `SORTABLE` | Sorting or range queries | `pubDate > date` |
| `SEARCHABLE` | Full-text search (STRING only) | `title CONTAINS "Swift"` |

## Common Patterns

### Boolean Fields
```
"isActive"     INT64 QUERYABLE          // 0 = false, 1 = true
```

### Timestamps
```
"createdAt"    TIMESTAMP QUERYABLE SORTABLE
"updatedAt"    TIMESTAMP QUERYABLE SORTABLE
```

### References (Foreign Keys)
```
"feed"         REFERENCE QUERYABLE      // Article → Feed
```

### Text Search
```
"title"        STRING SEARCHABLE        // Full-text search
```

### Unique Identifiers
```
"guid"         STRING QUERYABLE SORTABLE
```

### Counters
```
"usageCount"   INT64 QUERYABLE SORTABLE // For ranking/sorting
```

### Lists
```
"tags"         LIST<STRING>
"images"       LIST<ASSET>
```

## System Fields (Auto-included)

```
"___recordID"      REFERENCE    // Unique ID
"___createTime"    TIMESTAMP    // Created at
"___modTime"       TIMESTAMP    // Modified at
"___createdBy"     REFERENCE    // Creator
"___modifiedBy"    REFERENCE    // Last modifier
"___etag"          STRING       // Conflict resolution
```

**Note:** Only declare system fields if adding indexes

## Permissions

### Standard Public Database
```
GRANT READ, CREATE, WRITE TO "_creator",     // Record owner
GRANT READ, CREATE, WRITE TO "_icloud",      // Authenticated users
GRANT READ TO "_world"                       // Everyone (unauthenticated)
```

### Private Database
```
GRANT READ, CREATE, WRITE TO "_creator"      // Owner only
```

### Custom Roles
```
CREATE ROLE Moderator;

GRANT READ, WRITE TO Moderator,
GRANT READ TO "_world"
```

## cktool Commands

### Validation
```bash
# Validate syntax
cktool validate-schema schema.ckdb
```

### Export/Import
```bash
# Export existing schema
cktool export-schema > schema.ckdb

# Import to development
export CLOUDKIT_ENVIRONMENT=development
cktool import-schema schema.ckdb

# Import to production (careful!)
export CLOUDKIT_ENVIRONMENT=production
cktool import-schema schema.ckdb
```

### Required Environment Variables
```bash
export CLOUDKIT_CONTAINER_ID="iCloud.com.example.app"
export CLOUDKIT_ENVIRONMENT="development"  # or "production"
export CLOUDKIT_MANAGEMENT_TOKEN="your_token_here"
```

## Indexing Decision Tree

```
Need to filter by exact value?
├─ Yes → QUERYABLE
└─ No → No index

Need to sort or use range queries?
├─ Yes → SORTABLE (also gives QUERYABLE)
└─ No → Check QUERYABLE above

Is it a STRING field users search within?
├─ Yes → SEARCHABLE
└─ No → Check above
```

## Type Mapping Examples

### Feed Record
```
RECORD TYPE Feed (
    "___recordID"    REFERENCE QUERYABLE,
    "feedURL"        STRING QUERYABLE SORTABLE,
    "title"          STRING SEARCHABLE,
    "isActive"       INT64 QUERYABLE,          // Boolean
    "lastAttempted"  TIMESTAMP QUERYABLE SORTABLE,
    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ TO "_world"
);
```

### Swift Model
```swift
struct Feed: Codable {
    var recordID: CKRecord.ID?
    var feedURL: String
    var title: String
    var isActive: Bool         // Convert INT64 0/1
    var lastAttempted: Date?
}
```

## Safe vs Unsafe Operations

### ✅ Safe (Development & Production)
- Add new fields
- Add new record types
- Add indexes to fields
- Change permissions

### ⚠️ Safe in Development Only
- Remove fields
- Remove record types
- Remove indexes

### 🚫 Never Allowed
- Change field types
- Rename fields (delete + add = data loss)

## Common Errors

### Invalid identifier
```
❌ "feed-url"     // Hyphens not allowed
✅ "feedURL"      // Use camelCase or underscores
```

### Wrong index on type
```
❌ "count" INT64 SEARCHABLE      // SEARCHABLE only for STRING
✅ "count" INT64 QUERYABLE       // Use QUERYABLE or SORTABLE
```

### Missing quotes on system fields
```
❌ ___recordID REFERENCE         // Missing quotes
✅ "___recordID" REFERENCE       // Must quote system fields
```

### Missing permissions
```
❌ RECORD TYPE Feed ( ... );     // No grants
✅ RECORD TYPE Feed (
       ...
       GRANT READ TO "_world"    // At least one grant
   );
```

## Validation Checklist

- [ ] Syntax validates: `cktool validate-schema schema.ckdb`
- [ ] Environment variables set correctly
- [ ] Tested import to development first
- [ ] Schema appears in CloudKit Dashboard
- [ ] Can create test records
- [ ] Queries work with new indexes
- [ ] No data loss warnings
- [ ] Swift models updated
- [ ] Tests pass
- [ ] Schema committed to git

## Example Complete Schema (Celestra)

```
DEFINE SCHEMA

RECORD TYPE Feed (
    "___recordID"            REFERENCE QUERYABLE,
    "feedURL"                STRING QUERYABLE SORTABLE,
    "title"                  STRING SEARCHABLE,
    "description"            STRING,
    "totalAttempts"          INT64,
    "successfulAttempts"     INT64,
    "usageCount"             INT64 QUERYABLE SORTABLE,
    "lastAttempted"          TIMESTAMP QUERYABLE SORTABLE,
    "isActive"               INT64 QUERYABLE,

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
);

RECORD TYPE Article (
    "___recordID"            REFERENCE QUERYABLE,
    "feed"                   REFERENCE QUERYABLE,
    "title"                  STRING SEARCHABLE,
    "link"                   STRING,
    "description"            STRING,
    "author"                 STRING QUERYABLE,
    "pubDate"                TIMESTAMP QUERYABLE SORTABLE,
    "guid"                   STRING QUERYABLE SORTABLE,
    "contentHash"            STRING QUERYABLE,
    "fetchedAt"              TIMESTAMP QUERYABLE SORTABLE,
    "expiresAt"              TIMESTAMP QUERYABLE SORTABLE,

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
);
```

---

## See Also

- **Detailed Guide:** [Celestra/AI_SCHEMA_WORKFLOW.md](Celestra/AI_SCHEMA_WORKFLOW.md)
- **Claude Reference:** [.claude/docs/cloudkit-schema-reference.md](../.claude/docs/cloudkit-schema-reference.md)
- **Task Master Integration:** [.taskmaster/docs/schema-design-workflow.md](../.taskmaster/docs/schema-design-workflow.md)
- **Setup Guide:** [Celestra/CLOUDKIT_SCHEMA_SETUP.md](Celestra/CLOUDKIT_SCHEMA_SETUP.md)
