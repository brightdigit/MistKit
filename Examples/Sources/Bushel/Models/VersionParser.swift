import Foundation

// MARK: - VersionParser

/// Utility for parsing semantic version strings
public enum VersionParser {
  // MARK: Public

  /// Parses a semantic version string (e.g., "1.2.3", "2.0.0-beta.1")
  /// - Parameter versionString: The version string to parse
  /// - Returns: A tuple containing (major, minor, patch, prerelease) or nil if invalid
  public static func parse(_ versionString: String) -> (major: Int, minor: Int, patch: Int, prerelease: String?)? {
    // Split on prerelease separator
    let components = versionString.split(separator: "-", maxSplits: 1)
    let versionPart = String(components[0])
    let prerelease = components.count > 1 ? String(components[1]) : nil

    // Split version numbers
    let numbers = versionPart.split(separator: ".")
    guard numbers.count == 3,
          let major = Int(numbers[0]),
          let minor = Int(numbers[1]),
          let patch = Int(numbers[2])
    else {
      return nil
    }

    return (major, minor, patch, prerelease)
  }

  /// Creates a version string from components
  /// - Parameters:
  ///   - major: Major version number
  ///   - minor: Minor version number
  ///   - patch: Patch version number
  ///   - prerelease: Optional prerelease identifier
  /// - Returns: Formatted version string
  public static func format(major: Int, minor: Int, patch: Int, prerelease: String? = nil) -> String {
    var result = "\(major).\(minor).\(patch)"
    if let prerelease {
      result += "-\(prerelease)"
    }
    return result
  }
}

// MARK: - Version + Convenience Initializer

extension Version {
  /// Creates a Version from a semantic version string
  /// - Parameters:
  ///   - versionString: The version string to parse (e.g., "1.2.3" or "2.0.0-beta.1")
  ///   - releaseDate: Date of release
  ///   - releaseNotes: Release notes content
  ///   - status: Release status (default: .released)
  ///   - buildNumber: Optional build number
  ///   - commitHash: Optional commit hash
  ///   - metadata: Optional metadata
  /// - Returns: A Version instance, or nil if the version string is invalid
  public init?(
    versionString: String,
    releaseDate: Date,
    releaseNotes: String,
    status: ReleaseStatus = .released,
    buildNumber: String? = nil,
    commitHash: String? = nil,
    metadata: [String: String]? = nil
  ) {
    guard let parsed = VersionParser.parse(versionString) else {
      return nil
    }

    self.init(
      recordID: nil,
      version: versionString.split(separator: "-", maxSplits: 1).first.map(String.init) ?? versionString,
      major: parsed.major,
      minor: parsed.minor,
      patch: parsed.patch,
      releaseDate: releaseDate,
      releaseNotes: releaseNotes,
      status: status,
      buildNumber: buildNumber,
      commitHash: commitHash,
      prerelease: parsed.prerelease,
      metadata: metadata
    )
  }
}
