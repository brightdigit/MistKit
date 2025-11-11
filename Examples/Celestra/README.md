# Celestra - RSS Reader with CloudKit Sync

Celestra is a command-line RSS reader that demonstrates MistKit's query filtering and sorting features by managing RSS feeds in CloudKit's public database.

## Features

- **RSS Parsing with SyndiKit**: Parse RSS and Atom feeds using BrightDigit's SyndiKit library
- **Add RSS Feeds**: Parse and validate RSS feeds, then store metadata in CloudKit
- **Duplicate Detection**: Automatically detect and skip duplicate articles using GUID-based queries
- **Filtered Updates**: Query feeds using MistKit's `QueryFilter` API (by date and popularity)
- **Batch Operations**: Upload multiple articles efficiently using non-atomic operations
- **Server-to-Server Auth**: Demonstrates CloudKit authentication for backend services
- **Record Modification**: Uses MistKit's new public record modification APIs

## Prerequisites

1. **Apple Developer Account** with CloudKit access
2. **CloudKit Container** configured in Apple Developer Console
3. **Server-to-Server Key** generated for CloudKit access
4. **Swift 5.9+** and **macOS 13.0+** (required by SyndiKit)

## CloudKit Setup

You can set up the CloudKit schema either automatically using `cktool` (recommended) or manually through the CloudKit Dashboard.

### Option 1: Automated Setup (Recommended)

Use the provided script to automatically import the schema:

```bash
# Set your CloudKit credentials
export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Celestra"
export CLOUDKIT_TEAM_ID="YOUR_TEAM_ID"
export CLOUDKIT_ENVIRONMENT="development"

# Run the setup script
cd Examples/Celestra
./Scripts/setup-cloudkit-schema.sh
```

For detailed instructions, see [CLOUDKIT_SCHEMA_SETUP.md](./CLOUDKIT_SCHEMA_SETUP.md).

### Option 2: Manual Setup

#### 1. Create CloudKit Container

