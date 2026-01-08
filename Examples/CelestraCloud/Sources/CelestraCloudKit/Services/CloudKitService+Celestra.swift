//
//  CloudKitService+Celestra.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import CelestraKit
public import Foundation
public import Logging
public import MistKit

/// CloudKit service extensions for Celestra operations
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  // MARK: - Feed Operations

  /// Create a new Feed record
  public func createFeed(_ feed: Feed) async throws -> RecordInfo {
    CelestraLogger.cloudkit.info("📝 Creating feed: \(feed.feedURL)")

    let operation = RecordOperation.create(
      recordType: "Feed",
      recordName: UUID().uuidString,
      fields: feed.toFieldsDict()
    )
    let results = try await self.modifyRecords([operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Update an existing Feed record
  public func updateFeed(recordName: String, feed: Feed) async throws -> RecordInfo {
    CelestraLogger.cloudkit.info("🔄 Updating feed: \(feed.feedURL)")

    let operation = RecordOperation.update(
      recordType: "Feed",
      recordName: recordName,
      fields: feed.toFieldsDict(),
      recordChangeTag: feed.recordChangeTag
    )
    let results = try await self.modifyRecords([operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Query feeds with optional filters (demonstrates QueryFilter and QuerySort)
  public func queryFeeds(
    lastAttemptedBefore: Date? = nil,
    minPopularity: Int? = nil,
    limit: Int = 100
  ) async throws -> [Feed] {
    var filters: [QueryFilter] = []

    // Filter by last attempted date if provided
    if let cutoff = lastAttemptedBefore {
      filters.append(.lessThan("attemptedTimestamp", .date(cutoff)))
    }

    // Filter by minimum popularity if provided
    if let minPop = minPopularity {
      filters.append(.greaterThanOrEquals("subscriberCount", .int64(minPop)))
    }

    // Query with filters and sort by feedURL (always queryable+sortable)
    let records = try await queryRecords(
      recordType: "Feed",
      filters: filters.isEmpty ? nil : filters,
      sortBy: [.ascending("feedURL")],  // Use feedURL since usageCount might have issues
      limit: limit
    )

    do {
      return try records.map { try Feed(from: $0) }
    } catch {
      CelestraLogger.errors.error("Failed to convert Feed records: \(error)")
      throw error
    }
  }

  // MARK: - Cleanup Operations

  /// Delete all Feed records (paginated)
  public func deleteAllFeeds() async throws {
    var totalDeleted = 0

    while true {
      let feeds = try await queryRecords(
        recordType: "Feed",
        limit: 200,
        desiredKeys: ["___recordID"]
      )

      guard !feeds.isEmpty else {
        break  // No more feeds to delete
      }

      let operations = feeds.map { record in
        RecordOperation.delete(
          recordType: "Feed",
          recordName: record.recordName,
          recordChangeTag: record.recordChangeTag
        )
      }

      _ = try await modifyRecords(operations)
      totalDeleted += feeds.count

      CelestraLogger.operations.info("Deleted \(feeds.count) feeds (total: \(totalDeleted))")

      // If we got fewer than the limit, we're done
      if feeds.count < 200 {
        break
      }
    }

    CelestraLogger.cloudkit.info("✅ Deleted \(totalDeleted) total feeds")
  }
}
