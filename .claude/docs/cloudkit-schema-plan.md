# CloudKit Schema Plan for Bushel & Demo App

## Overview

Three CloudKit record types for tracking macOS restore images, Xcode releases, and Swift versions with their compatibility relationships. Optimized for Bushel's virtualization use case and demonstrating MistKit's capabilities.

## Record Types

### 1. RestoreImage

**Purpose**: macOS IPSW files for Apple Virtualization framework (VirtualMac restore images)

**Fields**:
- `version` (String, indexed) - macOS version: "14.2.1", "15.0 Beta 3"
- `buildNumber` (String, indexed) - Build identifier: "23C71", "24A5264n"
- `releaseDate` (Date, indexed) - Official release date
- `downloadURL` (String) - Direct IPSW download link
- `fileSize` (Int64) - File size in bytes
- `sha256Hash` (String) - SHA-256 checksum for integrity verification
- `sha1Hash` (String) - SHA-1 hash (from MESU/ipsw.me for compatibility)
- `isSigned` (Boolean, indexed) - Whether Apple still signs this restore image
- `isPrerelease` (Boolean, indexed) - Beta/RC release indicator
- `source` (String) - Data source: "ipsw.me", "mrmacintosh.com", "mesu.apple.com"
- `notes` (String) - Additional metadata or release notes

**Indexes**:
- `version` - For version lookups
- `buildNumber` - Unique identifier queries
- `releaseDate` - Chronological sorting
- `isSigned` - Filter to signed-only images
- `isPrerelease` - Filter beta vs final releases
- Compound: `(isSigned, releaseDate)` - "Latest signed releases"

### 2. XcodeVersion

**Purpose**: Xcode releases with macOS requirements and bundled Swift versions

**Fields**:
- `version` (String, indexed) - Xcode version: "15.1", "15.2 Beta 3"
- `buildNumber` (String) - Build identifier: "15C65"
- `releaseDate` (Date, indexed) - Release date
- `downloadURL` (String) - Optional developer.apple.com download link
- `fileSize` (Int64) - Download size in bytes
- `isPrerelease` (Boolean, indexed) - Beta/RC indicator
- `minimumMacOS` (Reference) - Link to minimum RestoreImage record required
- `includedSwiftVersion` (Reference) - Link to bundled Swift compiler
- `sdkVersions` (String) - JSON of SDKs: `{"macOS": "14.2", "iOS": "17.2", "watchOS": "10.2"}`
- `notes` (String) - Release notes or additional info

**Indexes**:
- `version` - Version lookups
- `releaseDate` - Chronological sorting
- `isPrerelease` - Filter production vs beta

### 3. SwiftVersion

**Purpose**: Swift compiler releases bundled with Xcode

**Fields**:
- `version` (String, indexed) - Swift version: "5.9", "5.10", "6.0"
- `releaseDate` (Date, indexed) - Release date
- `downloadURL` (String) - Optional swift.org toolchain download
- `isPrerelease` (Boolean) - Beta/snapshot indicator
- `notes` (String) - Release notes

**Indexes**:
- `version` - Version lookups
- `releaseDate` - Chronological sorting

## Relationship Model

**Simplified unidirectional references:**

```
RestoreImage "14.2.1"
  - No outbound references

XcodeVersion "15.1"
  ├─ minimumMacOS → RestoreImage "13.5"
  └─ includedSwiftVersion → SwiftVersion "5.9.2"

SwiftVersion "5.9.2"
  - No outbound references
```

**Example Query (Bushel use case):**
```swift
// 1. Get RestoreImage by version
let restoreImage = queryRestoreImage(version: "14.2.1")

// 2. Find compatible Xcode versions
let xcodeVersions = queryXcode(where: minimumMacOS.version <= "14.2.1")

// 3. Display restore image with compatible dev tools
```

## Data Sources

### RestoreImage Records

#### Primary Source - ipsw.me API via IPSWDownloads Swift Package

- **Device**: `VirtualMac2,1` (Apple Virtual Machine restore images)
- **Coverage**: 46 final releases from macOS 12.4 (May 2022) onwards
- **Provides**: version, buildid, sha256sum, sha1sum, md5sum, filesize, url, releasedate, signed status
- **Format**: Clean JSON API
- **Package**: https://github.com/brightdigit/IPSWDownloads

**Example API Response:**
```json
{
  "identifier": "VirtualMac2,1",
  "version": "26.1",
  "buildid": "25B78",
  "sha1sum": "479d6bb78f069062ca016d496fd50804b673e815",
  "md5sum": "e270ede6a1eba02253ac42bcd76dab4b",
  "sha256sum": "e0217b3cd0f2edb9ab3294480bef5af2a0be43e86d84a15fab6bca31d3802ee8",
  "filesize": 18718884780,
  "url": "https://updates.cdn-apple.com/2025FallFCS/fullrestores/089-04148/791B6F00-A30B-4EB0-B2E3-257167F7715B/UniversalMac_26.1_25B78_Restore.ipsw",
  "releasedate": "2025-11-03T21:34:29Z",
  "uploaddate": "2025-10-30T05:50:08Z",
  "signed": true
}
```