1. Go to [Apple Developer Console](https://developer.apple.com)
2. Navigate to CloudKit Dashboard
3. Create a new container (e.g., `iCloud.com.brightdigit.Celestra`)

#### 2. Configure Record Types

In CloudKit Dashboard, create these record types in the **Public Database**:

#### Feed Record Type
| Field Name | Field Type | Indexed |
|------------|------------|---------|
| feedURL | String | Yes (Queryable, Sortable) |
| title | String | Yes (Searchable) |
| description | String | No |
| totalAttempts | Int64 | No |
| successfulAttempts | Int64 | No |
| usageCount | Int64 | Yes (Queryable, Sortable) |
| lastAttempted | Date/Time | Yes (Queryable, Sortable) |
| isActive | Int64 | Yes (Queryable) |

#### Article Record Type
| Field Name | Field Type | Indexed |
|------------|------------|---------|
| feedRecordName | String | Yes (Queryable, Sortable) |
| title | String | Yes (Searchable) |
| link | String | No |
| description | String | No |
| author | String | Yes (Queryable) |
| pubDate | Date/Time | Yes (Queryable, Sortable) |
| guid | String | Yes (Queryable, Sortable) |
| contentHash | String | Yes (Queryable) |
| fetchedAt | Date/Time | Yes (Queryable, Sortable) |
| expiresAt | Date/Time | Yes (Queryable, Sortable) |

#### 3. Generate Server-to-Server Key

1. In CloudKit Dashboard, go to **API Tokens**
2. Click **Server-to-Server Keys**
3. Generate a new key
4. Download the `.pem` file and save it securely
5. Note the **Key ID** (you'll need this)

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/brightdigit/MistKit.git
cd MistKit/Examples/Celestra
```

### 2. Configure Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your CloudKit credentials
nano .env
```

Update `.env` with your values:

```bash
CLOUDKIT_CONTAINER_ID=iCloud.com.brightdigit.Celestra
CLOUDKIT_KEY_ID=your-key-id-here
CLOUDKIT_PRIVATE_KEY_PATH=/path/to/eckey.pem
CLOUDKIT_ENVIRONMENT=development
```

### 3. Build

```bash
swift build
```

## Usage

Source your environment variables before running commands:

```bash
source .env
```

### Add a Feed

Add a new RSS feed to CloudKit:

```bash
swift run celestra add-feed https://example.com/feed.xml
```

Example output:
```
🌐 Fetching RSS feed: https://example.com/feed.xml
✅ Found feed: Example Blog
   Articles: 25
✅ Feed added to CloudKit
   Record Name: ABC123-DEF456-GHI789
   Zone: default
```

### Update Feeds

Fetch and update all feeds:

```bash
swift run celestra update
```

Update with filters (demonstrates QueryFilter API):

```bash
# Update feeds last attempted before a specific date
swift run celestra update --last-attempted-before 2025-01-01T00:00:00Z

# Update only popular feeds (minimum 10 usage count)
swift run celestra update --min-popularity 10

# Combine filters
swift run celestra update \
  --last-attempted-before 2025-01-01T00:00:00Z \
  --min-popularity 5
```

Example output:
```
🔄 Starting feed update...
   Filter: last attempted before 2025-01-01T00:00:00Z
   Filter: minimum popularity 5
📋 Querying feeds...
✅ Found 3 feed(s) to update

[1/3] 📰 Example Blog
   ✅ Fetched 25 articles
   ℹ️  Skipped 20 duplicate(s)
   ✅ Uploaded 5 new article(s)

[2/3] 📰 Tech News
   ✅ Fetched 15 articles
   ℹ️  Skipped 10 duplicate(s)
   ✅ Uploaded 5 new article(s)

[3/3] 📰 Daily Updates
   ✅ Fetched 10 articles
   ℹ️  No new articles to upload

✅ Update complete!
   Success: 3
   Errors: 0
```

### Clear All Data

Delete all feeds and articles from CloudKit:

```bash
swift run celestra clear --confirm
```

## How It Demonstrates MistKit Features

### 1. Query Filtering (`QueryFilter`)

The `update` command demonstrates filtering with date and numeric comparisons:

```swift
// In CloudKitService+Celestra.swift
var filters: [QueryFilter] = []

// Date comparison filter
if let cutoff = lastAttemptedBefore {
    filters.append(.lessThan("lastAttempted", .date(cutoff)))
}

// Numeric comparison filter
if let minPop = minPopularity {
    filters.append(.greaterThanOrEquals("usageCount", .int64(minPop)))
}
```

### 2. Query Sorting (`QuerySort`)

Results are automatically sorted by popularity (descending):

```swift
let records = try await queryRecords(
    recordType: "Feed",
    filters: filters.isEmpty ? nil : filters,
    sortBy: [.descending("usageCount")],  // Sort by popularity
    limit: limit
)
```

### 3. Batch Operations

Articles are uploaded in batches using non-atomic operations for better performance:

```swift
// Non-atomic allows partial success
return try await modifyRecords(operations: operations, atomic: false)
```

### 4. Duplicate Detection

Celestra automatically detects and skips duplicate articles during feed updates:

```swift
// In UpdateCommand.swift
// 1. Extract GUIDs from fetched articles
let guids = articles.map { $0.guid }

// 2. Query existing articles by GUID
let existingArticles = try await service.queryArticlesByGUIDs(
    guids,
    feedRecordName: recordName
)

// 3. Filter out duplicates
let existingGUIDs = Set(existingArticles.map { $0.guid })
let newArticles = articles.filter { !existingGUIDs.contains($0.guid) }

// 4. Only upload new articles
if !newArticles.isEmpty {
    _ = try await service.createArticles(newArticles)
}
```

#### How Duplicate Detection Works

1. **GUID-Based Identification**: Each article has a unique GUID (Globally Unique Identifier) from the RSS feed
2. **Pre-Upload Query**: Before uploading, Celestra queries CloudKit for existing articles with the same GUIDs
3. **Content Hash Fallback**: Articles also include a SHA256 content hash for duplicate detection when GUIDs are unreliable
4. **Efficient Filtering**: Uses Set-based filtering for O(n) performance with large article counts

This ensures you can run `update` multiple times without creating duplicate articles in CloudKit.

### 5. Server-to-Server Authentication

Demonstrates CloudKit authentication without user interaction:

```swift
let tokenManager = try ServerToServerAuthManager(
    keyID: keyID,
    pemString: privateKeyPEM
)

let service = try CloudKitService(
    containerIdentifier: containerID,
    tokenManager: tokenManager,
    environment: environment,
    database: .public
)
```

## Architecture

```
Celestra/
├── Models/
│   ├── Feed.swift          # Feed metadata model
│   └── Article.swift       # Article model
├── Services/
│   ├── RSSFetcherService.swift   # RSS parsing with SyndiKit
│   └── CloudKitService+Celestra.swift  # CloudKit operations
├── Commands/
│   ├── AddFeedCommand.swift      # Add feed command
│   ├── UpdateCommand.swift       # Update feeds command (demonstrates filters)
│   └── ClearCommand.swift        # Clear data command
└── Celestra.swift                # Main CLI entry point
```

## Documentation

### CloudKit Schema Guides

Celestra uses CloudKit's text-based schema language for database management. See these guides for working with schemas:

- **[AI Schema Workflow Guide](./AI_SCHEMA_WORKFLOW.md)** - Comprehensive guide for AI agents and developers to understand, design, modify, and validate CloudKit schemas
- **[CloudKit Schema Setup](./CLOUDKIT_SCHEMA_SETUP.md)** - Detailed setup instructions for both automated (cktool) and manual schema configuration
- **[Schema Quick Reference](../SCHEMA_QUICK_REFERENCE.md)** - One-page cheat sheet with syntax, patterns, and common operations
- **[Task Master Schema Integration](../../.taskmaster/docs/schema-design-workflow.md)** - Integrate schema design into Task Master workflows

### Additional Resources

- **[Claude Code Schema Reference](../../.claude/docs/cloudkit-schema-reference.md)** - Quick reference auto-loaded in Claude Code sessions
- **[Apple's Schema Language Documentation](../../.claude/docs/sosumi-cloudkit-schema-source.md)** - Official CloudKit Schema Language reference from Apple
- **[Implementation Notes](./IMPLEMENTATION_NOTES.md)** - Design decisions and patterns used in Celestra

## Troubleshooting

### Authentication Errors

- Verify your Key ID is correct
- Ensure the private key file exists and is readable
- Check that the container ID matches your CloudKit container

### Missing Record Types

- Make sure you created the record types in CloudKit Dashboard
- Verify you're using the correct database (public)
- Check the environment setting (development vs production)

### Build Errors

- Ensure Swift 5.9+ is installed: `swift --version`
- Clean and rebuild: `swift package clean && swift build`
- Update dependencies: `swift package update`

## License

MIT License - See main MistKit repository for details.
