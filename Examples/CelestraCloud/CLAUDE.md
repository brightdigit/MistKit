# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Celestra is a command-line RSS reader that demonstrates MistKit's CloudKit integration capabilities. It fetches RSS feeds, stores them in CloudKit's public database, and implements comprehensive web etiquette best practices including rate limiting, robots.txt checking, and conditional HTTP requests.

**Tech Stack**: Swift 6.2, MistKit (CloudKit wrapper), CelestraKit (shared models & services), SyndiKit (RSS parsing), Swift Configuration (configuration management)

## Common Commands

### Build and Run

```bash
# Build the project
swift build

# Run with environment variables
source .env
swift run celestra-cloud <command>

# Add a feed
swift run celestra-cloud add-feed https://example.com/feed.xml

# Update feeds with filters
swift run celestra-cloud update
swift run celestra-cloud update --update-last-attempted-before 2025-01-01T00:00:00Z
swift run celestra-cloud update --update-min-popularity 10 --update-delay 3.0
swift run celestra-cloud update --update-limit 5 --update-max-failures 0

# Clear all data
swift run celestra-cloud clear --confirm

# Using both environment variables and CLI arguments (CLI wins)
UPDATE_DELAY=2.0 swift run celestra-cloud update --update-delay 3.0
```

### Environment Setup

Required environment variables (see `.env.example`):
- `CLOUDKIT_KEY_ID` - Server-to-Server key ID from Apple Developer Console
- `CLOUDKIT_PRIVATE_KEY_PATH` - Path to `.pem` private key file

Optional environment variables:
- `CLOUDKIT_CONTAINER_ID` - CloudKit container identifier (default: `iCloud.com.brightdigit.Celestra`)
- `CLOUDKIT_ENVIRONMENT` - Either `development` or `production` (default: `development`)

### CloudKit Schema Management

```bash
# Automated schema deployment (requires cktool)
export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Celestra"
export CLOUDKIT_TEAM_ID="YOUR_TEAM_ID"
export CLOUDKIT_ENVIRONMENT="development"
./Scripts/setup-cloudkit-schema.sh
```

Schema is defined in `schema.ckdb` using CloudKit's text-based schema language.

## Architecture

### High-Level Structure

```
Sources/CelestraCloud/
├── Celestra.swift              # CLI entry point
└── Commands/                   # CLI subcommands
    ├── AddFeedCommand.swift    # Parse and add RSS feeds
    ├── UpdateCommand.swift     # Fetch/update feeds (shows MistKit QueryFilter)
    └── ClearCommand.swift      # Delete all records

Sources/CelestraCloudKit/
├── Configuration/              # Swift Configuration integration
│   ├── CelestraConfiguration.swift          # Root config struct
│   ├── CloudKitConfiguration.swift          # CloudKit credentials config
│   ├── UpdateCommandConfiguration.swift     # Update command options
│   ├── ConfigurationLoader.swift            # Multi-source config loader
│   └── ConfigurationError.swift             # Enhanced errors
├── CelestraConfig.swift        # CloudKit service factory
├── Services/
│   ├── CloudKitService+Celestra.swift  # MistKit operations
│   ├── CelestraError.swift             # Error types
│   └── CelestraLogger.swift            # Structured logging
├── Models/
│   └── BatchOperationResult.swift      # Batch operation tracking
└── Extensions/
    ├── Feed+MistKit.swift      # Feed ↔ CloudKit conversion
    └── Article+MistKit.swift   # Article ↔ CloudKit conversion
```

**External Dependencies**: The `Feed` and `Article` models, along with `RateLimiter` and `RobotsTxtService`, are provided by the CelestraKit package for reuse across CLI and other clients.

### Key Architectural Patterns

**1. MistKit Integration**

CloudKitService is configured in `CelestraConfig.createCloudKitService()`:
- Server-to-Server authentication using PEM keys
- Public database access for shared feeds
- Environment-based configuration (dev/prod)

All CloudKit operations are in `CloudKitService+Celestra.swift` extension:
- `queryFeeds()` - Demonstrates QueryFilter and QuerySort APIs
- `createArticles()` / `updateArticles()` - Batch operations with chunking
- `queryArticlesByGUIDs()` - Duplicate detection queries

**2. Field Mapping Pattern**

Models use direct field mapping with validation (CloudKitConvertible protocol):

