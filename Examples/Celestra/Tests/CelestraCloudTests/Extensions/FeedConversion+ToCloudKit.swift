import CelestraKit
import Foundation
import MistKit
import Testing

@testable import CelestraCloudKit

extension FeedConversion {
  @Suite("Feed to CloudKit Conversion")
  internal struct ToCloudKit {
    @Test("toFieldsDict converts required fields correctly")
    internal func testToFieldsDictRequiredFields() {
      let feed = Feed(
        recordName: "test-feed",
        recordChangeTag: nil,
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        description: nil,
        category: nil,
        imageURL: nil,
        siteURL: nil,
        language: nil,
        isFeatured: false,
        isVerified: true,
        qualityScore: 75,
        subscriberCount: 100,
        addedAt: Date(timeIntervalSince1970: 1_000_000),
        lastVerified: nil,
        updateFrequency: nil,
        tags: [],
        totalAttempts: 5,
        successfulAttempts: 4,
        lastAttempted: nil,
        isActive: true,
        etag: nil,
        lastModified: nil,
        failureCount: 1,
        lastFailureReason: nil,
        minUpdateInterval: nil
      )

      let fields = feed.toFieldsDict()

      // Check required string fields
      #expect(fields["feedURL"] == .string("https://example.com/feed.xml"))
      #expect(fields["title"] == .string("Test Feed"))

      // Check boolean fields stored as Int64
      #expect(fields["isFeatured"] == .int64(0))
      #expect(fields["isVerified"] == .int64(1))
      #expect(fields["isActive"] == .int64(1))

      // Check numeric fields
      #expect(fields["qualityScore"] == .int64(75))
      #expect(fields["subscriberCount"] == .int64(100))
      #expect(fields["totalAttempts"] == .int64(5))
      #expect(fields["successfulAttempts"] == .int64(4))
      #expect(fields["failureCount"] == .int64(1))

      // Note: addedAt uses CloudKit's built-in createdTimestamp system field, not in dictionary
    }

    @Test("toFieldsDict handles optional fields correctly")
    internal func testToFieldsDictOptionalFields() {
      let feed = Feed(
        recordName: "test-feed",
        recordChangeTag: nil,
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        description: "A test description",
        category: "Technology",
        imageURL: "https://example.com/image.png",
        siteURL: "https://example.com",
        language: "en",
        isFeatured: true,
        isVerified: false,
        qualityScore: 50,
        subscriberCount: 0,
        addedAt: Date(),
        lastVerified: Date(timeIntervalSince1970: 2_000_000),
        updateFrequency: 3_600.0,
        tags: ["tech", "news"],
        totalAttempts: 0,
        successfulAttempts: 0,
        lastAttempted: Date(timeIntervalSince1970: 3_000_000),
        isActive: true,
        etag: "abc123",
        lastModified: "Mon, 01 Jan 2024 00:00:00 GMT",
        failureCount: 0,
        lastFailureReason: "Network error",
        minUpdateInterval: 1_800.0
      )

      let fields = feed.toFieldsDict()

      // Check optional string fields are present
      #expect(fields["description"] == .string("A test description"))
      #expect(fields["category"] == .string("Technology"))
      #expect(fields["imageURL"] == .string("https://example.com/image.png"))
      #expect(fields["siteURL"] == .string("https://example.com"))
      #expect(fields["language"] == .string("en"))
      #expect(fields["etag"] == .string("abc123"))
      #expect(fields["lastModified"] == .string("Mon, 01 Jan 2024 00:00:00 GMT"))
      #expect(fields["lastFailureReason"] == .string("Network error"))

      // Check optional date fields
      #expect(fields["verifiedTimestamp"] == .date(Date(timeIntervalSince1970: 2_000_000)))
      #expect(fields["attemptedTimestamp"] == .date(Date(timeIntervalSince1970: 3_000_000)))

      // Check optional numeric fields
      #expect(fields["updateFrequency"] == .double(3_600.0))
      #expect(fields["minUpdateInterval"] == .double(1_800.0))

      // Check array field
      if case .list(let tagValues) = fields["tags"] {
        #expect(tagValues.count == 2)
        #expect(tagValues[0] == .string("tech"))
        #expect(tagValues[1] == .string("news"))
      } else {
        Issue.record("tags field should be a list")
      }
    }

    @Test("toFieldsDict omits nil optional fields")
    internal func testToFieldsDictOmitsNilFields() {
      let feed = Feed(
        recordName: "test-feed",
        recordChangeTag: nil,
        feedURL: "https://example.com/feed.xml",
        title: "Test Feed",
        description: nil,
        category: nil,
        imageURL: nil,
        siteURL: nil,
        language: nil,
        isFeatured: false,
        isVerified: false,
        qualityScore: 50,
        subscriberCount: 0,
        addedAt: Date(),
        lastVerified: nil,
        updateFrequency: nil,
        tags: [],
        totalAttempts: 0,
        successfulAttempts: 0,
        lastAttempted: nil,
        isActive: true,
        etag: nil,
        lastModified: nil,
        failureCount: 0,
        lastFailureReason: nil,
        minUpdateInterval: nil
      )

      let fields = feed.toFieldsDict()

      // Verify optional fields are not present when nil
      #expect(fields["description"] == nil)
      #expect(fields["category"] == nil)
      #expect(fields["imageURL"] == nil)
      #expect(fields["siteURL"] == nil)
      #expect(fields["language"] == nil)
      #expect(fields["verifiedTimestamp"] == nil)
      #expect(fields["updateFrequency"] == nil)
      #expect(fields["attemptedTimestamp"] == nil)
      #expect(fields["etag"] == nil)
      #expect(fields["lastModified"] == nil)
      #expect(fields["lastFailureReason"] == nil)
      #expect(fields["minUpdateInterval"] == nil)
      #expect(fields["tags"] == nil)
    }
  }
}
