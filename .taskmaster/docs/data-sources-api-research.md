# Data Sources & API Research

This document contains detailed research on all external data sources and MistKit API patterns needed for implementing the Bushel CloudKit demo tool.

## Table of Contents

1. [xcodereleases.com API](#xcodereleases-com-api)
2. [swiftversion.net Scraping](#swiftversion-net-scraping)
3. [MistKit API Patterns](#mistkit-api-patterns)

---

## xcodereleases.com API

### API Endpoint

**URL**: https://xcodereleases.com/data.json
**Format**: JSON
**Authentication**: None required
**Method**: GET

### Data Structure

```json
{
  "_dateOrder": 20251103,
  "_swiftOrder": 6002001,
  "_versionOrder": 26001000999,
  "checksums": {
    "sha1": "24df34c049bf695f2ef7262815828c52ed5479fe"
  },
  "compilers": {
    "clang": [
      {
        "build": "1700.4.4.1",
        "number": "17.0.0",
        "release": {
          "release": true
        }
      }
    ],
    "swift": [
      {
        "build": "6.2.1.4.8",
        "number": "6.2.1",
        "release": {
          "release": true
        }
      }
    ]
  },
  "date": {
    "day": 3,
    "month": 11,
    "year": 2025
  },
  "links": {
    "download": {
      "architectures": ["arm64", "x86_64"],
      "url": "https://download.developer.apple.com/Developer_Tools/Xcode_26.1/XcodeXIP_26.1_Universal.xip"
    },
    "notes": {
      "url": "https://developer.apple.com/documentation/xcode-release-notes/xcode-26_1-release-notes"
    }
  },
  "name": "Xcode",
  "requires": "15.6",
  "sdks": {
    "iOS": [{"build": "23B77", "number": "26.1", "release": {"release": true}}],
    "macOS": [{"build": "25B74", "number": "26.1", "release": {"release": true}}],
    "tvOS": [{"build": "23J576", "number": "26.1", "release": {"release": true}}],
    "visionOS": [{"build": "23N45", "number": "26.1", "release": {"release": true}}],
    "watchOS": [{"build": "23S34", "number": "26.1", "release": {"release": true}}]
  },
  "version": {
    "build": "17B55",
    "number": "26.1",
    "release": {
      "release": true
    }
  }
}
```

### Key Fields

| Field | Type | Description | Mapping |
|-------|------|-------------|---------|
| `version.number` | String | Xcode version | → `XcodeVersion.version` |
| `version.build` | String | Build identifier | → `XcodeVersion.buildNumber` |
| `version.release.release` | Boolean | Is final release | → `!XcodeVersion.isPrerelease` |
| `date` | Object | Release date | → `XcodeVersion.releaseDate` |
| `requires` | String | Minimum macOS version | → `XcodeVersion.minimumMacOS` (Reference) |
| `compilers.swift[0].number` | String | Swift version | → `XcodeVersion.includedSwiftVersion` (Reference) |
| `sdks` | Object | SDK versions | → `XcodeVersion.sdkVersions` (JSON) |
| `links.download.url` | String | Download URL | → `XcodeVersion.downloadURL` |
| `checksums.sha1` | String | SHA-1 checksum | (Optional field) |

### Swift Parsing Code

```swift
import Foundation

struct XcodeRelease: Codable {
    let _dateOrder: Int
    let _swiftOrder: Int
    let _versionOrder: Int
    let checksums: Checksums?
    let compilers: Compilers
    let date: ReleaseDate
    let links: Links
    let name: String
    let requires: String
    let sdks: SDKs
    let version: Version

    struct Checksums: Codable {
        let sha1: String
    }

    struct Compilers: Codable {
        let clang: [Compiler]
        let swift: [Compiler]
    }

    struct Compiler: Codable {
        let build: String
        let number: String
        let release: Release
    }

    struct Release: Codable {
        let release: Bool?
        let beta: Int?
        let rc: Int?
    }

    struct ReleaseDate: Codable {
        let day: Int
        let month: Int
        let year: Int

        var toDate: Date {
            let components = DateComponents(year: year, month: month, day: day)
            return Calendar.current.date(from: components)!
        }
    }

    struct Links: Codable {
        let download: Download
        let notes: Notes

        struct Download: Codable {
            let architectures: [String]
            let url: String
        }

        struct Notes: Codable {
            let url: String
        }
    }

    struct SDKs: Codable {
        let iOS: [SDK]
        let macOS: [SDK]
        let tvOS: [SDK]
        let visionOS: [SDK]
        let watchOS: [SDK]
    }

    struct SDK: Codable {
        let build: String
        let number: String
        let release: Release
    }

    struct Version: Codable {
        let build: String
        let number: String
        let release: Release
    }

    var isPrerelease: Bool {
        version.release.beta != nil || version.release.rc != nil
    }

    var swiftVersion: String {
        compilers.swift.first?.number ?? "Unknown"
    }

    var sdkVersionsJSON: String {
        let dict: [String: String] = [
            "macOS": sdks.macOS.first?.number ?? "",
            "iOS": sdks.iOS.first?.number ?? "",
            "watchOS": sdks.watchOS.first?.number ?? "",
            "tvOS": sdks.tvOS.first?.number ?? "",
            "visionOS": sdks.visionOS.first?.number ?? ""
        ]
        let data = try! JSONEncoder().encode(dict)
        return String(data: data, encoding: .utf8)!
    }
}

// Usage
func fetchXcodeReleases() async throws -> [XcodeRelease] {
    let url = URL(string: "https://xcodereleases.com/data.json")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let releases = try JSONDecoder().decode([XcodeRelease].self, from: data)
    return releases
}
```

---

## swiftversion.net Scraping

### Website URL

**URL**: https://swiftversion.net
**Format**: HTML Table
**Authentication**: None required
**Method**: GET + HTML Parsing

### HTML Structure

```html
<table>
    <thead>
        <tr>
            <th>Date</th>
            <th>Swift</th>
            <th>Xcode</th>
        </tr>
    </thead>
    <tbody>
        <tr class="table-entry is-visible">
            <td>15 Sep 25</td>
            <td><a href="https://www.swift.org/swift-evolution/#?version=6.2">6.2</a></td>
            <td>26</td>
        </tr>
        <tr class="table-entry is-visible">
            <td>31 Mar 25</td>
            <td><a href="https://www.swift.org/swift-evolution/#?version=6.1">6.1</a></td>
            <td>16.3</td>
        </tr>
    </tbody>
</table>
```

### Data Format

| Date | Swift | Xcode |
|------|-------|-------|
| 15 Sep 25 | 6.2 | 26 |
| 31 Mar 25 | 6.1 | 16.3 |
| 16 Sep 24 | 6.0 | 16.0 |

**Date Format**: `DD Mon YY` (e.g., "15 Sep 25")
**Swift Version**: Semantic version (e.g., "6.2")
**Xcode Version**: Major version only (e.g., "26")

### Key Fields

| Field | Type | Description | Mapping |
|-------|------|-------------|---------|
| Date | String | Release date | → `SwiftVersion.releaseDate` (parse date) |
| Swift | String | Swift version | → `SwiftVersion.version` |
| Xcode | String | Xcode major version | (Used to link with XcodeVersion) |

### Swift Parsing Code

```swift
import Foundation
import SwiftSoup  // Add dependency: https://github.com/scinfu/SwiftSoup

struct SwiftVersionEntry {
    let date: Date
    let swiftVersion: String
    let xcodeVersion: String
}

func fetchSwiftVersions() async throws -> [SwiftVersionEntry] {
    let url = URL(string: "https://swiftversion.net")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let html = String(data: data, encoding: .utf8)!

    let doc = try SwiftSoup.parse(html)
    let rows = try doc.select("tbody tr.table-entry")

    var entries: [SwiftVersionEntry] = []
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM yy"

    for row in rows {
        let cells = try row.select("td")
        guard cells.count == 3 else { continue }

        let dateStr = try cells[0].text()
        let swiftVer = try cells[1].text()
        let xcodeVer = try cells[2].text()

        guard let date = dateFormatter.date(from: dateStr) else {
            print("Warning: Could not parse date: \(dateStr)")
            continue
        }

        entries.append(SwiftVersionEntry(
            date: date,
            swiftVersion: swiftVer,
            xcodeVersion: xcodeVer
        ))
    }

    return entries
}
```

### Dependencies

Add SwiftSoup to Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
]
```

---

## MistKit API Patterns

### Main Client Class

**Type**: `CloudKitService`
**Location**: `Sources/MistKit/Service/CloudKitService.swift`

### Initialization

```swift
// Option 1: API Token Only (Public Database)
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    apiToken: apiToken
)

// Option 2: Web Authentication (Private/Shared Database)
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    apiToken: apiToken,
    webAuthToken: webAuthToken
)

