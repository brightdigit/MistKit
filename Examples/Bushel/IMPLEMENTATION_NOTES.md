# Bushel Demo Implementation Notes

## Session Summary: AppleDB Integration & S2S Authentication Refactoring

This document captures key implementation decisions, issues encountered, and solutions applied during the development of the Bushel CloudKit demo. Use this as a reference when building similar demos (e.g., Celestra).

---

## Major Changes Completed

### 1. AppleDB Data Source Integration

**Purpose**: Fetch comprehensive restore image data with device-specific signing status for VirtualMac2,1 to complement ipsw.me's data.

**Implementation**:
- Integrated AppleDB API for device-specific restore image information
- Created modern, error-handled implementation with Swift 6 concurrency
- Integrated as an additional fetcher in `DataSourcePipeline`

**Files Created**:
```text
AppleDB/
├── AppleDBParser.swift        # Fetches from api.appledb.dev
├── AppleDBFetcher.swift       # Implements fetcher pattern
└── Models/
    ├── AppleDBVersion.swift   # Domain model with CloudKit helpers
    └── AppleDBAPITypes.swift  # API response types
```

**Key Features**:
- Device filtering for VirtualMac variants
- File size parsing (string → Int64 for CloudKit)
- Prerelease detection (beta/RC in version string)
- Robust error handling with custom error types

**Integration Point**:
```swift
// DataSourcePipeline.swift
async let appleDBImages = options.includeAppleDB
    ? AppleDBFetcher().fetch()
    : [RestoreImageRecord]()
```

### 2. Server-to-Server Authentication Refactoring

**Motivation**:
- Server-to-Server Keys are the recommended enterprise authentication method
- More secure than API Tokens (private key never transmitted, only signatures)
- Better demonstrates production-ready CloudKit integration

**What Changed**:

| Before (API Token) | After (Server-to-Server Key) |
|-------------------|------------------------------|
| Single token string | Key ID + Private Key (.pem file) |
| `APITokenManager` | `ServerToServerAuthManager` |
| `CLOUDKIT_API_TOKEN` env var | `CLOUDKIT_KEY_ID` + `CLOUDKIT_KEY_FILE` |
| `--api-token` flag | `--key-id` + `--key-file` flags |

**Files Modified**:
1. `BushelCloudKitService.swift` - Switch to `ServerToServerAuthManager`
2. `SyncEngine.swift` - Update initializer parameters
3. `SyncCommand.swift` - New CLI options and env vars
4. `ExportCommand.swift` - New CLI options and env vars
5. `setup-cloudkit-schema.sh` - Updated instructions
6. `README.md` - Comprehensive S2S documentation

**New Usage**:
```bash
# Command-line flags
bushel-images sync \
  --key-id "YOUR_KEY_ID" \
  --key-file ./private-key.pem

# Environment variables (recommended)
export CLOUDKIT_KEY_ID="YOUR_KEY_ID"
export CLOUDKIT_KEY_FILE="$HOME/.cloudkit/bushel-private-key.pem"
bushel-images sync
```

---

## Critical Issues Solved

### Issue 1: CloudKit Schema File Format

**Problem**: `cktool validate-schema` failed with parsing error.

**Root Cause**: Schema file was missing `DEFINE SCHEMA` header and included CloudKit system fields.

**Solution**:
```text
# Before (incorrect)
RECORD TYPE RestoreImage (
    "__recordID" RECORD ID,  # ❌ System fields shouldn't be in schema
    ...
)

# After (correct)
DEFINE SCHEMA

RECORD TYPE RestoreImage (
    "version" STRING QUERYABLE,  # ✅ Only user-defined fields
    ...
)
```

**Lesson**: CloudKit automatically adds system fields (`__recordID`, `___createTime`, etc.). Never include them in schema definitions.

### Issue 2: Authentication Terminology Confusion

**Problem**: Confusing "API Token", "Server-to-Server Key", "Management Token", and "User Token".

**Clarification**:

| Token Type | Used For | Used By | Where to Get |
|-----------|----------|---------|--------------|
| **Management Token** | Schema operations (import/export) | `cktool` | Dashboard → CloudKit Web Services |
| **Server-to-Server Key** | Runtime API operations (server-side) | `ServerToServerAuthManager` | Dashboard → Server-to-Server Keys |
| **API Token** | Runtime API operations (simpler) | `APITokenManager` | Dashboard → API Tokens |
| **User Token** | User-specific operations | Web apps with user auth | OAuth-like flow |

