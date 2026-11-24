# CloudKit Server-to-Server Authentication Setup

Configure CloudKit credentials and schema for BushelCloud.

## Overview

BushelCloud uses CloudKit's Server-to-Server authentication, which allows command-line tools and servers to access CloudKit without user credentials. This guide explains how to set up the required authentication keys and CloudKit schema.

## Quick Start

If you just want to get started quickly:

1. Generate an S2S key pair and register it in CloudKit Dashboard
2. Set environment variables for the key ID and private key file
3. Run the automated schema setup script
4. Start syncing data

For detailed instructions, continue reading below.

---

## Part 1: Server-to-Server Authentication

### What is Server-to-Server Authentication?

Server-to-Server (S2S) authentication allows backend services, scripts, and CLI tools to access CloudKit **without requiring a signed-in iCloud user**. This is essential for:

- Automated data syncing from external APIs
- Scheduled batch operations
- Server-side data processing
- Command-line tools that manage CloudKit data

### Step 1: Generate the Key Pair

Open Terminal and generate an ECDSA P-256 key pair using OpenSSL:

```bash
# Generate private key
openssl ecparam -name prime256v1 -genkey -noout -out eckey.pem

# Extract public key
openssl ec -in eckey.pem -pubout -out eckey_pub.pem
```

**Important:** Keep `eckey.pem` (private key) **secure and confidential**. Never commit it to version control.

### Step 2: Register Key in CloudKit Dashboard

