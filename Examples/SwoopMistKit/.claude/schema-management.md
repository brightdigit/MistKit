# CloudKit Schema Management (Advanced)

> **Note**: This is a detailed reference guide for advanced CloudKit schema management. For daily development, see the main [CLAUDE.md](../CLAUDE.md) file.

This document covers advanced schema management, `cktool` usage, and troubleshooting for developers working with CloudKit schemas.

## Schema File Format

CloudKit schemas use a declarative language defined in `.ckdb` files:

```text
DEFINE SCHEMA

RECORD TYPE RestoreImage (
    "version"                STRING QUERYABLE SORTABLE SEARCHABLE,
    "buildNumber"            STRING QUERYABLE SORTABLE,
    "releaseDate"            TIMESTAMP QUERYABLE SORTABLE,
    "downloadURL"            STRING,
    "fileSize"               INT64,
    "sha256Hash"             STRING,
    "sha1Hash"               STRING,
    "isSigned"               INT64 QUERYABLE,
    "isPrerelease"           INT64 QUERYABLE,
    "source"                 STRING,
    "notes"                  STRING,
    "sourceUpdatedAt"        TIMESTAMP,

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
);
```

## Critical Schema Rules

**1. Always start with `DEFINE SCHEMA`:**
```text
DEFINE SCHEMA  ← Required header

RECORD TYPE YourType (
    ...
)
```

**2. Never include system fields:**
CloudKit automatically adds system fields like `___recordID`, `___createTime`, `___modTime`. Including them causes validation errors.

**Bad:**
```text
RECORD TYPE RestoreImage (
    "___recordID"    QUERYABLE,  ← ❌ ERROR
    "version"        STRING
)
```

**Good:**
```text
RECORD TYPE RestoreImage (
    "version"        STRING  ← ✅ Only user-defined fields
)
```

**3. Use INT64 for booleans:**
CloudKit doesn't have a native boolean type.

```text
"isSigned"       INT64 QUERYABLE,  # 0 = false, 1 = true
"isPrerelease"   INT64 QUERYABLE,
```

**4. Field modifiers:**
- `QUERYABLE` - Can be used in query predicates
- `SORTABLE` - Can be used for sorting results
- `SEARCHABLE` - Supports full-text search (STRING only)

## Permission Requirements for Server-to-Server Auth

**Critical:** S2S authentication requires BOTH `_creator` AND `_icloud` permissions:

```text
GRANT READ, CREATE, WRITE TO "_creator",
GRANT READ, CREATE, WRITE TO "_icloud",
GRANT READ TO "_world"
```

**Why both are required:**
- `_creator` - S2S keys authenticate as the developer/application
- `_icloud` - Required for public database operations

**Common mistake:** Only granting to one role results in `ACCESS_DENIED` errors.

## cktool Commands Reference

### Save Management Token

Management tokens allow schema operations:

```bash
xcrun cktool save-token
# Paste token from CloudKit Dashboard when prompted
```

**Getting a management token:**
1. CloudKit Dashboard → Select container
2. Settings → CloudKit Web Services
3. Generate Management Token
4. Copy and save with `cktool save-token`

### Validate Schema

Check schema syntax without importing:

```bash
xcrun cktool validate-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.Bushel \
  --environment development \
  --file schema.ckdb
```

### Import Schema

Upload schema to CloudKit:

```bash
xcrun cktool import-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.Bushel \
  --environment development \
  --file schema.ckdb
```

**Note:** This modifies your CloudKit container. Always test in development first!

### Export Schema

Download current schema from CloudKit:

```bash
xcrun cktool export-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.Bushel \
  --environment development \
  > schema-backup.ckdb
```

**Use cases:**
- Backup before making changes
- Verify what's currently deployed
- Compare development vs production schemas

### Query Records

Test queries with cktool:

```bash
xcrun cktool query \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.Bushel \
  --environment development \
  --record-type RestoreImage \
  --limit 10
```

## Common cktool Errors

**"Authentication failed":**
- **Solution:** Generate new management token and save with `cktool save-token`

**"Container not found":**
- **Solution:** Verify container ID matches Dashboard exactly
- Check Team ID is correct

**"Schema validation failed: Was expecting DEFINE":**
- **Solution:** Add `DEFINE SCHEMA` header at top of `.ckdb` file