// Option 3: Custom TokenManager
let service = try CloudKitService(
    containerIdentifier: "iCloud.com.example.MyApp",
    tokenManager: tokenManager,
    environment: .development,
    database: .private
)
```

### Environment Configuration

```bash
# .env file
CLOUDKIT_API_TOKEN=your_api_token_here
CLOUDKIT_CONTAINER=iCloud.com.example.MyApp
```

```swift
// Load from environment
let apiToken = ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]!
let container = ProcessInfo.processInfo.environment["CLOUDKIT_CONTAINER"]!
```

### Field Values

```swift
import MistKit

// Simple types
let title: FieldValue = .string("Buy groceries")
let count: FieldValue = .int64(5)
let price: FieldValue = .double(19.99)
let isComplete: FieldValue = .boolean(true)
let createdAt: FieldValue = .date(Date())

// Reference to another record
let categoryRef: FieldValue = .reference(
    FieldValue.Reference(
        recordName: "category-123",
        action: nil  // or "DELETE_SELF" for cascade delete
    )
)

// Location
let location: FieldValue = .location(
    FieldValue.Location(
        latitude: 37.7749,
        longitude: -122.4194
    )
)

// List of values
let tags: FieldValue = .list([
    .string("urgent"),
    .string("shopping")
])
```

### Query Records

```swift
func queryRecords(service: CloudKitService) async throws -> [RecordInfo] {
    let records = try await service.queryRecords(
        recordType: "RestoreImage",
        limit: 100
    )

    for record in records {
        print("Record: \(record.recordName)")

        // Extract fields using pattern matching
        if case .string(let version) = record.fields["version"] {
            print("  Version: \(version)")
        }

        if case .boolean(let isSigned) = record.fields["isSigned"] {
            print("  Signed: \(isSigned)")
        }

        if case .reference(let ref) = record.fields["minimumMacOS"] {
            print("  Min macOS: \(ref.recordName)")
        }
    }

    return records
}
```

### Create Record

```swift
func createRecord(service: CloudKitService) async throws {
    let client = service.mistKitClient.client

    // Create field values
    let fields: [String: Components.Schemas.FieldValue] = [
        "version": .init(
            value: .stringValue("14.2.1"),
            type: .string
        ),
        "buildNumber": .init(
            value: .stringValue("23C71"),
            type: .string
        ),
        "isSigned": .init(
            value: .booleanValue(true),
            type: nil
        ),
        "releaseDate": .init(
            value: .dateTimeValue(Date().timeIntervalSince1970),
            type: .dateTime
        )
    ]

    // Create record operation
    let operation = Components.Schemas.RecordOperation(
        operationType: .create,
        record: .init(
            recordName: "RestoreImage-23C71",  // Unique ID based on build
            recordType: "RestoreImage",
            recordChangeTag: nil,
            fields: .init(additionalProperties: fields)
        )
    )

    // Execute modify
    let response = try await client.modifyRecords(
        .init(
            path: .init(
                version: "1",
                container: service.containerIdentifier,
                environment: service.environment.toComponentsEnvironment(),
                database: service.database.toComponentsDatabase()
            ),
            body: .json(.init(
                operations: [operation],
                atomic: true
            ))
        )
    )

    switch response {
    case .ok:
        print("Record created successfully")
    default:
        throw CloudKitError.httpErrorWithRawResponse(
            statusCode: 400,
            rawResponse: "Failed to create record"
        )
    }
}
```

### Update Record

```swift
func updateRecord(
    service: CloudKitService,
    recordName: String,
    recordChangeTag: String
) async throws {
    let client = service.mistKitClient.client

    let operation = Components.Schemas.RecordOperation(
        operationType: .update,
        record: .init(
            recordName: recordName,
            recordType: "RestoreImage",
            recordChangeTag: recordChangeTag,  // Required for optimistic locking
            fields: .init(additionalProperties: [
                "isSigned": .init(
                    value: .booleanValue(false),
                    type: nil
                )
            ])
        )
    )

    let response = try await client.modifyRecords(
        .init(
            path: .init(
                version: "1",
                container: service.containerIdentifier,
                environment: service.environment.toComponentsEnvironment(),
                database: service.database.toComponentsDatabase()
            ),
            body: .json(.init(
                operations: [operation],
                atomic: true
            ))
        )
    )
}
```

### Handle References

```swift
func createWithReference(service: CloudKitService) async throws {
    let client = service.mistKitClient.client

    // Create fields including reference
    let fields: [String: Components.Schemas.FieldValue] = [
        "version": .init(
            value: .stringValue("15.1"),
            type: .string
        ),
        "minimumMacOS": .init(
            value: .referenceValue(
                .init(
                    recordName: "RestoreImage-23A344",  // Reference to another record
                    action: nil  // or .DELETE_SELF for cascade delete
                )
            ),
            type: .reference
        )
    ]

    let operation = Components.Schemas.RecordOperation(
        operationType: .create,
        record: .init(
            recordName: "XcodeVersion-15C65",
            recordType: "XcodeVersion",
            recordChangeTag: nil,
            fields: .init(additionalProperties: fields)
        )
    )

    let response = try await client.modifyRecords(
        .init(
            path: .init(
                version: "1",
                container: service.containerIdentifier,
                environment: service.environment.toComponentsEnvironment(),
                database: service.database.toComponentsDatabase()
            ),
            body: .json(.init(
                operations: [operation],
                atomic: true
            ))
        )
    )
}
```

### Batch Operations

```swift
func batchCreate(service: CloudKitService, records: [RecordData]) async throws {
    let client = service.mistKitClient.client

    // Create multiple operations
    let operations = records.map { recordData in
        Components.Schemas.RecordOperation(
            operationType: .create,
            record: .init(
                recordName: recordData.id,
                recordType: recordData.type,
                recordChangeTag: nil,
                fields: .init(additionalProperties: recordData.fields)
            )
        )
    }

    // Execute all in one request
    let response = try await client.modifyRecords(
        .init(
            path: .init(
                version: "1",
                container: service.containerIdentifier,
                environment: service.environment.toComponentsEnvironment(),
                database: service.database.toComponentsDatabase()
            ),
            body: .json(.init(
                operations: operations,
                atomic: true  // All succeed or all fail
            ))
        )
    )
}
```

### Error Handling

```swift
do {
    let records = try await service.queryRecords(recordType: "RestoreImage")
} catch let error as CloudKitError {
    switch error {
    case .httpErrorWithRawResponse(let statusCode, let response):
        print("HTTP \(statusCode): \(response)")
    case .networkError(let underlying):
        print("Network error: \(underlying)")
    default:
        print("CloudKit error: \(error.localizedDescription)")
    }
} catch let error as TokenManagerError {
    print("Auth error: \(error)")
}
```

### Async/Await Patterns

All MistKit operations are async:

```swift
// Basic usage
let records = try await service.queryRecords(recordType: "RestoreImage")