1. **Navigate to CloudKit Dashboard**
   - Go to [CloudKit Dashboard](https://icloud.developer.apple.com/)
   - Select your Team
   - Select your Container (or create one if needed)

2. **Navigate to Server-to-Server Keys**
   - In the left sidebar, under "Settings"
   - Click "Server-to-Server Keys"

3. **Create New Server-to-Server Key**
   - Click the "+" button to create a new key
   - **Name:** Give it a descriptive name (e.g., "BushelCloud Demo Key")
   - **Public Key:** Paste the contents of `eckey_pub.pem`

4. **Save and Record Key ID**
   - After saving, CloudKit will display a **Key ID** (long hexadecimal string)
   - **Copy this Key ID** - you'll need it for authentication
   - Example: `3e76ace055d2e3881a4e9c862dd1119ea85717bd743c1c8c15d95b2280cd93ab`

### Step 3: Secure Key Storage

Store your private key securely:

```bash
# Create secure directory
mkdir -p ~/.cloudkit
chmod 700 ~/.cloudkit

# Move private key to secure location
mv eckey.pem ~/.cloudkit/bushel-private-key.pem
chmod 600 ~/.cloudkit/bushel-private-key.pem
```

### Step 4: Configure Environment Variables

Set the following environment variables:

```bash
export CLOUDKIT_KEY_ID="your-key-id-here"
export CLOUDKIT_KEY_FILE="$HOME/.cloudkit/bushel-private-key.pem"
export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Bushel"  # Optional
```

Add these to your shell profile (~/.zshrc or ~/.bashrc) for persistence:

```bash
# Add to ~/.zshrc
echo 'export CLOUDKIT_KEY_ID="your-key-id-here"' >> ~/.zshrc
echo 'export CLOUDKIT_KEY_FILE="$HOME/.cloudkit/bushel-private-key.pem"' >> ~/.zshrc
echo 'export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Bushel"' >> ~/.zshrc
```

### Step 5: Verify Setup

Test your configuration with a status check:

```bash
bushel-cloud status --verbose
```

This should connect to CloudKit and display your container configuration.

---

## Part 2: CloudKit Schema Setup

BushelCloud requires specific record types in your CloudKit public database. You can set up the schema automatically or manually.

### Option 1: Automated Setup (Recommended)

Use the provided script to automatically import the schema:

```bash
# Set required environment variables
export CLOUDKIT_CONTAINER_ID="iCloud.com.yourcompany.Bushel"
export CLOUDKIT_TEAM_ID="YOUR_TEAM_ID"
export CLOUDKIT_ENVIRONMENT="development"  # or "production"

# Run the setup script
./Scripts/setup-cloudkit-schema.sh
```

**Prerequisites:**
- Xcode Command Line Tools installed
- CloudKit Management Token (the script will guide you through obtaining one)
- Your Team ID (10-character identifier from Apple Developer account)

### Option 2: Manual Schema Creation

If you prefer manual setup, follow these steps:

#### Get a Management Token

Management tokens allow `cktool` to modify your CloudKit schema:

1. Open [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container
3. Click your profile icon (top right)
4. Select "API Access" → "CloudKit Web Services"
5. Click "Create Management Token"
6. Give it a name: "BushelCloud Schema Management"
7. **Copy the token** (you won't see it again!)
8. Save it using `cktool`:

```bash
xcrun cktool save-token
# Paste token when prompted
```

#### Import the Schema

```bash
xcrun cktool import-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.Bushel \
  --environment development \
  --file schema.ckdb
```

#### Verify Schema Import

```bash
xcrun cktool export-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.yourcompany.Bushel \
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

## Required Record Types

BushelCloud requires these record types in your CloudKit public database:

### RestoreImage

macOS restore images for virtualization:

| Field | Type | Description |
|-------|------|-------------|
| `version` | STRING | macOS version (e.g., "15.0") |
| `buildNumber` | STRING | Build number (e.g., "24A335") - unique key |
| `releaseDate` | TIMESTAMP | Release date |
| `downloadURL` | STRING | Download URL for IPSW file |
| `fileSize` | INT64 | File size in bytes |
| `sha256Hash` | STRING | SHA-256 checksum |
| `sha1Hash` | STRING | SHA-1 checksum |
| `isSigned` | INT64 | Signing status (0=no, 1=yes) |
| `isPrerelease` | INT64 | Prerelease status (0=no, 1=yes) |
| `source` | STRING | Data source (e.g., "ipsw.me") |
| `notes` | STRING | Optional metadata |
| `sourceUpdatedAt` | TIMESTAMP | Last update from source |

### XcodeVersion

Xcode releases and build numbers:

| Field | Type | Description |
|-------|------|-------------|
| `version` | STRING | Xcode version (e.g., "16.0") |
| `buildNumber` | STRING | Build number (e.g., "16A242") - unique key |
| `releaseDate` | TIMESTAMP | Release date |
| `downloadURL` | STRING | Download URL (optional) |
| `isPrerelease` | INT64 | Prerelease status (0=no, 1=yes) |
| `source` | STRING | Data source |
| `minimumMacOS` | REFERENCE | Reference to RestoreImage record |
| `swiftVersion` | REFERENCE | Reference to SwiftVersion record |
| `notes` | STRING | Optional metadata |

### SwiftVersion

Swift compiler versions:

| Field | Type | Description |
|-------|------|-------------|
| `version` | STRING | Swift version (e.g., "6.0.2") - unique key |
| `releaseDate` | TIMESTAMP | Release date |
| `downloadURL` | STRING | Download URL (optional) |
| `source` | STRING | Data source |
| `notes` | STRING | Optional metadata |

### DataSourceMetadata

Fetch metadata and throttling information:

| Field | Type | Description |
|-------|------|-------------|
| `sourceName` | STRING | Data source name |
| `recordTypeName` | STRING | Record type being tracked |
| `lastFetchedAt` | TIMESTAMP | Last fetch time |
| `sourceUpdatedAt` | TIMESTAMP | Source last updated |
| `recordCount` | INT64 | Number of records fetched |
| `fetchDurationSeconds` | INT64 | Fetch duration |
| `lastError` | STRING | Last error message (optional) |

---

## Critical Schema Permissions

**Important:** For Server-to-Server authentication to work, your schema must grant permissions to **both** `_creator` and `_icloud` roles:

```text
GRANT READ, CREATE, WRITE TO "_creator",
GRANT READ, CREATE, WRITE TO "_icloud",
GRANT READ TO "_world"
```

**Why both are required:**
- `_creator` - S2S keys authenticate as the developer/creator
- `_icloud` - Required for public database operations
- `_world` - Allows public read access (optional, but recommended for shared data)

**Common mistake:** Only granting to one role results in `ACCESS_DENIED` errors.

---

## Troubleshooting

### "Authentication failed" (HTTP 401)

**Cause:** Invalid or revoked Key ID

**Solution:**
1. Generate a new S2S key in CloudKit Dashboard
2. Update `CLOUDKIT_KEY_ID` environment variable
3. Verify private key file is correct

### "ACCESS_DENIED - CREATE operation not permitted"

**Cause:** Schema permissions don't grant CREATE to both `_creator` and `_icloud`

**Solution:**
1. Export current schema: `xcrun cktool export-schema ...`
2. Verify permissions show both `_creator` and `_icloud`
3. If missing, update schema file and re-import

### "Private key file not found"

**Cause:** File doesn't exist at specified path

**Solution:**
- Use absolute path: `$HOME/.cloudkit/bushel-private-key.pem`
- Verify file exists: `ls -la $CLOUDKIT_KEY_FILE`
- Check file permissions: `chmod 600 $CLOUDKIT_KEY_FILE`

### "Schema validation failed: Was expecting DEFINE"

**Cause:** Schema file missing `DEFINE SCHEMA` header

**Solution:**
Add this line at the top of your `schema.ckdb` file:
```text
DEFINE SCHEMA
```

### "Container not found"

**Cause:** Container ID doesn't match CloudKit Dashboard

**Solution:**
1. Verify container ID in CloudKit Dashboard
2. Check `CLOUDKIT_CONTAINER_ID` environment variable
3. Ensure Team ID is correct

---

## Security Notes

**Never commit** your private key (.pem file) to version control:

```gitignore
# .gitignore
*.pem
*.p8
.env
.cloudkit/
```

**Best practices:**
- Store credentials in `~/.cloudkit/` with restrictive permissions (600)
- Use environment variables, not hardcoded values
- Generate separate keys for development and production
- Rotate keys periodically (every 6-12 months)

---

## Next Steps

After setting up authentication and schema:

- <doc:SyncingData> - Start syncing data to CloudKit
- <doc:DataFlow> - Understand how data flows through BushelCloud
- <doc:ExportingData> - Export CloudKit data to JSON

## Additional Resources

- [CloudKit Web Services Documentation](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/)
- [Server-to-Server Keys Guide](https://developer.apple.com/documentation/cloudkit)
- [cktool Reference](https://keith.github.io/xcode-man-pages/cktool.1.html)
- [CloudKit Dashboard](https://icloud.developer.apple.com/)