```swift
// To CloudKit
func toFieldsDict() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
        "title": .string(title),
        "isActive": .int64(isActive ? 1 : 0)  // Booleans as INT64
    ]
    // Optional fields only added if present
    if let description = description {
        fields["description"] = .string(description)
    }
    return fields
}

// From CloudKit - with validation (throws CloudKitConversionError)
init(from record: RecordInfo) throws {
    // Required fields throw if missing or empty
    guard case .string(let title) = record.fields["title"],
          !title.isEmpty else {
        throw CloudKitConversionError.missingRequiredField(
            fieldName: "title",
            recordType: "Feed"
        )
    }

    // Boolean extraction with default
    if case .int64(let value) = record.fields["isActive"] {
        self.isActive = value != 0
    } else {
        self.isActive = true  // Default for optional fields
    }
}
```

**Validation Behavior:**
- Required fields (feedURL, title for Feed; feedRecordName, guid, title, url for Article) throw `CloudKitConversionError` if missing or empty
- Invalid articles are skipped with warning logs; one bad article won't fail the entire feed update
- Feed conversion errors propagate (fail-fast for feed metadata)

**3. Duplicate Detection Strategy**

UpdateCommand implements GUID-based duplicate detection:
1. Extract GUIDs from fetched articles
2. Query CloudKit for existing articles with those GUIDs (`queryArticlesByGUIDs`)
3. Separate into new vs modified articles (using `contentHash` comparison)
4. Create new articles, update modified ones, skip unchanged

This minimizes CloudKit writes and prevents duplicate content.

**4. Batch Operations**

Articles are processed in batches of 10 (conservative to keep payload size manageable with full content):
- Non-atomic operations allow partial success
- Each batch tracked in `BatchOperationResult`
- Provides success rate, failure count, and detailed error tracking
- See `createArticles()` / `updateArticles()` in CloudKitService+Celestra.swift

**5. Web Etiquette Implementation**

Celestra is a respectful RSS client:
- **Rate Limiting**: Uses `RateLimiter` actor from CelestraKit - configurable delays between feeds (default 2s), per-domain tracking
- **Robots.txt**: Uses `RobotsTxtService` actor from CelestraKit - parses and respects robots.txt rules
- **Conditional Requests**: Uses If-Modified-Since/ETag headers, handles 304 Not Modified
- **Failure Tracking**: Tracks consecutive failures per feed, can filter by max failures
- **Update Intervals**: Respects feed's `minUpdateInterval` to avoid over-fetching
- **User-Agent**: Identifies as "Celestra/1.0 (MistKit RSS Reader; +https://github.com/brightdigit/MistKit)"

All web etiquette features are demonstrated in UpdateCommand.swift using services from CelestraKit.

## CloudKit Schema

Two record types in public database:

**Feed**: RSS feed metadata
- Key fields: `feedURL` (QUERYABLE SORTABLE), `title` (SEARCHABLE)
- Metrics: `totalAttempts`, `successfulAttempts`, `subscriberCount`
- Web etiquette: `etag`, `lastModified`, `failureCount`, `minUpdateInterval`
- Booleans stored as INT64: `isActive`, `isFeatured`, `isVerified`

**Article**: RSS article content
- Key fields: `guid` (QUERYABLE SORTABLE), `feedRecordName` (STRING)
- Content: `title`, `excerpt`, `content`, `contentText` (all SEARCHABLE)
- Deduplication: `contentHash` (SHA256), `guid`
- TTL: `expiresAt` (QUERYABLE SORTABLE) for cleanup

**Relationship Design**: Uses string-based `feedRecordName` instead of CKReference for simplicity and clearer querying patterns. Trade-off: Manual cascade delete vs automatic with CKReference.

## Swift Configuration (v1.0.0)

CelestraCloud uses Apple's Swift Configuration library for unified configuration management across environment variables and command-line arguments.

### Configuration Architecture

**Priority Order**: CLI arguments > Environment variables > Defaults

```swift
// ConfigurationLoader uses CommandLineArgumentsProvider
let loader = ConfigurationLoader()
let config = await loader.loadConfiguration()
```

### Built-in Providers Used

1. **CommandLineArgumentsProvider** - Automatic CLI argument parsing (highest priority)
2. **EnvironmentVariablesProvider** - System environment variables

**Package Trait**: `CommandLineArguments` trait is enabled in Package.swift to support CommandLineArgumentsProvider.

### Configuration Reference

#### CloudKit Configuration

CloudKit authentication credentials must be provided via environment variables:

| Environment Variable | Type | Default | Required | Description |
|---------------------|------|---------|----------|-------------|
| `CLOUDKIT_CONTAINER_ID` | String | `iCloud.com.brightdigit.Celestra` | No | CloudKit container identifier |
| `CLOUDKIT_KEY_ID` | String | None | **Yes** | Server-to-Server key ID from Apple Developer Console |
| `CLOUDKIT_PRIVATE_KEY_PATH` | String | None | **Yes** | Absolute path to `.pem` private key file |
| `CLOUDKIT_ENVIRONMENT` | String | `development` | No | CloudKit environment: `development` or `production` |

