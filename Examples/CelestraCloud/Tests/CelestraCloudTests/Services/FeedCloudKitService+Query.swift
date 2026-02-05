//
//  FeedCloudKitService+Query.swift
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

import CelestraKit
import Foundation
import MistKit
import Testing

@testable import CelestraCloudKit

extension FeedCloudKitService {
  @Suite("FeedCloudKitService Query Operations")
  internal struct QueryTests {
    // MARK: - Test Fixtures

    private func createMockRecordInfo(
      recordName: String = "test-record",
      fields: [String: FieldValue] = [:]
    ) -> RecordInfo {
      RecordInfo(
        recordName: recordName,
        recordType: "Feed",
        recordChangeTag: "tag-123",
        fields: fields
      )
    }

    private func createTestFeed() -> Feed {
      Feed(
        recordName: nil,
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        description: "A test feed",
        isFeatured: false,
        isVerified: true,
        subscriberCount: 100,
        totalAttempts: 5,
        successfulAttempts: 4,
        lastAttempted: Date(timeIntervalSince1970: 1_000_000),
        isActive: true,
        etag: "etag-123",
        lastModified: "Mon, 01 Jan 2024 00:00:00 GMT",
        failureCount: 1,
        minUpdateInterval: 3_600
      )
    }

    // MARK: - queryFeeds Tests

    @Test("queryFeeds returns feeds from query results")
    internal func testQueryFeedsReturnsFeeds() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.FeedCloudKitService(recordOperator: mock)

      let feedFields: [String: FieldValue] = [
        "feedURL": .string("https://example.com/feed.xml"),
        "title": .string("Test Feed"),
        "isActive": .int64(1),
        "isFeatured": .int64(0),
        "isVerified": .int64(1),
        "subscriberCount": .int64(50),
        "totalAttempts": .int64(10),
        "successfulAttempts": .int64(9),
        "failureCount": .int64(1),
      ]
      let mockRecord = createMockRecordInfo(recordName: "feed-1", fields: feedFields)
      mock.queryRecordsResult = .success([mockRecord])

      let feeds = try await service.queryFeeds()

      #expect(feeds.count == 1)
      #expect(feeds[0].feedURL == "https://example.com/feed.xml")
      #expect(feeds[0].title == "Test Feed")
      #expect(feeds[0].recordName == "feed-1")
    }

    @Test("queryFeeds applies date filter when provided")
    internal func testQueryFeedsAppliesDateFilter() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.FeedCloudKitService(recordOperator: mock)
      let cutoffDate = Date(timeIntervalSince1970: 1_000_000)

      mock.queryRecordsResult = .success([])

      _ = try await service.queryFeeds(lastAttemptedBefore: cutoffDate)

      #expect(mock.queryCalls.count == 1)
      let call = mock.queryCalls[0]
      #expect(call.recordType == "Feed")
      #expect(call.filters != nil)
      #expect(call.filters?.count == 1)
    }

    @Test("queryFeeds applies popularity filter when provided")
    internal func testQueryFeedsAppliesPopularityFilter() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.FeedCloudKitService(recordOperator: mock)

      mock.queryRecordsResult = .success([])

      _ = try await service.queryFeeds(minPopularity: 100)

      #expect(mock.queryCalls.count == 1)
      let call = mock.queryCalls[0]
      #expect(call.filters != nil)
      #expect(call.filters?.count == 1)
    }

    @Test("queryFeeds applies both filters when provided")
    internal func testQueryFeedsAppliesBothFilters() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.FeedCloudKitService(recordOperator: mock)
      let cutoffDate = Date(timeIntervalSince1970: 1_000_000)

      mock.queryRecordsResult = .success([])

      _ = try await service.queryFeeds(lastAttemptedBefore: cutoffDate, minPopularity: 50)

      #expect(mock.queryCalls.count == 1)
      let call = mock.queryCalls[0]
      #expect(call.filters?.count == 2)
    }

    @Test("queryFeeds respects limit parameter")
    internal func testQueryFeedsRespectsLimit() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.FeedCloudKitService(recordOperator: mock)

      mock.queryRecordsResult = .success([])

      _ = try await service.queryFeeds(limit: 50)

      #expect(mock.queryCalls.count == 1)
      #expect(mock.queryCalls[0].limit == 50)
    }
  }
}
