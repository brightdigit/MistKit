# Server-to-Server Authentication (Implementation Details)

> **Note**: This is a detailed reference guide for CloudKit Server-to-Server authentication implementation. For daily development, see the main [CLAUDE.md](../CLAUDE.md) file.

This document explains how BushelCloud implements CloudKit Server-to-Server (S2S) authentication using MistKit, including internal workings and best practices.

## What is Server-to-Server Authentication?

Server-to-Server authentication allows backend services, scripts, or CLI tools to access CloudKit **without requiring a signed-in iCloud user**. This is essential for:

- Automated data syncing from external APIs
- Scheduled batch operations
- Server-side data processing
- Command-line tools that manage CloudKit data

## How It Works

1. **Generate a Server-to-Server key pair** (ECDSA P-256)
2. **Register public key** in CloudKit Dashboard, receive Key ID
3. **Sign requests** using private key and Key ID (handled by MistKit)
4. **CloudKit authenticates** requests as the developer/"_creator" role
5. **Schema permissions** grant access based on "_creator" and "_icloud" roles

## BushelCloudKitService Implementation Pattern

BushelCloud wraps MistKit's `CloudKitService` for convenience:

```swift
struct BushelCloudKitService {
    let service: CloudKitService

    init(
        containerIdentifier: String,
        keyID: String,
        privateKeyPath: String
    ) throws {
        // 1. Validate file exists
        guard FileManager.default.fileExists(atPath: privateKeyPath) else {
            throw BushelCloudKitError.privateKeyFileNotFound(path: privateKeyPath)
        }

        // 2. Read PEM file
        let pemString = try String(contentsOfFile: privateKeyPath, encoding: .utf8)

        // 3. Create S2S authentication manager
        let tokenManager = try ServerToServerAuthManager(
            keyID: keyID,
            pemString: pemString
        )

        // 4. Initialize CloudKit service
        self.service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: .development,  // or .production
            database: .public
        )
    }
}
```

## How ServerToServerAuthManager Works Internally

**Initialization:**
```swift
let tokenManager = try ServerToServerAuthManager(
    keyID: "your-key-id",
    pemString: pemFileContents  // Reads from .pem file
)
```

**What happens internally (MistKit):**
1. Parses PEM string into ECDSA P-256 private key using Swift Crypto
2. Stores key ID and private key data
3. Creates `TokenCredentials` with `.serverToServer` authentication method

**Request signing (automatic):**
- For each CloudKit API request
- MistKit creates a signature using the private key
- Sends Key ID + signature in HTTP headers
- CloudKit server verifies with registered public key

## Security Best Practices

### Private Key Storage

**Secure storage:**
```bash
# Create secure directory
mkdir -p ~/.cloudkit
chmod 700 ~/.cloudkit

# Store private key securely
mv ~/Downloads/AuthKey_*.pem ~/.cloudkit/bushel-private-key.pem
chmod 600 ~/.cloudkit/bushel-private-key.pem
```

**Environment setup:**
```bash
# Add to ~/.zshrc or ~/.bashrc
export CLOUDKIT_KEY_ID="your_key_id"
export CLOUDKIT_KEY_FILE="$HOME/.cloudkit/bushel-private-key.pem"
export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Bushel"
```

**Git protection:**
```gitignore
# .gitignore
*.pem
*.p8
.env
.cloudkit/
```

### Key Management Rules

**Never:**
- ❌ Commit .pem files to version control
- ❌ Share private keys in Slack/email
- ❌ Store in public locations
- ❌ Use same key across development/production
- ❌ Hardcode keys in source code

**Always:**
- ✅ Use environment variables
- ✅ Set restrictive file permissions (600)
- ✅ Store in user-specific locations (~/.cloudkit/)
- ✅ Generate separate keys per environment
- ✅ Rotate keys periodically (every 6-12 months)

## Common Authentication Errors

### "Private key file not found"

```text
BushelCloudKitError.privateKeyFileNotFound(path: "./key.pem")
```

**Cause:** File doesn't exist at specified path or wrong working directory

**Solution:**
- Use absolute path: `$HOME/.cloudkit/bushel-private-key.pem`
- Or verify current working directory matches expected location
- Check file permissions (readable by current user)

### "PEM string is invalid"

```text
TokenManagerError.invalidCredentials(.invalidPEMFormat)
```

**Cause:** .pem file is corrupted or not in correct format

**Solution:**
- Verify file has proper BEGIN/END markers:
  ```
  -----BEGIN EC PRIVATE KEY-----
  ...
  -----END EC PRIVATE KEY-----
  ```
- Re-download from CloudKit Dashboard if corrupted
- Ensure UTF-8 encoding (no binary corruption)

### "Key ID is empty"

```text
TokenManagerError.invalidCredentials(.keyIdEmpty)
```

**Cause:** Key ID not provided or environment variable not set

**Solution:**
```bash
# Check environment variable
echo $CLOUDKIT_KEY_ID

# Set if missing
export CLOUDKIT_KEY_ID="your-key-id-here"
```

### "ACCESS_DENIED - CREATE operation not permitted"

```json
{
  "recordName": "RestoreImage-24A335",
  "reason": "CREATE operation not permitted",
  "serverErrorCode": "ACCESS_DENIED"
}
```

**Cause:** Schema permissions don't grant CREATE to `_creator` and `_icloud`

