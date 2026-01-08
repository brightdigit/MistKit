# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bushel is a CloudKit demonstration project that syncs macOS restore images, Xcode versions, and Swift compiler versions to CloudKit using MistKit. This is an **example application** designed to showcase MistKit's CloudKit Web Services capabilities, particularly Server-to-Server authentication and batch record operations.

**Key Purpose**: Tutorial-friendly demo for developers learning CloudKit and MistKit integration patterns.

## Quick Start

### Building and Running

```bash
# Build the project
swift build

# Run the CLI tool
.build/debug/bushel-cloud --help
```

### Common Commands

```bash
# Sync data to CloudKit (verbose mode recommended)
.build/debug/bushel-cloud sync --verbose

# Dry run (fetch data without uploading)
.build/debug/bushel-cloud sync --dry-run --verbose

# Export CloudKit data to JSON
.build/debug/bushel-cloud export --output data.json --verbose

# Clear all CloudKit data
.build/debug/bushel-cloud clear

# List records in CloudKit
.build/debug/bushel-cloud list

# Check CloudKit status
.build/debug/bushel-cloud status
```

### Environment Variables

Required for CloudKit operations:

```bash
export CLOUDKIT_KEY_ID="your-key-id"
export CLOUDKIT_PRIVATE_KEY_PATH="$HOME/.cloudkit/bushel-private-key.pem"
export CLOUDKIT_CONTAINER_ID="iCloud.com.yourcompany.Bushel"  # Optional, has default
```

Optional for VirtualBuddy TSS signing status:

```bash
export VIRTUALBUDDY_API_KEY="your-virtualbuddy-api-key"  # Get from https://tss.virtualbuddy.app/
```

### GitHub Actions Workflows

Manually trigger the scheduled CloudKit sync workflow:

```bash
# Trigger sync workflow on 8-scheduled-job branch
gh workflow run cloudkit-sync.yml --ref 8-scheduled-job

# Or using the API directly
gh api repos/brightdigit/BushelCloud/actions/workflows/cloudkit-sync.yml/dispatches -f ref=8-scheduled-job

# Check status of recent workflow runs
gh run list --workflow=cloudkit-sync.yml --limit 5

# View details of a specific run
gh run view <run-id>

# Watch logs of a running workflow
gh run watch <run-id>
```

## Architecture

### Modular Architecture with BushelKit

Starting with v0.0.1, BushelCloud uses **BushelKit** as a modular foundation:

**BushelKit** (`Packages/BushelKit/`):
- `BushelFoundation` - Core domain models (RestoreImageRecord, XcodeVersionRecord, SwiftVersionRecord)
- `BushelUtilities` - Shared utilities (FormattingHelpers, JSONDecoder extensions)
- `BushelLogging` - Logging abstractions

**BushelCloudKit** (`Sources/BushelCloudKit/`):
- Extends BushelKit models with CloudKit integration
- `Extensions/*+CloudKit.swift` - CloudKitRecord protocol conformance
- `DataSources/` - API fetchers (IPSW, AppleDB, MESU, etc.)
- `CloudKit/` - SyncEngine and service layer

**Dependency Flow**:
```
BushelCloudCLI → BushelCloudKit → BushelFoundation → BushelUtilities → MistKit
```

**Why This Architecture**:
- Domain models reusable across projects (BushelKit can evolve independently)
- CloudKit logic isolated to extensions (clean separation)
- Shared utilities promote consistency
- Testing each layer independently

### Core Data Flow

The application follows a pipeline architecture:

```
External Data Sources → DataSourcePipeline → CloudKitService → CloudKit
                              ↓
                    (deduplication & merging)
```

**Three-Phase Sync Process**:
1. **Fetch**: `DataSourcePipeline` fetches from multiple external APIs in parallel
2. **Transform**: Records are deduplicated and references resolved
3. **Upload**: `BushelCloudKitService` batches operations and uploads to CloudKit

### Key Components

