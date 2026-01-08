//
//  UpdateReport.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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
  /// When the update started
  public let startTime: Date

  /// When the update completed
  public let endTime: Date

  /// Total duration in seconds
  public var duration: TimeInterval {
    endTime.timeIntervalSince(startTime)
  }

  /// Configuration used for this update
  public let configuration: UpdateConfiguration

  /// Summary statistics
  public let summary: Summary

  /// Detailed per-feed results
  public let feeds: [FeedResult]

  /// Summary statistics for the update operation
  public struct Summary: Codable, Sendable {
    public let totalFeeds: Int
    public let successCount: Int
    public let errorCount: Int
    public let skippedCount: Int
    public let notModifiedCount: Int
    public let articlesCreated: Int
    public let articlesUpdated: Int

    public var successRate: Double {
      guard totalFeeds > 0 else { return 0 }
      return Double(successCount) / Double(totalFeeds) * 100
    }

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
    }
  }

  /// Configuration snapshot
  public struct UpdateConfiguration: Codable, Sendable {
    public let delay: Double
    public let skipRobotsCheck: Bool
    public let maxFailures: Int?
    public let minPopularity: Int?
    public let limit: Int?
    public let environment: String

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

  /// Result for a single feed update
  public struct FeedResult: Codable, Sendable {
    public let feedURL: String
    public let recordName: String
    public let status: String  // "success", "error", "skipped", "notModified"
    public let articlesCreated: Int
    public let articlesUpdated: Int
    public let duration: TimeInterval
    public let error: String?

    public init(
      feedURL: String,
      recordName: String,
      status: String,
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

  public init(
    startTime: Date,
    endTime: Date,
    configuration: UpdateConfiguration,
    summary: Summary,
    feeds: [FeedResult]
  ) {
    self.startTime = startTime
    self.endTime = endTime
    self.configuration = configuration
    self.summary = summary
    self.feeds = feeds
  }
}

// MARK: - JSON Output

extension UpdateReport {
  /// Write the report to a JSON file
  public func writeJSON(to path: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    let data = try encoder.encode(self)
    try data.write(to: URL(fileURLWithPath: path))
  }
}
