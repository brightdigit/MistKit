internal import Foundation
internal import Testing

@testable import MistKit

@Suite("Field Value")
/// Tests for FieldValue functionality
internal struct FieldValueTests {
  /// Cases that survive a full JSON encode → decode round-trip unchanged.
  ///
  /// Exercises both encode paths in `FieldValue+Codable`: scalar `.value` arms and
  /// homogeneous `.list` / complex `.value` arms. Heterogeneous lists are
  /// unrepresentable after issue #481.
  private static let roundTripCases: [FieldValue] = [
    .string(.value("test")),
    .int64(.value(123)),
    // Fractional on purpose: a whole-valued double decodes back as `.int64`.
    .double(.value(3.14)),
    .string(.list(["item1", "item2"])),
    .int64(.list([1, 2, 42])),
    .location(.value(Location(latitude: 37.7749, longitude: -122.4194, horizontalAccuracy: 10.0))),
    .reference(.value(Reference(recordName: "test-record"))),
    .asset(
      .value(
        Asset(fileChecksum: "abc123", size: 1_024, downloadURL: "https://example.com/file")
      )
    ),
  ]

  /// Tests FieldValue string type creation and equality
  @Test("FieldValue string type creation and equality")
  internal func fieldValueString() {
    let value = FieldValue.string(.value("test"))
    #expect(value == .string(.value("test")))
  }

  /// Tests FieldValue int64 type creation and equality
  @Test("FieldValue int64 type creation and equality")
  internal func fieldValueInt64() {
    let value = FieldValue.int64(.value(123))
    #expect(value == .int64(.value(123)))
  }

  /// Tests FieldValue double type creation and equality
  @Test("FieldValue double type creation and equality")
  internal func fieldValueDouble() {
    let value = FieldValue.double(.value(3.14))
    #expect(value == .double(.value(3.14)))
  }

  /// Tests FieldValue boolean helper creation and equality
  @Test("FieldValue boolean helper creation and equality")
  internal func fieldValueBoolean() {
    let trueValue = FieldValue(booleanValue: true)
    #expect(trueValue == .int64(.value(1)))

    let falseValue = FieldValue(booleanValue: false)
    #expect(falseValue == .int64(.value(0)))
  }

  /// Tests FieldValue date type creation and equality
  @Test("FieldValue date type creation and equality")
  internal func fieldValueDate() {
    let date = Date()
    let value = FieldValue.date(.value(date))
    #expect(value == .date(.value(date)))
  }

  /// Tests FieldValue location type creation and equality
  @Test("FieldValue location type creation and equality")
  internal func fieldValueLocation() {
    let location = Location(
      latitude: 37.7749,
      longitude: -122.4194,
      horizontalAccuracy: 10.0
    )
    let value = FieldValue.location(.value(location))
    #expect(value == .location(.value(location)))
  }

  /// Tests FieldValue reference type creation and equality
  @Test("FieldValue reference type creation and equality")
  internal func fieldValueReference() {
    let reference = Reference(recordName: "test-record")
    let value = FieldValue.reference(.value(reference))
    #expect(value == .reference(.value(reference)))
  }

  /// Tests FieldValue asset type creation and equality
  @Test("FieldValue asset type creation and equality")
  internal func fieldValueAsset() {
    let asset = Asset(
      fileChecksum: "abc123",
      size: 1_024,
      downloadURL: "https://example.com/file"
    )
    let value = FieldValue.asset(.value(asset))
    #expect(value == .asset(.value(asset)))
  }

  /// Tests FieldValue homogeneous string list creation and equality
  @Test("FieldValue homogeneous string list creation and equality")
  internal func fieldValueList() {
    let value = FieldValue.string(.list(["item1", "item2"]))
    #expect(value == .string(.list(["item1", "item2"])))
  }

  /// Tests FieldValue JSON encode → decode round-trips for scalar and complex cases
  @Test(
    "FieldValue JSON encode/decode round-trip",
    arguments: FieldValueTests.roundTripCases
  )
  internal func fieldValueRoundTrip(_ value: FieldValue) throws {
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(FieldValue.self, from: data)
    #expect(decoded == value)
  }

  /// Tests that `.date` encodes as CloudKit milliseconds.
  ///
  /// `.date` does not round-trip: the decoder has no date branch on purpose
  /// (a bare millisecond number is claimed by `.int64`/`.double` first — see
  /// `decodeComplexTypes`), so this asserts the encoded wire value directly.
  @Test("FieldValue date encodes as milliseconds")
  internal func fieldValueDateEncodesMilliseconds() throws {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let data = try JSONEncoder().encode(FieldValue.date(.value(date)))
    let milliseconds = try JSONDecoder().decode(Double.self, from: data)
    #expect(milliseconds == date.timeIntervalSince1970 * 1_000)
  }

  /// Tests that `.bytes` encodes as a base64 string payload.
  ///
  /// Encoding emits `Data.base64EncodedString()`. Decoding still has no bytes
  /// branch, so the payload reads back as `.string`.
  @Test("FieldValue bytes encodes as its base64 string payload")
  internal func fieldValueBytesEncodesAsString() throws {
    let payload = Data("abc123".utf8)
    let encoded = payload.base64EncodedString()
    let bytesData = try JSONEncoder().encode(FieldValue.bytes(.value(payload)))
    let stringData = try JSONEncoder().encode(FieldValue.string(.value(encoded)))
    #expect(bytesData == stringData)

    let decoded = try JSONDecoder().decode(FieldValue.self, from: bytesData)
    #expect(decoded == .string(.value(encoded)))
  }
}