**Note**: CloudKit credentials (`CLOUDKIT_KEY_ID` and `CLOUDKIT_PRIVATE_KEY_PATH`) are marked as secrets and automatically redacted from logs.

#### Update Command Configuration (Optional)

All update command settings are **optional** and can be provided via environment variables OR CLI arguments:

| Option | Env Variable | CLI Argument | Type | Default | Description |
|--------|--------------|--------------|------|---------|-------------|
| Delay | `UPDATE_DELAY` | `--update-delay <seconds>` | Double | `2.0` | Delay between feed updates in seconds |
| Skip Robots | `UPDATE_SKIP_ROBOTS_CHECK` | `--update-skip-robots-check` | Bool | `false` | Skip robots.txt validation (flag) |
| Max Failures | `UPDATE_MAX_FAILURES` | `--update-max-failures <count>` | Int | None | Skip feeds above this failure threshold |
| Min Popularity | `UPDATE_MIN_POPULARITY` | `--update-min-popularity <count>` | Int | None | Only update feeds with minimum subscribers |
| Last Attempted Before | `UPDATE_LAST_ATTEMPTED_BEFORE` | `--update-last-attempted-before <iso8601>` | Date | None | Only update feeds attempted before this date |
| Limit | `UPDATE_LIMIT` | `--update-limit <count>` | Int | None | Maximum number of feeds to query and update |
| JSON Output Path | `UPDATE_JSON_OUTPUT_PATH` | `--update-json-output-path <path>` | String | None | Path to write JSON report with detailed results |

**Date Format**: ISO8601 (e.g., `2025-01-01T00:00:00Z`)

### Configuration Key Mapping

**Command-line arguments** use kebab-case:
- `--cloudkit-container-id` → `cloudkit.container_id`
- `--update-delay` → `update.delay`
- `--update-skip-robots-check` → `update.skip_robots_check`

**Environment variables** use SCREAMING_SNAKE_CASE:
- `CLOUDKIT_CONTAINER_ID` → `cloudkit.container_id`
- `UPDATE_DELAY` → `update.delay`
- `UPDATE_SKIP_ROBOTS_CHECK` → `update.skip_robots_check`

### Usage Examples

**Note**: Examples below assume `celestra-cloud` is in your PATH. If running from source, prefix commands with `swift run` (e.g., `swift run celestra-cloud update`).

**Via environment variables:**
```bash
export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Celestra"
export UPDATE_DELAY=3.0
export UPDATE_MAX_FAILURES=5
celestra-cloud update
```

**Via command-line arguments:**
```bash
celestra-cloud update \
  --update-delay 3.0 \
  --update-max-failures 5 \
  --update-min-popularity 10
```

**Mixed (CLI overrides ENV):**
```bash
# Environment has UPDATE_DELAY=2.0, but CLI overrides to 5.0
UPDATE_DELAY=2.0 celestra-cloud update --update-delay 5.0
# Uses 5.0 (CLI wins)
```

**Filtering by date:**
```bash
# Only update feeds last attempted before January 1, 2025
celestra-cloud update --update-last-attempted-before 2025-01-01T00:00:00Z
```

**With JSON output for detailed reporting:**
```bash
# Generate JSON report with per-feed results and summary statistics
celestra-cloud update --update-json-output-path /tmp/feed-update-report.json

# Combine with other options for CI/CD workflows
celestra-cloud update \
  --update-limit 10 \
  --update-delay 1.0 \
  --update-json-output-path ./build/feed-update-results.json
```

### Adding New Configuration Options

To add a new configuration option (e.g., `--concurrency`):

1. **Add to configuration struct:**
```swift
// In UpdateCommandConfiguration.swift
public var concurrency: Int = 1
```

2. **Update ConfigurationLoader:**
```swift
// In ConfigurationLoader.loadConfiguration()
let update = UpdateCommandConfiguration(
    // ... existing fields
    concurrency: readInt(forKey: "update.concurrency") ?? 1
)
```

3. **Access in command:**
```swift
// In UpdateCommand.swift
let config = try await loader.loadConfiguration()
let concurrency = config.update.concurrency
```

**No manual parsing needed!** Users can now use:
- `--update-concurrency 3` (CLI - kebab-case)
- `UPDATE_CONCURRENCY=3` (environment - SCREAMING_SNAKE_CASE)

### Key Documentation

