//
//  ArticleCategorizer.swift
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

/// Pure function type for categorizing feed items into new vs modified articles
@available(macOS 13.0, *)
public struct ArticleCategorizer: Sendable {
  /// Result of article categorization
  public struct Result: Sendable, Equatable {
    /// New articles (GUID not found in existing)
    public let new: [Article]

    /// Modified articles (GUID found, contentHash differs)
    public let modified: [Article]

    /// Initialize categorization result
    /// - Parameters:
    ///   - new: New articles not found in existing articles
    ///   - modified: Modified articles with matching GUID but different content
    public init(new: [Article], modified: [Article]) {
      self.new = new
      self.modified = modified
    }
  }

  /// Initialize article categorizer
  public init() {}

  /// Categorize feed items into new and modified articles
  /// - Parameters:
  ///   - items: RSS feed items to process
  ///   - existingArticles: Existing articles from CloudKit for duplicate detection
  ///   - feedRecordName: Feed record name to associate with new articles
  /// - Returns: Categorization result with new and modified article arrays
  public func categorize(
    items: [FeedItem],
    existingArticles: [Article],
    feedRecordName: String
  ) -> Result {
    // Build lookup map for efficient GUID matching
    let existingMap = Dictionary(
      uniqueKeysWithValues: existingArticles.map { ($0.guid, $0) }
    )

    var newArticles: [Article] = []
    var modifiedArticles: [Article] = []

    for item in items {
      let article = Article(
        feedRecordName: feedRecordName,
        guid: item.guid,
        title: item.title,
        excerpt: item.description,
        content: item.content,
        author: item.author,
        url: item.link,
        publishedDate: item.pubDate
      )

      if let existing = existingMap[article.guid] {
        // Article exists - check if content changed
        if existing.contentHash != article.contentHash {
          // Content changed - preserve CloudKit metadata
          modifiedArticles.append(
            Article(
              recordName: existing.recordName,
              recordChangeTag: existing.recordChangeTag,
              feedRecordName: article.feedRecordName,
              guid: article.guid,
              title: article.title,
              excerpt: article.excerpt,
              content: article.content,
              author: article.author,
              url: article.url,
              publishedDate: article.publishedDate
            )
          )
        }
        // else: unchanged - skip
      } else {
        // New article
        newArticles.append(article)
      }
    }

    return Result(new: newArticles, modified: modifiedArticles)
  }
}