// With Task groups for parallel operations
await withThrowingTaskGroup(of: Void.self) { group in
    group.addTask {
        try await createRestoreImage(service)
    }
    group.addTask {
        try await createXcodeVersion(service)
    }
    group.addTask {
        try await createSwiftVersion(service)
    }

    try await group.waitForAll()
}
```

### Key Files

- **Main Service**: `Sources/MistKit/Service/CloudKitService.swift`
- **Service Operations**: `Sources/MistKit/Service/CloudKitService+Operations.swift`
- **Field Values**: `Sources/MistKit/FieldValue.swift`
- **Record Info**: `Sources/MistKit/Service/RecordInfo.swift`
- **Generated Client**: `Sources/MistKit/Generated/Client.swift`
- **Generated Types**: `Sources/MistKit/Generated/Types.swift`
- **Example Demo**: `Examples/Sources/MistDemo/MistDemo.swift`

---

## Implementation Checklist

### Phase 1: Data Fetchers

- [ ] Implement xcodereleases.com JSON fetcher
- [ ] Implement swiftversion.net HTML scraper (with SwiftSoup)
- [ ] Integrate IPSWDownloads for ipsw.me
- [ ] Implement MESU XML parser
- [ ] Implement Mr. Macintosh scraper (if needed)

### Phase 2: CloudKit Integration

- [ ] Create wrapper functions for record create/update
- [ ] Implement RestoreImage record builder
- [ ] Implement XcodeVersion record builder
- [ ] Implement SwiftVersion record builder
- [ ] Handle CKReference relationships
- [ ] Implement batch operations

### Phase 3: Sync Logic

- [ ] Fetch data from all sources
- [ ] Deduplicate records (match by build/version)
- [ ] Create/update CloudKit records
- [ ] Handle reference resolution
- [ ] Implement incremental sync
- [ ] Add progress reporting

### Phase 4: Export Logic

- [ ] Query all records from CloudKit
- [ ] Serialize to JSON
- [ ] Support filtering options
- [ ] Pretty-print output

### Phase 5: CLI Interface

- [ ] Setup ArgumentParser
- [ ] Implement `sync` command with options
- [ ] Implement `export` command with options
- [ ] Add help documentation
- [ ] Environment variable configuration
