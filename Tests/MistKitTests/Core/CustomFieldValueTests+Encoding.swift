import Foundation
import Testing

@testable import MistKit

extension CustomFieldValueTests {
  // MARK: - Edge Cases

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
