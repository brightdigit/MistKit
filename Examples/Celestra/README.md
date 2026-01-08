# CelestraCloud - RSS Reader with CloudKit Sync

[![CelestraCloud](https://github.com/brightdigit/CelestraCloud/actions/workflows/CelestraCloud.yml/badge.svg)](https://github.com/brightdigit/CelestraCloud/actions/workflows/CelestraCloud.yml)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%20Linux-lightgrey.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

CelestraCloud is a command-line RSS reader that demonstrates MistKit's query filtering and sorting features by managing RSS feeds in CloudKit's public database.

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
./Scripts/setup-cloudkit-schema.sh
```

For detailed instructions, see [.claude/CLOUDKIT_SCHEMA_SETUP.md](./.claude/CLOUDKIT_SCHEMA_SETUP.md).

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
git clone https://github.com/brightdigit/CelestraCloud.git
cd CelestraCloud
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
# Or use the Makefile
make build
```

## Usage

Source your environment variables before running commands:

```bash
source .env
```

### Add a Feed

Add a new RSS feed to CloudKit:

```bash
swift run celestra-cloud add-feed https://example.com/feed.xml
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

Fetch and update all active RSS feeds from CloudKit.

#### Basic Usage

```bash
# Update all feeds with default settings
swift run celestra-cloud update

# With custom rate limiting
swift run celestra-cloud update --update-delay 3.0

# Skip robots.txt checks (not recommended)
swift run celestra-cloud update --update-skip-robots-check
```

#### Filtering Options

Use filters to selectively update feeds based on various criteria:

**By Date:**
```bash
# Update only feeds last attempted before a specific date
swift run celestra-cloud update --update-last-attempted-before 2025-01-01T00:00:00Z
```

**By Popularity:**
```bash
# Update only popular feeds (minimum 10 subscribers)
swift run celestra-cloud update --update-min-popularity 10
```

**By Failure Count:**
```bash
# Skip feeds with more than 5 consecutive failures
swift run celestra-cloud update --update-max-failures 5
```

**Combined Filters:**
```bash
# Update popular feeds that haven't been updated recently
swift run celestra-cloud update \
  --update-last-attempted-before 2025-01-01T00:00:00Z \
  --update-min-popularity 5 \
  --update-delay 1.5
```

#### Configuration Options

All update options can be configured via environment variables or CLI arguments:

| Option | Environment Variable | CLI Argument | Default |
|--------|---------------------|--------------|---------|
| Rate Limit | `UPDATE_DELAY=3.0` | `--update-delay 3.0` | `2.0` seconds |
| Skip Robots | `UPDATE_SKIP_ROBOTS_CHECK=true` | `--update-skip-robots-check` | `false` |
| Max Failures | `UPDATE_MAX_FAILURES=5` | `--update-max-failures 5` | None |
| Min Popularity | `UPDATE_MIN_POPULARITY=10` | `--update-min-popularity 10` | None |
| Date Filter | `UPDATE_LAST_ATTEMPTED_BEFORE=2025-01-01T00:00:00Z` | `--update-last-attempted-before 2025-01-01T00:00:00Z` | None |

**Priority**: CLI arguments override environment variables.

**Example with environment variables:**
```bash
# Set defaults in .env file
echo "UPDATE_DELAY=3.0" >> .env
echo "UPDATE_MAX_FAILURES=5" >> .env

# Source and run
source .env
swift run celestra-cloud update

# Or use mixed configuration
UPDATE_DELAY=2.0 swift run celestra-cloud update --update-delay 5.0
# Uses 5.0 (CLI wins over ENV)
```

#### Example Output

```
🔄 Starting feed update...
   ⏱️  Rate limit: 2.0 seconds between feeds
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
swift run celestra-cloud clear --confirm
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
Sources/Celestra/
├── Models/
│   └── BatchOperationResult.swift     # Batch operation tracking
├── Services/
│   ├── RSSFetcherService.swift        # RSS parsing with SyndiKit
│   ├── CloudKitService+Celestra.swift # CloudKit operations
│   ├── CelestraError.swift            # Error types
│   └── CelestraLogger.swift           # Structured logging
├── Commands/
│   ├── AddFeedCommand.swift           # Add feed command
│   ├── UpdateCommand.swift            # Update feeds command (demonstrates filters)
│   └── ClearCommand.swift             # Clear data command
├── Extensions/
│   ├── Feed+MistKit.swift             # Feed ↔ CloudKit conversion
│   └── Article+MistKit.swift          # Article ↔ CloudKit conversion
├── CelestraConfig.swift               # CloudKit service factory
└── Celestra.swift                     # Main CLI entry point

External Dependencies (from CelestraKit):
├── Feed.swift                         # Feed metadata model
├── Article.swift                      # Article model
├── RateLimiter.swift                  # Per-domain rate limiting
└── RobotsTxtService.swift             # Robots.txt compliance checking
```

## Schema Design

### Overview

CelestraCloud uses CloudKit's public database with a carefully designed schema optimized for RSS feed aggregation and content discovery. The schema includes two record types (`Feed` and `Article`) with a mix of user-provided data, calculated fields, and server-managed metadata.

### Record Types

#### Feed Record Type

Stores RSS feed metadata in the public database, shared across all users.

**Core Metadata:**
- `feedURL` (String, Queryable+Sortable) - Unique RSS/Atom feed URL
- `title` (String, Searchable) - Feed title
- `description` (String) - Feed description/subtitle
- `category` (String, Queryable) - Content category
- `imageURL` (String) - Feed logo/icon URL
- `siteURL` (String) - Website home page URL
- `language` (String, Queryable) - ISO language code
- `tags` (List<String>) - User-defined tags

**Quality Indicators:**
- `isFeatured` (Int64, Queryable) - 1 if featured, 0 otherwise
- `isVerified` (Int64, Queryable) - 1 if verified/trusted, 0 otherwise
- `qualityScore` (Int64, Queryable+Sortable) - **CALCULATED** quality score (0-100)
- `subscriberCount` (Int64, Queryable+Sortable) - Number of subscribers

**Timestamps:**
- `verifiedTimestamp` (Timestamp, Queryable+Sortable) - Last verification time
- `attemptedTimestamp` (Timestamp, Queryable+Sortable) - Last fetch attempt
- Note: Creation time uses CloudKit's built-in `createdTimestamp` field

**Feed Characteristics (Calculated):**
- `updateFrequency` (Double) - **CALCULATED:** Average articles per day
- `minUpdateInterval` (Double) - **CALCULATED:** Minimum hours between requests

**Server Metrics:**
- `totalAttempts` (Int64) - Total fetch attempts
- `successfulAttempts` (Int64) - Successful fetches
- `failureCount` (Int64) - Consecutive failures (reset on success)
- `lastFailureReason` (String) - Most recent error message
- `isActive` (Int64, Queryable) - 1 if active, 0 if disabled

**HTTP Caching:**
- `etag` (String) - ETag for conditional requests
- `lastModified` (String) - Last-Modified header value

#### Article Record Type

Stores RSS article content in the public database.

**Identity & Relationships:**
- `feedRecordName` (String, Queryable+Sortable) - Parent Feed recordName
- `guid` (String, Queryable+Sortable) - Article unique ID from RSS

**Core Content:**
- `title` (String, Searchable) - Article title
- `excerpt` (String) - Summary/description
- `content` (String, Searchable) - Full HTML content
- `contentText` (String, Searchable) - **CALCULATED:** Plain text from HTML
- `author` (String, Queryable) - Author name
- `url` (String) - Article permalink
- `imageURL` (String) - Featured image URL (manually enriched)

**Publishing Metadata:**
- `publishedTimestamp` (Timestamp, Queryable+Sortable) - Original publish date
- `fetchedTimestamp` (Timestamp, Queryable+Sortable) - When fetched from RSS
- `expiresTimestamp` (Timestamp, Queryable+Sortable) - **CALCULATED:** Cache expiration

**Deduplication & Analysis (Calculated):**
- `contentHash` (String, Queryable) - **CALCULATED:** SHA256 composite key (title|url|guid)
- `wordCount` (Int64) - **CALCULATED:** Word count from contentText
- `estimatedReadingTime` (Int64) - **CALCULATED:** Minutes to read (wordCount / 200)

**Enrichment Fields:**
- `language` (String, Queryable) - ISO language code (manually enriched)
- `tags` (List<String>) - Content tags (manually enriched)

### Calculated Fields

The schema includes several calculated/derived fields that are computed during RSS feed processing:

#### Feed Calculations

**`qualityScore` (0-100):**
Composite metric balancing reliability, popularity, update consistency, and verification:

```
qualityScore = min(100,
  (successRate × 40) +        // 40 points: reliability
  (subscriberBonus × 30) +    // 30 points: popularity
  (updateConsistency × 20) +  // 20 points: update pattern
  (verifiedBonus × 10)        // 10 points: verification
)

where:
- successRate = successfulAttempts / max(1, totalAttempts)
- subscriberBonus = min(10, log10(max(1, subscriberCount)) × 3)
- updateConsistency = calculated from updateFrequency deviation
- verifiedBonus = isVerified ? 10 : 0
```

**`updateFrequency` (articles/day):**
```
updateFrequency = articlesPublished / daysSinceFirstArticle
```
Calculated during feed refresh, represents how often new articles appear.

**`minUpdateInterval` (hours):**
```
minUpdateInterval = max(
  ttl_from_rss,               // RSS <ttl> tag if present
  feedUpdateFrequency × 0.8,  // 80% of average update frequency
  1.0                         // Minimum 1 hour
)
```
Respects feed's requested update rate for web etiquette.

#### Article Calculations

**`contentText`:**
```
contentText = stripHTML(content).trimmed()
```
Uses HTML parser to extract text, removes tags and scripts.

**`contentHash`:**
```
contentHash = SHA256("\(guid)|\(title)|\(url)")
```
Composite hash for identifying content changes and duplicates.

**`wordCount`:**
```
wordCount = contentText.split(by: whitespace).count
```

**`estimatedReadingTime` (minutes):**
```
estimatedReadingTime = max(1, wordCount / 200)
```
Assumes 200 words per minute reading speed.

**`expiresTimestamp`:**
```
expiresTimestamp = fetchedTimestamp + (ttlDays × 24 × 3600)
```
Defaults to 30 days unless specified.

### CloudKit Security Model

CelestraCloud uses a **server-managed public database** architecture with carefully designed permissions:

**Permissions for Feed and Article:**
```
GRANT READ TO "_world",
GRANT CREATE, WRITE TO "_icloud"
```

**Why this design?**

1. **Public Read Access (`_world`):**
   - All users can read the feed catalog and articles
   - Enables content discovery across the platform
   - No authentication required for browsing

2. **Server-Only Write (`_icloud`):**
   - Only server-to-server operations can create/modify feeds
   - Prevents individual users from polluting the shared catalog
   - Ensures content quality and consistency
   - Uses CLI/backend with explicit credentials

3. **No `_creator` Role:**
   - Feeds are shared resources, not user-owned
   - Prevents per-user feed duplication
   - Eliminates ownership conflicts
   - Simplifies permission model

**Security Implications:**
- ✅ Public feeds remain readable by everyone
- ✅ Only authorized servers can modify content
- ✅ Individual users cannot claim ownership of shared feeds
- ✅ Prevents accidental data corruption
- ✅ Centralized content moderation

**Server-to-Server Authentication:**
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

### Error Handling Strategy

CelestraCloud uses a **hybrid error handling approach** balancing CloudKit storage costs with debugging needs:

**1. Inline Error Fields (CloudKit):**
```swift
// Feed record includes lightweight error tracking
"failureCount"       INT64    // Consecutive failure count
"lastFailureReason"  STRING   // Most recent error message only
```

**Benefits:**
- ✅ Simple queries: "show feeds with failures"
- ✅ No additional lookups needed
- ✅ Minimal storage overhead

**Limitations:**
- ❌ Only stores latest error
- ❌ No error history

**2. Local Logging (CelestraLogger):**
```swift
// Detailed errors logged locally, not to CloudKit
CelestraLogger.errors.error("Failed to fetch feed: \(feedURL) - \(error)")
CelestraLogger.operations.info("Retrying after 60s...")
```

**Benefits:**
- ✅ Full error history for debugging
- ✅ Detailed stack traces and context
- ✅ No CloudKit storage costs
- ✅ Can integrate with external logging services

**Why Not a Separate ErrorLog Record Type?**

We considered creating an `ErrorLog` record type in CloudKit but opted against it:
- ❌ Additional CloudKit queries needed
- ❌ Increased storage costs for verbose logs
- ❌ Public database not ideal for error logs
- ❌ Better handled by external logging infrastructure

**Recommendation:**
- Keep inline fields for quick error status checks
- Use CelestraLogger for detailed debugging
- For production, integrate with external logging (e.g., CloudWatch, Sentry)

### Timestamp Field Naming

All timestamp fields use a consistent `Timestamp` suffix to match CloudKit conventions:

**Feed Timestamps:**
- `createdTimestamp` (CloudKit built-in) - When feed was created
- `verifiedTimestamp` - Last verification time
- `attemptedTimestamp` - Last fetch attempt

**Article Timestamps:**
- `publishedTimestamp` - Original publication date
- `fetchedTimestamp` - When fetched from RSS feed
- `expiresTimestamp` - Cache expiration time

**Benefits:**
- ✅ Matches CloudKit's `createdTimestamp` and `modifiedTimestamp` pattern
- ✅ Consistent suffix makes fields easily recognizable
- ✅ Clearer than mixed `*At`, `*Date`, `last*` patterns
- ✅ Eliminated redundant `addedAt` field

### Schema Migration Notes

**Breaking Changes from v0.x:**

The schema was refactored for consistency and CloudKit best practices:

1. **Removed Fields:**
   - `addedAt` → Use CloudKit's `createdTimestamp`

2. **Renamed Fields:**
   - `lastVerified` → `verifiedTimestamp`
   - `lastAttempted` → `attemptedTimestamp`
   - `publishedDate` → `publishedTimestamp`
   - `fetchedAt` → `fetchedTimestamp`
   - `expiresAt` → `expiresTimestamp`

**Migration Required:** If you have existing CloudKit records, you'll need to migrate field data or recreate the database.

## Dependencies

CelestraCloud builds upon several key dependencies:

### CelestraKit
[CelestraKit](https://github.com/brightdigit/CelestraKit) provides shared models and web etiquette services:
- **Feed & Article Models**: Core data structures for RSS feed metadata and articles
- **RateLimiter**: Actor-based per-domain rate limiting for respectful web crawling
- **RobotsTxtService**: Robots.txt parsing and compliance checking

This separation allows the models and services to be reused across the Celestra ecosystem (future mobile apps, additional CLI tools, etc.).

### MistKit
CloudKit Web Services wrapper providing query filtering, sorting, and record modification APIs.

### SyndiKit
RSS and Atom feed parsing library from BrightDigit.

### Swift Packages
- **ArgumentParser**: Command-line interface framework
- **Logging**: Structured logging infrastructure

## Development

### Using the Makefile

CelestraCloud includes a comprehensive Makefile for common development tasks:

```bash
# Install development dependencies (SwiftLint, SwiftFormat, etc.)
make install

# Build the project
make build

# Run unit tests
make test

# Run linters
make lint

# Auto-format code
make format

# Run the CLI (requires .env sourced)
make run

# Deploy CloudKit schema
make setup-cloudkit

# Clean build artifacts
make clean
```

Run `make help` to see all available targets.

### Running Tests

```bash
# Run all tests
make test

# Or use Swift directly
swift test
```

The test suite includes 22 local tests across 3 test suites:
- Feed+MistKitTests (7 tests)
- Article+MistKitTests (6 tests)
- BatchOperationResultTests (9 tests)

Note: RateLimiter and RobotsTxtService tests (19 tests) are maintained in the CelestraKit package.

### Code Quality

```bash
# Run SwiftLint
make lint

# Auto-format code with SwiftFormat
make format
```

The project enforces strict code quality standards with 90+ SwiftLint rules and comprehensive SwiftFormat configuration.

## Documentation

### Project Guides

- **[CLAUDE.md](./CLAUDE.md)** - Guidance for AI agents working with this codebase
- **[CHANGELOG.md](./CHANGELOG.md)** - Release notes and version history
- **[.claude/IMPLEMENTATION_NOTES.md](./.claude/IMPLEMENTATION_NOTES.md)** - Design decisions and architectural patterns
- **[.claude/AI_SCHEMA_WORKFLOW.md](./.claude/AI_SCHEMA_WORKFLOW.md)** - CloudKit schema design workflow for AI agents
- **[.claude/CLOUDKIT_SCHEMA_SETUP.md](./.claude/CLOUDKIT_SCHEMA_SETUP.md)** - CloudKit schema deployment instructions
- **[.claude/PRD.md](./.claude/PRD.md)** - Product Requirements Document for v1.0.0 release

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

MIT License - See [LICENSE](./LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
