//
//  ArticleCloudKitService+Mutations.swift
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
  @Suite("ArticleCloudKitService Mutations Tests")
  internal struct MutationsTests {
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

    // MARK: - createArticles Tests

    @Test("createArticles returns empty result for empty input")
    internal func testCreateArticlesEmptyArray() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)

      let result = try await service.createArticles([])

      #expect(result.totalProcessed == 0)
      #expect(mock.modifyCalls.isEmpty)
    }

    @Test("createArticles creates articles with correct operations")
    internal func testCreateArticlesCreatesOperations() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)
      let articles = [createTestArticle(guid: "guid-1"), createTestArticle(guid: "guid-2")]

      let mockRecords = [
        createMockRecordInfo(recordName: "new-1"),
        createMockRecordInfo(recordName: "new-2"),
      ]
      mock.modifyRecordsResult = .success(mockRecords)

      let result = try await service.createArticles(articles)

      #expect(result.successCount == 2)
      #expect(mock.modifyCalls.count == 1)

      let operations = mock.modifyCalls[0].operations
      #expect(operations.count == 2)
      #expect(operations[0].operationType == .create)
      #expect(operations[0].recordType == "Article")
    }

    @Test("createArticles batches large article lists")
    internal func testCreateArticlesBatchesCorrectly() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)

      // Create 25 articles to trigger batching (batch size is 10)
      let articles = (0..<25).map { createTestArticle(guid: "guid-\($0)") }
      mock.modifyRecordsResult = .success([createMockRecordInfo()])

      _ = try await service.createArticles(articles)

      // Should have made 3 modify calls (10 + 10 + 5)
      #expect(mock.modifyCalls.count == 3)
    }

    // MARK: - updateArticles Tests

    @Test("updateArticles returns empty result for empty input")
    internal func testUpdateArticlesEmptyArray() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)

      let result = try await service.updateArticles([])

      #expect(result.totalProcessed == 0)
      #expect(mock.modifyCalls.isEmpty)
    }

    @Test("updateArticles skips articles without recordName")
    internal func testUpdateArticlesSkipsArticlesWithoutRecordName() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)

      // Article without recordName
      let article = createTestArticle(recordName: nil)

      let result = try await service.updateArticles([article])

      #expect(result.totalProcessed == 0)
      #expect(mock.modifyCalls.isEmpty)
    }

    @Test("updateArticles creates update operations for valid articles")
    internal func testUpdateArticlesCreatesOperations() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)

      let article = createTestArticle(recordName: "existing-article")
      mock.modifyRecordsResult = .success([createMockRecordInfo(recordName: "existing-article")])

      let result = try await service.updateArticles([article])

      #expect(result.successCount == 1)
      #expect(mock.modifyCalls.count == 1)

      let operations = mock.modifyCalls[0].operations
      #expect(operations.count == 1)
      #expect(operations[0].operationType == .update)
      #expect(operations[0].recordName == "existing-article")
    }

    // MARK: - deleteAllArticles Tests

    @Test("deleteAllArticles deletes articles in batches")
    internal func testDeleteAllArticles() async throws {
      let mock = MockCloudKitRecordOperator()
      let service = CelestraCloudKit.ArticleCloudKitService(recordOperator: mock)

      let article1 = createMockRecordInfo(recordName: "article-1")
      let article2 = createMockRecordInfo(recordName: "article-2")

      mock.queryRecordsResult = .success([article1, article2])
      mock.modifyRecordsResult = .success([])

      try await service.deleteAllArticles()

      #expect(mock.queryCalls.count >= 1)
      #expect(mock.modifyCalls.count >= 1)

      if let modifyCall = mock.modifyCalls.first {
        for operation in modifyCall.operations {
          #expect(operation.operationType == .delete)
        }
      }
    }
  }
}
