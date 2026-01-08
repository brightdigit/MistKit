//
//  FeedMetadataBuilder+Success.swift
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
  @Suite("Success Metadata Tests")
  internal struct SuccessTests {
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

    // MARK: - Success Metadata Tests

    @Test("Success metadata uses new feed data")
    internal func testSuccessMetadataUsesNewData() {
      let builder = CelestraCloudKit.FeedMetadataBuilder()
      let feed = createFeed()
      let feedData = createFeedData(
        title: "Updated Title",
        description: "Updated Description",
        minUpdateInterval: 7_200
      )
      let response = createFetchResponse(
        feedData: feedData,
        etag: "new-etag-123",
        lastModified: "Wed, 03 Jan 2024 12:00:00 GMT"
      )

      let metadata = builder.buildSuccessMetadata(
        feedData: feedData,
        response: response,
        feed: feed,
        totalAttempts: 11
      )

      // New feed data should override
      #expect(metadata.title == "Updated Title")
      #expect(metadata.description == "Updated Description")
      #expect(metadata.minUpdateInterval == 7_200)

      // HTTP headers from response
      #expect(metadata.etag == "new-etag-123")
      #expect(metadata.lastModified == "Wed, 03 Jan 2024 12:00:00 GMT")

      // Counters
      #expect(metadata.totalAttempts == 11)
      #expect(metadata.successfulAttempts == 9)  // 8 + 1
      #expect(metadata.failureCount == 0)  // Reset on success
    }

    @Test("Success metadata increments successful attempts")
    internal func testSuccessIncrementsSuccessfulAttempts() {
      let builder = CelestraCloudKit.FeedMetadataBuilder()
      let feed = createFeed(successfulAttempts: 5)
      let feedData = createFeedData()
      let response = createFetchResponse(feedData: feedData)

      let metadata = builder.buildSuccessMetadata(
        feedData: feedData,
        response: response,
        feed: feed,
        totalAttempts: 11
      )

      #expect(metadata.successfulAttempts == 6)  // 5 + 1
    }

    @Test("Success metadata resets failure count")
    internal func testSuccessResetsFailureCount() {
      let builder = CelestraCloudKit.FeedMetadataBuilder()
      let feed = createFeed(failureCount: 5)
      let feedData = createFeedData()
      let response = createFetchResponse(feedData: feedData)

      let metadata = builder.buildSuccessMetadata(
        feedData: feedData,
        response: response,
        feed: feed,
        totalAttempts: 11
      )

      #expect(metadata.failureCount == 0)  // Always reset on success
    }
  }
}