- See `.claude/https_-swiftpackageindex.com-apple-swift-configuration-1.0.0-documentation-configuration.md` for complete Swift Configuration API reference
- Provider hierarchy documentation: Configuration providers are queried in order, first non-nil value wins

## Swift 6.2 Features

Package.swift enables extensive Swift 6.2 upcoming and experimental features:
- Strict concurrency checking (`-strict-concurrency=complete`)
- Existential `any` keyword
- Typed throws
- Noncopyable generics
- Move-only types
- Variadic generics

Code must be concurrency-safe with proper actor isolation.

## Development Guidelines

**When Adding Features:**
- MistKit operations go in `CloudKitService+Celestra.swift` extension
- Configuration options: Add to appropriate struct in `Configuration/` directory, update `ConfigurationLoader`
- All CloudKit field types: Use FieldValue enum (.string, .int64, .date, .double, etc.)
- Booleans: Always store as INT64 (0/1) in CloudKit schema
- Batch operations: Chunk into batches of 10 for large payloads, use non-atomic for partial success
- Logging: Use CelestraLogger categories (cloudkit, rss, operations, errors)

**External Dependencies:**
- `RateLimiter`, `RobotsTxtService`, and `RSSFetcherService` are from CelestraKit - contributions should be made to that repository
- Feed and Article models are also in CelestraKit for reuse across the Celestra ecosystem
- Web etiquette suite (rate limiting, robots.txt, RSS fetching) is now complete in CelestraKit

**Testing CloudKit Operations:**
- Use development environment first
- Schema changes require redeployment via `./Scripts/setup-cloudkit-schema.sh`
- Clear data with `celestra clear --confirm` between tests

**Key Documentation:**
- `.claude/IMPLEMENTATION_NOTES.md` - Design decisions, patterns, and technical context
- `.claude/AI_SCHEMA_WORKFLOW.md` - CloudKit schema design guide for AI agents
- `.claude/CLOUDKIT_SCHEMA_SETUP.md` - Schema deployment instructions

## Pull Request Testing

Integration tests automatically validate the update-feeds workflow on all pull requests to `main`:

**Test Scope:**
- Runs against CloudKit **development environment** only (production never touched)
- Limited smoke test: Maximum 5 feeds, zero failures allowed
- Completes in ~2-5 minutes (vs. production's 60-120 minute runs)
- Uses same binary caching as production workflow

**Behavior:**
- **Repository branch PRs**: Full integration test runs automatically
- **Fork PRs**: Tests skipped gracefully (GitHub security prevents secret access)
- Fails fast on errors (unlike production which continues on error)

**Workflow Details:**
- Workflow: `.github/workflows/update-feeds.yml` (shared with scheduled production runs)
- Tier: `pr-test` (alongside `high`, `standard`, `stale` tiers)
- Filter: `--update-limit 5 --update-max-failures 0 --update-delay 1.0`
- Timeout: 10 minutes maximum

**External Contributors:**
Fork PRs cannot run integration tests due to GitHub's security model (secrets unavailable). Maintainers can create repository branches for contributors to run tests before merge, or tests will validate after merge.

## Important Patterns

**QueryFilter Examples** (see CloudKitService+Celestra.swift:44-68):
```swift
var filters: [QueryFilter] = []
filters.append(.lessThan("lastAttempted", .date(cutoffDate)))
filters.append(.greaterThanOrEquals("subscriberCount", .int64(minPopularity)))

let records = try await queryRecords(
    recordType: "Feed",
    filters: filters.isEmpty ? nil : filters,
    sortBy: [.ascending("feedURL")],
    limit: limit
)
```

**Duplicate Detection** (see UpdateCommand.swift:192-236):
```swift
let guids = articles.map { $0.guid }
let existingArticles = try await service.queryArticlesByGUIDs(guids, feedRecordName: recordName)
let existingMap = Dictionary(uniqueKeysWithValues: existingArticles.map { ($0.guid, $0) })

for article in articles {
    if let existing = existingMap[article.guid] {
        if existing.contentHash != article.contentHash {
            modifiedArticles.append(article.withRecordName(existing.recordName))
        }
    } else {
        newArticles.append(article)
    }
}
```

**Server-to-Server Auth** (see CelestraConfig.swift):
```swift
let privateKeyPEM = try String(contentsOfFile: privateKeyPath, encoding: .utf8)
let tokenManager = try ServerToServerAuthManager(keyID: keyID, pemString: privateKeyPEM)
let service = try CloudKitService(
    containerIdentifier: containerID,
    tokenManager: tokenManager,
    environment: environment,
    database: .public
)
```