#### Secondary Source - Mr. Macintosh Database

- **URL**: https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/
- **Coverage**: Beta/RC releases including Big Sur 11.x through current
- **Provides**: version, build, releasedate, download url, signing status, beta/RC classification
- **Total additional entries**: ~100+ beta/RC versions
- **Format**: HTML scraping required

**Data Available:**
- Version number (e.g., "26.1 Beta 4")
- Build identifier (e.g., "25B5072a")
- Release date (formatted as MM/DD or MM/DD/YY)
- Download URL (Apple CDN links)
- Signing status ("YES" or "N/A")
- Release classification (Final, RC, Beta with numbering)

#### Freshness Detection - Apple MESU XML

- **URL**: https://mesu.apple.com/assets/macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml
- **Coverage**: Single entry - currently signed latest release only
- **Provides**: BuildVersion, ProductVersion, FirmwareURL, FirmwareSHA1
- **Purpose**: Detect new releases immediately, trigger sync if version not in database
- **Update Frequency**: Real-time by Apple

**Example XML Structure:**
```xml
<Assets>
  <Asset>
    <BuildVersion>25B78</BuildVersion>
    <ProductVersion>26.1</ProductVersion>
    <FirmwareURL>https://updates.cdn-apple.com/.../UniversalMac_26.1_25B78_Restore.ipsw</FirmwareURL>
    <FirmwareSHA1>479d6bb78f069062ca016d496fd50804b673e815</FirmwareSHA1>
  </Asset>
</Assets>
```

**Total Coverage**: ~140+ restore images from Big Sur 11.0 (2020) to current

### XcodeVersion Records

#### Primary Source - xcodereleases.com

- **URL**: https://xcodereleases.com
- **Coverage**: Community-maintained comprehensive database
- **Provides**: version, build, release date, minimum macOS, bundled Swift version, SDK versions
- **Includes**: Both release and beta versions
- **Format**: Likely requires scraping or API if available

#### Secondary Source - Apple Developer Release Notes

- **Purpose**: Official documentation for validation
- **Use**: Manual curation for critical metadata

### SwiftVersion Records

#### Primary Source - swiftversion.net

- **URL**: https://swiftversion.net
- **Coverage**: Community-maintained Swift version database
- **Provides**: version, release date, Xcode bundling information
- **Includes**: Comprehensive historical coverage
- **Format**: Likely requires scraping or API if available

#### Secondary Source - swift.org Official Releases

- **URL**: https://swift.org
- **Purpose**: Primary validation source
- **Use**: GitHub releases for version tracking

## Database Configuration

- **Schema Level**: Container (schema applies to both public and private databases)
- **Database**: Public Database (readable by all, writable with authentication)
- **Write Target**: Demo app writes to public database via `database: .public` parameter
- **Zone**: Default Zone (sufficient for this use case)
- **Write Access**: API token authentication for sync tool (MistKit)
- **Read Access**: Public (Bushel queries directly using native CloudKit framework)
- **Permissions**: `GRANT READ TO "_world"` makes records publicly readable
- **Container**: User-configurable (e.g., `iCloud.com.yourcompany.Bushel`)

## Data Import Strategy

### Sync Command Workflow

#### 1. Fetch from ipsw.me (via IPSWDownloads package)

```swift
// Query VirtualMac2,1 device for all firmwares
let device = try await ipswDownloads.device("VirtualMac2,1")
let firmwares = device.firmwares

// Map to RestoreImage records with complete metadata
let restoreImages = firmwares.map { firmware in
    RestoreImageRecord(
        version: firmware.version,
        buildNumber: firmware.buildid,
        releaseDate: firmware.releasedate,
        downloadURL: firmware.url,
        fileSize: firmware.filesize,
        sha256Hash: firmware.sha256sum,
        sha1Hash: firmware.sha1sum,
        isSigned: firmware.signed,
        isPrerelease: false, // ipsw.me only has finals
        source: "ipsw.me"
    )
}
```

#### 2. Fetch from Mr. Macintosh