**"Schema validation failed: Encountered '___recordID'":**
- **Solution:** Remove all system fields from schema (they're auto-added)

**"Permission denied":**
- **Solution:** Ensure your Apple ID has Admin role in the container

## Schema Versioning Best Practices

**1. Version control your schema:**
```bash
git add schema.ckdb
git commit -m "Add DataSourceMetadata record type"
```

**2. Test in development first:**
```bash
# Import to development environment
xcrun cktool import-schema --environment development --file schema.ckdb

# Test with your app
bushel-cloud sync --verbose

# If successful, deploy to production
xcrun cktool import-schema --environment production --file schema.ckdb
```

**3. Backward compatibility:**
- Avoid removing fields (breaks existing records)
- Mark fields optional instead of removing
- Add new fields as optional
- Update all clients before schema changes

**4. Export before major changes:**
```bash
# Backup current production schema
xcrun cktool export-schema --environment production > schema-backup-$(date +%Y%m%d).ckdb
```

## CI/CD Schema Deployment

Automate schema deployment in CI/CD pipelines:

```bash
#!/bin/bash
# Schema deployment script

# Load token from secure environment variable
echo "$CLOUDKIT_MANAGEMENT_TOKEN" | xcrun cktool save-token --file -

# Validate schema first
xcrun cktool validate-schema \
  --team-id "$TEAM_ID" \
  --container-id "$CONTAINER_ID" \
  --environment development \
  --file schema.ckdb

# Import if validation passes
xcrun cktool import-schema \
  --team-id "$TEAM_ID" \
  --container-id "$CONTAINER_ID" \
  --environment development \
  --file schema.ckdb
```

**Security:** Store management token in CI secrets, never commit to repository.

## Token Types Clarification

CloudKit uses different tokens for different purposes:

| Token Type | Purpose | Used By | Where to Get |
|-----------|---------|---------|--------------|
| **Management Token** | Schema operations (import/export) | `cktool` | CloudKit Dashboard → CloudKit Web Services |
| **Server-to-Server Key** | Runtime API operations | Your application | CloudKit Dashboard → Server-to-Server Keys |
| **API Token** | Simpler runtime auth (deprecated) | Legacy apps | CloudKit Dashboard → API Tokens |

**For BushelCloud:**
- Schema setup: **Management Token** (via `cktool save-token`)
- Sync/export commands: **Server-to-Server Key** (Key ID + .pem file)

## Troubleshooting Schema Import

**Schema imports successfully but records still fail to create:**

1. **Check permissions in exported schema:**
   ```bash
   xcrun cktool export-schema --environment development | grep -A 2 "GRANT"
   ```
   Should show both `_creator` and `_icloud` with CREATE, READ, WRITE

2. **Verify field types match your code:**
   Export schema and compare field types to your `toCloudKitFields()` implementation

3. **Test with a simple record:**
   ```swift
   let testOp = RecordOperation.create(
       recordType: "RestoreImage",
       recordName: "test-123",
       fields: ["version": .string("1.0")]
   )
   try await service.modifyRecords([testOp])
   ```

**Permissions seem correct but still get ACCESS_DENIED:**

CloudKit schema changes can take a few minutes to propagate. Wait 5-10 minutes and try again.

## Database Scope Considerations

Schema import applies to the **container level**, making record types available in both public and private databases.

**BushelCloud configuration:**
- Writes to **public database** (see `BushelCloudKitService.swift`)
- `GRANT READ TO "_world"` enables public read access
- S2S auth uses public database scope

**Private database** would require:
- User authentication
- Different permission model
- Per-user data isolation

BushelCloud uses public database to demonstrate server-managed shared data accessible to all users.

## Advanced: Programmatic Schema Validation

You can validate CloudKit field values before upload:

```swift
// Example validation helper
func validateRestoreImageFields(_ fields: [String: FieldValue]) throws {
    guard case .string(let version) = fields["version"], !version.isEmpty else {
        throw ValidationError.missingRequiredField("version")
    }

    guard case .int64(let isSigned) = fields["isSigned"],
          (isSigned == 0 || isSigned == 1) else {
        throw ValidationError.invalidBooleanValue("isSigned")
    }

    // ... more validations
}
```

This catches errors before CloudKit upload, providing better error messages.
