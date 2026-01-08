//
//  ArticleCloudKitService+Query.swift
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

extension ArticleCloudKitService {
  @Suite("ArticleCloudKitService Query Tests")
  internal struct QueryTests {
    // MARK: - Test Fixtures

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

    private func createTestArticle(
      recordName: String? = nil,
      guid: String = "test-guid"
    ) -> Article {
      Article(
        recordName: recordName,
        feedRecordName: "feed-123",
        guid: guid,
        title: "Test Article",
        url: "https://example.com/article",
        fetchedAt: Date(timeIntervalSince1970: 1_000_000),
        ttlDays: 30
      )
    }

    private func createArticleRecordFields(guid: String = "test-guid") -> [String: FieldValue] {
      [
        "feedRecordName": .string("feed-123"),
        "guid": .string(guid),
        "title": .string("Test Article"),
        "url": .string("https://example.com/article"),
        "fetchedTimestamp": .date(Date(timeIntervalSince1970: 1_000_000)),
        "expiresTimestamp": .date(Date(timeIntervalSince1970: 1_000_000 + 30 * 24 * 60 * 60)),
        "contentHash": .string("abc123"),
      ]
    }

    // MARK: - queryArticlesByGUIDs Tests

    @Test("queryArticlesByGUIDs returns empty array for empty GUIDs")
    internal func testQueryArticlesByGUIDsEmptyGUIDs() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)

      let result = try await service.queryArticlesByGUIDs([])

      #expect(result.isEmpty)
      #expect(mock.queryCalls.isEmpty)
    }

    @Test("queryArticlesByGUIDs queries with GUID filter")
    internal func testQueryArticlesByGUIDsFiltersArticles() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)

      let fields = createArticleRecordFields(guid: "guid-1")
      mock.queryRecordsResult = .success([
        createMockRecordInfo(recordName: "article-1", fields: fields)
      ])

      let result = try await service.queryArticlesByGUIDs(["guid-1", "guid-2"])

      #expect(result.count == 1)
      #expect(mock.queryCalls.count == 1)
      #expect(mock.queryCalls[0].recordType == "Article")
      #expect(mock.queryCalls[0].filters != nil)
    }

    @Test("queryArticlesByGUIDs applies feedRecordName filter when provided")
    internal func testQueryArticlesByGUIDsFiltersByFeed() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)

      // Mock returns 2 articles: one matching feed, one not
      let matchingFields = createArticleRecordFields(guid: "guid-1")
      let nonMatchingFields = createArticleRecordFields(guid: "guid-2")
        .merging(["feedRecordName": .string("other-feed")]) { _, new in new }

      mock.queryRecordsResult = .success([
        createMockRecordInfo(recordName: "article-1", fields: matchingFields),
        createMockRecordInfo(recordName: "article-2", fields: nonMatchingFields)
      ])

      let result = try await service.queryArticlesByGUIDs(
        ["guid-1", "guid-2"],
        feedRecordName: "feed-123"
      )

      // Verify CloudKit query behavior
      #expect(mock.queryCalls.count == 1)
      // Should have 1 filter (GUID only), feedRecordName filtered in-memory
      #expect(mock.queryCalls[0].filters?.count == 1)

      // Verify in-memory filtering works
      #expect(result.count == 1)  // Only matching article returned
      #expect(result[0].guid == "guid-1")
      #expect(result[0].feedRecordName == "feed-123")
    }

    @Test("queryArticlesByGUIDs batches large GUID lists")
    internal func testQueryArticlesByGUIDsBatchesLargeGUIDLists() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)

      // Create 200 GUIDs to trigger batching (batch size is 150)
      let guids = (0..<200).map { "guid-\($0)" }
      mock.queryRecordsResult = .success([])

      _ = try await service.queryArticlesByGUIDs(guids)

      // Should have made 2 query calls (150 + 50)
      #expect(mock.queryCalls.count == 2)
    }
  }
}
