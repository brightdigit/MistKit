//
//  UpdateReport.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

/// Comprehensive report of feed update operations for JSON export
public struct UpdateReport: Codable, Sendable {
  // MARK: - Subtypes

  /// Summary statistics for the update operation
  public struct Summary: Codable, Sendable {
    // MARK: - Properties

    /// Total number of feeds processed.
    public let totalFeeds: Int
    /// Number of feeds that updated successfully.
    public let successCount: Int
    /// Number of feeds that encountered errors.
    public let errorCount: Int
    /// Number of feeds that were skipped.
    public let skippedCount: Int
    /// Number of feeds that returned not-modified responses.
    public let notModifiedCount: Int
    /// Total number of articles created across all feeds.
    public let articlesCreated: Int
    /// Total number of articles updated across all feeds.
    public let articlesUpdated: Int
    /// Percentage of feeds that updated successfully (0-100).
    public let successRate: Double

    // MARK: - Lifecycle

    /// Creates a new summary with the given statistics.
    public init(
      totalFeeds: Int,
      successCount: Int,
      errorCount: Int,
      skippedCount: Int,
      notModifiedCount: Int,
      articlesCreated: Int,
      articlesUpdated: Int
    ) {
      self.totalFeeds = totalFeeds
      self.successCount = successCount
      self.errorCount = errorCount
      self.skippedCount = skippedCount
      self.notModifiedCount = notModifiedCount
      self.articlesCreated = articlesCreated
      self.articlesUpdated = articlesUpdated
      self.successRate =
        totalFeeds > 0
        ? Double(successCount) / Double(totalFeeds) * 100
        : 0
    }
  }

  /// Configuration snapshot used for an update run.
  public struct UpdateConfiguration: Codable, Sendable {
    // MARK: - Properties

    /// Delay in seconds between feed updates.
    public let delay: Double
    /// Whether robots.txt checking was skipped.
    public let skipRobotsCheck: Bool
    /// Maximum number of consecutive failures before skipping a feed.
    public let maxFailures: Int?
    /// Minimum subscriber count required to update a feed.
    public let minPopularity: Int?
    /// Maximum number of feeds to process.
    public let limit: Int?
    /// CloudKit environment used for this update.
    public let environment: String

    // MARK: - Lifecycle

    /// Creates a new configuration snapshot.
    public init(
      delay: Double,
      skipRobotsCheck: Bool,
      maxFailures: Int?,
      minPopularity: Int?,
      limit: Int?,
      environment: String
    ) {
      self.delay = delay
      self.skipRobotsCheck = skipRobotsCheck
      self.maxFailures = maxFailures
      self.minPopularity = minPopularity
      self.limit = limit
      self.environment = environment
    }
  }

  /// Result for a single feed update.
  public struct FeedResult: Codable, Sendable {
    /// Outcome status for a feed update.
    public enum Status: String, Codable, Sendable {
      case success
      case error
      case skipped
      case notModified
    }

    // MARK: - Properties

    /// URL of the feed that was processed.
    public let feedURL: String
    /// CloudKit record name for this feed.
    public let recordName: String
    /// Outcome status for this feed update.
    public let status: Status
    /// Number of new articles created for this feed.
    public let articlesCreated: Int
    /// Number of existing articles updated for this feed.
    public let articlesUpdated: Int
    /// Time in seconds taken to process this feed.
    public let duration: TimeInterval
    /// Error message if the feed update failed, nil otherwise.
    public let error: String?

    // MARK: - Lifecycle

    /// Creates a new feed result.
    public init(
      feedURL: String,
      recordName: String,
      status: Status,
      articlesCreated: Int,
      articlesUpdated: Int,
      duration: TimeInterval,
      error: String? = nil
    ) {
      self.feedURL = feedURL
      self.recordName = recordName
      self.status = status
      self.articlesCreated = articlesCreated
      self.articlesUpdated = articlesUpdated
      self.duration = duration
      self.error = error
    }
  }

  // MARK: - Properties

  /// When the update started
  public let startTime: Date
  /// When the update completed
  public let endTime: Date
  /// Total duration in seconds
  public let duration: TimeInterval

  /// Configuration used for this update
  public let configuration: UpdateConfiguration
  /// Summary statistics
  public let summary: Summary
  /// Detailed per-feed results
  public let feeds: [FeedResult]

  // MARK: - Lifecycle

  /// Creates a new update report.
  public init(
    startTime: Date,
    endTime: Date,
    configuration: UpdateConfiguration,
    summary: Summary,
    feeds: [FeedResult]
  ) {
    self.startTime = startTime
    self.endTime = endTime
    self.duration = endTime.timeIntervalSince(startTime)
    self.configuration = configuration
    self.summary = summary
    self.feeds = feeds
  }
}
