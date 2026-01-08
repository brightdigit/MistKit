# Xcode Scheme Setup for Bushel Demo

This guide explains how to set up the Xcode scheme to run and debug the `bushel-images` CLI tool.

## Opening the Package in Xcode

1. Open Xcode
2. Go to **File > Open...**
3. Navigate to `/Users/leo/Documents/Projects/MistKit/Examples/Bushel/`
4. Select `Package.swift` and click **Open**

Alternatively, from Terminal:
```bash
cd /Users/leo/Documents/Projects/MistKit/Examples/Bushel
open Package.swift
```

## Creating/Editing the Scheme

### 1. Open Scheme Editor

- Click the scheme selector in the toolbar (next to the Run/Stop buttons)
- Select **bushel-images** if it exists, or create a new scheme
- Click **Edit Scheme...** (or press `Cmd+Shift+,`)

### 2. Configure Run Settings

In the Scheme Editor, select **Run** in the left sidebar.

#### Info Tab
- **Executable**: Select `bushel-images`
- **Build Configuration**: Debug
- **Debugger**: LLDB

#### Arguments Tab

**Environment Variables**:
Add the following environment variables:

| Name | Value | Description |
|------|-------|-------------|
| `CLOUDKIT_CONTAINER_ID` | `iCloud.com.yourcompany.Bushel` | Your CloudKit container identifier |
| `CLOUDKIT_API_TOKEN` | `your-api-token-here` | Your CloudKit API token |

**Arguments Passed On Launch**:
Add command-line arguments for testing different commands:

For sync command:
```
sync --container-id $(CLOUDKIT_CONTAINER_ID) --api-token $(CLOUDKIT_API_TOKEN)
```

For export command:
```
export --container-id $(CLOUDKIT_CONTAINER_ID) --api-token $(CLOUDKIT_API_TOKEN) --output ./export.json
```

For help:
```
--help
```

#### Options Tab
- **Working Directory**:
  - Select **Use custom working directory**
  - Set to: `/Users/leo/Documents/Projects/MistKit/Examples/Bushel`

### 3. Configure Build Settings (Optional)

In the Scheme Editor, select **Build** in the left sidebar:

- Ensure `bushel-images` target is checked for **Run**
- Optionally check **Test** if you add tests later
- Ensure `MistKit` is listed as a dependency (should be automatic)

## Getting CloudKit Credentials

### CloudKit Container Identifier

