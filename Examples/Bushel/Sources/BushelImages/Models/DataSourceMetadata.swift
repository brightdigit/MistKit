//  DataSourceMetadata.swift
//  Created by Claude Code

public import Foundation
public import MistKit

/// Metadata about when a data source was last fetched and updated
public struct DataSourceMetadata: Codable, Sendable {
  // MARK: Lifecycle

  public init(
    sourceName: String,
    recordTypeName: String,
    lastFetchedAt: Date,
    sourceUpdatedAt: Date? = nil,
    recordCount: Int = 0,
    fetchDurationSeconds: Double = 0,
    lastError: String? = nil
  ) {
    self.sourceName = sourceName
    self.recordTypeName = recordTypeName
    self.lastFetchedAt = lastFetchedAt
    self.sourceUpdatedAt = sourceUpdatedAt
    self.recordCount = recordCount
    self.fetchDurationSeconds = fetchDurationSeconds
    self.lastError = lastError
  }

  // MARK: Public

  /// The name of the data source (e.g., "appledb.dev", "ipsw.me")
  public let sourceName: String

  /// The type of records this source provides (e.g., "RestoreImage", "XcodeVersion")
  public let recordTypeName: String

  /// When we last fetched data from this source
  public let lastFetchedAt: Date

  /// When the source last updated its data (from HTTP Last-Modified or API metadata)
  public let sourceUpdatedAt: Date?

  /// Number of records retrieved from this source
  public let recordCount: Int

  /// How long the fetch operation took in seconds
  public let fetchDurationSeconds: Double

  /// Last error message if the fetch failed
  public let lastError: String?

  /// CloudKit record name for this metadata entry
  public var recordName: String {
    "metadata-\(sourceName)-\(recordTypeName)"
  }
}

// MARK: - CloudKitRecord Conformance

extension DataSourceMetadata: CloudKitRecord {
  public static var cloudKitRecordType: String { "DataSourceMetadata" }

  public func toCloudKitFields() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "sourceName": .string(sourceName),
      "recordTypeName": .string(recordTypeName),
      "lastFetchedAt": .date(lastFetchedAt),
      "recordCount": .int64(recordCount),
      "fetchDurationSeconds": .double(fetchDurationSeconds)
    ]

    // Optional fields
    if let sourceUpdatedAt {
      fields["sourceUpdatedAt"] = .date(sourceUpdatedAt)
    }

    if let lastError {
      fields["lastError"] = .string(lastError)
    }

    return fields
  }

  public static func from(recordInfo: RecordInfo) -> Self? {
    guard let sourceName = recordInfo.fields["sourceName"]?.stringValue,
          let recordTypeName = recordInfo.fields["recordTypeName"]?.stringValue,
          let lastFetchedAt = recordInfo.fields["lastFetchedAt"]?.dateValue
    else {
      return nil
    }

    return DataSourceMetadata(
      sourceName: sourceName,
      recordTypeName: recordTypeName,
      lastFetchedAt: lastFetchedAt,
      sourceUpdatedAt: recordInfo.fields["sourceUpdatedAt"]?.dateValue,
      recordCount: recordInfo.fields["recordCount"]?.intValue ?? 0,
      fetchDurationSeconds: recordInfo.fields["fetchDurationSeconds"]?.doubleValue ?? 0,
      lastError: recordInfo.fields["lastError"]?.stringValue
    )
  }

  public static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let sourceName = recordInfo.fields["sourceName"]?.stringValue ?? "Unknown"
    let recordTypeName = recordInfo.fields["recordTypeName"]?.stringValue ?? "Unknown"
    let lastFetchedAt = recordInfo.fields["lastFetchedAt"]?.dateValue
    let recordCount = recordInfo.fields["recordCount"]?.intValue ?? 0

    let dateStr = lastFetchedAt.map { formatDate($0) } ?? "Unknown"

    var output = "\n  \(sourceName) → \(recordTypeName)\n"
    output += "    Last fetched: \(dateStr) | Records: \(recordCount)"
    return output
  }

  private static func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