**CloudKit Integration** (`Sources/BushelCloud/CloudKit/`):
- `BushelCloudKitService.swift` - Server-to-Server auth setup and batch operations wrapper
- `SyncEngine.swift` - Orchestrates the full sync process from fetch to upload
- `CloudKitFieldMapping.swift` - Type conversion helpers between Swift and CloudKit FieldValue
- `RecordManaging+Query.swift` - Query extensions for fetching records

**Data Sources** (`Sources/BushelCloud/DataSources/`):
- `DataSourcePipeline.swift` - Coordinates fetching from all sources with metadata tracking
- Individual fetchers: `IPSWFetcher`, `AppleDBFetcher`, `MESUFetcher`, `XcodeReleasesFetcher`, etc.

**Models** (`Packages/BushelKit/Sources/BushelFoundation/`):
- `RestoreImageRecord` - macOS restore images (uses `URL` and `Int` types)
- `XcodeVersionRecord` - Xcode releases with CKReference relationships
- `SwiftVersionRecord` - Swift compiler versions
- `DataSourceMetadata` - Fetch metadata with timestamp tracking

**CloudKit Extensions** (`Sources/BushelCloudKit/Extensions/`):
- `RestoreImageRecord+CloudKit.swift` - Implements CloudKitRecord protocol
- `XcodeVersionRecord+CloudKit.swift` - Handles CKReference serialization
- `SwiftVersionRecord+CloudKit.swift` - Basic CloudKit mapping
- `DataSourceMetadata+CloudKit.swift` - Metadata sync record
- `FieldValue+URL.swift` - URL ↔ STRING conversion

**Commands** (`Sources/BushelCloud/Commands/`):
- CLI commands using swift-argument-parser
- Each command (sync, export, clear, list, status) is a separate file

### CloudKit Record Relationships

Records have dependencies that must be uploaded in order:

```
SwiftVersion (no dependencies)
RestoreImage (no dependencies)
    ↓
    | CKReference (minimumMacOS, swiftVersion)
    ↓
XcodeVersion
```

**Upload Order**: SwiftVersion & RestoreImage → XcodeVersion (see `SyncEngine.swift:100`)

### Data Deduplication

Multiple sources provide overlapping data. The pipeline deduplicates using:
- **Build Number** as unique key for Restore Images and Xcode Versions
- **Version String** as unique key for Swift Versions
- **Merge Priority**: MESU for signing status, AppleDB for hashes, most recent `sourceUpdatedAt` wins

See `.claude/implementation-patterns.md` for detailed deduplication logic and code examples.

### VirtualBuddy TSS API Integration

**Purpose**: VirtualBuddy provides real-time TSS (Tatsu Signing Status) verification for macOS restore images for virtual machines.

**API Endpoint**:
```
GET https://tss.virtualbuddy.app/v1/status?apiKey=<key>&ipsw=<IPSW URL>
```

**Board Config**: Checks `VMA2MACOSAP` (macOS virtual machines)

**Key Response Fields**:
- `isSigned` (boolean) - true if Apple is signing the build, false otherwise
- `uuid` - Request tracking ID for debugging
- `version` - macOS version (e.g., "15.0")
- `build` - Build number (e.g., "24A5327a")
- `code` - Status code (0 = SUCCESS, 94 = not eligible)
- `message` - Human-readable status message

**HTTP Status Codes**:
- `200` - Success (returned regardless of signing status)
- `400` - Bad request (invalid IPSW URL)
- `429` - Rate limit exceeded
- `500` - Internal server error

**Rate Limits & Caching**:
- **Rate limit**: 2 requests per 5 seconds
- **Server-side CDN cache**: 12 hours (to avoid Apple TSS rate limiting)
- **Client-side implementation**: Random delays of 2.5-3.5 seconds with 1-second tolerance between requests

**Implementation Details**:
- **File**: `Sources/BushelCloudKit/DataSources/VirtualBuddyFetcher.swift`
- **Integration**: Enriches RestoreImageRecord with real-time signing status after other data sources
- **Error handling**: HTTP 429 errors are logged; original record preserved on any error
- **Progress tracking**: Shows "X/Y images checked" during sync
- **Performance**: ~2.5-4 minutes for 50 images (acceptable for 8-16 hour sync schedules)