**For Bushel Demo**:
- Schema setup: **Management Token** (via `cktool save-token`)
- Sync/Export commands: **Server-to-Server Key** (Key ID + .pem file)

### Issue 3: cktool Command Syntax

**Problem**: Script used non-existent `list-containers` command and missing `--file` flag.

**Fixes**:
```bash
# Token check (before - wrong)
xcrun cktool list-containers  # ❌ Not a valid command

# Token check (after - correct)
xcrun cktool get-teams  # ✅ Valid command that requires auth

# Schema validation (before - wrong)
xcrun cktool validate-schema ... "$SCHEMA_FILE"  # ❌ Missing --file

# Schema validation (after - correct)
xcrun cktool validate-schema ... --file "$SCHEMA_FILE"  # ✅ Correct syntax
```

---

## MistKit Authentication Architecture

### How ServerToServerAuthManager Works

1. **Initialization**:
```swift
let tokenManager = try ServerToServerAuthManager(
    keyID: "YOUR_KEY_ID",
    pemString: pemFileContents  // Reads from .pem file
)
```

2. **What happens internally**:
   - Parses PEM string into ECDSA P-256 private key
   - Stores key ID and private key data
   - Creates `TokenCredentials` with `.serverToServer` method

3. **Request signing** (handled by MistKit):
   - For each CloudKit API request
   - Creates signature using private key
   - Sends Key ID + signature in headers
   - Server verifies with public key

### BushelCloudKitService Pattern

```swift
struct BushelCloudKitService {
    init(containerIdentifier: String, keyID: String, privateKeyPath: String) throws {
        // 1. Validate file exists
        guard FileManager.default.fileExists(atPath: privateKeyPath) else {
            throw BushelCloudKitError.privateKeyFileNotFound(path: privateKeyPath)
        }

        // 2. Read PEM file
        let pemString = try String(contentsOfFile: privateKeyPath, encoding: .utf8)

        // 3. Create auth manager
        let tokenManager = try ServerToServerAuthManager(
            keyID: keyID,
            pemString: pemString
        )

        // 4. Create CloudKit service
        self.service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: .development,
            database: .public
        )
    }
}
```

---

## Data Source Integration Pattern

### Adding a New Data Source (AppleDB Example)

**Step 1: Create Fetcher**
```swift
struct AppleDBFetcher: Sendable {
    func fetch() async throws -> [RestoreImageRecord] {
        // Fetch and parse data
        // Map to CloudKit record model
        // Return array
    }
}
```

**Step 2: Add to Pipeline Options**
```swift
struct DataSourcePipeline {
    struct Options: Sendable {
        var includeAppleDB: Bool = true
    }
}
```

**Step 3: Integrate into Pipeline**
```swift
private func fetchRestoreImages(options: Options) async throws -> [RestoreImageRecord] {
    // Parallel fetching
    async let appleDBImages = options.includeAppleDB
        ? AppleDBFetcher().fetch()
        : [RestoreImageRecord]()

    // Collect results
    allImages.append(contentsOf: try await appleDBImages)

    // Deduplicate by buildNumber
    return deduplicateRestoreImages(allImages)
}
```

**Step 4: Add CLI Option**
```swift
struct SyncCommand {
    @Flag(name: .long, help: "Exclude AppleDB.dev as data source")
    var noAppleDB: Bool = false

    private func buildSyncOptions() -> SyncEngine.SyncOptions {
        if noAppleDB {
            pipelineOptions.includeAppleDB = false
        }
    }
}
```

### Deduplication Strategy

Bushel uses **buildNumber** as the unique key:

```swift
private func deduplicateRestoreImages(_ images: [RestoreImageRecord]) -> [RestoreImageRecord] {
    var uniqueImages: [String: RestoreImageRecord] = [:]

    for image in images {
        let key = image.buildNumber

        if let existing = uniqueImages[key] {
            // Merge records, prefer most complete data
            uniqueImages[key] = mergeRestoreImages(existing, image)
        } else {
            uniqueImages[key] = image
        }
    }

    return Array(uniqueImages.values).sorted { $0.releaseDate > $1.releaseDate }
}
```

**Merge Priority**:
1. ipsw.me (most complete: has both SHA1 + SHA256)
2. AppleDB (device-specific signing status, comprehensive coverage)
3. MESU (freshness detection only)
4. MrMacintosh (beta/RC releases)

---

## Security Best Practices

