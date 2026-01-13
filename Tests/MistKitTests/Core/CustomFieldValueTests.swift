import Foundation
import Testing

@testable import MistKit

@Suite("CustomFieldValue Tests")
internal struct CustomFieldValueTests {
  // MARK: - Initialization Tests

  @Test("CustomFieldValue init with string value and type")
  internal func initWithStringValue() {
    let fieldValue = CustomFieldValue(
      value: .stringValue("test"),
      type: .string
    )

    #expect(fieldValue.type == .string)
    if case .stringValue(let value) = fieldValue.value {
      #expect(value == "test")
    } else {
      Issue.record("Expected stringValue")
    }
  }

  @Test("CustomFieldValue init with int64 value and type")
  internal func initWithInt64Value() {
    let fieldValue = CustomFieldValue(
      value: .int64Value(42),
      type: .int64
    )

    #expect(fieldValue.type == .int64)
    if case .int64Value(let value) = fieldValue.value {
      #expect(value == 42)
    } else {
      Issue.record("Expected int64Value")
    }
  }

  @Test("CustomFieldValue init with double value and type")
  internal func initWithDoubleValue() {
    let fieldValue = CustomFieldValue(
      value: .doubleValue(3.14),
      type: .double
    )

    #expect(fieldValue.type == .double)
    if case .doubleValue(let value) = fieldValue.value {
      #expect(value == 3.14)
    } else {
      Issue.record("Expected doubleValue")
    }
  }

  @Test("CustomFieldValue init with boolean value and type")
  internal func initWithBooleanValue() {
    let fieldValue = CustomFieldValue(
      value: .booleanValue(true),
      type: .int64
    )

    #expect(fieldValue.type == .int64)
    if case .booleanValue(let value) = fieldValue.value {
      #expect(value == true)
    } else {
      Issue.record("Expected booleanValue")
    }
  }

  @Test("CustomFieldValue init with date value and type")
  internal func initWithDateValue() {
    let timestamp = 1_000_000.0
    let fieldValue = CustomFieldValue(
      value: .dateValue(timestamp),
      type: .timestamp
    )

    #expect(fieldValue.type == .timestamp)
    if case .dateValue(let value) = fieldValue.value {
      #expect(value == timestamp)
    } else {
      Issue.record("Expected dateValue")
    }
  }

  @Test("CustomFieldValue init with bytes value and type")
  internal func initWithBytesValue() {
    let fieldValue = CustomFieldValue(
      value: .bytesValue("base64data"),
      type: .bytes
    )

    #expect(fieldValue.type == .bytes)
    if case .bytesValue(let value) = fieldValue.value {
      #expect(value == "base64data")
    } else {
      Issue.record("Expected bytesValue")
    }
  }

  @Test("CustomFieldValue init with reference value and type")
  internal func initWithReferenceValue() {
    let reference = Components.Schemas.ReferenceValue(
      recordName: "test-record",
      action: .DELETE_SELF
    )
    let fieldValue = CustomFieldValue(
      value: .referenceValue(reference),
      type: .reference
    )

    #expect(fieldValue.type == .reference)
    if case .referenceValue(let value) = fieldValue.value {
      #expect(value.recordName == "test-record")
      #expect(value.action == .DELETE_SELF)
    } else {
      Issue.record("Expected referenceValue")
    }
  }

  @Test("CustomFieldValue init with location value and type")
  internal func initWithLocationValue() {
    let location = Components.Schemas.LocationValue(
      latitude: 37.7749,
      longitude: -122.4194
    )
    let fieldValue = CustomFieldValue(
      value: .locationValue(location),
      type: .location
    )

    #expect(fieldValue.type == .location)
    if case .locationValue(let value) = fieldValue.value {
      #expect(value.latitude == 37.7749)
      #expect(value.longitude == -122.4194)
    } else {
      Issue.record("Expected locationValue")
    }
  }

