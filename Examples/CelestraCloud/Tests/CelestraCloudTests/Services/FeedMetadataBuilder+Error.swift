//
//  FeedMetadataBuilder+Error.swift
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
import Testing

@testable import CelestraCloudKit

extension FeedMetadataBuilder {
  @Suite("Error Metadata Tests")
  internal struct ErrorTests {
    // MARK: - Test Fixtures

    private func createFeed(
      title: String = "Original Title",
      description: String? = "Original Description",
      etag: String? = "original-etag",
      lastModified: String? = "Mon, 01 Jan 2024 00:00:00 GMT",
      minUpdateInterval: TimeInterval? = 3_600,
      totalAttempts: Int64 = 10,
      successfulAttempts: Int64 = 8,
      failureCount: Int64 = 2
    ) -> Feed {
      Feed(
        recordName: "feed-123",
        feedURL: "https://example.com/feed.xml",
        title: title,
        description: description,
        totalAttempts: totalAttempts,
        successfulAttempts: successfulAttempts,
        etag: etag,
        lastModified: lastModified,
        failureCount: failureCount,
        minUpdateInterval: minUpdateInterval
      )
    }

    private func createFeedData(
      title: String = "New Feed Title",
      description: String? = "New Feed Description",
      minUpdateInterval: TimeInterval? = 7_200
    ) -> FeedData {
      FeedData(
        title: title,
        description: description,
        items: [],  // Not used in metadata building
        minUpdateInterval: minUpdateInterval
      )
    }

    private func createFetchResponse(
      feedData: FeedData? = nil,
      etag: String? = "new-etag",
      lastModified: String? = "Tue, 02 Jan 2024 00:00:00 GMT"
    ) -> FetchResponse {
      FetchResponse(
        feedData: feedData,
        lastModified: lastModified,
        etag: etag,
        wasModified: feedData != nil
      )
    }

    // MARK: - Error Metadata Tests

    @Test("Error metadata preserves all feed data")
    internal func testErrorMetadataPreservesAllData() {
      let builder = CelestraCloudKit.FeedMetadataBuilder()
      let feed = createFeed(
        title: "Feed Title",
        description: "Feed Description",
        etag: "feed-etag",
        lastModified: "feed-date",
        minUpdateInterval: 1_800
      )

      let metadata = builder.buildErrorMetadata(
        feed: feed,
        totalAttempts: 11
      )

      // Everything preserved
      #expect(metadata.title == "Feed Title")
      #expect(metadata.description == "Feed Description")
      #expect(metadata.etag == "feed-etag")
      #expect(metadata.lastModified == "feed-date")
      #expect(metadata.minUpdateInterval == 1_800)
    }

    @Test("Error metadata increments failure count")
    internal func testErrorIncrementsFailureCount() {
      let builder = CelestraCloudKit.FeedMetadataBuilder()
      let feed = createFeed(
        successfulAttempts: 8,
        failureCount: 2
      )

      let metadata = builder.buildErrorMetadata(
        feed: feed,
        totalAttempts: 11
      )

      #expect(metadata.successfulAttempts == 8)  // No change on error
      #expect(metadata.failureCount == 3)  // 2 + 1
      #expect(metadata.totalAttempts == 11)
    }
  }
}
