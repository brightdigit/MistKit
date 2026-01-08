# Migration Plan: BushelCloudKit to BushelKit (Gradual Migration Strategy)

## Overview

Gradually migrate code from `Sources/BushelCloudKit` to BushelKit package using a safe, incremental approach:

1. **Isolate** non-MistKit code into a separate target (`BushelCloudData`)
2. **Deprecate** the isolated code to signal upcoming migration
3. **Migrate** to BushelKit incrementally as code stabilizes
4. **Update** BushelCloud periodically as dependencies shift

This approach minimizes risk, maintains working code throughout, and allows for iterative testing.

## Architecture Strategy

**Key Principle:** Gradual migration with deprecation warnings and intermediate targets

### Phase 1: Current State
```
BushelCloud/Sources/BushelCloudKit/
├── Models/* (with MistKit FieldValue/RecordInfo)
├── DataSources/* (fetchers + pipeline)
├── CloudKit/* (service + sync)
└── Utilities/*
```

### Phase 2: Intermediate (Isolation)
```
BushelCloud/Sources/
├── BushelCloudKit/                    (MistKit-dependent)
│   ├── CloudKit/* (service + sync)
│   └── Extensions/* (CloudKitRecord)
│
└── BushelCloudData/                   (NEW - MistKit-independent, DEPRECATED)
    ├── Models/* (plain structs)
    ├── DataSources/* (fetchers)
    └── Utilities/*
```

### Phase 3: Final State (After Migration)
```
BushelKit/Sources/
├── BushelFoundation/ (models from BushelCloudData)
├── BushelHub/ (fetchers from BushelCloudData)
└── BushelUtilities/ (utilities from BushelCloudData)

BushelCloud/Sources/BushelCloudKit/
├── CloudKit/* (service + sync + errors)
└── Extensions/* (CloudKitRecord extensions)
```

## What Moves Where

### To BushelKit/BushelFoundation (Core Models & Configuration)

**Plain Swift models (remove MistKit dependencies):**
- `Models/RestoreImageRecord.swift` → `BushelFoundation/RestoreImageRecord.swift`
  - Remove: `toCloudKitFields()`, `from(recordInfo:)`, `formatForDisplay()`
  - Keep: Core properties as plain Swift struct with Codable

- `Models/XcodeVersionRecord.swift` → `BushelFoundation/XcodeVersionRecord.swift`
  - Remove: CloudKit-specific methods
  - Keep: Core properties, references as plain String fields

- `Models/SwiftVersionRecord.swift` → `BushelFoundation/SwiftVersionRecord.swift`
  - Remove: CloudKit-specific methods
  - Keep: Core properties

- `Models/DataSourceMetadata.swift` → `BushelFoundation/DataSourceMetadata.swift`
  - Remove: CloudKit-specific methods
  - Keep: Core metadata tracking properties

**Configuration:**
- `Configuration/FetchConfiguration.swift` → `BushelFoundation/FetchConfiguration.swift`
  - No changes needed (no MistKit dependency)

### To BushelKit/BushelHub (Data Fetching)

**Protocols & Infrastructure:**
- `DataSources/DataSourceFetcher.swift` → `BushelHub/DataSourceFetcher.swift`
- `DataSources/HTTPHeaderHelpers.swift` → `BushelHub/HTTPHeaderHelpers.swift`

**Orchestration:**
- `DataSources/DataSourcePipeline.swift` → `BushelHub/DataSourcePipeline.swift`
  - Update imports to use BushelFoundation models

**Individual Fetchers:**
- `DataSources/IPSWFetcher.swift` → `BushelHub/Fetchers/IPSWFetcher.swift`
- `DataSources/AppleDBFetcher.swift` → `BushelHub/Fetchers/AppleDBFetcher.swift`
- `DataSources/AppleDB/*.swift` (9 files) → `BushelHub/Fetchers/AppleDB/`
- `DataSources/XcodeReleasesFetcher.swift` → `BushelHub/Fetchers/XcodeReleasesFetcher.swift`
- `DataSources/SwiftVersionFetcher.swift` → `BushelHub/Fetchers/SwiftVersionFetcher.swift`
- `DataSources/MESUFetcher.swift` → `BushelHub/Fetchers/MESUFetcher.swift`
- `DataSources/MrMacintoshFetcher.swift` → `BushelHub/Fetchers/MrMacintoshFetcher.swift`
- `DataSources/TheAppleWikiFetcher.swift` → `BushelHub/Fetchers/TheAppleWikiFetcher.swift`
- `DataSources/TheAppleWiki/*.swift` (4 files) → `BushelHub/Fetchers/TheAppleWiki/`

