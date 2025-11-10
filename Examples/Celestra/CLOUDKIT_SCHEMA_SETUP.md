# CloudKit Schema Setup Guide

This guide explains how to set up the CloudKit schema for the Celestra RSS reader application.

## CloudKit Credentials Overview

Celestra requires **two different types of CloudKit credentials**:

1. **Management Token** (for schema setup only)
   - Used by `cktool` to create/modify record types
   - Only needed during initial schema setup
   - Generated in CloudKit Dashboard → Profile → "Manage Tokens"
   - Used in this guide for schema import

2. **Server-to-Server Key** (for runtime operations)
   - Used by MistKit to authenticate API requests at runtime
   - Required for the app to read/write CloudKit data
   - Generated in CloudKit Dashboard → API Tokens → "Server-to-Server Keys"
   - Configured in `.env` file (see main README)

This guide focuses on setting up the schema using a **Management Token**. After schema setup, you'll generate a **Server-to-Server Key** for the app.

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
   export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Celestra"
   export CLOUDKIT_TEAM_ID="YOUR_TEAM_ID"
   export CLOUDKIT_ENVIRONMENT="development"  # or "production"
   ```

3. **Run the setup script**

   ```bash
   cd Examples/Celestra
   ./Scripts/setup-cloudkit-schema.sh
   ```

   The script will:
   - Validate the schema file
   - Confirm before importing
   - Import the schema to your CloudKit container
   - Display success/error messages

4. **Verify in CloudKit Dashboard**

   Open [CloudKit Dashboard](https://icloud.developer.apple.com/) and verify the two record types exist:
   - Feed
   - Article

### Option 2: Manual Schema Creation

For manual setup or if you prefer to use the CloudKit Dashboard directly.

#### Steps

1. **Open CloudKit Dashboard**

   Go to [https://icloud.developer.apple.com/](https://icloud.developer.apple.com/)

2. **Select your container**

   Choose your Celestra container (e.g., `iCloud.com.brightdigit.Celestra`)

3. **Switch to Development environment**

   Use the environment selector to choose "Development"

4. **Navigate to Schema section**

   Click on "Schema" in the sidebar

5. **Create Feed record type**

   - Click "+" to add a new record type
   - Name: `Feed`
   - Add the following fields:

   | Field Name | Field Type | Options |
   |------------|------------|---------|
   | feedURL | String | ✓ Queryable, ✓ Sortable |
   | title | String | |
   | totalAttempts | Int64 | |
   | successfulAttempts | Int64 | |
   | usageCount | Int64 | ✓ Queryable, ✓ Sortable |
   | lastAttempted | Date/Time | ✓ Queryable, ✓ Sortable |

   - Set Permissions:
     - Read: World Readable
     - Write: Requires Creator

6. **Create Article record type**

   - Click "+" to add another record type
   - Name: `Article`
   - Add the following fields:

   | Field Name | Field Type | Options |
   |------------|------------|---------|
   | feedRecordName | String | ✓ Queryable, ✓ Sortable |
   | title | String | |
   | link | String | |
   | description | String | |
   | author | String | |
   | pubDate | Date/Time | |
   | guid | String | ✓ Queryable, ✓ Sortable |
   | fetchedAt | Date/Time | |
   | expiresAt | Date/Time | ✓ Queryable, ✓ Sortable |

   - Set Permissions:
     - Read: World Readable
     - Write: Requires Creator

7. **Save the schema**

   Click "Save" to apply the changes

## Getting a Management Token

Management tokens allow `cktool` to modify your CloudKit schema.

1. Open [CloudKit Dashboard](https://icloud.developer.apple.com/)
2. Select your container
3. Click your profile icon (top right)
4. Select "Manage Tokens"
5. Click "Create Token"
6. Give it a name: "Celestra Schema Management"
7. **Copy the token** (you won't see it again!)
8. Save it using `xcrun cktool save-token`

## Schema File Format

The schema is defined in `schema.ckdb` using CloudKit's declarative schema language:

```
RECORD TYPE Feed (
    "feedURL"          STRING QUERYABLE SORTABLE,
    "title"            STRING,
    "totalAttempts"    INT64,
    "successfulAttempts" INT64,
    "usageCount"       INT64 QUERYABLE SORTABLE,
    "lastAttempted"    TIMESTAMP QUERYABLE SORTABLE,

    GRANT WRITE TO "_creator",
    GRANT READ TO "_world"
);