```swift
// Scrape database for beta/RC versions
let mrMacHTML = try await fetchHTML("https://mrmacintosh.com/...")
let betaReleases = parseMrMacTable(mrMacHTML)

// Filter duplicates (match on version + build)
let uniqueBetas = betaReleases.filter { beta in
    !restoreImages.contains(where: { $0.buildNumber == beta.buildNumber })
}

// Add beta-specific RestoreImage records
restoreImages.append(contentsOf: uniqueBetas.map { beta in
    RestoreImageRecord(
        version: beta.version,
        buildNumber: beta.build,
        releaseDate: beta.releaseDate,
        downloadURL: beta.url,
        isSigned: beta.signed,
        isPrerelease: true, // Beta/RC
        source: "mrmacintosh.com"
    )
})
```

#### 3. Check MESU XML

```swift
// Parse for latest signed release
let mesuXML = try await fetchMESU()
let latestRelease = parseMESUXML(mesuXML)

// If version not in database, add from MESU
if !restoreImages.contains(where: { $0.buildNumber == latestRelease.buildNumber }) {
    restoreImages.append(RestoreImageRecord(
        version: latestRelease.productVersion,
        buildNumber: latestRelease.buildVersion,
        downloadURL: latestRelease.firmwareURL,
        sha1Hash: latestRelease.firmwareSHA1,
        isSigned: true,
        isPrerelease: false,
        source: "mesu.apple.com"
    ))
}

// Update signing status for existing records
// (MESU only lists currently signed version, so others are unsigned)
```

#### 4. Fetch Xcode data (xcodereleases.com)

```swift
// Parse versions and requirements
let xcodeReleases = try await fetchXcodeReleases()

// Create XcodeVersion records with References to RestoreImage
let xcodeRecords = xcodeReleases.map { release in
    XcodeVersionRecord(
        version: release.version,
        buildNumber: release.build,
        releaseDate: release.date,
        isPrerelease: release.isBeta,
        minimumMacOS: referenceToRestoreImage(version: release.minMacOS),
        includedSwiftVersion: referenceToSwiftVersion(version: release.swiftVersion),
        sdkVersions: release.sdks.toJSON()
    )
}
```

#### 5. Fetch Swift data (swiftversion.net)

```swift
// Parse versions and metadata
let swiftReleases = try await fetchSwiftVersions()

// Create SwiftVersion records
let swiftRecords = swiftReleases.map { release in
    SwiftVersionRecord(
        version: release.version,
        releaseDate: release.date,
        isPrerelease: release.isBeta
    )
}

// Link from XcodeVersion records (already done in step 4)
```

#### 6. Upsert to CloudKit

```swift
// Use record IDs based on version+build for idempotency
for image in restoreImages {
    let recordID = CKRecord.ID(recordName: "RestoreImage-\(image.buildNumber)")

    // Update existing records if data changed
    // Create new records for new versions
    try await cloudKit.save(image, withID: recordID)
}

// Same for XcodeVersion and SwiftVersion records
```

### Export Command

Simple JSON dump for inspection/debugging:

```json
{
  "restoreImages": [
    {
      "version": "14.2.1",
      "buildNumber": "23C71",
      "releaseDate": "2024-01-22T00:00:00Z",
      "downloadURL": "https://updates.cdn-apple.com/.../UniversalMac_14.2.1_23C71_Restore.ipsw",
      "fileSize": 17892345678,
      "sha256Hash": "abc123...",
      "isSigned": true,
      "isPrerelease": false,
      "source": "ipsw.me"
    }
  ],
  "xcodeVersions": [...],
  "swiftVersions": [...]
}
```

## Demo CLI Application

### Two Commands

#### 1. `sync` - Import/update all data from sources to CloudKit

```bash
# Full sync - fetch all data from all sources
./demo sync

# Incremental sync - only check for new versions
./demo sync --incremental

# Dry run - preview changes without writing to CloudKit
./demo sync --dry-run

# Sync specific record types only
./demo sync --restore-images-only
./demo sync --xcode-only
./demo sync --swift-only
```

**Implementation:**
- Uses MistKit for all CloudKit operations
- Implements async/await throughout
- Handles rate limiting and batch operations
- Provides progress output
- Logs all changes made

#### 2. `export` - Export CloudKit data to JSON

```bash
# Export all records to stdout
./demo export

# Write to file
./demo export --output data.json

# Export specific record types
./demo export --restore-images-only
./demo export --xcode-only

# Pretty-print JSON
./demo export --pretty

# Filter exports
./demo export --signed-only
./demo export --no-betas
```

**Implementation:**
- Queries CloudKit for all records
- Serializes to JSON
- Supports filtering and formatting options

## Bushel Integration Pattern

Bushel will use **native CloudKit framework** (not MistKit) to query the public database:

### Example Queries

#### 1. Get all signed restore images, sorted by date

```swift
let query = CKQuery(
    recordType: "RestoreImage",
    predicate: NSPredicate(format: "isSigned == true")
)
query.sortDescriptors = [NSSortDescriptor(key: "releaseDate", ascending: false)]

let results = try await publicDatabase.records(matching: query)
```

