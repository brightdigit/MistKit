import Foundation
import MistKit

// MARK: - VersionService

/// Service for managing Version records in CloudKit
@available(macOS 14.0, *)
public actor VersionService {
  // MARK: Lifecycle

  public init(configuration: BushelConfiguration) throws {
    self.configuration = configuration

    // Create token manager based on configuration
    let tokenManager: any TokenManager
    if let apiToken = configuration.apiToken {
      tokenManager = APITokenManager(apiToken: apiToken)
    } else if let serverKey = configuration.serverToServerKey {
      // For now, we'll use API token manager as placeholder
      // Server-to-server auth would require additional setup
      throw ConfigurationError.missingAuthentication
    } else {
      throw ConfigurationError.missingAuthentication
    }

    self.cloudKitService = try CloudKitService(
      containerIdentifier: configuration.containerIdentifier,
      tokenManager: tokenManager,
      environment: configuration.environment == .development ? .development : .production,
      database: Self.mapDatabase(configuration.database)
    )
  }

  // MARK: Public

  /// CloudKit record type name for versions
  public static let recordTypeName = "Version"

  /// Add a new version to CloudKit
  public func addVersion(_ version: Version) async throws {
    // Convert Version to CloudKit record fields
    let _ = createFields(from: version)

    // Create record using MistKit
    // Note: This is a placeholder - actual implementation will use modifyRecords operation
    // when the generated code is available
    throw VersionServiceError.notImplemented("Add operation will be implemented with modifyRecords")
  }

  /// List all versions from CloudKit
  public func listVersions(
    status: Version.ReleaseStatus? = nil,
    includePrerelease: Bool = false,
    limit: Int = 100
  ) async throws -> [Version] {
    do {
      // Query all Version records
      let records = try await cloudKitService.queryRecords(
        recordType: Self.recordTypeName,
        limit: limit
      )

      // Convert to Version objects and filter
      var versions = records.compactMap { recordInfo -> Version? in
        guard let version = createVersion(from: recordInfo) else {
          return nil
        }

        // Apply status filter
        if let status, version.status != status {
          return nil
        }

        // Apply prerelease filter
        if !includePrerelease, version.prerelease != nil {
          return nil
        }

        return version
      }

      // Sort by version number (descending)
      versions.sort(by: >)

      return versions
    } catch {
      if let cloudKitError = error as? CloudKitError {
        throw VersionServiceError.cloudKitError(cloudKitError)
      }
      throw VersionServiceError.unknown(error)
    }
  }

  /// Get a specific version by version string
  public func getVersion(_ versionString: String) async throws -> Version? {
    let versions = try await listVersions(limit: 1000)
    return versions.first { $0.version == versionString }
  }

  /// Update an existing version
  public func updateVersion(_ versionString: String, updates: VersionUpdates) async throws {
    // This will be implemented with modifyRecords operation
    throw VersionServiceError.notImplemented("Update operation will be implemented with modifyRecords")
  }

  /// Delete a version
  public func deleteVersion(_ versionString: String) async throws {
    // This will be implemented with modifyRecords operation
    throw VersionServiceError.notImplemented("Delete operation will be implemented with modifyRecords")
  }

  // MARK: Private

  private let configuration: BushelConfiguration
  private let cloudKitService: CloudKitService

  /// Map BushelConfiguration database to MistKit database
  private static func mapDatabase(_ database: BushelConfiguration.CloudKitDatabase) -> Database {
    switch database {
    case .public:
      return .public
    case .private:
      return .private
    case .shared:
      return .shared
    }
  }

  /// Create CloudKit fields from Version model
  private func createFields(from version: Version) -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "version": .string(version.version),
      "major": .int64(version.major),
      "minor": .int64(version.minor),
      "patch": .int64(version.patch),
      "releaseDate": .date(version.releaseDate),
      "releaseNotes": .string(version.releaseNotes),
      "status": .string(version.status.rawValue),
    ]

    if let buildNumber = version.buildNumber {
      fields["buildNumber"] = .string(buildNumber)
    }

    if let commitHash = version.commitHash {
      fields["commitHash"] = .string(commitHash)
    }

    if let prerelease = version.prerelease {
      fields["prerelease"] = .string(prerelease)
    }

    if let metadata = version.metadata {
      // Convert metadata dictionary to JSON string
      if let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
         let jsonString = String(data: jsonData, encoding: .utf8)
      {
        fields["metadata"] = .string(jsonString)
      }
    }

    return fields
  }

  /// Create Version model from CloudKit record
  private func createVersion(from recordInfo: RecordInfo) -> Version? {
    guard
      let versionString = recordInfo.fields["version"]?.stringValue,
      let majorValue = recordInfo.fields["major"]?.intValue,
      let minorValue = recordInfo.fields["minor"]?.intValue,
      let patchValue = recordInfo.fields["patch"]?.intValue,
      let releaseDate = recordInfo.fields["releaseDate"]?.timestampValue,
      let releaseNotes = recordInfo.fields["releaseNotes"]?.stringValue,
      let statusString = recordInfo.fields["status"]?.stringValue,
      let status = Version.ReleaseStatus(rawValue: statusString)
    else {
      return nil
    }

    let buildNumber = recordInfo.fields["buildNumber"]?.stringValue
    let commitHash = recordInfo.fields["commitHash"]?.stringValue
    let prerelease = recordInfo.fields["prerelease"]?.stringValue

    // Parse metadata JSON if present
    var metadata: [String: String]?
    if let metadataString = recordInfo.fields["metadata"]?.stringValue,
       let data = metadataString.data(using: .utf8),
       let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
    {
      metadata = dict
    }

    return Version(
      recordID: recordInfo.recordName,
      version: versionString,
      major: Int(majorValue),
      minor: Int(minorValue),
      patch: Int(patchValue),
      releaseDate: releaseDate,
      releaseNotes: releaseNotes,
      status: status,
      buildNumber: buildNumber,
      commitHash: commitHash,
      prerelease: prerelease,
      metadata: metadata
    )
  }
}

// MARK: - VersionUpdates

/// Struct for updating version fields
public struct VersionUpdates: Sendable {
  public var releaseNotes: String?
  public var status: Version.ReleaseStatus?
  public var buildNumber: String?

  public init(releaseNotes: String? = nil, status: Version.ReleaseStatus? = nil, buildNumber: String? = nil) {
    self.releaseNotes = releaseNotes
    self.status = status
    self.buildNumber = buildNumber
  }
}

// MARK: - VersionServiceError

public enum VersionServiceError: Error {
  case cloudKitError(CloudKitError)
  case versionNotFound(String)
  case invalidVersionFormat(String)
  case notImplemented(String)
  case unknown(Error)
}

// MARK: LocalizedError

extension VersionServiceError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case let .cloudKitError(error):
      return "CloudKit error: \(error.localizedDescription)"
    case let .versionNotFound(version):
      return "Version not found: \(version)"
    case let .invalidVersionFormat(version):
      return "Invalid version format: \(version)"
    case let .notImplemented(message):
      return "Not implemented: \(message)"
    case let .unknown(error):
      return "Unknown error: \(error.localizedDescription)"
    }
  }
}

// MARK: - FieldValue Extensions

extension FieldValue {
  var stringValue: String? {
    guard case let .string(value) = self else { return nil }
    return value
  }

  var intValue: Int64? {
    guard case let .int64(value) = self else { return nil }
    return Int64(value)
  }

  var timestampValue: Date? {
    guard case let .date(value) = self else { return nil }
    return value
  }
}
