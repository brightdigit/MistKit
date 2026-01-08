# CloudKit Server-to-Server Authentication Setup Guide

This guide documents the complete process for setting up CloudKit Server-to-Server (S2S) authentication to sync data from external sources to CloudKit's public database. This was implemented for the Bushel demo application, which syncs Apple restore images, Xcode versions, and Swift versions to CloudKit.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Server-to-Server Key Setup](#server-to-server-key-setup)
4. [Schema Configuration](#schema-configuration)
5. [Understanding CloudKit Permissions](#understanding-cloudkit-permissions)
6. [Common Issues and Solutions](#common-issues-and-solutions)
7. [Implementation Details](#implementation-details)
8. [Testing and Verification](#testing-and-verification)

---

## Overview

### What is Server-to-Server Authentication?

Server-to-Server (S2S) authentication allows your backend services, scripts, or command-line tools to interact with CloudKit **without requiring a signed-in iCloud user**. This is essential for:

- Automated data syncing from external APIs
- Scheduled batch operations
- Server-side data processing
- Command-line tools that manage CloudKit data

### How It Works

1. **Generate a Server-to-Server key** in CloudKit Dashboard
2. **Download the private key** (.pem file) and securely store it
3. **Sign requests** using the private key and key ID
4. **CloudKit authenticates** your requests as the developer/creator
5. **Permissions are checked** against the schema's security roles

### Key Characteristics

- Operates at the **developer/application level**, not user level
- Authenticates as the **"_creator"** role in CloudKit's permission model
- Requires explicit permissions in your CloudKit schema
- Works with the **public database** only (not private or shared databases)

---

## Prerequisites

### 1. Apple Developer Account

- Active Apple Developer Program membership
- Access to [CloudKit Dashboard](https://icloud.developer.apple.com/)

### 2. CloudKit Container

- A configured CloudKit container (e.g., `iCloud.com.yourcompany.YourApp`)
- Container must be set up in your Apple Developer account

### 3. Tools

- **Xcode Command Line Tools** (for `cktool`)
- **Swift** (for building and running your sync tool)
- **OpenSSL** (for generating the key pair)

### 4. Development Environment

```bash
# Verify you have the required tools
xcode-select --version
swift --version
openssl version
```

---

## Server-to-Server Key Setup

### Step 1: Generate the Key Pair

Open Terminal and generate an ECPRIME256V1 key pair:

```bash
# Generate private key
openssl ecparam -name prime256v1 -genkey -noout -out eckey.pem

# Extract public key
openssl ec -in eckey.pem -pubout -out eckey_pub.pem
```

**Important:** Keep `eckey.pem` (private key) **secure and confidential**. Never commit it to version control.

### Step 2: Add Key to CloudKit Dashboard

1. **Navigate to CloudKit Dashboard**
   - Go to [CloudKit Dashboard](https://icloud.developer.apple.com/)
   - Select your Team
   - Select your Container

2. **Navigate to Tokens & Keys**
   - In the left sidebar, under "Settings"
   - Click "Tokens & Keys"

3. **Create New Server-to-Server Key**
   - Click the "+" button to create a new key
   - **Name:** Give it a descriptive name (e.g., "MistKit Demo for Restore Images")
   - **Public Key:** Paste the contents of `eckey_pub.pem`

4. **Save and Record Key ID**
   - After saving, CloudKit will display a **Key ID** (long hexadecimal string)
   - **Copy this Key ID** - you'll need it for authentication
   - Example: `3e76ace055d2e3881a4e9c862dd1119ea85717bd743c1c8c15d95b2280cd93ab`

### Step 3: Secure Storage

Store your private key securely:

```bash
# Option 1: iCloud Drive (encrypted)
mv eckey.pem ~/Library/Mobile\ Documents/com~apple~CloudDocs/Keys/your-app-cloudkit.pem

# Option 2: Environment variable (for CI/CD)
export CLOUDKIT_PRIVATE_KEY=$(cat eckey.pem)

# Option 3: Secure keychain (macOS)
# Store in macOS Keychain as a secure note
```

**Never:**
- Commit the private key to Git
- Share it in Slack/email
- Store it in plain text in your repository

---

## Schema Configuration

### Understanding the Schema File

CloudKit schemas define your data structure and **security permissions**. For S2S authentication to work, you must explicitly grant permissions in your schema.

### Schema File Format

Create a `schema.ckdb` file:

```text
DEFINE SCHEMA

RECORD TYPE YourRecordType (
    "field1"  STRING QUERYABLE SORTABLE SEARCHABLE,
    "field2"  TIMESTAMP QUERYABLE SORTABLE,
    "field3"  INT64 QUERYABLE,

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
);
```

### Critical Permissions for S2S

**For Server-to-Server authentication to work, you MUST include:**

```text
GRANT READ, CREATE, WRITE TO "_creator",
GRANT READ, CREATE, WRITE TO "_icloud",
```

**Why both roles are required:**
- `_creator` - S2S keys authenticate as the developer/creator
- `_icloud` - Provides additional context for authenticated operations

**Our testing showed:**
- ❌ Only `_icloud` → `ACCESS_DENIED` errors
- ❌ Only `_creator` → `ACCESS_DENIED` errors
- ✅ **Both `_creator` AND `_icloud`** → Success

### Example: Bushel Schema

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

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
);

RECORD TYPE XcodeVersion (
    "version"                STRING QUERYABLE SORTABLE SEARCHABLE,
    "buildNumber"            STRING QUERYABLE SORTABLE,
    "releaseDate"            TIMESTAMP QUERYABLE SORTABLE,
    "isPrerelease"           INT64 QUERYABLE,
    "downloadURL"            STRING,
    "fileSize"               INT64,
    "minimumMacOS"           REFERENCE,
    "includedSwiftVersion"   REFERENCE,
    "sdkVersions"            STRING,
    "notes"                  STRING,

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
);

RECORD TYPE SwiftVersion (
    "version"                STRING QUERYABLE SORTABLE SEARCHABLE,
    "releaseDate"            TIMESTAMP QUERYABLE SORTABLE,
    "isPrerelease"           INT64 QUERYABLE,
    "downloadURL"            STRING,
    "notes"                  STRING,

    GRANT READ, CREATE, WRITE TO "_creator",
    GRANT READ, CREATE, WRITE TO "_icloud",
    GRANT READ TO "_world"
);
```

### Importing the Schema

Use `cktool` to import your schema to CloudKit:

```bash
xcrun cktool import-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.YourApp \
  --environment development \
  --file schema.ckdb
```

**Note:** You'll be prompted to authenticate with your Apple ID. This requires a management token, which `cktool` will help you obtain.

### Verifying the Schema

Export and verify your schema was imported correctly:

```bash
xcrun cktool export-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.YourApp \
  --environment development \
  > current-schema.ckdb

# Check the permissions
cat current-schema.ckdb | grep -A 2 "GRANT"
```

You should see:
```text
GRANT READ, CREATE, WRITE TO "_creator",
GRANT READ, CREATE, WRITE TO "_icloud",
GRANT READ TO "_world"
```

---

## Understanding CloudKit Permissions

### Security Roles

CloudKit uses a role-based permission system with three built-in roles:

| Role | Who | Typical Use |
|------|-----|-------------|
| `_world` | Everyone (including unauthenticated users) | Public read access |
| `_icloud` | Any signed-in iCloud user | User-level operations |
| `_creator` | The developer/owner of the container | Admin/server operations |

### Permission Types

| Permission | What It Allows |
|------------|----------------|
| `READ` | Query and fetch records |
| `CREATE` | Create new records |
| `WRITE` | Update existing records |

### How S2S Authentication Maps to Roles

When you use Server-to-Server authentication:

1. Your private key + key ID authenticate you **as the developer**
2. CloudKit treats this as the **`_creator`** role
3. For public database operations, **both `_creator` and `_icloud`** permissions are needed

### Common Permission Patterns

**Public read-only data:**
```text
GRANT READ TO "_world"
```

**User-generated content:**
```text
GRANT READ, CREATE, WRITE TO "_creator",
GRANT READ, WRITE TO "_icloud",
GRANT READ TO "_world"
```

**Server-managed data (our use case):**
```text
GRANT READ, CREATE, WRITE TO "_creator",
GRANT READ, CREATE, WRITE TO "_icloud",
GRANT READ TO "_world"
```

**Admin-only data:**
```text
GRANT READ, CREATE, WRITE TO "_creator"
```

### CloudKit Dashboard UI vs Schema Syntax

The CloudKit Dashboard shows permissions with checkboxes:
- ☑️ Create
- ☑️ Read
- ☑️ Write

In the schema file, these map to:
```text
GRANT READ, CREATE, WRITE TO "role_name"
```

**Important:** The Dashboard and schema file should match. Always verify by exporting the schema after making Dashboard changes.

---

## Common Issues and Solutions

### Issue 1: ACCESS_DENIED - "CREATE operation not permitted"

**Symptom:**
```json
{
  "recordName": "YourRecord-123",
  "reason": "CREATE operation not permitted",
  "serverErrorCode": "ACCESS_DENIED"
}
```

**Root Causes:**

1. **Missing `_creator` permissions in schema**

   **Solution:** Update schema to include:
   ```text
   GRANT READ, CREATE, WRITE TO "_creator",
   ```

2. **Missing `_icloud` permissions in schema**

   **Solution:** Update schema to include:
   ```text
   GRANT READ, CREATE, WRITE TO "_icloud",
   ```

3. **Schema not properly imported to CloudKit**

   **Solution:** Re-import schema using `cktool import-schema`

4. **Server-to-Server key not active**

   **Solution:** Check CloudKit Dashboard → Tokens & Keys → Verify key is active

### Issue 2: AUTHENTICATION_FAILED (HTTP 401)

**Symptom:**
```text
HTTP 401: Authentication failed
```

**Root Causes:**

1. **Invalid or revoked Key ID**

   **Solution:** Generate a new S2S key in CloudKit Dashboard

2. **Incorrect private key**

   **Solution:** Verify you're using the correct `.pem` file

3. **Key ID and private key mismatch**

   **Solution:** Ensure the private key matches the public key registered for that Key ID

### Issue 3: Schema Syntax Errors

**Symptom:**
```text
Was expecting LIST
Encountered "QUERYABLE" at line X, column Y
```

**Root Causes:**

1. **System fields cannot have modifiers**

   **Bad:**
   ```text
   ___recordName QUERYABLE
   ```

   **Good:** Omit system fields entirely (CloudKit adds them automatically)

2. **Invalid field type**

   **Solution:** Use CloudKit's supported types:
   - `STRING`
   - `INT64` (not `BOOLEAN` - use `INT64` with 0/1)
   - `DOUBLE`
   - `TIMESTAMP`
   - `REFERENCE`
   - `ASSET`
   - `LOCATION`
   - `LIST<TYPE>`

### Issue 4: JSON Parsing Error (HTTP 500)

**Symptom:**
```text
HTTP 500: The data couldn't be read because it isn't in the correct format
```

**Root Cause:**
Response payload is too large (>500KB). This is a **client-side** parsing limitation, **not a CloudKit error**.

**Evidence it still worked:**
- HTTP 200 response received
- Record data present in response body
- Records exist in CloudKit when queried

**Solutions:**

1. **Reduce batch size** (CloudKit allows up to 200 operations per request)
   ```swift
   let batchSize = 100 // Instead of 200
   ```

2. **Don't decode the entire response** - just check for errors
   ```swift
   // Parse just the serverErrorCode field
   let json = try JSONSerialization.jsonObject(with: data)
   ```

3. **Use streaming JSON parser** for large responses

4. **Verify success by querying CloudKit** after sync

### Issue 5: Boolean Fields in CloudKit

**Symptom:**
CloudKit schema import fails or fields have wrong type

**Root Cause:**
CloudKit doesn't have a native `BOOLEAN` type in the schema language.

**Solution:**
Use `INT64` with `0` for false and `1` for true:

**Schema:**
```text
isPrerelease  INT64 QUERYABLE,
isSigned      INT64 QUERYABLE,
```

**Swift code:**
```swift
fields["isSigned"] = .int64(record.isSigned ? 1 : 0)
fields["isPrerelease"] = .int64(record.isPrerelease ? 1 : 0)
```

---

## Implementation Details

### Swift Package Structure

```text
Sources/
├── YourApp/
│   ├── CloudKit/
│   │   ├── YourAppCloudKitService.swift  # Main service wrapper
│   │   ├── RecordBuilder.swift            # Converts models to CloudKit operations
│   │   └── Models.swift                   # Data models
│   └── DataSources/
│       ├── ExternalAPIFetcher.swift       # Fetch from external sources
│       └── ...
```

### Initialize CloudKit Service

```swift
import MistKit

// Initialize with S2S authentication
let service = try BushelCloudKitService(
    containerIdentifier: "iCloud.com.yourcompany.YourApp",
    keyID: "3e76ace055d2e3881a4e9c862dd1119ea85717bd743c1c8c15d95b2280cd93ab",
    privateKeyPath: "/path/to/your-cloudkit.pem"
)
```

**Under the hood** (MistKit implementation):

```swift
struct BushelCloudKitService {
    let service: CloudKitService

    init(containerIdentifier: String, keyID: String, privateKeyPath: String) throws {
        // Read PEM file
        guard FileManager.default.fileExists(atPath: privateKeyPath) else {
            throw BushelCloudKitError.privateKeyFileNotFound(path: privateKeyPath)
        }

        let pemString = try String(contentsOfFile: privateKeyPath, encoding: .utf8)

        // Create S2S authentication manager
        let tokenManager = try ServerToServerAuthManager(
            keyID: keyID,
            pemString: pemString
        )

        // Initialize CloudKit service
        self.service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: .development,
            database: .public
        )
    }
}
```

### Building CloudKit Operations

Use `.forceReplace` for idempotent operations:

```swift
static func buildRestoreImageOperation(_ record: RestoreImageRecord) -> RecordOperation {
    var fields: [String: FieldValue] = [:]

    fields["version"] = .string(record.version)
    fields["buildNumber"] = .string(record.buildNumber)
    fields["releaseDate"] = .timestamp(record.releaseDate)
    fields["downloadURL"] = .string(record.downloadURL)
    fields["fileSize"] = .int64(Int64(record.fileSize))
    fields["sha256Hash"] = .string(record.sha256Hash)
    fields["sha1Hash"] = .string(record.sha1Hash)
    fields["isSigned"] = .int64(record.isSigned ? 1 : 0)
    fields["isPrerelease"] = .int64(record.isPrerelease ? 1 : 0)
    fields["source"] = .string(record.source)
    if let notes = record.notes {
        fields["notes"] = .string(notes)
    }

    return RecordOperation(
        operationType: .forceReplace,  // Create if not exists, update if exists
        recordType: "RestoreImage",
        recordName: record.recordName,
        fields: fields
    )
}
```

**Why `.forceReplace`?**
- Idempotent: Running sync multiple times won't create duplicates
- Creates new records if they don't exist
- Updates existing records with new data
- Requires both `CREATE` and `WRITE` permissions

### Batch Operations

CloudKit limits operations to **200 per request**:

```swift
func syncRecords(_ records: [RestoreImageRecord]) async throws {
    let operations = records.map { record in
        RecordOperation.create(
            recordType: RestoreImageRecord.cloudKitRecordType,
            recordName: record.recordName,
            fields: record.toCloudKitFields()
        )
    }

    let batchSize = 200
    let batches = operations.chunked(into: batchSize)

    for (index, batch) in batches.enumerated() {
        print("Batch \(index + 1)/\(batches.count): \(batch.count) records...")
        let results = try await service.modifyRecords(batch)

        // Check for errors
        let failures = results.filter { $0.recordType == "Unknown" }
        let successes = results.filter { $0.recordType != "Unknown" }

        print("✓ \(successes.count) succeeded, ❌ \(failures.count) failed")
    }
}
```

### Error Handling

CloudKit returns **partial success** - some operations may succeed while others fail:

```swift
let results = try await service.modifyRecords(batch)

// CloudKit returns mixed results
for result in results {
    if result.recordType == "Unknown" {
        // This is an error response
        print("❌ Error: \(result.serverErrorCode)")
        print("   Reason: \(result.reason)")
    } else {
        // Successfully created/updated
        print("✓ Record: \(result.recordName)")
    }
}
```

Common error codes:
- `ACCESS_DENIED` - Permissions issue
- `AUTHENTICATION_FAILED` - Invalid key ID or signature
- `CONFLICT` - Record version mismatch (use `.forceReplace` to avoid)
- `QUOTA_EXCEEDED` - Too many operations or storage limit reached

---

## Testing and Verification

### 1. Test Authentication

```swift
// Try a simple query to verify auth works
let records = try await service.queryRecords(recordType: "YourRecordType", limit: 1)
print("✓ Authentication successful, found \(records.count) records")
```

### 2. Verify Schema Permissions

```bash
# Export current schema
xcrun cktool export-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.YourApp \
  --environment development

# Check permissions include _creator and _icloud
# Look for:
# GRANT READ, CREATE, WRITE TO "_creator",
# GRANT READ, CREATE, WRITE TO "_icloud",
```

### 3. Test Record Creation

```swift
// Create a test record
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

### 4. Query Records from CloudKit

```bash
# Using cktool (requires management token)
xcrun cktool query \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.YourApp \
  --environment development \
  --record-type RestoreImage \
  --limit 10
```

Or in Swift:

```swift
let records = try await service.queryRecords(
    recordType: "RestoreImage",
    limit: 10
)

for record in records {
    print("Record: \(record.recordName)")
    print("  Version: \(record.fields["version"]?.stringValue ?? "N/A")")
    print("  Build: \(record.fields["buildNumber"]?.stringValue ?? "N/A")")
}
```

### 5. Verify in CloudKit Dashboard

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/)
2. Select your Container
3. Navigate to **Data** in the left sidebar
4. Select **Public Database**
5. Choose your **Record Type** (e.g., "RestoreImage")
6. You should see your synced records

---

## Complete Setup Checklist

### Initial Setup

- [ ] Generate ECPRIME256V1 key pair with OpenSSL
- [ ] Add public key to CloudKit Dashboard → Tokens & Keys
- [ ] Copy and securely store the Key ID
- [ ] Store private key in secure location (not in Git!)
- [ ] Create `schema.ckdb` with proper permissions
- [ ] Import schema using `cktool import-schema`
- [ ] Verify schema with `cktool export-schema`

### Schema Requirements

- [ ] All record types have `GRANT READ, CREATE, WRITE TO "_creator"`
- [ ] All record types have `GRANT READ, CREATE, WRITE TO "_icloud"`
- [ ] Public read access: `GRANT READ TO "_world"` (if needed)
- [ ] No system fields (___*) have QUERYABLE modifiers
- [ ] Boolean fields use INT64 type (0/1)
- [ ] All REFERENCE fields point to valid record types

### Code Implementation

- [ ] Initialize `ServerToServerAuthManager` with keyID and PEM string
- [ ] Create `CloudKitService` with public database
- [ ] Build `RecordOperation` with `.forceReplace` for idempotency
- [ ] Implement batch processing (max 200 operations per request)
- [ ] Handle partial failures in responses
- [ ] Filter error responses (`recordType == "Unknown"`)

### Testing

- [ ] Test authentication with simple query
- [ ] Verify record creation works
- [ ] Check records appear in CloudKit Dashboard
- [ ] Test batch operations with multiple records
- [ ] Verify idempotency (running sync twice doesn't duplicate)
- [ ] Test error handling (invalid data, quota limits)

### Production Readiness

- [ ] Switch to `.production` environment
- [ ] Import schema to production container
- [ ] Rotate keys regularly (create new S2S key every 6-12 months)
- [ ] Monitor CloudKit usage and quotas
- [ ] Set up logging/monitoring for sync operations
- [ ] Document key rotation procedure
- [ ] Add rate limiting to avoid quota exhaustion

---

## Additional Resources

### Apple Documentation

- [CloudKit Web Services Reference](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/)
- [CloudKit Console Guide](https://developer.apple.com/documentation/cloudkit/managing_icloud_containers_with_the_cloudkit_database_app)
- [Server-to-Server Authentication](https://developer.apple.com/documentation/cloudkit/ckoperation)

### MistKit Documentation

- [MistKit GitHub Repository](https://github.com/brightdigit/MistKit)
- [Server-to-Server Auth Example](https://github.com/brightdigit/MistKit/tree/main/Examples/Bushel)

### Tools

- **cktool**: `xcrun cktool --help`
- **OpenSSL**: `man openssl`
- **Swift**: `swift --help`

---

## Troubleshooting Commands

```bash
# Check cktool is available
xcrun cktool --version

# List your CloudKit containers
xcrun cktool list-containers

# Export current schema
xcrun cktool export-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.YourApp \
  --environment development

# Import updated schema
xcrun cktool import-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.YourApp \
  --environment development \
  --file schema.ckdb

# Query records
xcrun cktool query \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.YourApp \
  --environment development \
  --record-type YourRecordType

# Validate private key format
openssl ec -in your-cloudkit.pem -text -noout
```

---

## Summary

CloudKit Server-to-Server authentication requires:

1. **Key pair generation** - ECPRIME256V1 format
2. **CloudKit Dashboard setup** - Register public key, get Key ID
3. **Schema permissions** - Grant to **both** `_creator` and `_icloud`
4. **Swift implementation** - Use MistKit's `ServerToServerAuthManager`
5. **Operation type** - Use `.forceReplace` for idempotency
6. **Error handling** - Parse responses, handle partial failures
7. **Testing** - Verify auth, permissions, and record creation

The most critical requirement discovered through testing:

> **Both `_creator` AND `_icloud` must have `READ, CREATE, WRITE` permissions for S2S authentication to work with the public database.**

This configuration allows your server-side tools to manage CloudKit data programmatically while also enabling public read access for your apps.