### To BushelKit/BushelUtilities (Utilities)

- `Utilities/FormattingHelpers.swift` → `BushelUtilities/FormattingHelpers.swift`
- `Utilities/ConsoleOutput.swift` → `BushelUtilities/ConsoleOutput.swift`

### Stay in BushelCloud (CloudKit Integration)

**CloudKit Service Layer:**
- `CloudKit/BushelCloudKitService.swift` (KEEP - requires MistKit)
- `CloudKit/SyncEngine.swift` (KEEP - requires MistKit)
- `CloudKit/RecordManaging+Query.swift` (KEEP - extends MistKit)
- `CloudKit/BushelCloudKitError.swift` (KEEP - service errors)

**New CloudKitRecord Extensions:**
- Create `Extensions/RestoreImageRecord+CloudKit.swift`
  - Add: `CloudKitRecord` protocol conformance
  - Add: `toCloudKitFields()`, `from(recordInfo:)`, `formatForDisplay()`
  - Import: MistKit, BushelFoundation

- Create `Extensions/XcodeVersionRecord+CloudKit.swift`
- Create `Extensions/SwiftVersionRecord+CloudKit.swift`
- Create `Extensions/DataSourceMetadata+CloudKit.swift`

**CLI Layer:**
- `BushelCloudCLI/` (KEEP - all CLI commands)

## Phase 1: Create BushelCloudData Target (Week 1)

**Goal:** Isolate non-MistKit code into a separate target within BushelCloud

### 1.1 Create New Target in Package.swift

Add new `BushelCloudData` target in `/Users/leo/Documents/Projects/BushelCloud/Package.swift`:

```swift
targets: [
    // Existing BushelCloudKit target (will be slimmed down)
    .target(
        name: "BushelCloudKit",
        dependencies: [
            .product(name: "MistKit", package: "MistKit"),
            .product(name: "BushelLogging", package: "BushelKit"),
            .target(name: "BushelCloudData"),  // NEW dependency
        ],
        swiftSettings: swiftSettings
    ),

    // NEW target - MistKit-independent code
    .target(
        name: "BushelCloudData",
        dependencies: [
            .product(name: "IPSWDownloads", package: "IPSWDownloads"),
            .product(name: "SwiftSoup", package: "SwiftSoup"),
            .product(name: "BushelLogging", package: "BushelKit"),
            // NO MistKit dependency
        ],
        swiftSettings: swiftSettings
    ),

    .executableTarget(
        name: "BushelCloudCLI",
        dependencies: [
            .target(name: "BushelCloudKit"),
            .target(name: "BushelCloudData"),  // NEW dependency
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ],
        swiftSettings: swiftSettings
    ),
]
```

### 1.2 Create BushelCloudData Directory Structure

```bash
mkdir -p Sources/BushelCloudData/Models
mkdir -p Sources/BushelCloudData/DataSources/AppleDB
mkdir -p Sources/BushelCloudData/DataSources/TheAppleWiki
mkdir -p Sources/BushelCloudData/Utilities
mkdir -p Sources/BushelCloudData/Configuration
```

### 1.3 Move Models to BushelCloudData (Remove MistKit)

Copy and refactor each model to remove MistKit dependencies:

**Example: RestoreImageRecord.swift**

Move from `BushelCloudKit/Models/` to `BushelCloudData/Models/`, removing CloudKit methods:

```swift
// Sources/BushelCloudData/Models/RestoreImageRecord.swift
import Foundation

@available(*, deprecated, message: "This type will move to BushelKit in a future release")
public struct RestoreImageRecord: Codable, Sendable {
    public let version: String
    public let buildNumber: String
    public let releaseDate: Date
    public let downloadURL: URL
    public let fileSize: UInt64?
    public let sha256Hash: String?
    public let sha1Hash: String?
    public let isSigned: Bool?
    public let isPrerelease: Bool
    public let source: String
    public let notes: String?
    public let sourceUpdatedAt: Date?

    public init(
        version: String,
        buildNumber: String,
        releaseDate: Date,
        downloadURL: URL,
        fileSize: UInt64? = nil,
        sha256Hash: String? = nil,
        sha1Hash: String? = nil,
        isSigned: Bool? = nil,
        isPrerelease: Bool = false,
        source: String,
        notes: String? = nil,
        sourceUpdatedAt: Date? = nil
    ) {
        self.version = version
        self.buildNumber = buildNumber
        self.releaseDate = releaseDate
        self.downloadURL = downloadURL
        self.fileSize = fileSize
        self.sha256Hash = sha256Hash
        self.sha1Hash = sha1Hash
        self.isSigned = isSigned
        self.isPrerelease = isPrerelease
        self.source = source
        self.notes = notes
        self.sourceUpdatedAt = sourceUpdatedAt
    }
}
```

