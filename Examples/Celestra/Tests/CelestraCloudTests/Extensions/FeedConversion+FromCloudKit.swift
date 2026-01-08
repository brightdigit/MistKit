import CelestraKit
import Foundation
import MistKit
import Testing

@testable import CelestraCloudKit

extension FeedConversion {
  @Suite("Feed from CloudKit Conversion")
  internal struct FromCloudKit {
    @Test("init(from:) parses all fields correctly")
    internal func testInitFromRecordAllFields() throws {
      let fields: [String: FieldValue] = [
        "feedURL": .string("https://example.com/feed.xml"),
        "title": .string("Test Feed"),
        "description": .string("A description"),
        "category": .string("Tech"),
        "imageURL": .string("https://example.com/image.png"),
        "siteURL": .string("https://example.com"),
        "language": .string("en"),
        "isFeatured": .int64(1),
        "isVerified": .int64(0),
        "isActive": .int64(1),
        "qualityScore": .int64(80),
        "subscriberCount": .int64(200),
        "createdTimestamp": .date(Date(timeIntervalSince1970: 1_000_000)),
        "verifiedTimestamp": .date(Date(timeIntervalSince1970: 2_000_000)),
        "updateFrequency": .double(3_600.0),
        "tags": .list([.string("tech"), .string("news")]),
        "totalAttempts": .int64(10),
        "successfulAttempts": .int64(8),
        "attemptedTimestamp": .date(Date(timeIntervalSince1970: 3_000_000)),
        "etag": .string("etag123"),
        "lastModified": .string("Mon, 01 Jan 2024 00:00:00 GMT"),
        "failureCount": .int64(2),
        "lastFailureReason": .string("Timeout"),
        "minUpdateInterval": .double(1_800.0),
      ]

      let record = RecordInfo(
        recordName: "test-record",
        recordType: "Feed",
        recordChangeTag: "change-tag",
        fields: fields
      )

      let feed = try Feed(from: record)

      verifyRequiredFields(feed)
      verifyOptionalStringFields(feed)
      verifyBooleanFields(feed)
      verifyNumericFields(feed)
      verifyDateFields(feed)
      verifyWebEtiquetteFields(feed)
    }

    @Test("init(from:) handles missing optional fields with defaults")
    internal func testInitFromRecordMissingFields() throws {
      let fields: [String: FieldValue] = [
        "feedURL": .string("https://example.com/feed.xml"),
        "title": .string("Minimal Feed"),
      ]

      let record = RecordInfo(
        recordName: "minimal-record",
        recordType: "Feed",
        recordChangeTag: nil,
        fields: fields
      )

      let feed = try Feed(from: record)

      // Required fields should be set
      #expect(feed.feedURL == "https://example.com/feed.xml")
      #expect(feed.title == "Minimal Feed")

      // Optional fields should be nil or have defaults
      #expect(feed.description == nil)
      #expect(feed.category == nil)
      #expect(feed.imageURL == nil)
      #expect(feed.siteURL == nil)
      #expect(feed.language == nil)
      #expect(feed.isFeatured == false)
      #expect(feed.isVerified == false)
      #expect(feed.isActive == true)  // Default is true
      #expect(feed.qualityScore == 50)  // Default
      #expect(feed.subscriberCount == 0)
      #expect(feed.totalAttempts == 0)
      #expect(feed.successfulAttempts == 0)
      #expect(feed.failureCount == 0)
      #expect(feed.lastVerified == nil)
      #expect(feed.updateFrequency == nil)
      #expect(feed.tags.isEmpty)
      #expect(feed.lastAttempted == nil)
      #expect(feed.etag == nil)
      #expect(feed.lastModified == nil)
      #expect(feed.lastFailureReason == nil)
      #expect(feed.minUpdateInterval == nil)
    }

    // MARK: - Helper Methods

    private func verifyRequiredFields(_ feed: Feed) {
      #expect(feed.recordName == "test-record")
      #expect(feed.feedURL == "https://example.com/feed.xml")
      #expect(feed.title == "Test Feed")
    }

    private func verifyOptionalStringFields(_ feed: Feed) {
      #expect(feed.description == "A description")
      #expect(feed.category == "Tech")
      #expect(feed.imageURL == "https://example.com/image.png")
      #expect(feed.siteURL == "https://example.com")
      #expect(feed.language == "en")
    }

    private func verifyBooleanFields(_ feed: Feed) {
      #expect(feed.isFeatured == true)
      #expect(feed.isVerified == false)
      #expect(feed.isActive == true)
    }

    private func verifyNumericFields(_ feed: Feed) {
      #expect(feed.qualityScore == 80)
      #expect(feed.subscriberCount == 200)
      #expect(feed.tags == ["tech", "news"])
      #expect(feed.totalAttempts == 10)
      #expect(feed.successfulAttempts == 8)
      #expect(feed.failureCount == 2)
      #expect(feed.updateFrequency == 3_600.0)
      #expect(feed.minUpdateInterval == 1_800.0)
    }

    private func verifyDateFields(_ feed: Feed) {
      #expect(feed.addedAt == Date(timeIntervalSince1970: 1_000_000))
      #expect(feed.lastVerified == Date(timeIntervalSince1970: 2_000_000))
      #expect(feed.lastAttempted == Date(timeIntervalSince1970: 3_000_000))
    }

    private func verifyWebEtiquetteFields(_ feed: Feed) {
      #expect(feed.etag == "etag123")
      #expect(feed.lastModified == "Mon, 01 Jan 2024 00:00:00 GMT")
      #expect(feed.lastFailureReason == "Timeout")
    }
  }
}