**Deduplication Priority**:
- VirtualBuddy is an **authoritative source** for `isSigned` status (along with MESU)
- Takes precedence over other sources when merging duplicate records
- See `DataSourcePipeline.swift:429-447` for merge logic

**Example Response (Signed)**:
```json
{
  "uuid": "67919BEC-F793-4544-A5E6-152EE435DCA6",
  "version": "15.0",
  "build": "24A5327a",
  "code": 0,
  "message": "SUCCESS",
  "isSigned": true
}
```

**Example Response (Unsigned)**:
```json
{
  "uuid": "02A12F2F-CE0E-4FBF-8155-884B8D9FD5CB",
  "version": "15.1",
  "build": "24B5024e",
  "code": 94,
  "message": "This device isn't eligible for the requested build.",
  "isSigned": false
}
```

### Logging

The project uses structured logging with `BushelLogger` (wrapping `os.Logger`):
- **Standard logs**: Progress and results
- **Verbose logs** (`--verbose`): MistKit API calls, batch details
- **Subsystems**: `.sync`, `.cloudKit`, `.dataSource`

## Git Subrepo Development

BushelKit is embedded as a git subrepo for rapid development during the migration phase.

### Configuration
- **Remote:** `git@github.com:brightdigit/BushelKit.git`
- **Branch:** `bushelcloud`
- **Location:** `Packages/BushelKit/`

### Making Changes to BushelKit

```bash
# 1. Edit files in Packages/BushelKit/
vim Packages/BushelKit/Sources/BushelFoundation/RestoreImageRecord.swift

# 2. Commit changes in BushelCloud repository
git add Packages/BushelKit/
git commit -m "Update BushelKit: add field documentation"

# 3. Push changes to BushelKit repository
git subrepo push Packages/BushelKit
```

### Pulling Updates from BushelKit

```bash
git subrepo pull Packages/BushelKit
```

### When to Switch to Remote Dependency

| Development Stage | Approach | Package.swift |
|-------------------|----------|---------------|
| Now (active migration) | Git subrepo (local path) | `.package(path: "Packages/BushelKit")` |
| After BushelKit v2.0 stable | Remote dependency | `.package(url: "https://github.com/brightdigit/BushelKit.git", from: "2.0.0")` |

**Benefits of Subrepo Now:**
- Edit BushelKit and BushelCloud together
- Test integration immediately
- No version coordination overhead

**Migration to Remote:**
1. Tag stable BushelKit version
2. Update `Package.swift` to use URL dependency
3. Remove `Packages/BushelKit/` directory
4. Use standard SPM workflow

### Best Practices
- Commit BushelKit changes separately from BushelCloud changes
- Push to subrepo after each logical change
- Pull before starting new work
- Test both repositories after changes

## Development Essentials

### Swift 6 Configuration

The project uses strict Swift 6 concurrency checking (see `Package.swift:10-78`):
- Full typed throws
- Complete strict concurrency checking
- Noncopyable generics, variadic generics
- Actor data race checks
- **All types are `Sendable`**

**When adding code**: Ensure all new types conform to `Sendable` and use `async/await` patterns consistently.

### Type Design Decisions

#### Int vs Int64 for File Sizes

**Decision:** All models use `Int` for byte counts (fileSize fields)

**Rationale:**
- All supported platforms are 64-bit (macOS 14+, iOS 17+, watchOS 10+)
- On 64-bit systems: `Int` == `Int64` (same size and range)
- Swift convention: use `Int` for counts, sizes, and indices
- CloudKit automatically converts via `.int64(fileSize)`

**Safety Analysis:**
- Largest image file: ~15 GB
- `Int.max` on 64-bit: 9,223,372,036,854,775,807 bytes (~9 exabytes)
- **No overflow risk** for any realistic file size

**CloudKit Integration:**
```swift
// Write to CloudKit
fields["fileSize"] = .int64(record.fileSize)  // Auto-converts Int → Int64

// Read from CloudKit
let size: Int? = recordInfo.fields["fileSize"]?.intValue  // Returns Int
```