RECORD TYPE Article (
    "feedRecordName"   STRING QUERYABLE SORTABLE,
    "title"            STRING,
    "link"             STRING,
    "description"      STRING,
    "author"           STRING,
    "pubDate"          TIMESTAMP,
    "guid"             STRING QUERYABLE SORTABLE,
    "fetchedAt"        TIMESTAMP,
    "expiresAt"        TIMESTAMP QUERYABLE SORTABLE,

    GRANT WRITE TO "_creator",
    GRANT READ TO "_world"
);
```

### Key Features

- **QUERYABLE**: Field can be used in query predicates
- **SORTABLE**: Field can be used for sorting results
- **GRANT READ TO "_world"**: Makes records publicly readable
- **GRANT WRITE TO "_creator"**: Only creator can modify

### Database Scope

**Important**: The schema import applies to the **container level**, making record types available in both public and private databases. However:

- **Celestra writes to the public database** for sharing RSS feeds
- The `GRANT READ TO "_world"` permission ensures public read access
- This allows RSS feeds and articles to be shared across all users

### Field Type Notes

- **TIMESTAMP**: CloudKit's date/time field type (maps to Date/Time in Dashboard)
- **INT64**: 64-bit integer for counts and metrics

### Celestra Record Types Explained

#### Feed

Stores RSS feed metadata and usage statistics:

- `feedURL`: The RSS feed URL (indexed for quick lookups)
- `title`: Feed title from RSS metadata
- `totalAttempts`: Total number of fetch attempts (for reliability tracking)
- `successfulAttempts`: Number of successful fetches
- `usageCount`: Popularity metric (how often this feed is accessed)
- `lastAttempted`: When the feed was last fetched (indexed for update queries)

#### Article

Stores individual articles from RSS feeds:

- `feedRecordName`: Reference to the parent Feed record (indexed for queries)
- `title`: Article title
- `link`: Article URL
- `description`: Article summary/content
- `author`: Article author
- `pubDate`: Publication date from RSS feed
- `guid`: Unique identifier from RSS feed (indexed to prevent duplicates)
- `fetchedAt`: When the article was fetched from the feed
- `expiresAt`: When the article should be considered stale (indexed for cleanup queries)

## Schema Export

To export your current schema (useful for version control):

```bash
xcrun cktool export-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.brightdigit.Celestra \
  --environment development \
  --output-file schema-backup.ckdb
```

## Validation Without Import

To validate your schema file without importing:

```bash
xcrun cktool validate-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.brightdigit.Celestra \
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
- Use TIMESTAMP for dates, INT64 for integers
- Check for typos in field names

### Permission Denied

**Problem**: "Insufficient permissions to modify schema"

**Solution**:
- Verify your Apple ID has Admin role in the container
- Check management token has correct permissions
- Try regenerating the management token

## Deploying to Production

After testing in development:

1. **Export development schema**
   ```bash
   xcrun cktool export-schema \
     --team-id YOUR_TEAM_ID \
     --container-id iCloud.com.brightdigit.Celestra \
     --environment development \
     --output-file celestra-prod-schema.ckdb
   ```

2. **Import to production**
   ```bash
   export CLOUDKIT_ENVIRONMENT=production
   ./Scripts/setup-cloudkit-schema.sh
   ```

3. **Verify in Dashboard**
   - Switch to Production environment
   - Verify record types exist
   - Test with a few manual records

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

1. **Configure credentials**: See main [README.md](./README.md) for .env setup
2. **Generate Server-to-Server Key**: Required for CloudKit authentication
3. **Add your first feed**: `swift run celestra add-feed https://example.com/feed.xml`
4. **Update feeds**: `swift run celestra update`
5. **Verify data**: Check CloudKit Dashboard for records

## Example Queries Using MistKit

Once your schema is set up, Celestra demonstrates MistKit's query capabilities:

### Query by Date
```swift
// Find feeds last attempted before a specific date
let filters: [QueryFilter] = [
    .lessThan("lastAttempted", .date(cutoffDate))
]
```

### Query by Popularity
```swift
// Find popular feeds (minimum usage count)
let filters: [QueryFilter] = [
    .greaterThanOrEquals("usageCount", .int64(10))
]
```

### Combined Filters with Sorting
```swift
// Find stale popular feeds, sorted by popularity
let records = try await queryRecords(
    recordType: "Feed",
    filters: [
        .lessThan("lastAttempted", .date(cutoffDate)),
        .greaterThanOrEquals("usageCount", .int64(5))
    ],
    sortBy: [.descending("usageCount")],
    limit: 100
)
```

## Resources

- [CloudKit Schema Documentation](https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database)
- [cktool Reference](https://keith.github.io/xcode-man-pages/cktool.1.html)
- [WWDC21: Automate CloudKit tests with cktool](https://developer.apple.com/videos/play/wwdc2021/10118/)
- [CloudKit Dashboard](https://icloud.developer.apple.com/)

## Troubleshooting

For Celestra-specific issues, see the main [README.md](./README.md).

For CloudKit schema issues:
- Check Apple Developer Forums: https://developer.apple.com/forums/tags/cloudkit
- Review CloudKit Dashboard logs
- Verify schema file syntax against Apple's documentation
