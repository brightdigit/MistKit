//
//  FeedMetadataBuilder+NotModified.swift
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
  @Suite("Not Modified Metadata Tests")
  internal struct NotModifiedTests {
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

    // MARK: - Not Modified Metadata Tests

    @Test("Not modified metadata preserves feed data")
    internal func testNotModifiedPreservesFeedData() {
      let builder = CelestraCloudKit.FeedMetadataBuilder()
      let feed = createFeed(
        title: "Original Title",
        description: "Original Description",
        minUpdateInterval: 3_600
      )
      let response = createFetchResponse(
        feedData: nil,  // 304 response has no feed data
        etag: "updated-etag",
        lastModified: "Thu, 04 Jan 2024 00:00:00 GMT"
      )

      let metadata = builder.buildNotModifiedMetadata(
        feed: feed,
        response: response,
        totalAttempts: 11
      )

      // Feed data should be preserved
      #expect(metadata.title == "Original Title")
      #expect(metadata.description == "Original Description")
      #expect(metadata.minUpdateInterval == 3_600)

      // HTTP headers updated from response
      #expect(metadata.etag == "updated-etag")
      #expect(metadata.lastModified == "Thu, 04 Jan 2024 00:00:00 GMT")
    }

    @Test("Not modified metadata updates HTTP headers if provided")
    internal func testNotModifiedUpdatesHTTPHeaders() {
      let builder = CelestraCloudKit.FeedMetadataBuilder()
      let feed = createFeed(
        etag: "old-etag",
        lastModified: "Old-Date"
      )
      let response = createFetchResponse(
        feedData: nil,
        etag: "new-etag",
        lastModified: "New-Date"
      )

      let metadata = builder.buildNotModifiedMetadata(
        feed: feed,
        response: response,
        totalAttempts: 11
      )

      #expect(metadata.etag == "new-etag")
      #expect(metadata.lastModified == "New-Date")
    }

    @Test("Not modified metadata keeps existing headers if none provided")
    internal func testNotModifiedKeepsExistingHeadersIfNoneProvided() {
      let builder = CelestraCloudKit.FeedMetadataBuilder()
      let feed = createFeed(
        etag: "existing-etag",
        lastModified: "existing-date"
      )
      let response = createFetchResponse(
        feedData: nil,
        etag: nil,
        lastModified: nil
      )

      let metadata = builder.buildNotModifiedMetadata(
        feed: feed,
        response: response,
        totalAttempts: 11
      )

      #expect(metadata.etag == "existing-etag")
      #expect(metadata.lastModified == "existing-date")
    }

    @Test("Not modified counts as successful attempt")
    internal func testNotModifiedCountsAsSuccess() {
      let builder = CelestraCloudKit.FeedMetadataBuilder()
      let feed = createFeed(
        successfulAttempts: 10,
        failureCount: 3
      )
      let response = createFetchResponse(feedData: nil)

      let metadata = builder.buildNotModifiedMetadata(
        feed: feed,
        response: response,
        totalAttempts: 14
      )

      #expect(metadata.successfulAttempts == 11)  // 10 + 1
      #expect(metadata.failureCount == 0)  // Reset on success
    }
  }
}
