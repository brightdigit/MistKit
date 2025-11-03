import Foundation

// MARK: - Version

/// Represents a software version record stored in CloudKit
public struct Version: Sendable {
  // MARK: Lifecycle

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

  // MARK: Public

  // MARK: - Types

  public enum ReleaseStatus: String, Sendable {
    case draft
    case released
    case deprecated
  }

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

  /// Additional metadata
  public let metadata: [String: String]?
}

// MARK: Codable

extension Version: Codable { }

// MARK: - Version.ReleaseStatus + Codable

extension Version.ReleaseStatus: Codable { }

// MARK: - Version + Comparable

extension Version: Comparable {
  public static func < (lhs: Version, rhs: Version) -> Bool {
    // Compare major, minor, patch in order
    if lhs.major != rhs.major {
      return lhs.major < rhs.major
    }
    if lhs.minor != rhs.minor {
      return lhs.minor < rhs.minor
    }
    if lhs.patch != rhs.patch {
      return lhs.patch < rhs.patch
    }

    // If version numbers are equal, compare prerelease
    // Releases without prerelease come after those with prerelease
    switch (lhs.prerelease, rhs.prerelease) {
    case (nil, nil):
      return false
    case (nil, _):
      return false
    case (_, nil):
      return true
    case let (lhsPre?, rhsPre?):
      return lhsPre < rhsPre
    }
  }
}

// MARK: - Version + Equatable

extension Version: Equatable {
  public static func == (lhs: Version, rhs: Version) -> Bool {
    lhs.version == rhs.version
      && lhs.major == rhs.major
      && lhs.minor == rhs.minor
      && lhs.patch == rhs.patch
      && lhs.prerelease == rhs.prerelease
  }
}

// MARK: - Version + CustomStringConvertible

extension Version: CustomStringConvertible {
  public var description: String {
    if let prerelease {
      return "\(version)-\(prerelease)"
    }
    return version
  }
}
