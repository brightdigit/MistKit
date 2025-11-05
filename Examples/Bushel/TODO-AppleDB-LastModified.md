# TODO: AppleDB Integration and Last-Modified Headers

## Overview

This document outlines the planned improvements to the Bushel data source system:
1. Replace TheAppleWiki with AppleDB for better data quality
2. Use HTTP Last-Modified headers for `sourceUpdatedAt` tracking across all web-based sources
3. Ensure MrMacintosh continues using HTML page update date

## Current State (As-Is)

### Working Implementations
- **MESUFetcher**: Uses `Date()` for `sourceUpdatedAt` (MESU is real-time, always authoritative)
- **MrMacintoshFetcher**: Extracts "UPDATED: MM/DD/YY" from HTML `<strong>` tag
- **IPSWFetcher**: Uses `firmware.uploaddate` from API (when Apple uploaded file)
- **TheAppleWikiFetcher**: Sets `sourceUpdatedAt: nil` (API doesn't provide metadata)

### Merge Logic Priority (Already Implemented)
1. MESU is always authoritative (overrides all other sources regardless of age)
2. For non-MESU sources, prefer most recently updated (`sourceUpdatedAt` comparison)
3. If both have same update time or both nil, prefer `false` when they disagree

## Planned Changes

### 1. IPSWFetcher - Use Last-Modified Header

**Current Code** (IPSWFetcher.swift lines 8-54):
```swift
func fetch() async throws -> [RestoreImageRecord] {
    let client = IPSWDownloads(transport: URLSessionTransport())
    let device = try await client.device(withIdentifier: "VirtualMac2,1", type: .ipsw)

    return device.firmwares.map { firmware in
        RestoreImageRecord(
            // ... fields
            sourceUpdatedAt: firmware.uploaddate // WRONG: when Apple uploaded, not when ipsw.me updated
        )
    }
}
```

**Planned Implementation**:
```swift
func fetch() async throws -> [RestoreImageRecord] {
    // Fetch Last-Modified header to know when ipsw.me database was updated
    let url = URL(string: "https://api.ipsw.me/v4/device/VirtualMac2,1?type=ipsw")!
    var request = URLRequest(url: url)
    request.httpMethod = "HEAD"

    let lastModified: Date?
    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        lastModified = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Last-Modified").flatMap { dateString in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.date(from: dateString)
        }
    } catch {
        lastModified = nil
    }

    // Now fetch actual data
    let client = IPSWDownloads(transport: URLSessionTransport())
    let device = try await client.device(withIdentifier: "VirtualMac2,1", type: .ipsw)

    return device.firmwares.map { firmware in
        RestoreImageRecord(
            // ... other fields
            sourceUpdatedAt: lastModified  // Use header, not firmware.uploaddate
        )
    }
}
```

**Why This Matters**:
- `firmware.uploaddate` = when Apple uploaded the file to their CDN (before public release)
- `Last-Modified` header = when ipsw.me last updated their database
- For merge logic, we care about when ipsw.me updated their signing status, not when Apple uploaded

### 2. MESUFetcher - Add Last-Modified Header (Optional)

**Current Code** (MESUFetcher.swift line 64):
```swift
sourceUpdatedAt: Date() // Always current time since MESU is real-time
```

**Planned Implementation** (optional, for consistency):
```swift
func fetch() async throws -> RestoreImageRecord? {
    let urlString = "https://mesu.apple.com/assets/macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml"
    guard let url = URL(string: urlString) else {
        throw FetchError.invalidURL
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    // Extract Last-Modified header
    let lastModified = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Last-Modified").flatMap { dateString in
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }

    // ... parse plist ...

    return RestoreImageRecord(
        // ... fields
        sourceUpdatedAt: lastModified ?? Date() // Prefer header, fallback to Date()
    )
}
```

**Note**: This doesn't affect merge logic since MESU always wins regardless of `sourceUpdatedAt`. Including it is for completeness only.

### 3. MrMacintoshFetcher - No Changes Needed

**Current Implementation** (MrMacintoshFetcher.swift lines 22-31):
```swift
var pageUpdatedAt: Date?
if let strongElements = try? doc.select("strong"),
   let updateElement = strongElements.first(where: { element in
       (try? element.text().uppercased().starts(with: "UPDATED:")) == true
   }),
   let updateText = try? updateElement.text(),
   let dateString = updateText.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) {
    pageUpdatedAt = parseDateMMDDYY(from: String(dateString))
}
```

**Status**: ✅ Already correct - extracts "UPDATED: 11/03/25" from HTML and parses it properly.

### 4. Replace TheAppleWiki with AppleDB

#### 4.1 Remove TheAppleWikiFetcher

**Files to Delete**:
- `Sources/BushelImages/DataSources/TheAppleWiki/TheAppleWikiFetcher.swift`
- `Sources/BushelImages/DataSources/TheAppleWiki/IPSWParser.swift` (if not used elsewhere)
- `Sources/BushelImages/DataSources/TheAppleWiki/` (entire directory)

**Package.swift Changes**:
Remove TheAppleWiki/IPSWParser dependencies if present.

#### 4.2 Create AppleDBFetcher

**New File**: `Sources/BushelImages/DataSources/AppleDBFetcher.swift`

**AppleDB API Reference**: https://github.com/littlebyteorg/appledb/blob/main/API.md

**Key API Details**:
- Base URL: `https://api.appledb.dev`
- Endpoint: `/ios/macOS/main.json.gz` (compressed, ~3MB vs 10MB uncompressed)
- Response: JSON array of macOS builds with comprehensive metadata
- Signing Status: `signed` field can be:
  - `true` - universally signed for all devices
  - `false` or missing - not signed
  - Array of strings - signed for specific devices only (e.g., `["VirtualMac2,1"]`)

**Implementation Structure**:

```swift
import Foundation

/// Fetcher for macOS restore images using AppleDB
struct AppleDBFetcher: Sendable {
    // MARK: - Internal Models

    private struct AppleDBBuild: Codable {
        let version: String
        let build: String
        let signed: SignedStatus?
        let releaseDate: String?
        let ipsw: IPSWInfo?

        struct IPSWInfo: Codable {
            let url: String?
            let size: Int64?
            let sha1sum: String?
            let sha256sum: String?
        }

        enum SignedStatus: Codable {
            case all(Bool)
            case devices([String])

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let bool = try? container.decode(Bool.self) {
                    self = .all(bool)
                } else if let devices = try? container.decode([String].self) {
                    self = .devices(devices)
                } else {
                    self = .all(false)
                }
            }
        }
    }

    // MARK: - Public API

    /// Fetch macOS restore images from AppleDB
    func fetch() async throws -> [RestoreImageRecord] {
        let urlString = "https://api.appledb.dev/ios/macOS/main.json.gz"
        guard let url = URL(string: urlString) else {
            throw FetchError.invalidURL
        }

        // Fetch with Last-Modified header
        let (data, response) = try await URLSession.shared.data(from: url)

        let lastModified = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Last-Modified").flatMap { dateString in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.date(from: dateString)
        }

        // Decompress gzip data
        let decompressed = try (data as NSData).decompressed(using: .zlib) as Data

        // Parse JSON
        let decoder = JSONDecoder()
        let builds = try decoder.decode([AppleDBBuild].self, from: decompressed)

        // Map to RestoreImageRecord, filtering for VirtualMac2,1 compatibility
        return builds.compactMap { build -> RestoreImageRecord? in
            // Check if signed for VirtualMac2,1
            let isSigned: Bool?
            switch build.signed {
            case .all(let allSigned):
                isSigned = allSigned
            case .devices(let deviceList):
                isSigned = deviceList.contains("VirtualMac2,1")
            case nil:
                isSigned = nil
            }

            guard let ipswInfo = build.ipsw,
                  let downloadURL = ipswInfo.url else {
                return nil
            }

            // Parse release date
            let releaseDate: Date
            if let releaseDateStr = build.releaseDate,
               let date = ISO8601DateFormatter().date(from: releaseDateStr) {
                releaseDate = date
            } else {
                releaseDate = Date()
            }

            // Detect prerelease from build number
            let isPrerelease = build.build.contains("beta") ||
                              build.build.contains("RC") ||
                              build.build.hasSuffix("a") ||
                              build.build.hasSuffix("b")

            return RestoreImageRecord(
                version: build.version,
                buildNumber: build.build,
                releaseDate: releaseDate,
                downloadURL: downloadURL,
                fileSize: ipswInfo.size ?? 0,
                sha256Hash: ipswInfo.sha256sum ?? "",
                sha1Hash: ipswInfo.sha1sum ?? "",
                isSigned: isSigned,
                isPrerelease: isPrerelease,
                source: "appledb.dev",
                notes: nil,
                sourceUpdatedAt: lastModified
            )
        }
    }

    // MARK: - Error Types

    enum FetchError: Error {
        case invalidURL
    }
}
```

**Note**: You'll need to add gzip decompression support. Foundation provides this via `NSData.decompressed(using:)`.

#### 4.3 Update DataSourcePipeline

**File**: `Sources/BushelImages/DataSources/DataSourcePipeline.swift`

**Changes**:

```swift
// Update Options struct (lines 7-13)
struct Options: Sendable {
    var includeRestoreImages: Bool = true
    var includeXcodeVersions: Bool = true
    var includeSwiftVersions: Bool = true
    var includeBetaReleases: Bool = true
    var includeAppleDB: Bool = true  // Changed from includeTheAppleWiki
}

// Update fetchRestoreImages method (lines 101-111)
// Replace TheAppleWiki section with AppleDB:
if options.includeAppleDB {
    do {
        let appleDBImages = try await AppleDBFetcher().fetch()
        allImages.append(contentsOf: appleDBImages)
        print("   ✓ AppleDB: \(appleDBImages.count) images")
    } catch {
        print("   ⚠️  AppleDB failed: \(error)")
        throw error
    }
}
```

## Benefits of These Changes

### AppleDB vs TheAppleWiki
- **Better Signing Status**: Per-device signing information (can check specifically for VirtualMac2,1)
- **More Complete Data**: SHA-256 hashes, file sizes, comprehensive metadata
- **Active Maintenance**: AppleDB is actively maintained by the community
- **Last-Modified Support**: API returns standard HTTP headers for freshness tracking
- **Compressed Format**: Smaller payload with .gz format

### Last-Modified Headers
- **Accurate Freshness**: Know when data source last updated, not when files were created
- **Better Merge Logic**: More intelligent deduplication based on actual data update times
- **Consistent Approach**: All web-based sources use same mechanism (except MrMacintosh HTML)

## Testing After Implementation

1. **Verify AppleDB Integration**:
   ```bash
   # Should show AppleDB in the output
   swift run bushel-images sync
   # Look for: "✓ AppleDB: X images"
   ```

2. **Check sourceUpdatedAt Values**:
   - All sources should have non-nil `sourceUpdatedAt` (except where API doesn't provide it)
   - Timestamps should be reasonable (not distant past/future)

3. **Verify Merge Logic**:
   - MESU should still win even with older `sourceUpdatedAt`
   - Non-MESU sources should prefer more recent `sourceUpdatedAt`
   - Builds with same timestamp should prefer `false` when disagreeing

4. **Validate Data Quality**:
   - Check that at least one build shows `isSigned: true` (from MESU)
   - Verify AppleDB provides VirtualMac2,1-specific signing status
   - Ensure no data loss compared to TheAppleWiki

## Implementation Checklist

- [ ] Update IPSWFetcher to use Last-Modified header
- [ ] Optionally update MESUFetcher to use Last-Modified header
- [ ] Create AppleDBFetcher.swift with proper JSON parsing
- [ ] Add gzip decompression support if needed
- [ ] Remove TheAppleWikiFetcher.swift and related files
- [ ] Update DataSourcePipeline.swift to use AppleDB
- [ ] Update Package.swift dependencies
- [ ] Test sync command with all changes
- [ ] Verify merge logic works correctly
- [ ] Update documentation/README if needed
- [ ] Commit changes with descriptive message

## Notes

- **No MrMacintosh Changes**: Already correctly extracts "UPDATED: MM/DD/YY" from HTML
- **MESU Always Wins**: Even if AppleDB has newer `sourceUpdatedAt`, MESU's signing status is authoritative
- **Backward Compatibility**: Existing CloudKit data won't be affected, will just be updated with fresher data
- **Error Handling**: All fetchers should handle failures gracefully (already implemented in DataSourcePipeline)
