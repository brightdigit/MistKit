internal import Foundation
internal import Testing

@testable import MistKit

@Suite("Field Value")
/// Tests for FieldValue functionality
internal struct FieldValueTests {
  /// Cases that survive a full JSON encode → decode round-trip unchanged.
  ///
  /// Exercises both encode paths in `FieldValue+Codable`: the scalar arm
  /// (`.string`/`.int64`/`.double` via `encodeScalar`) and the complex arm
  /// (`.list`/`.location`/`.reference`/`.asset` via `encodeComplex`). The
  /// complex cases are exactly those `encodeScalar` returns `false` for, so
  /// this drives the `encodeScalar` → `encodeComplex` delegation.
  ///
  /// The throwing `default` in `encodeComplex` is intentionally unreachable —
  /// every `FieldValue` case is routed by one of the two arms — so it is a
  /// defensive guard covered by switch exhaustiveness, not by a test.
  private static let roundTripCases: [FieldValue] = [
    .string("test"),
    .int64(123),
    // Fractional on purpose: a whole-valued double decodes back as `.int64`.
    .double(3.14),
    .list([.string("item1"), .int64(42)]),
    .location(
      Location(latitude: 37.7749, longitude: -122.4194, horizontalAccuracy: 10.0)
    ),
    .reference(Reference(recordName: "test-record")),
    .asset(
      Asset(fileChecksum: "abc123", size: 1_024, downloadURL: "https://example.com/file")
    ),
  ]

  /// Tests FieldValue string type creation and equality
  @Test("FieldValue string type creation and equality")
  internal func fieldValueString() {
    let value = FieldValue.string("test")
    #expect(value == .string("test"))
  }

  /// Tests FieldValue int64 type creation and equality
  @Test("FieldValue int64 type creation and equality")
  internal func fieldValueInt64() {
    let value = FieldValue.int64(123)
    #expect(value == .int64(123))
  }

  /// Tests FieldValue double type creation and equality
  @Test("FieldValue double type creation and equality")
  internal func fieldValueDouble() {
    let value = FieldValue.double(3.14)
    #expect(value == .double(3.14))
  }

  /// Tests FieldValue boolean helper creation and equality
  @Test("FieldValue boolean helper creation and equality")
  internal func fieldValueBoolean() {
    let trueValue = FieldValue(booleanValue: true)
    #expect(trueValue == .int64(1))

    let falseValue = FieldValue(booleanValue: false)
    #expect(falseValue == .int64(0))
  }

  /// Tests FieldValue date type creation and equality
  @Test("FieldValue date type creation and equality")
  internal func fieldValueDate() {
    let date = Date()
    let value = FieldValue.date(date)
    #expect(value == .date(date))
  }

  /// Tests FieldValue location type creation and equality
  @Test("FieldValue location type creation and equality")
  internal func fieldValueLocation() {
    let location = Location(
      latitude: 37.7749,
      longitude: -122.4194,
      horizontalAccuracy: 10.0
    )
    let value = FieldValue.location(location)
    #expect(value == .location(location))
  }

  /// Tests FieldValue reference type creation and equality
  @Test("FieldValue reference type creation and equality")
  internal func fieldValueReference() {
    let reference = Reference(recordName: "test-record")
    let value = FieldValue.reference(reference)
    #expect(value == .reference(reference))
  }

  /// Tests FieldValue asset type creation and equality
  @Test("FieldValue asset type creation and equality")
  internal func fieldValueAsset() {
    let asset = Asset(
      fileChecksum: "abc123",
      size: 1_024,
      downloadURL: "https://example.com/file"
    )
    let value = FieldValue.asset(asset)
    #expect(value == .asset(asset))
  }

  /// Tests FieldValue list type creation and equality
  @Test("FieldValue list type creation and equality")
  internal func fieldValueList() {
    let list = [FieldValue.string("item1"), FieldValue.int64(42)]
    let value = FieldValue.list(list)
    #expect(value == .list(list))
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
    let data = try JSONEncoder().encode(FieldValue.date(date))
    let milliseconds = try JSONDecoder().decode(Double.self, from: data)
    #expect(milliseconds == date.timeIntervalSince1970 * 1_000)
  }

  /// Tests that `.bytes` encodes as its raw string payload.
  ///
  /// `.bytes` shares the scalar arm with `.string`, so it emits the same wire
  /// value; it decodes back as `.string` since the decoder has no bytes branch.
  @Test("FieldValue bytes encodes as its string payload")
  internal func fieldValueBytesEncodesAsString() throws {
    let payload = "YWJjMTIz"
    let bytesData = try JSONEncoder().encode(FieldValue.bytes(payload))
    let stringData = try JSONEncoder().encode(FieldValue.string(payload))
    #expect(bytesData == stringData)

    let decoded = try JSONDecoder().decode(FieldValue.self, from: bytesData)
    #expect(decoded == .string(payload))
  }
}