1. Open [CloudKit Dashboard](https://icloud.developer.apple.com/)
2. Sign in with your Apple Developer account
3. Select or create a container
4. The identifier format is: `iCloud.com.yourcompany.YourApp`

### CloudKit API Token

#### Option 1: API Token (Recommended for Development)

1. In CloudKit Dashboard, select your container
2. Go to **API Access** tab
3. Click **API Tokens**
4. Click **Add API Token**
5. Give it a name (e.g., "Bushel Development")
6. Copy the token value

#### Option 2: Server-to-Server Authentication (Production)

For production use, you'll need:
- Key ID
- Private key file (.pem)
- Server-to-Server key authentication

See MistKit documentation for server-to-server setup.

## Environment Variables File (Alternative)

Instead of adding environment variables to the scheme, you can create a `.env` file:

```bash
# Create .env file in Bushel directory
cat > .env << 'EOF'
CLOUDKIT_CONTAINER_ID=iCloud.com.yourcompany.Bushel
CLOUDKIT_API_TOKEN=your-api-token-here
EOF

# Don't commit this file!
echo ".env" >> .gitignore
```

Then modify the scheme to load environment from file (requires additional code).

## Running the CLI

### From Xcode

1. Select the `bushel-images` scheme
2. Press `Cmd+R` to run
3. View output in the Console pane (bottom of Xcode)

### From Terminal

After building in Xcode, you can also run from Terminal:

```bash
# Navigate to build products
cd /Users/leo/Documents/Projects/MistKit/Examples/Bushel/.build/arm64-apple-macosx/debug

# Run with arguments
./bushel-images sync \
  --container-id "iCloud.com.yourcompany.Bushel" \
  --api-token "your-api-token-here"

# Or set environment variables
export CLOUDKIT_CONTAINER_ID="iCloud.com.yourcompany.Bushel"
export CLOUDKIT_API_TOKEN="your-api-token-here"
./bushel-images sync --container-id $CLOUDKIT_CONTAINER_ID --api-token $CLOUDKIT_API_TOKEN
```

## Debugging Tips

### Breakpoints

1. Open relevant source files (e.g., `BushelCloudKitService.swift`)
2. Click in the gutter to set breakpoints
3. Run with `Cmd+R`
4. Execution will pause at breakpoints

### Console Output

The CLI uses `print()` statements to show progress:
- "Fetching X from Y..."
- "Syncing N record(s) in M batch(es)..."
- "✅ Synced N records"

### Common Issues

**Issue**: "Cannot find container"
- **Solution**: Verify container ID is correct in CloudKit Dashboard

**Issue**: "Authentication failed"
- **Solution**: Check API token is valid and has correct permissions

**Issue**: "Cannot find type 'RecordOperation'"
- **Solution**: Clean build folder (`Cmd+Shift+K`) and rebuild

**Issue**: Module 'MistKit' not found
- **Solution**: Ensure MistKit is built first (should be automatic via dependencies)

## Testing Without Real CloudKit

To test the data fetching without CloudKit:

1. Comment out the CloudKit sync calls in `SyncCommand.swift`
2. Add export of fetched data:
   ```swift
   // In SyncCommand.run()
   let (restoreImages, xcodeVersions, swiftVersions) = try await engine.fetchAllData()
   print("Fetched:")
   print("  - \(restoreImages.count) restore images")
   print("  - \(xcodeVersions.count) Xcode versions")
   print("  - \(swiftVersions.count) Swift versions")
   ```

## CloudKit Schema Setup

Before running sync, ensure your CloudKit schema has the required record types:

### RestoreImage Record Type
- `version` (String)
- `buildNumber` (String)
- `releaseDate` (Date/Time)
- `downloadURL` (String)
- `fileSize` (Int64)
- `sha256Hash` (String)
- `sha1Hash` (String)
- `isSigned` (Boolean)
- `isPrerelease` (Boolean)
- `source` (String)
- `notes` (String, optional)

### XcodeVersion Record Type
- `version` (String)
- `buildNumber` (String)
- `releaseDate` (Date/Time)
- `isPrerelease` (Boolean)
- `downloadURL` (String, optional)
- `fileSize` (Int64, optional)
- `minimumMacOS` (Reference to RestoreImage, optional)
- `includedSwiftVersion` (Reference to SwiftVersion, optional)
- `sdkVersions` (String, optional)
- `notes` (String, optional)

### SwiftVersion Record Type
- `version` (String)
- `releaseDate` (Date/Time)
- `isPrerelease` (Boolean)
- `downloadURL` (String, optional)
- `notes` (String, optional)

You can create these schemas in CloudKit Dashboard > Schema section.

## Next Steps

1. Set up CloudKit container and get credentials
2. Configure the Xcode scheme with your credentials
3. Run the CLI to test data fetching (comment out CloudKit sync first)
4. Create CloudKit schema (record types)
5. Run full sync to populate CloudKit

## Troubleshooting

### Getting More Verbose Output

Add `--verbose` flag support to commands if needed, or temporarily add debug prints:

```swift
// In BushelCloudKitService.swift
print("DEBUG: Syncing batch with operations: \(batch.map { $0.recordName })")
```

### Viewing Network Requests

Add logging middleware to MistKit (already configured) by setting environment variable:
```
MISTKIT_DEBUG_LOGGING=1
```

This will print all HTTP requests/responses to console.
