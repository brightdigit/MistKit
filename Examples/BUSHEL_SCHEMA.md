# Bushel Version History - CloudKit Schema Design

## Record Type: `Version`

A CloudKit record type for storing software version history information.

### Fields

| Field Name | Type | Required | Indexed | Description |
|------------|------|----------|---------|-------------|
| `version` | String | ✓ | ✓ | Full semantic version string (e.g., "1.2.3") |
| `major` | Int64 | ✓ | ✓ | Major version number |
| `minor` | Int64 | ✓ | ✓ | Minor version number |
| `patch` | Int64 | ✓ | ✓ | Patch version number |
| `releaseDate` | Date/Time | ✓ | ✓ | Date and time of release |
| `releaseNotes` | String | ✓ | - | Markdown-formatted release notes and description |
| `status` | String | ✓ | ✓ | Release status: "draft", "released", "deprecated" |
| `buildNumber` | String | - | - | Optional build number |
| `commitHash` | String | - | - | Optional Git commit SHA |
| `prerelease` | String | - | ✓ | Prerelease identifier (e.g., "alpha", "beta", "rc.1") |
| `metadata` | String | - | - | JSON string for additional metadata |

### Indexes

For efficient querying, the following fields should be indexed:
- `version` - For exact version lookups
- `major`, `minor`, `patch` - For version range queries
- `releaseDate` - For chronological queries
- `status` - For filtering by release status
- `prerelease` - For filtering release types

### Query Patterns

#### 1. Get All Released Versions (Chronological)
```
Query: status = "released"
Sort: releaseDate DESC
```

#### 2. Find Specific Version
```
Query: version = "1.2.3"
```

#### 3. Get Latest Version
```
Query: status = "released" AND prerelease = null
Sort: major DESC, minor DESC, patch DESC
Limit: 1
```

#### 4. Get Versions in Range
```
Query: major >= 1 AND major <= 2
Sort: major DESC, minor DESC, patch DESC
```

#### 5. Get All Pre-releases
```
Query: prerelease != null
Sort: releaseDate DESC
```

### Swift Model

```swift
import Foundation

/// Represents a software version record stored in CloudKit
public struct Version: Codable, Sendable {
    // MARK: - Properties

    /// CloudKit record identifier
    public let recordID: String?

    /// Full semantic version string (e.g., "1.2.3")
    public let version: String

    /// Major version number
    public let major: Int

    /// Minor version number
    public let minor: Int

    /// Patch version number
    public let patch: Int

    /// Date and time of release
    public let releaseDate: Date

    /// Markdown-formatted release notes
    public let releaseNotes: String

    /// Release status: draft, released, deprecated
    public let status: ReleaseStatus

    /// Optional build number
    public let buildNumber: String?

    /// Optional Git commit SHA
    public let commitHash: String?

    /// Prerelease identifier (e.g., "alpha", "beta")
    public let prerelease: String?

    /// Additional metadata as JSON
    public let metadata: [String: String]?

    // MARK: - Types

    public enum ReleaseStatus: String, Codable, Sendable {
        case draft
        case released
        case deprecated
    }

    // MARK: - Initialization

    public init(
        recordID: String? = nil,
        version: String,
        major: Int,
        minor: Int,
        patch: Int,
        releaseDate: Date,
        releaseNotes: String,
        status: ReleaseStatus = .released,
        buildNumber: String? = nil,
        commitHash: String? = nil,
        prerelease: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.recordID = recordID
        self.version = version
        self.major = major
        self.minor = minor
        self.patch = patch
        self.releaseDate = releaseDate
        self.releaseNotes = releaseNotes
        self.status = status
        self.buildNumber = buildNumber
        self.commitHash = commitHash
        self.prerelease = prerelease
        self.metadata = metadata
    }
}
```

### CloudKit Record Type Configuration

When setting up the CloudKit schema in the CloudKit Dashboard:

1. **Record Type Name**: `Version`
2. **Security**:
   - Public database: Read by all, write by authenticated users
   - Private database: Read/write by owner only
3. **Indexes**: Create queryable indexes on:
   - `version` (String, Queryable)
   - `major` (Int64, Queryable, Sortable)
   - `minor` (Int64, Queryable, Sortable)
   - `patch` (Int64, Queryable, Sortable)
   - `releaseDate` (Date/Time, Queryable, Sortable)
   - `status` (String, Queryable)
   - `prerelease` (String, Queryable)

### Design Rationale

1. **Separate Major/Minor/Patch Fields**: Allows efficient range queries and sorting by version components
2. **Status Field**: Enables filtering draft versions from released ones
3. **Prerelease Field**: Distinguishes stable releases from alpha/beta/RC versions
4. **Metadata JSON**: Provides extensibility without schema changes
5. **Indexed Fields**: Optimizes common query patterns (latest version, version ranges, status filtering)

### Example Data

```json
{
  "recordID": "version-1.2.3",
  "version": "1.2.3",
  "major": 1,
  "minor": 2,
  "patch": 3,
  "releaseDate": "2024-11-03T12:00:00Z",
  "releaseNotes": "## What's New\n- Fixed critical bug\n- Added new features",
  "status": "released",
  "buildNumber": "42",
  "commitHash": "abc123def456",
  "prerelease": null,
  "metadata": {
    "platform": "macOS",
    "minOS": "13.0"
  }
}
```
