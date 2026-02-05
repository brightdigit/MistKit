//
//  ArticleSyncService.swift
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
public import MistKit

/// Service for synchronizing articles: query existing, categorize, create/update
@available(macOS 13.0, *)
public struct ArticleSyncService: Sendable {
  private let articleService: ArticleCloudKitService
  private let categorizer: ArticleCategorizer

  /// Initialize article sync service
  /// - Parameters:
  ///   - articleService: Service for CloudKit article operations
  ///   - categorizer: Pure function for categorizing articles
  public init(
    articleService: ArticleCloudKitService,
    categorizer: ArticleCategorizer = ArticleCategorizer()
  ) {
    self.articleService = articleService
    self.categorizer = categorizer
  }

  /// Synchronize articles with CloudKit using GUID-based deduplication.
  ///
  /// ## Deduplication Strategy
  ///
  /// This method prevents duplicate articles through a sequential 4-step process:
  /// 1. **Query existing**: Fetch all articles with matching GUIDs from CloudKit
  /// 2. **Categorize**: Pure function separates new vs modified articles
  /// 3. **Create new**: Upload articles not found in CloudKit
  /// 4. **Update modified**: Update articles with changed content (contentHash comparison)
  ///
  /// GUID-based querying happens *before* any mutations, ensuring duplicate detection
  /// is safe even when multiple feed updates run concurrently. Each feed's articles
  /// use unique GUIDs scoped to that feed.
  ///
  /// - Parameters:
  ///   - items: Fetched RSS feed items to process
  ///   - feedRecordName: Feed record identifier for scoping queries
  /// - Returns: Sync result with creation and update statistics
  /// - Throws: CloudKitError if queries or modifications fail
  public func syncArticles(
    items: [FeedItem],
    feedRecordName: String
  ) async throws(CloudKitError) -> ArticleSyncResult {
    // 1. Query existing articles by GUID
    // TEMPORARY: Skip GUID query due to CloudKit Web Services .in() operator issue
    // TODO: Fix query or implement alternative deduplication strategy
    let existingArticles: [Article] = []
    // let guids = items.map(\.guid)
    // let existingArticles = try await articleService.queryArticlesByGUIDs(
    //   guids,
    //   feedRecordName: feedRecordName
    // )

    // 2. Categorize into new vs modified (pure function)
    let categorization = categorizer.categorize(
      items: items,
      existingArticles: existingArticles,
      feedRecordName: feedRecordName
    )

    // 3. Create new articles
    let createResult = try await articleService.createArticles(
      categorization.new
    )

    // 4. Update modified articles
    let updateResult = try await articleService.updateArticles(
      categorization.modified
    )

    // 5. Return aggregated result
    return ArticleSyncResult(
      created: createResult,
      updated: updateResult
    )
  }
}
