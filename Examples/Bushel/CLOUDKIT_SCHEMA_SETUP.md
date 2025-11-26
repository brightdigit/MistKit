# CloudKit Schema Setup Guide

This guide explains how to set up the CloudKit schema for the Bushel demo application.

## Two Approaches

### Option 1: Automated Setup with cktool (Recommended)

Use the provided script to automatically import the schema.

#### Prerequisites

- **Xcode 13+** installed (provides `cktool`)
- **CloudKit container** created in [CloudKit Dashboard](https://icloud.developer.apple.com/)
- **Apple Developer Team ID** (10-character identifier)
- **CloudKit Management Token** (see "Getting a Management Token" below)

#### Steps

1. **Save your CloudKit Management Token**

   ```bash
   xcrun cktool save-token
   ```

   When prompted, paste your management token from CloudKit Dashboard.

2. **Set environment variables**

   ```bash
   export CLOUDKIT_CONTAINER_ID="iCloud.com.yourcompany.Bushel"
   export CLOUDKIT_TEAM_ID="YOUR_TEAM_ID"
   export CLOUDKIT_ENVIRONMENT="development"  # or "production"
   ```

3. **Run the setup script**

   ```bash
   cd Examples/Bushel
   ./Scripts/setup-cloudkit-schema.sh
   ```

   The script will:
   - Validate the schema file
   - Confirm before importing
   - Import the schema to your CloudKit container
   - Display success/error messages

4. **Verify in CloudKit Dashboard**

   Open [CloudKit Dashboard](https://icloud.developer.apple.com/) and verify the three record types exist:
   - RestoreImage
   - XcodeVersion
   - SwiftVersion

### Option 2: Manual Schema Creation (Development Only)

For quick development testing, you can use CloudKit's "just-in-time schema" feature.

#### Steps

1. **Run the CLI with export command** (no schema needed)

   ```bash
   bushel-images export --output test-data.json
   ```

   This fetches data from APIs without CloudKit.

2. **Temporarily modify SyncCommand to create test records**

   Add this to `SyncCommand.swift`:

   ```swift
   // In run() method, before actual sync:
   let testImage = RestoreImageRecord(
       version: "15.0",
       buildNumber: "24A335",
       releaseDate: Date(),
       downloadURL: "https://example.com/test.ipsw",
       fileSize: 1000000,
       sha256Hash: "test",
       sha1Hash: "test",
       isSigned: true,
       isPrerelease: false,
       source: "test"
   )

   let operation = RecordOperation.create(
       recordType: RestoreImageRecord.cloudKitRecordType,
       recordName: testImage.recordName,
       fields: testImage.toCloudKitFields()
   )
   try await service.modifyRecords([operation])
   ```

3. **Run sync once**

   ```bash
   bushel-images sync
   ```

   CloudKit will auto-create the record types in development.

4. **Deploy schema to production** (when ready)

   In CloudKit Dashboard:
   - Go to Schema section
   - Click "Deploy Schema Changes"
   - Review and confirm

⚠️ **Note**: Just-in-time schema creation only works in development environment and doesn't set up indexes.

## Getting a Management Token

Management tokens allow `cktool` to modify your CloudKit schema.

1. Open [CloudKit Dashboard](https://icloud.developer.apple.com/)
2. Select your container
3. Click your profile icon (top right)
4. Select "Manage Tokens"
5. Click "Create Token"
6. Give it a name: "Bushel Schema Management"
7. **Copy the token** (you won't see it again!)
8. Save it using `xcrun cktool save-token`

## Schema File Format

The schema is defined in `schema.ckdb` using CloudKit's declarative schema language:

```text
RECORD TYPE RestoreImage (
    "version"      STRING QUERYABLE SORTABLE SEARCHABLE,
    "buildNumber"  STRING QUERYABLE SORTABLE,
    "releaseDate"  TIMESTAMP QUERYABLE SORTABLE,
    "fileSize"     INT64,
    "isSigned"     INT64 QUERYABLE,
    // ... more fields

    GRANT WRITE TO "_creator",
    GRANT READ TO "_world"
);
```

### Key Features

- **QUERYABLE**: Field can be used in query predicates
- **SORTABLE**: Field can be used for sorting results
- **SEARCHABLE**: Field supports full-text search
- **GRANT READ TO "_world"**: Makes records publicly readable
- **GRANT WRITE TO "_creator"**: Only creator can modify

### Database Scope

**Important**: The schema import applies to the **container level**, making record types available in both public and private databases. However:

- The **Bushel demo writes to the public database** (`BushelCloudKitService.swift:16`)
- The `GRANT READ TO "_world"` permission ensures public read access
- Other apps (like Bushel itself) query the **public database** directly

This architecture allows:
- The demo app (MistKit) to populate data in the public database
- Bushel (native CloudKit) to read that data without authentication

### Field Type Notes

- **Boolean → INT64**: CloudKit doesn't have a native boolean type, so we use INT64 (0 = false, 1 = true)
- **TIMESTAMP**: CloudKit's date/time field type
- **REFERENCE**: Link to another record (for relationships)

## Schema Export

To export your current schema (useful for version control):

```bash
xcrun cktool export-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.Bushel \
  --environment development \
  --output-file schema-backup.ckdb
```

## Validation Without Import

To validate your schema file without importing:

```bash
xcrun cktool validate-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.Bushel \
  --environment development \
  schema.ckdb
```

## Common Issues

### Authentication Failed

**Problem**: "Authentication failed" or "Invalid token"

**Solution**:
1. Generate a new management token in CloudKit Dashboard
2. Save it: `xcrun cktool save-token`
3. Ensure you're using the correct Team ID

### Container Not Found

**Problem**: "Container not found" or "Invalid container"

**Solution**:
- Verify container ID matches CloudKit Dashboard exactly
- Ensure container exists and you have access
- Check Team ID is correct

### Schema Validation Errors

**Problem**: "Schema validation failed" with field type errors

**Solution**:
- Ensure all field types match CloudKit's supported types
- Remember: Use INT64 for booleans, TIMESTAMP for dates
- Check for typos in field names

### Permission Denied

**Problem**: "Insufficient permissions to modify schema"

**Solution**:
- Verify your Apple ID has Admin role in the container
- Check management token has correct permissions
- Try regenerating the management token

## CI/CD Integration

For automated deployment, you can integrate schema management into your CI/CD pipeline:

```bash
#!/bin/bash
# In your CI/CD script

# Load token from secure environment variable
echo "$CLOUDKIT_MANAGEMENT_TOKEN" | xcrun cktool save-token --file -

# Import schema
xcrun cktool import-schema \
  --team-id "$TEAM_ID" \
  --container-id "$CONTAINER_ID" \
  --environment development \
  schema.ckdb
```

## Schema Versioning

Best practices for managing schema changes:

1. **Version Control**: Keep `schema.ckdb` in git
2. **Development First**: Always test changes in development environment
3. **Schema Export**: Periodically export production schema as backup
4. **Migration Plan**: Document any breaking changes
5. **Backward Compatibility**: Avoid removing fields when possible

## Next Steps

After setting up the schema:

1. **Configure credentials**: See [XCODE_SCHEME_SETUP.md](./XCODE_SCHEME_SETUP.md)
2. **Run data sync**: `bushel-images sync`
3. **Verify data**: Check CloudKit Dashboard for records
4. **Test queries**: Use CloudKit Dashboard's Data section

## Resources

- [CloudKit Schema Documentation](https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database)
- [cktool Reference](https://keith.github.io/xcode-man-pages/cktool.1.html)
- [WWDC21: Automate CloudKit tests with cktool](https://developer.apple.com/videos/play/wwdc2021/10118/)
- [CloudKit Dashboard](https://icloud.developer.apple.com/)

## Troubleshooting

For Bushel-specific issues, see the main [README.md](./README.md).

For CloudKit schema issues:
- Check [Apple Developer Forums](https://developer.apple.com/forums/tags/cloudkit)
- Review CloudKit Dashboard logs
- Verify schema file syntax against Apple's documentation
