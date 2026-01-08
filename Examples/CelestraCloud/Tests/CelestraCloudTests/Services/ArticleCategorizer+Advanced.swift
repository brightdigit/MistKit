//
//  ArticleCategorizer+Advanced.swift
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

// swiftlint:disable file_length

extension ArticleCategorizer {
  @Suite("Advanced Scenarios")
  internal struct Advanced {
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

    @Test("Mixed scenario: new, modified, and unchanged")
    internal func testMixedScenario() {
      let categorizer = CelestraCloudKit.ArticleCategorizer()

      let items = [
        createFeedItem(guid: "new-1", title: "New Article"),
        createFeedItem(guid: "modified-1", title: "Modified Title"),
        createFeedItem(guid: "unchanged-1", title: "Unchanged"),
      ]

      let existing = [
        createArticle(
          recordName: "record-mod",
          guid: "modified-1",
          title: "Original Title"
        ),
        createArticle(
          recordName: "record-unch",
          guid: "unchanged-1",
          title: "Unchanged"
        ),
      ]

      let result = categorizer.categorize(
        items: items,
        existingArticles: existing,
        feedRecordName: "feed-123"
      )

      #expect(result.new.count == 1)
      #expect(result.new[0].guid == "new-1")

      #expect(result.modified.count == 1)
      #expect(result.modified[0].guid == "modified-1")
      #expect(result.modified[0].recordName == "record-mod")
    }

    @Test("Duplicate GUIDs within feed items")
    internal func testDuplicateGUIDsInItems() {
      let categorizer = CelestraCloudKit.ArticleCategorizer()

      let items = [
        createFeedItem(guid: "dup-1", title: "First"),
        createFeedItem(guid: "dup-1", title: "Second"),
      ]

      let result = categorizer.categorize(
        items: items,
        existingArticles: [],
        feedRecordName: "feed-123"
      )

      // Both should be treated as new (no deduplication within items)
      #expect(result.new.count == 2)
    }

    @Test("Existing articles with no matching items")
    internal func testExistingWithNoMatchingItems() {
      let categorizer = CelestraCloudKit.ArticleCategorizer()

      let existing = [
        createArticle(recordName: "record-1", guid: "old-1"),
        createArticle(recordName: "record-2", guid: "old-2"),
      ]

      let items = [createFeedItem(guid: "new-1")]

      let result = categorizer.categorize(
        items: items,
        existingArticles: existing,
        feedRecordName: "feed-123"
      )

      #expect(result.new.count == 1)
      #expect(result.modified.isEmpty)
      // Old articles are not deleted - that's a separate operation
    }

    @Test("Feed record name is correctly assigned to new articles")
    internal func testFeedRecordNameAssignment() {
      let categorizer = CelestraCloudKit.ArticleCategorizer()
      let customFeedRecordName = "custom-feed-456"

      let items = [createFeedItem(guid: "guid-1")]

      let result = categorizer.categorize(
        items: items,
        existingArticles: [],
        feedRecordName: customFeedRecordName
      )

      #expect(result.new.count == 1)
      #expect(result.new[0].feedRecordName == customFeedRecordName)
    }

    @Test("Items with no existing articles")
    internal func testNoExistingArticles() {
      let categorizer = CelestraCloudKit.ArticleCategorizer()
      let items = [createFeedItem(guid: "guid-1")]

      let result = categorizer.categorize(
        items: items,
        existingArticles: [],
        feedRecordName: "feed-123"
      )

      #expect(result.new.count == 1)
      #expect(result.modified.isEmpty)
    }

    @Test("CloudKit metadata preservation for modified articles")
    internal func testCloudKitMetadataPreservation() {
      let categorizer = CelestraCloudKit.ArticleCategorizer()

      let item = createFeedItem(guid: "guid-1", title: "New Title")
      let existing = createArticle(
        recordName: "record-abc-123",
        recordChangeTag: "tag-xyz-789",
        guid: "guid-1",
        title: "Old Title"
      )

      let result = categorizer.categorize(
        items: [item],
        existingArticles: [existing],
        feedRecordName: "feed-123"
      )

      #expect(result.modified.count == 1)
      let modified = result.modified[0]

      // CloudKit metadata must be preserved
      #expect(modified.recordName == "record-abc-123")
      #expect(modified.recordChangeTag == "tag-xyz-789")

      // Content must be updated
      #expect(modified.title == "New Title")
      #expect(modified.guid == "guid-1")
    }
  }
}
