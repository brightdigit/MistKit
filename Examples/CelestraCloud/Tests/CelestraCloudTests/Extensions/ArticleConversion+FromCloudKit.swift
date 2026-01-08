import CelestraKit
import Foundation
import MistKit
import Testing

@testable import CelestraCloudKit

extension ArticleConversion {
  @Suite("Article from CloudKit Conversion")
  internal struct FromCloudKit {
    @Test("init(from:) parses all fields correctly")
    internal func testInitFromRecordAllFields() throws {
      let fetchedDate = Date(timeIntervalSince1970: 1_000_000)
      let expiresDate = Date(timeIntervalSince1970: 3_000_000)

      let fields: [String: FieldValue] = [
        "feedRecordName": .string("feed-123"),
        "guid": .string("guid-456"),
        "title": .string("Complete Article"),
        "url": .string("https://example.com/complete"),
        "publishedTimestamp": .date(Date(timeIntervalSince1970: 500_000)),
        "excerpt": .string("Excerpt text"),
        "content": .string("<p>HTML content</p>"),
        "contentText": .string("Plain text"),
        "author": .string("Jane Smith"),
        "imageURL": .string("https://example.com/img.jpg"),
        "language": .string("en-US"),
        "tags": .list([.string("news"), .string("tech")]),
        "wordCount": .int64(750),
        "estimatedReadingTime": .int64(4),
        "fetchedTimestamp": .date(fetchedDate),
        "expiresTimestamp": .date(expiresDate),
        "contentHash": .string("complete-hash"),
      ]

      let record = RecordInfo(
        recordName: "complete-article-record",
        recordType: "Article",
        recordChangeTag: "tag-123",
        fields: fields
      )

      let article = try Article(from: record)

      #expect(article.recordName == "complete-article-record")
      #expect(article.feedRecordName == "feed-123")
      #expect(article.guid == "guid-456")
      #expect(article.title == "Complete Article")
      #expect(article.url == "https://example.com/complete")
      #expect(article.publishedDate == Date(timeIntervalSince1970: 500_000))
      #expect(article.excerpt == "Excerpt text")
      #expect(article.content == "<p>HTML content</p>")
      #expect(article.contentText == "Plain text")
      #expect(article.author == "Jane Smith")
      #expect(article.imageURL == "https://example.com/img.jpg")
      #expect(article.language == "en-US")
      #expect(article.tags == ["news", "tech"])
      #expect(article.wordCount == 750)
      #expect(article.estimatedReadingTime == 4)
      #expect(article.fetchedAt == fetchedDate)
    }

    @Test("init(from:) handles missing optional fields with defaults")
    internal func testInitFromRecordMissingFields() throws {
      let fetchedDate = Date(timeIntervalSince1970: 1_000_000)
      let expiresDate = Date(timeIntervalSince1970: 2_000_000)

      let fields: [String: FieldValue] = [
        "feedRecordName": .string("feed-123"),
        "guid": .string("guid-789"),
        "title": .string("Minimal Article"),
        "url": .string("https://example.com/minimal"),
        "fetchedTimestamp": .date(fetchedDate),
        "expiresTimestamp": .date(expiresDate),
        "contentHash": .string("hash-minimal"),
      ]

      let record = RecordInfo(
        recordName: "minimal-article-record",
        recordType: "Article",
        recordChangeTag: nil,
        fields: fields
      )

      let article = try Article(from: record)

      // Required fields should be set
      #expect(article.feedRecordName == "feed-123")
      #expect(article.guid == "guid-789")
      #expect(article.title == "Minimal Article")
      #expect(article.url == "https://example.com/minimal")
      #expect(article.fetchedAt == fetchedDate)

      // Optional fields should be nil or empty
      #expect(article.publishedDate == nil)
      #expect(article.excerpt == nil)
      #expect(article.content == nil)
      #expect(article.contentText == nil)
      #expect(article.author == nil)
      #expect(article.imageURL == nil)
      #expect(article.language == nil)
      #expect(article.tags.isEmpty)
      #expect(article.wordCount == nil)
      #expect(article.estimatedReadingTime == nil)
    }

    @Test("Round-trip conversion preserves data")
    internal func testRoundTripConversion() throws {
      let originalArticle = Article(
        recordName: "roundtrip-article",
        recordChangeTag: "rt-tag",
        feedRecordName: "feed-rt",
        guid: "guid-rt-123",
        title: "Round Trip Article",
        excerpt: "Round trip excerpt",
        content: "<p>Round trip content</p>",
        contentText: "Round trip text",
        author: "Round Trip Author",
        url: "https://example.com/roundtrip",
        imageURL: "https://example.com/rt.jpg",
        publishedDate: Date(timeIntervalSince1970: 700_000),
        fetchedAt: Date(timeIntervalSince1970: 1_000_000),
        ttlDays: 45,
        wordCount: 600,
        estimatedReadingTime: 3,
        language: "en",
        tags: ["roundtrip", "test"]
      )

      // Convert to fields
      let fields = originalArticle.toFieldsDict()

      // Create a record
      let record = RecordInfo(
        recordName: originalArticle.recordName ?? "roundtrip-article",
        recordType: "Article",
        recordChangeTag: originalArticle.recordChangeTag,
        fields: fields
      )

      // Convert back to Article
      let reconstructedArticle = try Article(from: record)

      // Verify all fields match
      #expect(reconstructedArticle.feedRecordName == originalArticle.feedRecordName)
      #expect(reconstructedArticle.guid == originalArticle.guid)
      #expect(reconstructedArticle.title == originalArticle.title)
      #expect(reconstructedArticle.url == originalArticle.url)
      #expect(reconstructedArticle.publishedDate == originalArticle.publishedDate)
      #expect(reconstructedArticle.excerpt == originalArticle.excerpt)
      #expect(reconstructedArticle.content == originalArticle.content)
      #expect(reconstructedArticle.contentText == originalArticle.contentText)
      #expect(reconstructedArticle.author == originalArticle.author)
      #expect(reconstructedArticle.imageURL == originalArticle.imageURL)
      #expect(reconstructedArticle.language == originalArticle.language)
      #expect(reconstructedArticle.tags == originalArticle.tags)
      #expect(reconstructedArticle.wordCount == originalArticle.wordCount)
      #expect(reconstructedArticle.estimatedReadingTime == originalArticle.estimatedReadingTime)
      #expect(reconstructedArticle.fetchedAt == originalArticle.fetchedAt)
    }
  }
}
