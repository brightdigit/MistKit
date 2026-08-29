//
//  FeedUpdateResultTests.swift
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

@testable import CelestraCloud
@testable import CelestraCloudKit

@Suite("FeedUpdateResult Resolving Tests")
internal struct FeedUpdateResultTests {
  @Test("Successful article sync preserves metadata result")
  internal func testResolvingPreservesMetadataOnCleanSync() {
    let syncResult = ArticleSyncResult(
      created: BatchOperationResult(),
      updated: BatchOperationResult()
    )
    let metadataResult = FeedUpdateResult.success(articlesCreated: 3, articlesUpdated: 1)

    let resolved = FeedUpdateResult.resolving(
      syncResult: syncResult,
      metadataResult: metadataResult
    )

    #expect(resolved == metadataResult)
  }

  @Test("Article create failures become an error even when metadata write succeeded")
  internal func testResolvingErrorsOnCreateFailures() {
    var created = BatchOperationResult()
    created.appendFailure(article: Self.testArticle, error: Self.testError)
    let syncResult = ArticleSyncResult(created: created, updated: BatchOperationResult())
    let metadataResult = FeedUpdateResult.success(articlesCreated: 0, articlesUpdated: 0)

    let resolved = FeedUpdateResult.resolving(
      syncResult: syncResult,
      metadataResult: metadataResult
    )

    guard case .error(let message) = resolved else {
      Issue.record("Expected .error, got \(resolved)")
      return
    }
    #expect(message.contains("1 failures"))
    #expect(message.contains("created: 1"))
    #expect(message.contains("updated: 0"))
  }

  @Test("Article update failures become an error even when metadata write succeeded")
  internal func testResolvingErrorsOnUpdateFailures() {
    var updated = BatchOperationResult()
    updated.appendFailure(article: Self.testArticle, error: Self.testError)
    let syncResult = ArticleSyncResult(created: BatchOperationResult(), updated: updated)
    let metadataResult = FeedUpdateResult.success(articlesCreated: 2, articlesUpdated: 0)

    let resolved = FeedUpdateResult.resolving(
      syncResult: syncResult,
      metadataResult: metadataResult
    )

    guard case .error(let message) = resolved else {
      Issue.record("Expected .error, got \(resolved)")
      return
    }
    #expect(message.contains("1 failures"))
    #expect(message.contains("created: 0"))
    #expect(message.contains("updated: 1"))
  }

  @Test("Article failures take precedence over a metadata-write error")
  internal func testResolvingPrefersArticleFailuresOverMetadataError() {
    var created = BatchOperationResult()
    created.appendFailure(article: Self.testArticle, error: Self.testError)
    let syncResult = ArticleSyncResult(created: created, updated: BatchOperationResult())
    let metadataResult = FeedUpdateResult.error(message: "Failed to update feed metadata")

    let resolved = FeedUpdateResult.resolving(
      syncResult: syncResult,
      metadataResult: metadataResult
    )

    guard case .error(let message) = resolved else {
      Issue.record("Expected .error, got \(resolved)")
      return
    }
    #expect(message.contains("Article sync had"))
    #expect(!message.contains("Failed to update feed metadata"))
  }

  // MARK: - Fixtures

  private static let testError = NSError(domain: "Test", code: 1)

  private static let testArticle = Article(
    recordName: "article-1",
    recordChangeTag: nil,
    feedRecordName: "feed-1",
    guid: "guid-1",
    title: "Test",
    url: "https://example.com/a",
    fetchedAt: Date(),
    ttlDays: 30
  )
}