**Repeat for:**
- XcodeVersionRecord (references become String properties)
- SwiftVersionRecord
- DataSourceMetadata

### 1.4 Move Data Fetchers to BushelCloudData

Copy all fetchers to BushelCloudData, update imports:

```swift
// Sources/BushelCloudData/DataSources/IPSWFetcher.swift
import Foundation
import BushelLogging
import BushelCloudData  // For models

@available(*, deprecated, message: "This type will move to BushelKit in a future release")
public struct IPSWFetcher: DataSourceFetcher {
    // Implementation stays the same
}
```

**Files to move:**
- DataSourceFetcher.swift (protocol)
- DataSourcePipeline.swift
- HTTPHeaderHelpers.swift
- All individual fetchers (IPSWFetcher, AppleDBFetcher, etc.)
- AppleDB/*.swift (9 files)
- TheAppleWiki/*.swift (4 files)

### 1.5 Move Utilities and Configuration

```swift
// Sources/BushelCloudData/Utilities/FormattingHelpers.swift
@available(*, deprecated, message: "This type will move to BushelKit in a future release")
public enum FormattingHelpers {
    // Implementation unchanged
}

// Sources/BushelCloudData/Configuration/FetchConfiguration.swift
@available(*, deprecated, message: "This type will move to BushelKit in a future release")
public struct FetchConfiguration: Codable, Sendable {
    // Implementation unchanged
}
```

### 1.6 Create CloudKitRecord Extensions in BushelCloudKit

Create new `Extensions/` directory:

```swift
// Sources/BushelCloudKit/CloudKitRecord.swift
import MistKit
import Foundation

public protocol CloudKitRecord {
    static var cloudKitRecordType: String { get }
    func toCloudKitFields() -> [String: FieldValue]
    static func from(recordInfo: RecordInfo) -> Self?
    static func formatForDisplay(_ recordInfo: RecordInfo) -> String
}

// Sources/BushelCloudKit/Extensions/RestoreImageRecord+CloudKit.swift
import MistKit
import BushelCloudData
import Foundation

extension RestoreImageRecord: CloudKitRecord {
    public static var cloudKitRecordType: String { "RestoreImage" }

    public func toCloudKitFields() -> [String: FieldValue] {
        // CloudKit serialization logic (moved from original model)
    }

    public static func from(recordInfo: RecordInfo) -> RestoreImageRecord? {
        // CloudKit deserialization logic (moved from original model)
    }

    public static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
        // Display formatting (moved from original model)
    }
}
```

**Create extensions for:**
- RestoreImageRecord+CloudKit.swift
- XcodeVersionRecord+CloudKit.swift
- SwiftVersionRecord+CloudKit.swift
- DataSourceMetadata+CloudKit.swift

### 1.7 Update Imports in BushelCloudKit

Update CloudKit service files:

```swift
// Sources/BushelCloudKit/CloudKit/BushelCloudKitService.swift
import MistKit
import BushelCloudData  // NEW - for models
import BushelLogging
import Foundation

// Implementation unchanged - CloudKitRecord extensions auto-available

// Sources/BushelCloudKit/CloudKit/SyncEngine.swift
import MistKit
import BushelCloudData  // NEW - for models and DataSourcePipeline
import BushelLogging
import Foundation

// Implementation unchanged
```

### 1.8 Test BushelCloud Build

```bash
cd /Users/leo/Documents/Projects/BushelCloud
swift build
```

Verify:
- Both BushelCloudData and BushelCloudKit targets build
- Deprecation warnings appear for BushelCloudData types
- All CLI commands still work
- Tests pass

### 1.9 Commit Phase 1

```bash
git add .
git commit -m "refactor: isolate non-MistKit code into BushelCloudData target

- Create new BushelCloudData target (deprecated, will move to BushelKit)
- Move models, fetchers, utilities to BushelCloudData
- Add CloudKitRecord extensions in BushelCloudKit
- Update imports throughout codebase

All functionality unchanged, preparing for gradual migration to BushelKit"
```

## Phase 2: Add Deprecation Warnings & Aliases (Week 2)

**Goal:** Add clear deprecation messages and type aliases for smooth transition

### 2.1 Add Detailed Deprecation Messages

Update each type with specific migration guidance:

```swift
@available(*, deprecated, renamed: "BushelKit.RestoreImageRecord", message: """
This type is moving to BushelKit.BushelFoundation.
Update your imports:
  Before: import BushelCloudData
  After:  import BushelFoundation
""")
public struct RestoreImageRecord: Codable, Sendable {
    // ...
}
```

### 2.2 Create Migration Guide Document

Add `MIGRATION-BUSHELCLOUDDATA.md` to BushelCloud:

```markdown
# BushelCloudData Migration Guide

## Status

The `BushelCloudData` target is **deprecated** and will be removed in a future release.
All types are moving to BushelKit:

- Models → BushelKit.BushelFoundation
- Fetchers → BushelKit.BushelHub
- Utilities → BushelKit.BushelUtilities

## Timeline

- **Current (v0.1.x):** BushelCloudData available but deprecated
- **Next (v0.2.0):** BushelKit modules available, BushelCloudData still present
- **Future (v1.0.0):** BushelCloudData removed entirely

## Migration Path

Update your Package.swift:
\`\`\`swift
dependencies: [
    .package(url: "https://github.com/brightdigit/BushelKit.git", from: "3.0.0")
]

.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "BushelFoundation", package: "BushelKit"),
        .product(name: "BushelHub", package: "BushelKit"),
    ]
)
\`\`\`

Update your imports:
\`\`\`swift
// Before
import BushelCloudData

// After
import BushelFoundation  // For models
import BushelHub         // For fetchers
\`\`\`
```

### 2.3 Test with Deprecation Warnings

```bash
swift build 2>&1 | grep -i deprecated
```

Verify all BushelCloudData usage shows deprecation warnings.

### 2.4 Commit Phase 2

```bash
git commit -am "docs: add comprehensive deprecation warnings and migration guide"
```

## Phase 3: Migrate to BushelKit Incrementally (Weeks 3-4)

**Goal:** Move code from BushelCloudData to BushelKit, one module at a time

### 3.1 Update BushelKit Package.swift (Add Dependencies)

```swift
// /Users/leo/Documents/Projects/BushelKit/Package.swift

dependencies: [
    // Add for data fetching
    .package(url: "https://github.com/brightdigit/IPSWDownloads.git", from: "1.0.0"),
    .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    // ... existing dependencies
]

// Update existing targets
targets: [
    .target(
        name: "BushelFoundation",
        dependencies: [
            // No new dependencies - models are plain Swift
        ]
    ),
    .target(
        name: "BushelHub",
        dependencies: [
            .target(name: "BushelFoundation"),
            .target(name: "BushelLogging"),
            .product(name: "IPSWDownloads", package: "IPSWDownloads"),
            .product(name: "SwiftSoup", package: "SwiftSoup"),
            // ... existing dependencies
        ]
    ),
    .target(
        name: "BushelUtilities",
        dependencies: [
            // Already has Foundation
        ]
    ),
]
```

### 3.2 Copy Models to BushelKit/BushelFoundation

Copy models from BushelCloudData to BushelFoundation (remove deprecation attributes):

```bash
cd /Users/leo/Documents/Projects/BushelKit
cp ../BushelCloud/Sources/BushelCloudData/Models/*.swift Sources/BushelFoundation/
```

Remove `@available(*, deprecated, ...)` attributes from the BushelKit versions.

### 3.3 Copy Fetchers to BushelKit/BushelHub

```bash
cd /Users/leo/Documents/Projects/BushelKit
mkdir -p Sources/BushelHub/DataSources/AppleDB
mkdir -p Sources/BushelHub/DataSources/TheAppleWiki

cp ../BushelCloud/Sources/BushelCloudData/DataSources/*.swift Sources/BushelHub/DataSources/
cp -r ../BushelCloud/Sources/BushelCloudData/DataSources/AppleDB/*.swift Sources/BushelHub/DataSources/AppleDB/
cp -r ../BushelCloud/Sources/BushelCloudData/DataSources/TheAppleWiki/*.swift Sources/BushelHub/DataSources/TheAppleWiki/
```

Update imports in all fetcher files:
```swift
// Before
import BushelCloudData

// After
import BushelFoundation  // For models
```

Remove deprecation attributes.

### 3.4 Copy Utilities to BushelKit

```bash
cp ../BushelCloud/Sources/BushelCloudData/Utilities/*.swift Sources/BushelUtilities/
cp ../BushelCloud/Sources/BushelCloudData/Configuration/*.swift Sources/BushelFoundation/
```

Remove deprecation attributes.

### 3.5 Test BushelKit Build

```bash
cd /Users/leo/Documents/Projects/BushelKit
swift build
swift test
```

Verify all platforms build successfully.

### 3.6 Tag BushelKit Release

```bash
cd /Users/leo/Documents/Projects/BushelKit
git add .
git commit -m "feat: add models, fetchers, and utilities from BushelCloud

- Add RestoreImageRecord, XcodeVersionRecord, SwiftVersionRecord to BushelFoundation
- Add data fetchers and DataSourcePipeline to BushelHub
- Add FormattingHelpers, ConsoleOutput to BushelUtilities
- Add FetchConfiguration to BushelFoundation

These types were previously in BushelCloud's BushelCloudData target (now deprecated)"

git tag v3.0.0-alpha.2
git push origin main --tags
```

## Phase 4: Update BushelCloud to Use BushelKit (Weeks 5-6)

**Goal:** Gradually switch BushelCloud from BushelCloudData to BushelKit modules

### 4.1 Update BushelCloud Package.swift

```swift
// /Users/leo/Documents/Projects/BushelCloud/Package.swift

dependencies: [
    .package(url: "https://github.com/brightdigit/MistKit.git", from: "1.0.0-alpha.3"),
    .package(url: "https://github.com/brightdigit/BushelKit.git", from: "3.0.0-alpha.2"), // UPDATED
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    // Remove IPSWDownloads and SwiftSoup - now transitive via BushelKit
]

targets: [
    .target(
        name: "BushelCloudKit",
        dependencies: [
            .product(name: "MistKit", package: "MistKit"),
            .product(name: "BushelLogging", package: "BushelKit"),
            .product(name: "BushelFoundation", package: "BushelKit"),  // NEW
            .product(name: "BushelHub", package: "BushelKit"),         // NEW
            .target(name: "BushelCloudData"),  // KEEP temporarily for transition
        ]
    ),

    // BushelCloudData target (keep for now, will remove in Phase 5)
    .target(
        name: "BushelCloudData",
        dependencies: [
            // Keep as-is for now
        ]
    ),

    .executableTarget(
        name: "BushelCloudCLI",
        dependencies: [
            .target(name: "BushelCloudKit"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            // Remove BushelData dependency (now via BushelCloudKit)
        ]
    ),
]
```

### 4.2 Update Imports in BushelCloudKit Extensions

```swift
// Sources/BushelCloudKit/Extensions/RestoreImageRecord+CloudKit.swift
import MistKit
import BushelFoundation  // CHANGED from BushelCloudData
import Foundation

extension RestoreImageRecord: CloudKitRecord {
    // Implementation unchanged
}
```

Update all 4 extension files to import from BushelFoundation instead of BushelCloudData.

### 4.3 Update Imports in CloudKit Service Files

```swift
// Sources/BushelCloudKit/CloudKit/BushelCloudKitService.swift
import MistKit
import BushelFoundation  // CHANGED from BushelCloudData
import BushelLogging
import Foundation

// Sources/BushelCloudKit/CloudKit/SyncEngine.swift
import MistKit
import BushelFoundation  // CHANGED from BushelCloudData
import BushelHub         // CHANGED from BushelCloudData
import BushelLogging
import Foundation
```

### 4.4 Test BushelCloud Build

```bash
cd /Users/leo/Documents/Projects/BushelCloud
swift build
```

At this point:
- BushelCloudKit uses BushelKit modules
- BushelCloudData still exists but is unused
- Deprecation warnings may still appear (that's ok)

Test all CLI commands:
```bash
.build/debug/bushel-cloud sync --dry-run --verbose
.build/debug/bushel-cloud export --output test.json --verbose
.build/debug/bushel-cloud list
.build/debug/bushel-cloud status
```

### 4.5 Commit Phase 4

```bash
git commit -am "refactor: migrate from BushelCloudData to BushelKit modules

- Update imports to use BushelFoundation and BushelHub
- Keep BushelCloudData target for backward compatibility (to be removed)"
```

## Phase 5: Remove BushelCloudData Target (Week 7)

**Goal:** Clean up deprecated code once BushelKit migration is complete

### 5.1 Remove BushelCloudData Target from Package.swift

```swift
// Remove entire BushelCloudData target
targets: [
    .target(
        name: "BushelCloudKit",
        dependencies: [
            .product(name: "MistKit", package: "MistKit"),
            .product(name: "BushelLogging", package: "BushelKit"),
            .product(name: "BushelFoundation", package: "BushelKit"),
            .product(name: "BushelHub", package: "BushelKit"),
            // BushelCloudData dependency REMOVED
        ]
    ),
    // BushelCloudData target REMOVED entirely
]
```

### 5.2 Delete BushelCloudData Directory

```bash
rm -rf Sources/BushelCloudData
```

### 5.3 Delete Old Model/Fetcher Files from BushelCloudKit

```bash
rm -rf Sources/BushelCloudKit/Models
rm -rf Sources/BushelCloudKit/DataSources
rm -rf Sources/BushelCloudKit/Utilities
rm -rf Sources/BushelCloudKit/Configuration
```

### 5.4 Final BushelCloudKit Structure

Verify final structure:

```
Sources/BushelCloudKit/
├── CloudKit/
│   ├── BushelCloudKitService.swift
│   ├── SyncEngine.swift
│   ├── RecordManaging+Query.swift
│   └── BushelCloudKitError.swift
├── Extensions/
│   ├── RestoreImageRecord+CloudKit.swift
│   ├── XcodeVersionRecord+CloudKit.swift
│   ├── SwiftVersionRecord+CloudKit.swift
│   └── DataSourceMetadata+CloudKit.swift
├── CloudKitRecord.swift
└── BushelCloud.docc/ (optional)
```

### 5.5 Full Integration Test

Test all CLI commands to ensure everything still works:

```bash
cd /Users/leo/Documents/Projects/BushelCloud
swift build

# Test all commands
.build/debug/bushel-cloud sync --dry-run --verbose
.build/debug/bushel-cloud sync --verbose
.build/debug/bushel-cloud export --output final-test.json --verbose
.build/debug/bushel-cloud list
.build/debug/bushel-cloud status
```

### 5.6 Run Full Test Suite

```bash
swift test
./Scripts/lint.sh
```

### 5.7 Commit Phase 5

```bash
git add .
git commit -m "refactor: remove deprecated BushelCloudData target

- Remove BushelCloudData target completely
- All code now in BushelKit (BushelFoundation, BushelHub, BushelUtilities)
- BushelCloudKit focused on CloudKit integration only
- Clean final architecture with clear separation of concerns"

git tag v0.2.0
git push origin main --tags
```

## Documentation Updates

### Update BushelCloud Documentation

**README.md:**
```markdown
## Architecture

BushelCloud demonstrates CloudKit integration patterns using BushelKit:

- **Models** (BushelFoundation): Plain Swift domain models
- **Data Fetchers** (BushelHub): Fetch data from external APIs
- **CloudKit Integration** (BushelCloudKit): MistKit-based CloudKit sync
- **CLI** (BushelCloudCLI): Command-line interface

Dependencies:
- BushelKit 3.0+ (models, fetchers, utilities)
- MistKit 1.0+ (CloudKit Web Services)
```

**CLAUDE.md:**
```markdown
## Dependencies

- **BushelKit** (3.0.0-alpha.2+) - Provides:
  - BushelFoundation: Core models (RestoreImageRecord, XcodeVersionRecord, SwiftVersionRecord)
  - BushelHub: Data fetchers and pipeline
  - BushelUtilities: Formatting and console utilities
  - BushelLogging: Structured logging

- **MistKit** (1.0.0-alpha.3+) - CloudKit Web Services client

Import example:
\`\`\`swift
import BushelFoundation  // For models
import BushelHub         // For fetchers
import MistKit           // For CloudKit (BushelCloudKit only)
\`\`\`
```

**Delete MIGRATION-BUSHELCLOUDDATA.md** (no longer needed after Phase 5)

### Update BushelKit Documentation

Add to **BushelFoundation.docc**:
```markdown
# Models from BushelCloud

BushelFoundation includes domain models originally from the BushelCloud demo:

- `RestoreImageRecord` - macOS restore images (IPSW)
- `XcodeVersionRecord` - Xcode releases
- `SwiftVersionRecord` - Swift compiler versions
- `DataSourceMetadata` - Fetch metadata tracking

These are plain Swift structs with no CloudKit dependencies, suitable for any use case.
```

Add to **BushelHub.docc**:
```markdown
# Data Fetchers from BushelCloud

BushelHub includes data fetchers for Apple platform software:

- `IPSWFetcher` - Fetch from ipsw.me
- `AppleDBFetcher` - Fetch from AppleDB
- `XcodeReleasesFetcher` - Fetch from xcodereleases.com
- `DataSourcePipeline` - Orchestrate multiple fetchers

See BushelCloud for complete working examples.
```

## Critical Files

### BushelCloud Files

1. **`/Users/leo/Documents/Projects/BushelCloud/Package.swift`**
   - Phase 1: Add BushelCloudData target
   - Phase 4: Add BushelKit module dependencies
   - Phase 5: Remove BushelCloudData target

2. **`/Users/leo/Documents/Projects/BushelCloud/Sources/BushelCloudKit/CloudKitRecord.swift`** (NEW)
   - Phase 1: Create protocol for CloudKit serialization

3. **`/Users/leo/Documents/Projects/BushelCloud/Sources/BushelCloudKit/Extensions/RestoreImageRecord+CloudKit.swift`** (NEW)
   - Phase 1: Create CloudKit extension
   - Phase 4: Update import to BushelFoundation

4. **`/Users/leo/Documents/Projects/BushelCloud/Sources/BushelCloudKit/CloudKit/SyncEngine.swift`**
   - Phase 1: Update imports to BushelCloudData
   - Phase 4: Update imports to BushelHub

5. **`/Users/leo/Documents/Projects/BushelCloud/Sources/BushelCloudData/Models/RestoreImageRecord.swift`** (NEW, then DELETED)
   - Phase 1: Create as plain struct with deprecation
   - Phase 5: Delete (now in BushelKit)

### BushelKit Files

1. **`/Users/leo/Documents/Projects/BushelKit/Package.swift`**
   - Phase 3: Add IPSWDownloads and SwiftSoup dependencies
   - Phase 3: Update BushelHub target dependencies

2. **`/Users/leo/Documents/Projects/BushelKit/Sources/BushelFoundation/RestoreImageRecord.swift`** (NEW)
   - Phase 3: Copy from BushelCloudData, remove deprecation

3. **`/Users/leo/Documents/Projects/BushelKit/Sources/BushelHub/DataSources/DataSourcePipeline.swift`** (NEW)
   - Phase 3: Copy from BushelCloudData, update imports

## Success Criteria

- [ ] **Phase 1:** BushelCloudData target exists, all tests pass, deprecation warnings appear
- [ ] **Phase 2:** Migration guide created, comprehensive deprecation messages added
- [ ] **Phase 3:** BushelKit 3.0.0-alpha.2 tagged with models/fetchers/utilities
- [ ] **Phase 4:** BushelCloud uses BushelKit modules, all CLI commands work
- [ ] **Phase 5:** BushelCloudData removed, final structure clean, all tests pass
- [ ] **Documentation:** All docs updated to reflect new architecture
- [ ] **CI/CD:** All GitHub Actions workflows pass
- [ ] **No Breaking Changes:** CLI interface unchanged throughout migration

## Timeline Summary

| Phase | Duration | Milestone |
|-------|----------|-----------|
| Phase 1 | Week 1 | BushelCloudData target created, code isolated |
| Phase 2 | Week 2 | Deprecation warnings added |
| Phase 3 | Weeks 3-4 | Code migrated to BushelKit, v3.0.0-alpha.2 tagged |
| Phase 4 | Weeks 5-6 | BushelCloud updated to use BushelKit |
| Phase 5 | Week 7 | BushelCloudData removed, final cleanup |

**Total:** 7 weeks for complete gradual migration

## Benefits of This Approach

1. **Safety:** Code stays working throughout migration
2. **Visibility:** Deprecation warnings guide developers
3. **Testability:** Each phase can be tested independently
4. **Reversibility:** Can pause or rollback at any phase
5. **Minimal Disruption:** CLI interface never changes
6. **Clear Communication:** Deprecation messages explain what to do

---

**End of Migration Plan**
