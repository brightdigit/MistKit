import CelestraKit
import Foundation
import MistKit
import Testing

@testable import CelestraCloudKit

extension ArticleConversion {
  @Suite("Article to CloudKit Conversion")
  internal struct ToCloudKit {
    @Test("toFieldsDict converts required fields correctly")
    internal func testToFieldsDictRequiredFields() {
      let article = Article(
        feedRecordName: "feed-123",
        guid: "article-guid-456",
        title: "Test Article",
        url: "https://example.com/article",
        fetchedAt: Date(timeIntervalSince1970: 1_000_000),
        ttlDays: 30
      )

      let fields = article.toFieldsDict()

      // Check required fields
      #expect(fields["feedRecordName"] == .string("feed-123"))
      #expect(fields["guid"] == .string("article-guid-456"))
      #expect(fields["title"] == .string("Test Article"))
      #expect(fields["url"] == .string("https://example.com/article"))
      #expect(fields["fetchedTimestamp"] == .date(Date(timeIntervalSince1970: 1_000_000)))
      // expiresTimestamp and contentHash are stored, check they exist
      #expect(fields["expiresTimestamp"] != nil)
      #expect(fields["contentHash"] != nil)
    }

    @Test("toFieldsDict handles optional fields correctly")
    internal func testToFieldsDictOptionalFields() {
      let article = Article(
        feedRecordName: "feed-123",
        guid: "article-guid-456",
        title: "Full Article",
        excerpt: "This is an excerpt",
        content: "<p>Full HTML content</p>",
        contentText: "Full text content",
        author: "John Doe",
        url: "https://example.com/article",
        imageURL: "https://example.com/image.jpg",
        publishedDate: Date(timeIntervalSince1970: 500_000),
        fetchedAt: Date(timeIntervalSince1970: 1_000_000),
        ttlDays: 60,
        wordCount: 500,
        estimatedReadingTime: 3,
        language: "en",
        tags: ["tech", "swift"]
      )

      let fields = article.toFieldsDict()

      // Check optional string fields
      #expect(fields["excerpt"] == .string("This is an excerpt"))
      #expect(fields["content"] == .string("<p>Full HTML content</p>"))
      #expect(fields["contentText"] == .string("Full text content"))
      #expect(fields["author"] == .string("John Doe"))
      #expect(fields["imageURL"] == .string("https://example.com/image.jpg"))
      #expect(fields["language"] == .string("en"))

      // Check optional date field
      #expect(fields["publishedTimestamp"] == .date(Date(timeIntervalSince1970: 500_000)))

      // Check optional numeric fields
      #expect(fields["wordCount"] == .int64(500))
      #expect(fields["estimatedReadingTime"] == .int64(3))

      // Check array field
      if case .list(let tagValues) = fields["tags"] {
        #expect(tagValues.count == 2)
        #expect(tagValues[0] == .string("tech"))
        #expect(tagValues[1] == .string("swift"))
      } else {
        Issue.record("tags field should be a list")
      }
    }

    @Test("toFieldsDict omits nil optional fields")
    internal func testToFieldsDictOmitsNilFields() {
      let article = Article(
        feedRecordName: "feed-123",
        guid: "guid-789",
        title: "Minimal Article",
        url: "https://example.com/minimal",
        fetchedAt: Date(),
        ttlDays: 30
      )

      let fields = article.toFieldsDict()

      // Verify optional fields are not present when nil
      #expect(fields["publishedTimestamp"] == nil)
      #expect(fields["excerpt"] == nil)
      #expect(fields["content"] == nil)
      #expect(fields["contentText"] == nil)
      #expect(fields["author"] == nil)
      #expect(fields["imageURL"] == nil)
      #expect(fields["language"] == nil)
      #expect(fields["wordCount"] == nil)
      #expect(fields["estimatedReadingTime"] == nil)
      #expect(fields["tags"] == nil)
    }
  }
}
