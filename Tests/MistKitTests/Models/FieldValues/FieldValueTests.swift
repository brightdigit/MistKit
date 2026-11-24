internal import Foundation
internal import Testing

@testable import MistKit

@Suite("Field Value")
/// Tests for FieldValue functionality
internal struct FieldValueTests {
  /// Cases that survive a full JSON encode → decode round-trip unchanged.
  ///
  /// Every value is written with its `type`, so the ambiguous scalars
  /// (whole-valued `DOUBLE`, `TIMESTAMP`, `BYTES`) and empty lists come back
  /// as the kind they were written.
  private static let roundTripCases: [FieldValue] = [
    .string(.value("test")),
    .int64(.value(123)),
    .double(.value(3.14)),
    .double(.value(5)),
    .bytes(.value(Data("abc123".utf8))),
    .date(.value(Date(timeIntervalSince1970: 1_700_000_000.5))),
    .string(.list(["item1", "item2"])),
    .string(.list([])),
    .int64(.list([1, 2, 42])),
    .double(.list([1, 2.5])),
    .bytes(.list([Data("a".utf8)])),
    .date(.list([Date(timeIntervalSince1970: 1_700_000_000)])),
    .location(.value(Location(latitude: 37.7749, longitude: -122.4194, horizontalAccuracy: 10.0))),
    .reference(.value(Reference(recordName: "test-record"))),
    .reference(.list([Reference(recordName: "a"), Reference(recordName: "b")])),
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

  /// Tests that a value encodes as a field dictionary that carries its type.
  @Test(
    "FieldValue encodes as {\"value\": …, \"type\": …}",
    arguments: [
      (
        FieldValue.date(.value(Date(timeIntervalSince1970: 1_700_000_000))),
        #"{"type":"TIMESTAMP","value":1700000000000}"#
      ),
      (.bytes(.value(Data("abc123".utf8))), #"{"type":"BYTES","value":"YWJjMTIz"}"#),
      (.double(.value(5)), #"{"type":"DOUBLE","value":5}"#),
      (.string(.value("Chen")), #"{"type":"STRING","value":"Chen"}"#),
      (.int64(.list([])), #"{"type":"INT64_LIST","value":[]}"#),
    ]
  )
  internal func fieldValueEncodesTagged(_ value: FieldValue, _ json: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let data = try encoder.encode(value)
    #expect(String(decoding: data, as: UTF8.self) == json)
  }

  /// Tests that input without a `type`, or with a null value, is a decoding error.
  @Test(
    "FieldValue rejects a value without a type",
    arguments: [
      #""Chen""#,
      "42",
      #"["a","b"]"#,
      #"{"value":"Chen"}"#,
      #"{"value":1700000000000}"#,
      #"{"value":null}"#,
      #"{"value":null,"type":"STRING"}"#,
    ]
  )
  internal func fieldValueRejectsUntagged(_ json: String) {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(FieldValue.self, from: Data(json.utf8))
    }
  }
}