#### URL Type for Download Links

**Decision:** Models use `URL` (not `String`) for download links

**Benefits:**
- Type safety at compile time
- URL component access (scheme, host, path, query)
- Automatic validation on creation
- Custom `FieldValue(url:)` extension handles CloudKit STRING conversion

**CloudKit Integration:**
```swift
// Extension: Sources/BushelCloudKit/Extensions/FieldValue+URL.swift
public extension FieldValue {
  init(url: URL) {
    self = .string(url.absoluteString)
  }

  var urlValue: URL? {
    if case .string(let value) = self {
      return URL(string: value)
    }
    return nil
  }
}
```

**Tests:** See `Tests/BushelCloudTests/Extensions/FieldValueURLTests.swift` (13 test methods)

### CloudKitRecord Protocol

All domain models conform to `CloudKitRecord`:

```swift
protocol CloudKitRecord {
    static var cloudKitRecordType: String { get }
    func toCloudKitFields() -> [String: FieldValue]
    static func from(recordInfo: RecordInfo) -> Self?
    static func formatForDisplay(_ recordInfo: RecordInfo) -> String
}
```

**When adding a new record type**:
1. Create model struct in `Models/`
2. Implement `CloudKitRecord` conformance
3. Add to `BushelCloudKitService.recordTypes` (line 19)
4. Update CloudKit schema in Dashboard or via `cktool`

### Date Handling

CloudKit dates use **milliseconds since epoch** (not seconds). MistKit's `FieldValue.date()` handles conversion automatically:

```swift
fields["releaseDate"] = .date(Date())  // ✅ Auto-converted to milliseconds
```

### Boolean Fields

CloudKit has no native boolean type. Use `INT64` with 0/1:

```swift
// In schema
"isSigned"       INT64 QUERYABLE,  // 0 = false, 1 = true

// In Swift
fields["isSigned"] = .int64(record.isSigned ? 1 : 0)

// Reading back
if case .int64(let value) = fields["isSigned"] {
    let isSigned = value == 1
}
```

### Reference Fields

CloudKit references use record names (not IDs):

```swift
// Creating a reference
fields["minimumMacOS"] = .reference(
    FieldValue.Reference(recordName: "RestoreImage-23C71")
)

// Reading a reference
if case .reference(let ref) = fieldValue {
    let recordName = ref.recordName
}
```

**Upload order matters**: Upload referenced records before records that reference them, or you'll get `VALIDATING_REFERENCE_ERROR`.

### Batch Operations

CloudKit enforces a **200 operations per request** limit. Operations are automatically chunked:

```swift
let batchSize = 200
let batches = operations.chunked(into: batchSize)
for batch in batches {
    let results = try await service.modifyRecords(batch)
}
```

See `.claude/s2s-auth-details.md` for detailed batch operation examples and error handling.

### Error Handling

- `BushelCloudKitError` enum defines project-specific errors
- MistKit operations throw `CloudKitError` for API failures
- Use `RecordInfo.isError` to detect partial batch failures
- Verbose mode logs error details (serverErrorCode, reason)

**Common error codes**:
- `ACCESS_DENIED` - Check schema permissions (_creator + _icloud)
- `AUTHENTICATION_FAILED` - Invalid key ID or signature
- `CONFLICT` - Use `.forceReplace` instead of `.create`
- `VALIDATING_REFERENCE_ERROR` - Referenced record doesn't exist

### Testing Data Sources

Individual fetchers can be tested directly:

```swift
let fetcher = IPSWFetcher()
let images = try await fetcher.fetch()
```

No formal test suite exists (this is a demo project).

## CloudKit Integration

### Server-to-Server Authentication Overview

S2S authentication allows CLI tools to access CloudKit without a signed-in iCloud user. BushelCloud uses ECDSA P-256 private keys:

```swift
// Initialize with private key from .pem file
let tokenManager = try ServerToServerAuthManager(
    keyID: "your-key-id",
    pemString: pemFileContents
)

let service = try CloudKitService(
    containerIdentifier: "iCloud.com.company.App",
    tokenManager: tokenManager,
    environment: .development,
    database: .public
)
```

**Key setup**:
1. Generate key pair in CloudKit Dashboard
2. Download .pem file to `~/.cloudkit/bushel-private-key.pem`
3. Set permissions: `chmod 600 ~/.cloudkit/bushel-private-key.pem`
4. Set environment variables (see Quick Start section)

See `.claude/s2s-auth-details.md` for implementation details, security best practices, and troubleshooting.

### CloudKit Schema Requirements

The project requires three record types in the public database:

**RestoreImage**: version, buildNumber, releaseDate, downloadURL, fileSize, sha256Hash, sha1Hash, isSigned (INT64), isPrerelease (INT64), source, notes, sourceUpdatedAt

**XcodeVersion**: version, buildNumber, releaseDate, downloadURL, isPrerelease (INT64), source, minimumMacOS (REFERENCE), swiftVersion (REFERENCE), notes

**SwiftVersion**: version, releaseDate, downloadURL, source, notes

**DataSourceMetadata**: sourceName, recordTypeName, lastFetchedAt, sourceUpdatedAt, recordCount, fetchDurationSeconds, lastError

**Critical Schema Rules**:
1. Always start schema files with `DEFINE SCHEMA`
2. System fields (`___recordID`, `___createdTimestamp`, etc.) can be included in `.ckdb` schema files but are auto-generated when creating records via API
3. Grant permissions to **both** `_creator` AND `_icloud` for S2S auth
4. Use `INT64` for booleans (0 = false, 1 = true)

### Basic cktool Commands

```bash
# Save management token (for schema operations)
xcrun cktool save-token

# Validate schema
xcrun cktool validate-schema --team-id TEAM_ID --container-id CONTAINER_ID --environment development --file schema.ckdb

# Import schema
xcrun cktool import-schema --team-id TEAM_ID --container-id CONTAINER_ID --environment development --file schema.ckdb

# Export current schema
xcrun cktool export-schema --team-id TEAM_ID --container-id CONTAINER_ID --environment development > backup.ckdb
```

See `.claude/schema-management.md` for complete cktool reference, schema versioning, CI/CD deployment, and troubleshooting.

### Common CloudKit Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `ACCESS_DENIED` | Missing permissions | Grant to both `_creator` and `_icloud` |
| `AUTHENTICATION_FAILED` | Invalid key/PEM | Check `CLOUDKIT_KEY_ID` and `.pem` file |
| `VALIDATING_REFERENCE_ERROR` | Referenced record missing | Upload referenced records first |
| `QUOTA_EXCEEDED` | Too many operations | Reduce batch size or wait |

## Xcode Development Setup

### Opening in Xcode

```bash
# From Terminal
cd /Users/leo/Documents/Projects/BushelCloud
open Package.swift

# Or: File > Open in Xcode, select Package.swift
```

### Scheme Configuration Essentials

1. **Edit Scheme** (Cmd+Shift+,)
2. **Run → Arguments tab**:
   - Add environment variables:
     - `CLOUDKIT_CONTAINER_ID`: `iCloud.com.brightdigit.Bushel`
     - `CLOUDKIT_KEY_ID`: Your key ID
     - `CLOUDKIT_PRIVATE_KEY_PATH`: `$HOME/.cloudkit/bushel-private-key.pem`
   - Add arguments for testing:
     - `sync --verbose` or `export --output ./export.json --verbose`
3. **Run → Options tab**:
   - Set custom working directory to project root

### Key Debugging Workflows

**Test data fetching without CloudKit**:
- Use `--dry-run` flag: `.build/debug/bushel-cloud sync --dry-run --verbose`
- Or set breakpoint in `SyncEngine.swift` after `fetchAllData()` to inspect fetched records

**Debug CloudKit upload**:
- Set breakpoint in `BushelCloudKitService.modifyRecords()` before upload
- Inspect `operations` array and `results` for errors

