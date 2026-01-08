//
//  ArticleCategorizer+Basic.swift
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

extension ArticleCategorizer {
  @Suite("Basic Scenarios")
  internal struct Basic {
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

    private func createArticle(
      recordName: String? = nil,
      recordChangeTag: String? = nil,
      feedRecordName: String = "feed-123",
      guid: String,
      title: String = "Test Title",
      url: String = "https://example.com/article",
      excerpt: String? = "Test description",
      content: String? = "Test content",
      author: String? = "Test Author",
      publishedDate: Date? = Date(timeIntervalSince1970: 1_000_000)
    ) -> Article {
      Article(
        recordName: recordName,
        recordChangeTag: recordChangeTag,
        feedRecordName: feedRecordName,
        guid: guid,
        title: title,
        excerpt: excerpt,
        content: content,
        author: author,
        url: url,
        publishedDate: publishedDate
      )
    }

    // MARK: - Tests

    @Test("Empty inputs returns empty result")
    internal func testEmptyInputs() {
      let categorizer = CelestraCloudKit.ArticleCategorizer()

      let result = categorizer.categorize(
        items: [],
        existingArticles: [],
        feedRecordName: "feed-123"
      )

      #expect(result.new.isEmpty)
      #expect(result.modified.isEmpty)
    }

    @Test("All new articles when no existing")
    internal func testAllNewArticles() {
      let categorizer = CelestraCloudKit.ArticleCategorizer()
      let items = [
        createFeedItem(guid: "guid-1"),
        createFeedItem(guid: "guid-2"),
        createFeedItem(guid: "guid-3"),
      ]

      let result = categorizer.categorize(
        items: items,
        existingArticles: [],
        feedRecordName: "feed-123"
      )

      #expect(result.new.count == 3)
      #expect(result.modified.isEmpty)
      #expect(result.new.map(\.guid) == ["guid-1", "guid-2", "guid-3"])
      #expect(result.new.allSatisfy { $0.feedRecordName == "feed-123" })
      #expect(result.new.allSatisfy { $0.recordName == nil })  // New articles don't have recordName
    }

    @Test("All unchanged when GUID and contentHash match")
    internal func testAllUnchanged() {
      let categorizer = CelestraCloudKit.ArticleCategorizer()

      // Create articles with matching content (same contentHash)
      let item = createFeedItem(
        guid: "guid-1",
        title: "Title",
        link: "https://example.com/1"
      )
      let existing = createArticle(
        recordName: "record-1",
        recordChangeTag: "tag-1",
        guid: "guid-1",
        title: "Title",
        url: "https://example.com/1"
      )

      let result = categorizer.categorize(
        items: [item],
        existingArticles: [existing],
        feedRecordName: "feed-123"
      )

      #expect(result.new.isEmpty)
      #expect(result.modified.isEmpty)  // Unchanged articles are skipped
    }

    @Test("Modified articles when GUID matches but contentHash differs")
    internal func testModifiedArticles() {
      let categorizer = CelestraCloudKit.ArticleCategorizer()

      // Create item with different title (different contentHash)
      let item = createFeedItem(guid: "guid-1", title: "Updated Title")
      let existing = createArticle(
        recordName: "record-1",
        recordChangeTag: "tag-1",
        guid: "guid-1",
        title: "Original Title"
      )

      let result = categorizer.categorize(
        items: [item],
        existingArticles: [existing],
        feedRecordName: "feed-123"
      )

      #expect(result.new.isEmpty)
      #expect(result.modified.count == 1)

      let modified = result.modified[0]
      #expect(modified.recordName == "record-1")  // Preserved
      #expect(modified.recordChangeTag == "tag-1")  // Preserved
      #expect(modified.guid == "guid-1")
      #expect(modified.title == "Updated Title")  // Updated content
    }
  }
}
