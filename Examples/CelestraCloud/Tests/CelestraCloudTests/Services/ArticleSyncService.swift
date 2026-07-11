//
//  ArticleSyncService.swift
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

internal import CelestraKit
internal import Foundation
internal import MistKit
internal import Testing

@testable import CelestraCloudKit

extension ArticleSyncService {
  @Suite("ArticleSyncService Sync Tests")
  internal struct SyncTests {
    // MARK: - Test Fixtures

    private func createFeedItem(
      guid: String,
      title: String = "Test Title",
      link: String = "https://example.com/article",
      description: String? = "Test description",
      content: String? = "Test content",
      author: String? = "Test Author",
      pubDate: Date? = Date(timeIntervalSince1970: 1_000_000)
    ) -> FeedItem {
      FeedItem(
        title: title,
        link: link,
        description: description,
        content: content,
        author: author,
        pubDate: pubDate,
        guid: guid
      )
    }

    private func createMockRecordInfo(
      recordName: String = "test-record",
      fields: [String: FieldValue] = [:]
    ) -> RecordInfo {
      RecordInfo(
        recordName: recordName,
        recordType: "Article",
        recordChangeTag: "tag-123",
        fields: fields
      )
    }

    private func createArticleRecordFields(
      guid: String = "test-guid",
      title: String = "Test Article"
    ) -> [String: FieldValue] {
      [
        "feedRecordName": .string("feed-123"),
        "guid": .string(guid),
        "title": .string(title),
        "url": .string("https://example.com/article"),
        "fetchedTimestamp": .date(Date(timeIntervalSince1970: 1_000_000)),
        "expiresTimestamp": .date(Date(timeIntervalSince1970: 1_000_000 + 30 * 24 * 60 * 60)),
        "contentHash": .string("abc123"),
      ]
    }

    private func makeService(
      _ mock: MockCloudKitRecordOperator
    ) -> ArticleSyncService {
      ArticleSyncService(
        articleService: CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)
      )
    }

    // MARK: - Deduplication Query Tests

    @Test("syncArticles queries existing articles scoped to the feed before mutating")
    internal func testSyncArticlesQueriesWithCombinedFilter() async throws {
      let mock = MockCloudKitRecordOperator()
      // No existing articles: every feed item is new.
      mock.queryRecordsResult = .success([])
      let sync = makeService(mock)

      let items = [
        createFeedItem(guid: "guid-1"),
        createFeedItem(guid: "guid-2"),
      ]

      _ = try await sync.syncArticles(items: items, feedRecordName: "feed-123")

      // The dedup query must run exactly once, targeting Article and combining the
      // IN("guid", …) + EQUALS("feedRecordName", …) filters. This guards against a
      // regression to the old workaround that stubbed existing articles to `[]`.
      #expect(mock.queryCalls.count == 1)
      #expect(mock.queryCalls[0].recordType == "Article")
      #expect(mock.queryCalls[0].filters?.count == 2)

      // Both items are new -> a single create batch, no update batch.
      #expect(mock.modifyCalls.count == 1)
    }

    @Test("syncArticles creates new and updates modified articles separately")
    internal func testSyncArticlesCreatesNewAndUpdatesModified() async throws {
      let mock = MockCloudKitRecordOperator()
      // Seed one existing article (recordName set so it is eligible for update).
      // Its content hash is title|url|guid, so a same-guid feed item with a
      // different title categorizes as *modified*.
      mock.queryRecordsResult = .success([
        createMockRecordInfo(
          recordName: "article-existing",
          fields: createArticleRecordFields(guid: "guid-existing", title: "Original Title")
        )
      ])
      let sync = makeService(mock)

      let items = [
        createFeedItem(guid: "guid-new"),
        createFeedItem(guid: "guid-existing", title: "Changed Title"),
      ]

      _ = try await sync.syncArticles(items: items, feedRecordName: "feed-123")

      // Dedup query still runs once, scoped to the feed.
      #expect(mock.queryCalls.count == 1)
      #expect(mock.queryCalls[0].filters?.count == 2)

      // One create batch (guid-new) + one update batch (guid-existing).
      #expect(mock.modifyCalls.count == 2)
    }

    @Test("syncArticles issues no mutations when there are no items")
    internal func testSyncArticlesWithNoItems() async throws {
      let mock = MockCloudKitRecordOperator()
      let sync = makeService(mock)

      _ = try await sync.syncArticles(items: [], feedRecordName: "feed-123")

      // Empty GUID list short-circuits the query, and there is nothing to create/update.
      #expect(mock.queryCalls.isEmpty)
      #expect(mock.modifyCalls.isEmpty)
    }
  }
}