### Private Key Management

**Storage**:
```bash
# Create secure directory
mkdir -p ~/.cloudkit
chmod 700 ~/.cloudkit

# Store private key securely
mv ~/Downloads/AuthKey_*.pem ~/.cloudkit/bushel-private-key.pem
chmod 600 ~/.cloudkit/bushel-private-key.pem
```

**Environment Setup**:
```bash
# Add to ~/.zshrc or ~/.bashrc
export CLOUDKIT_KEY_ID="your_key_id"
export CLOUDKIT_KEY_FILE="$HOME/.cloudkit/bushel-private-key.pem"
```

**Git Protection**:
```gitignore
# .gitignore
*.pem
.env
```

**Never**:
- ❌ Commit .pem files to version control
- ❌ Share private keys in Slack/email
- ❌ Store in public locations
- ❌ Use same key across development/production

**Always**:
- ✅ Use environment variables
- ✅ Set restrictive file permissions (600)
- ✅ Store in user-specific locations (~/.cloudkit/)
- ✅ Generate separate keys per environment
- ✅ Rotate keys periodically

---

## Common Error Messages & Solutions

### "Private key file not found"
```text
BushelCloudKitError.privateKeyFileNotFound(path: "./key.pem")
```
**Solution**: Use absolute path or ensure working directory is correct.

### "PEM string is invalid"
```text
TokenManagerError.invalidCredentials(.invalidPEMFormat)
```
**Solution**: Verify .pem file is valid. Check for:
- Correct BEGIN/END markers
- No corruption during download
- Proper encoding (UTF-8)

### "Key ID is empty"
```text
TokenManagerError.invalidCredentials(.keyIdEmpty)
```
**Solution**: Ensure `CLOUDKIT_KEY_ID` is set or `--key-id` is provided.

### "Schema validation failed: Was expecting DEFINE"
```text
❌ Schema validation failed: Encountered "RECORD" at line 1
Was expecting: "DEFINE" ...
```
**Solution**: Add `DEFINE SCHEMA` header at top of schema.ckdb file.

---

## CloudKit Dashboard Navigation

### Schema Setup (Management Token)
1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container
3. Navigate to: **API Access** → **CloudKit Web Services**
4. Click **Generate Management Token**
5. Copy token and run: `xcrun cktool save-token`

### Runtime Auth (Server-to-Server Key)
1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container
3. Navigate to: **API Access** → **Server-to-Server Keys**
4. Click **Create a Server-to-Server Key**
5. Download .pem file (can't download again!)
6. Note the Key ID displayed

---

## Testing Checklist

Before considering Bushel complete:

- [ ] Schema imports successfully with `setup-cloudkit-schema.sh`
- [ ] Sync command fetches from all data sources
- [ ] AppleDB fetcher returns VirtualMac2,1 data
- [ ] Deduplication works correctly (no duplicate buildNumbers)
- [ ] Records upload to CloudKit public database
- [ ] Export command retrieves and formats data
- [ ] Error messages are helpful
- [ ] Private keys are properly protected (.gitignore)
- [ ] Documentation is complete and accurate

---

## Lessons for Celestra Demo

When building the Celestra demo, apply these patterns:

1. **Authentication**: Start with Server-to-Server Keys from the beginning
2. **Schema**: Always include `DEFINE SCHEMA` header, no system fields
3. **Fetchers**: Use the same pipeline pattern for data sources
4. **Error Handling**: Create custom error types with helpful messages
5. **CLI Design**: Use `--key-id` and `--key-file` flags consistently
6. **Documentation**: Include comprehensive authentication setup section
7. **Security**: Create .gitignore immediately with `*.pem` entry

### Reusable Patterns

**BushelCloudKitService pattern** → Can be copied for Celestra
**DataSourcePipeline pattern** → Adapt for Celestra's data sources
**RecordBuilder pattern** → Reuse for Celestra's record types
**CLI structure** → Same flag naming and env var conventions

---

## References

- MistKit: `Sources/MistKit/Authentication/ServerToServerAuthManager.swift`
- CloudKit Schema: `Examples/Bushel/schema.ckdb`
- Setup Script: `Examples/Bushel/Scripts/setup-cloudkit-schema.sh`
- Pipeline: `Examples/Bushel/Sources/BushelImages/DataSources/DataSourcePipeline.swift`

---

**Last Updated**: Current session
**Status**: AppleDB integration complete, S2S auth refactoring complete, ready for testing
