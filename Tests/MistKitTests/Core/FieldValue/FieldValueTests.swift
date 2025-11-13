import Foundation
import Testing

@testable import MistKit

@Suite("Field Value")
/// Tests for FieldValue functionality
internal struct FieldValueTests {
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
    let trueValue = FieldValue.from(true)
    #expect(trueValue == .int64(1))

    let falseValue = FieldValue.from(false)
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
    let location = FieldValue.Location(
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
    let reference = FieldValue.Reference(recordName: "test-record")
    let value = FieldValue.reference(reference)
    #expect(value == .reference(reference))
  }

  /// Tests FieldValue asset type creation and equality
  @Test("FieldValue asset type creation and equality")
  internal func fieldValueAsset() {
    let asset = FieldValue.Asset(
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

  /// Tests FieldValue JSON encoding and decoding
  @Test("FieldValue JSON encoding and decoding")
  internal func fieldValueEncodable() throws {
    let value = FieldValue.string("test")
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(FieldValue.self, from: data)
    #expect(value == decoded)
  }
}