  @Test("CustomFieldValue init with asset value and type")
  internal func initWithAssetValue() {
    let asset = Components.Schemas.AssetValue(
      fileChecksum: "checksum123",
      size: 1_024
    )
    let fieldValue = CustomFieldValue(
      value: .assetValue(asset),
      type: .asset
    )

    #expect(fieldValue.type == .asset)
    if case .assetValue(let value) = fieldValue.value {
      #expect(value.fileChecksum == "checksum123")
      #expect(value.size == 1_024)
    } else {
      Issue.record("Expected assetValue")
    }
  }

  @Test("CustomFieldValue init with asset value and assetid type")
  internal func initWithAssetValueAndAssetidType() {
    let asset = Components.Schemas.AssetValue(
      fileChecksum: "checksum456",
      size: 2_048
    )
    let fieldValue = CustomFieldValue(
      value: .assetValue(asset),
      type: .assetid
    )

    #expect(fieldValue.type == .assetid)
    if case .assetValue(let value) = fieldValue.value {
      #expect(value.fileChecksum == "checksum456")
      #expect(value.size == 2_048)
    } else {
      Issue.record("Expected assetValue")
    }
  }

  @Test("CustomFieldValue init with list value and type")
  internal func initWithListValue() {
    let list: [CustomFieldValue.CustomFieldValuePayload] = [
      .stringValue("one"),
      .int64Value(2),
      .doubleValue(3.0),
    ]
    let fieldValue = CustomFieldValue(
      value: .listValue(list),
      type: .list
    )

    #expect(fieldValue.type == .list)
    if case .listValue(let values) = fieldValue.value {
      #expect(values.count == 3)
    } else {
      Issue.record("Expected listValue")
    }
  }

  @Test("CustomFieldValue init with empty list")
  internal func initWithEmptyList() {
    let fieldValue = CustomFieldValue(
      value: .listValue([]),
      type: .list
    )

    #expect(fieldValue.type == .list)
    if case .listValue(let values) = fieldValue.value {
      #expect(values.isEmpty)
    } else {
      Issue.record("Expected listValue")
    }
  }

  @Test("CustomFieldValue init with nil type")
  internal func initWithNilType() {
    let fieldValue = CustomFieldValue(
      value: .stringValue("test"),
      type: nil
    )

    #expect(fieldValue.type == nil)
    if case .stringValue(let value) = fieldValue.value {
      #expect(value == "test")
    } else {
      Issue.record("Expected stringValue")
    }
  }

  // MARK: - Encoding/Decoding Tests

  @Test("CustomFieldValue encodes and decodes string correctly")
  internal func encodeDecodeString() throws {
    let original = CustomFieldValue(
      value: .stringValue("test string"),
      type: .string
    )

    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(CustomFieldValue.self, from: encoded)

    #expect(decoded.type == .string)
    if case .stringValue(let value) = decoded.value {
      #expect(value == "test string")
    } else {
      Issue.record("Expected stringValue")
    }
  }

  @Test("CustomFieldValue encodes and decodes int64 correctly")
  internal func encodeDecodeInt64() throws {
    let original = CustomFieldValue(
      value: .int64Value(123),
      type: .int64
    )

    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(CustomFieldValue.self, from: encoded)

    #expect(decoded.type == .int64)
    if case .int64Value(let value) = decoded.value {
      #expect(value == 123)
    } else {
      Issue.record("Expected int64Value")
    }
  }

  @Test("CustomFieldValue encodes and decodes boolean correctly")
  internal func encodeDecodeBoolean() throws {
    let original = CustomFieldValue(
      value: .booleanValue(true),
      type: .int64
    )

    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(CustomFieldValue.self, from: encoded)

    #expect(decoded.type == .int64)
    // Note: Booleans encode as int64 (0 or 1)
    if case .int64Value(let value) = decoded.value {
      #expect(value == 1)
    } else {
      Issue.record("Expected int64Value from boolean encoding")
    }
  }
}
