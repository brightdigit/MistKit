//  DataSourceMetadata.swift
//  Created by Claude Code

import Foundation

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