**Solution:** Update schema with both permission grants:
```text
GRANT READ, CREATE, WRITE TO "_creator",
GRANT READ, CREATE, WRITE TO "_icloud",
```

**Critical:** Both roles are required. Only granting to one causes ACCESS_DENIED errors.

## Operation Types and Permissions

CloudKit operations have different permission requirements:

**READ operations:**
- `queryRecords()` - Requires READ permission
- `fetchRecords()` - Requires READ permission

**CREATE operations:**
- `RecordOperation.create()` - Requires CREATE permission
- First-time record creation

**WRITE operations:**
- `RecordOperation.update()` - Requires WRITE permission
- Modifying existing records

**REPLACE operations:**
- `RecordOperation.forceReplace()` - Requires both CREATE and WRITE
- Creates if doesn't exist, updates if exists
- **Recommended for idempotent syncs**

## Batch Operations and Limits

CloudKit enforces a **200 operations per request** limit:

```swift
func syncRecords(_ records: [RestoreImageRecord]) async throws {
    let operations = records.map { record in
        RecordOperation.create(
            recordType: RestoreImageRecord.cloudKitRecordType,
            recordName: record.recordName,
            fields: record.toCloudKitFields()
        )
    }

    // Chunk into batches of 200
    let batchSize = 200
    let batches = operations.chunked(into: batchSize)

    for (index, batch) in batches.enumerated() {
        print("Batch \(index + 1)/\(batches.count): \(batch.count) records...")
        let results = try await service.modifyRecords(batch)

        // Check for partial failures
        let failures = results.filter { $0.recordType == "Unknown" }
        let successes = results.filter { $0.recordType != "Unknown" }

        print("✓ \(successes.count) succeeded, ❌ \(failures.count) failed")
    }
}
```

## Error Handling in Batch Operations

CloudKit returns **partial success** - some operations may succeed while others fail:

```swift
let results = try await service.modifyRecords(batch)

for result in results {
    if result.recordType == "Unknown" {
        // This is an error response
        print("❌ Error for \(result.recordName ?? "unknown")")
        print("   Code: \(result.serverErrorCode ?? "N/A")")
        print("   Reason: \(result.reason ?? "N/A")")
    } else {
        // Successfully created/updated
        print("✓ Success: \(result.recordName ?? "unknown")")
    }
}
```

**Common error codes:**
- `ACCESS_DENIED` - Permission denied (check schema permissions)
- `AUTHENTICATION_FAILED` - Invalid key ID or signature
- `CONFLICT` - Record version mismatch (use `.forceReplace` to avoid)
- `QUOTA_EXCEEDED` - Too many operations or storage limit reached
- `VALIDATING_REFERENCE_ERROR` - Referenced record doesn't exist

## Reference Resolution

When creating records with references, upload order matters:

```swift
// 1. Upload referenced records first (no dependencies)
try await uploadSwiftVersions()   // No dependencies
try await uploadRestoreImages()    // No dependencies

// 2. Upload records with references last
try await uploadXcodeVersions()    // References SwiftVersion and RestoreImage
```

**Creating a reference:**
```swift
fields["minimumMacOS"] = .reference(
    FieldValue.Reference(recordName: "RestoreImage-23C71")
)
fields["swiftVersion"] = .reference(
    FieldValue.Reference(recordName: "SwiftVersion-6.0")
)
```

**Reference validation:** CloudKit validates that referenced records exist. If not, returns `VALIDATING_REFERENCE_ERROR`.

## Testing S2S Authentication

**1. Test authentication:**
```swift
let records = try await service.queryRecords(recordType: "RestoreImage", limit: 1)
print("✓ Authentication successful, found \(records.count) records")
```

**2. Test record creation:**
```swift
let testRecord = RestoreImageRecord(
    version: "18.0",
    buildNumber: "22A123",
    releaseDate: Date(),
    downloadURL: "https://example.com/test.ipsw",
    fileSize: 1000000,
    sha256Hash: "abc123",
    sha1Hash: "def456",
    isSigned: true,
    isPrerelease: false,
    source: "test"
)

let operation = RecordOperation.create(
    recordType: RestoreImageRecord.cloudKitRecordType,
    recordName: testRecord.recordName,
    fields: testRecord.toCloudKitFields()
)

let results = try await service.modifyRecords([operation])

if results.first?.recordType == "Unknown" {
    print("❌ Failed: \(results.first?.reason ?? "unknown")")
} else {
    print("✓ Success! Record created: \(results.first?.recordName ?? "")")
}
```

**3. Verify in CloudKit Dashboard:**
1. Go to CloudKit Dashboard
2. Select your Container
3. Navigate to Data → Public Database
4. Select record type
5. Verify test record appears

## Environment: Development vs Production

**Development environment:**
- Use `environment: .development` in CloudKitService init
- Separate schema from production
- Test freely without affecting production data
- Changes deploy instantly

**Production environment:**
- Use `environment: .production`
- Requires schema deployment from development
- Real user data - be cautious
- Changes may require app updates

**Best practice:**
```swift
let environment: CloudKitEnvironment = {
    #if DEBUG
    return .development
    #else
    return .production
    #endif
}()

let service = try CloudKitService(
    containerIdentifier: containerID,
    tokenManager: tokenManager,
    environment: environment,
    database: .public
)
```