#### 2. Filter to final releases only (no betas)

```swift
let query = CKQuery(
    recordType: "RestoreImage",
    predicate: NSPredicate(format: "isSigned == true AND isPrerelease == false")
)
```

#### 3. Find compatible Xcode versions for a restore image

```swift
// For a given restore image version, find Xcode versions that can run on it
let query = CKQuery(
    recordType: "XcodeVersion",
    predicate: NSPredicate(format: "minimumMacOS.version <= %@", "14.2.1")
)
```

#### 4. Get Swift version for an Xcode release

```swift
// Fetch Xcode record
let xcodeRecord = try await publicDatabase.record(for: xcodeRecordID)

// Fetch referenced Swift version
let swiftReference = xcodeRecord["includedSwiftVersion"] as! CKRecord.Reference
let swiftRecord = try await publicDatabase.record(for: swiftReference.recordID)
```

### Display Patterns

Bushel can display:
- Restore image metadata: version, build, size, signing status, release date
- Compatible Xcode versions for each restore image
- Swift versions bundled with Xcode
- Filtering options: final vs beta, signed vs unsigned
- Search by version number or build

## Implementation Plan

### Phase 1: Schema Documentation ✓

- [x] Create `cloudkit-schema-plan.md` with complete schema definition
- [x] Document all fields, indexes, relationships
- [x] Include query patterns and examples

### Phase 2: Swift Model Types

- [ ] Define Codable structs matching CloudKit schema
  - `RestoreImageRecord`
  - `XcodeVersionRecord`
  - `SwiftVersionRecord`
- [ ] Create CloudKit field mapping helpers
- [ ] Implement Reference type handling for relationships

### Phase 3: Data Fetchers

- [ ] Integrate IPSWDownloads package for ipsw.me
- [ ] Implement Mr. Macintosh HTML scraper
- [ ] Implement MESU XML parser
- [ ] Implement xcodereleases.com parser (research API/scraping approach)
- [ ] Implement swiftversion.net parser (research API/scraping approach)

### Phase 4: Demo CLI with MistKit

- [ ] Setup Swift Package with MistKit dependency
- [ ] Setup CloudKit container and configure authentication
- [ ] Implement `sync` command with data pipeline
- [ ] Implement `export` command for inspection
- [ ] Add Swift ArgumentParser for CLI interface
- [ ] Add logging and error handling

### Phase 5: Blog Post Integration

- [ ] Demonstrate MistKit usage patterns in blog post
- [ ] Show CloudKit querying with async/await
- [ ] Highlight practical real-world use case
- [ ] Document lessons learned
- [ ] Include code examples from demo app

## Reference Documentation

### MobileAsset Framework

Key insights from TheAppleWiki MobileAsset documentation:

- MESU (mesu.apple.com) serves **static XML plists** containing asset metadata
- MESU is **not a MobileAsset** - it's a special firmware manifest system
- The macOS IPSW XML is one of three special plists:
  - `macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml`
  - `bridgeos/com_apple_bridgeOSIPSW/com_apple_bridgeOSIPSW.xml`
  - `visionos/com_apple_visionOSIPSW/com_apple_visionOSIPSW.xml`
- These contain URLs for **.ipsw files for the latest version** only
- MESU is intentionally limited to current signed releases

### Firmware Wiki

Key insights from TheAppleWiki Firmware documentation:

- Main firmware manifest for iOS/iPod/Apple TV/HomePod mini: https://s.mzstatic.com/version
- Separate manifests for macOS, bridgeOS, visionOS (listed above)
- MESU serves only the **latest signed version**, updated in real-time by Apple
- Historical versions and beta releases require community databases like ipsw.me

### ipsw.me API

- **Devices endpoint**: https://api.ipsw.me/v4/devices
- **Device firmware endpoint**: https://api.ipsw.me/v4/device/{identifier}
- **VirtualMac identifier**: `VirtualMac2,1` for Apple Virtualization framework
- Comprehensive coverage: 46 final releases from macOS 12.4 onwards
- Complete metadata: SHA-256, SHA-1, MD5, file sizes, release dates, signing status

## Next Steps

1. Save MobileAsset and Firmware wiki documentation for future reference
2. Update Task 5 subtasks in Task Master with refined implementation plan
3. Begin Swift model type definitions
4. Research xcodereleases.com and swiftversion.net data access methods
5. Setup CloudKit container configuration
6. Begin demo app scaffolding with MistKit integration

## Notes

- This schema is designed for **public database** read access by Bushel
- Demo app uses **MistKit** to populate and maintain CloudKit data
- Bushel uses **native CloudKit framework** to query the data
- Blog post will showcase both approaches as a complete ecosystem