**Useful breakpoint locations**:
- `SyncEngine.swift` - `sync()` method start
- `DataSourcePipeline.swift` - `fetchAllData()` to inspect fetched records
- `BushelCloudKitService.swift` - `modifyRecords()` before CloudKit upload
- Individual fetchers - `fetch()` methods for data source issues

### Common Xcode Issues

| Issue | Solution |
|-------|----------|
| "Cannot find container" | Verify `CLOUDKIT_CONTAINER_ID` is correct |
| "Authentication failed" | Check `CLOUDKIT_KEY_ID` and `CLOUDKIT_PRIVATE_KEY_PATH` |
| "Module 'MistKit' not found" | Reset package cache or rebuild |
| "Cannot find type 'RecordOperation'" | Clean build folder (Cmd+Shift+K) and rebuild |

### XcodeGen (Optional)

Generate Xcode project with pre-configured settings:

```bash
brew install xcodegen
xcodegen generate
open BushelCloud.xcodeproj
```

Note: The `.xcodeproj` is in `.gitignore` - always regenerate rather than committing.

## Dependencies

- **MistKit** (local path: `../MistKit`) - CloudKit Web Services client with S2S auth
- **IPSWDownloads** - ipsw.me API wrapper for restore images
- **SwiftSoup** - HTML parsing for web scraping
- **ArgumentParser** - CLI framework
- **swift-log** - Logging infrastructure

MistKit is the parent package; BushelCloud is an example in `Examples/Bushel/`.

## CI/CD and Code Quality

### Linting

```bash
./Scripts/lint.sh
```

**Tools (managed via Mint)**:
- `swift-format@602.0.0` - Code formatting
- `SwiftLint@0.62.2` - Style and convention linting (90+ opt-in rules)
- `periphery@3.2.0` - Unused code detection

**Configuration**: `.swiftlint.yml`, `.swift-format`, `Mintfile`

### Testing

```bash
swift test
```

Note: Currently only placeholder tests exist (demo project focused on CloudKit patterns).

### GitHub Actions Workflows

- **BushelCloud.yml** - Main CI with multi-platform testing (Ubuntu, Windows, macOS)
- **codeql.yml** - Security analysis
- **claude.yml** - Claude Code integration for issues/PRs
- **claude-code-review.yml** - Automated PR reviews

### Branch Protection

The `main` branch requires:
- All 14 status checks passing (multi-platform builds + lint + CodeQL)
- Pull request reviews
- Conversation resolution

## Important Limitations

As noted in README.md, this is a **demonstration project** with known limitations:

- No incremental sync (always fetches all data from external sources)
- No conflict resolution for concurrent updates
- Limited error recovery in batch operations
- **Export pagination**: Export only retrieves first 200 records per type (see Issue #8)

These are intentional to keep the demo focused on MistKit patterns rather than production robustness.

**Note on Duplicates**: The sync properly uses `.forceReplace` operations with deterministic record names (based on build numbers), so repeated syncs **update** existing records rather than creating duplicates.

## Additional Documentation

For detailed guides on advanced topics, see:

- **[.claude/schema-management.md](.claude/schema-management.md)** - Complete CloudKit schema management guide
  - Schema file format and rules
  - Complete cktool command reference
  - Schema validation errors and solutions
  - Versioning best practices
  - CI/CD deployment automation
  - Database scope considerations

- **[.claude/s2s-auth-details.md](.claude/s2s-auth-details.md)** - Server-to-Server authentication implementation
  - How S2S authentication works internally
  - BushelCloudKitService implementation pattern
  - Security best practices and key management
  - Common authentication errors and solutions
  - Operation types and permissions
  - Batch operations with detailed examples
  - Testing S2S authentication
  - Development vs Production environments

- **[.claude/implementation-patterns.md](.claude/implementation-patterns.md)** - Implementation patterns and history
  - Data source integration pattern with code examples
  - Deduplication strategy and merge logic
  - AppleDB integration details
  - S2S authentication migration history
  - Critical issues solved and lessons learned
  - Common pitfalls to avoid
  - Lessons for building future CloudKit demos
