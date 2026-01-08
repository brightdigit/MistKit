import CelestraKit
import Foundation
import MistKit
import Testing

@testable import CelestraCloudKit

extension FeedConversion {
  @Suite("Feed Round-Trip Conversion")
  internal struct RoundTrip {
    @Test("Round-trip conversion preserves data")
    internal func testRoundTripConversion() throws {
      let originalFeed = Feed(
        recordName: "round-trip",
        recordChangeTag: "tag1",
        feedURL: "https://example.com/feed.xml",
        title: "Round Trip Feed",
        description: "Testing round-trip",
        category: "Test",
        imageURL: "https://example.com/img.png",
        siteURL: "https://example.com",
        language: "en",
        isFeatured: true,
        isVerified: true,
        qualityScore: 90,
        subscriberCount: 500,
        addedAt: Date(timeIntervalSince1970: 1_000_000),
        lastVerified: Date(timeIntervalSince1970: 2_000_000),
        updateFrequency: 7_200.0,
        tags: ["test", "roundtrip"],
        totalAttempts: 15,
        successfulAttempts: 14,
        lastAttempted: Date(timeIntervalSince1970: 3_000_000),
        isActive: true,
        etag: "round123",
        lastModified: "Thu, 01 Feb 2024 00:00:00 GMT",
        failureCount: 1,
        lastFailureReason: "Brief timeout",
        minUpdateInterval: 3_600.0
      )

      // Convert to fields
      let fields = originalFeed.toFieldsDict()

      // Create a record
      let record = RecordInfo(
        recordName: originalFeed.recordName ?? "round-trip",
        recordType: "Feed",
        recordChangeTag: originalFeed.recordChangeTag,
        fields: fields
      )

      // Convert back to Feed
      let reconstructedFeed = try Feed(from: record)

      // Verify all fields match
      verifyStringFields(reconstructedFeed, original: originalFeed)
      verifyBooleanFields(reconstructedFeed, original: originalFeed)
      verifyNumericFields(reconstructedFeed, original: originalFeed)
      verifyWebEtiquetteFields(reconstructedFeed, original: originalFeed)
    }

    @Test("Boolean fields correctly convert between Bool and Int64")
    internal func testBooleanFieldConversion() throws {
      let feed = Feed(
        recordName: "bool-test",
        recordChangeTag: nil,
        feedURL: "https://example.com/feed.xml",
        title: "Boolean Test",
        description: nil,
        category: nil,
        imageURL: nil,
        siteURL: nil,
        language: nil,
        isFeatured: true,  // Should be 1
        isVerified: false,  // Should be 0
        qualityScore: 50,
        subscriberCount: 0,
        addedAt: Date(),
        lastVerified: nil,
        updateFrequency: nil,
        tags: [],
        totalAttempts: 0,
        successfulAttempts: 0,
        lastAttempted: nil,
        isActive: false,  // Should be 0
        etag: nil,
        lastModified: nil,
        failureCount: 0,
        lastFailureReason: nil,
        minUpdateInterval: nil
      )

      let fields = feed.toFieldsDict()

      // Verify booleans are stored as Int64
      #expect(fields["isFeatured"] == .int64(1))
      #expect(fields["isVerified"] == .int64(0))
      #expect(fields["isActive"] == .int64(0))

      // Round-trip back
      let record = RecordInfo(
        recordName: "bool-test",
        recordType: "Feed",
        recordChangeTag: nil,
        fields: fields
      )

      let reconstructed = try Feed(from: record)

      #expect(reconstructed.isFeatured == true)
      #expect(reconstructed.isVerified == false)
      #expect(reconstructed.isActive == false)
    }

    // MARK: - Helper Methods

    private func verifyStringFields(_ reconstructed: Feed, original: Feed) {
      #expect(reconstructed.feedURL == original.feedURL)
      #expect(reconstructed.title == original.title)
      #expect(reconstructed.description == original.description)
      #expect(reconstructed.category == original.category)
      #expect(reconstructed.imageURL == original.imageURL)
      #expect(reconstructed.siteURL == original.siteURL)
      #expect(reconstructed.language == original.language)
    }

    private func verifyBooleanFields(_ reconstructed: Feed, original: Feed) {
      #expect(reconstructed.isFeatured == original.isFeatured)
      #expect(reconstructed.isVerified == original.isVerified)
      #expect(reconstructed.isActive == original.isActive)
    }

    private func verifyNumericFields(_ reconstructed: Feed, original: Feed) {
      #expect(reconstructed.qualityScore == original.qualityScore)
      #expect(reconstructed.subscriberCount == original.subscriberCount)
      #expect(reconstructed.tags == original.tags)
      #expect(reconstructed.totalAttempts == original.totalAttempts)
      #expect(reconstructed.successfulAttempts == original.successfulAttempts)
      #expect(reconstructed.failureCount == original.failureCount)
      #expect(reconstructed.updateFrequency == original.updateFrequency)
      #expect(reconstructed.minUpdateInterval == original.minUpdateInterval)
    }

    private func verifyWebEtiquetteFields(_ reconstructed: Feed, original: Feed) {
      #expect(reconstructed.etag == original.etag)
      #expect(reconstructed.lastModified == original.lastModified)
      #expect(reconstructed.lastFailureReason == original.lastFailureReason)
    }
  }
}
