import Foundation
import Testing

@testable import MistKit

@Suite("FieldValue Conversion Tests")
internal struct FieldValueConversionTests {
  // MARK: - Basic Type Conversions

  @Test("Convert string FieldValue to Components.FieldValue")
  func convertString() {
    let fieldValue = FieldValue.string("test string")
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .string)
    if case let .stringValue(value) = components.value {
      #expect(value == "test string")
    } else {
      Issue.record("Expected stringValue")
    }
  }

  @Test("Convert int64 FieldValue to Components.FieldValue")
  func convertInt64() {
    let fieldValue = FieldValue.int64(42)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .int64)
    if case let .int64Value(value) = components.value {
      #expect(value == 42)
    } else {
      Issue.record("Expected int64Value")
    }
  }

  @Test("Convert double FieldValue to Components.FieldValue")
  func convertDouble() {
    let fieldValue = FieldValue.double(3.14159)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .double)
    if case let .doubleValue(value) = components.value {
      #expect(value == 3.14159)
    } else {
      Issue.record("Expected doubleValue")
    }
  }

  @Test("Convert boolean FieldValue to Components.FieldValue")
  func convertBoolean() {
    let trueValue = FieldValue.boolean(true)
    let trueComponents = trueValue.toComponentsFieldValue()
    #expect(trueComponents.type == .int64)
    if case let .booleanValue(value) = trueComponents.value {
      #expect(value == true)
    } else {
      Issue.record("Expected booleanValue true")
    }

    let falseValue = FieldValue.boolean(false)
    let falseComponents = falseValue.toComponentsFieldValue()
    #expect(falseComponents.type == .int64)
    if case let .booleanValue(value) = falseComponents.value {
      #expect(value == false)
    } else {
      Issue.record("Expected booleanValue false")
    }
  }

  @Test("Convert bytes FieldValue to Components.FieldValue")
  func convertBytes() {
    let fieldValue = FieldValue.bytes("base64encodedstring")
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .bytes)
    if case let .bytesValue(value) = components.value {
      #expect(value == "base64encodedstring")
    } else {
      Issue.record("Expected bytesValue")
    }
  }

  @Test("Convert date FieldValue to Components.FieldValue")
  func convertDate() {
    let date = Date(timeIntervalSince1970: 1_000_000)
    let fieldValue = FieldValue.date(date)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .timestamp)
    if case let .dateValue(value) = components.value {
      #expect(value == date.timeIntervalSince1970 * 1_000)
    } else {
      Issue.record("Expected dateValue")
    }
  }

  // MARK: - Complex Type Conversions

  @Test("Convert location FieldValue to Components.FieldValue")
  func convertLocation() {
    let location = FieldValue.Location(
      latitude: 37.7749,
      longitude: -122.4194,
      horizontalAccuracy: 10.0,
      verticalAccuracy: 5.0,
      altitude: 100.0,
      speed: 2.5,
      course: 45.0,
      timestamp: Date(timeIntervalSince1970: 1_000_000)
    )
    let fieldValue = FieldValue.location(location)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .location)
    if case let .locationValue(value) = components.value {
      #expect(value.latitude == 37.7749)
      #expect(value.longitude == -122.4194)
      #expect(value.horizontalAccuracy == 10.0)
      #expect(value.verticalAccuracy == 5.0)
      #expect(value.altitude == 100.0)
      #expect(value.speed == 2.5)
      #expect(value.course == 45.0)
      #expect(value.timestamp != nil)
    } else {
      Issue.record("Expected locationValue")
    }
  }

  @Test("Convert location with minimal fields to Components.FieldValue")
  func convertMinimalLocation() {
    let location = FieldValue.Location(latitude: 0.0, longitude: 0.0)
    let fieldValue = FieldValue.location(location)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .location)
    if case let .locationValue(value) = components.value {
      #expect(value.latitude == 0.0)
      #expect(value.longitude == 0.0)
      #expect(value.horizontalAccuracy == nil)
      #expect(value.verticalAccuracy == nil)
      #expect(value.altitude == nil)
      #expect(value.speed == nil)
      #expect(value.course == nil)
      #expect(value.timestamp == nil)
    } else {
      Issue.record("Expected locationValue")
    }
  }

  @Test("Convert reference FieldValue without action to Components.FieldValue")
  func convertReferenceWithoutAction() {
    let reference = FieldValue.Reference(recordName: "test-record-123")
    let fieldValue = FieldValue.reference(reference)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .reference)
    if case let .referenceValue(value) = components.value {
      #expect(value.recordName == "test-record-123")
      #expect(value.action == nil)
    } else {
      Issue.record("Expected referenceValue")
    }
  }

  @Test("Convert reference FieldValue with DELETE_SELF action to Components.FieldValue")
  func convertReferenceWithDeleteSelfAction() {
    let reference = FieldValue.Reference(recordName: "test-record-456", action: "DELETE_SELF")
    let fieldValue = FieldValue.reference(reference)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .reference)
    if case let .referenceValue(value) = components.value {
      #expect(value.recordName == "test-record-456")
      #expect(value.action == .DELETE_SELF)
    } else {
      Issue.record("Expected referenceValue")
    }
  }

  @Test("Convert reference FieldValue with non-DELETE_SELF action to Components.FieldValue")
  func convertReferenceWithOtherAction() {
    let reference = FieldValue.Reference(recordName: "test-record-789", action: "SOME_OTHER_ACTION")
    let fieldValue = FieldValue.reference(reference)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .reference)
    if case let .referenceValue(value) = components.value {
      #expect(value.recordName == "test-record-789")
      #expect(value.action == nil)
    } else {
      Issue.record("Expected referenceValue")
    }
  }

  @Test("Convert asset FieldValue with all fields to Components.FieldValue")
  func convertAssetWithAllFields() {
    let asset = FieldValue.Asset(
      fileChecksum: "abc123",
      size: 1_024,
      referenceChecksum: "def456",
      wrappingKey: "key789",
      receipt: "receipt_xyz",
      downloadURL: "https://example.com/file.jpg"
    )
    let fieldValue = FieldValue.asset(asset)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .asset)
    if case let .assetValue(value) = components.value {
      #expect(value.fileChecksum == "abc123")
      #expect(value.size == 1_024)
      #expect(value.referenceChecksum == "def456")
      #expect(value.wrappingKey == "key789")
      #expect(value.receipt == "receipt_xyz")
      #expect(value.downloadURL == "https://example.com/file.jpg")
    } else {
      Issue.record("Expected assetValue")
    }
  }

  @Test("Convert asset FieldValue with minimal fields to Components.FieldValue")
  func convertAssetWithMinimalFields() {
    let asset = FieldValue.Asset()
    let fieldValue = FieldValue.asset(asset)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .asset)
    if case let .assetValue(value) = components.value {
      #expect(value.fileChecksum == nil)
      #expect(value.size == nil)
      #expect(value.referenceChecksum == nil)
      #expect(value.wrappingKey == nil)
      #expect(value.receipt == nil)
      #expect(value.downloadURL == nil)
    } else {
      Issue.record("Expected assetValue")
    }
  }

  // MARK: - List Conversions

  @Test("Convert list FieldValue with strings to Components.FieldValue")
  func convertListWithStrings() {
    let list: [FieldValue] = [.string("one"), .string("two"), .string("three")]
    let fieldValue = FieldValue.list(list)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .list)
    if case let .listValue(values) = components.value {
      #expect(values.count == 3)
    } else {
      Issue.record("Expected listValue")
    }
  }

  @Test("Convert list FieldValue with numbers to Components.FieldValue")
  func convertListWithNumbers() {
    let list: [FieldValue] = [.int64(1), .int64(2), .int64(3)]
    let fieldValue = FieldValue.list(list)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .list)
    if case let .listValue(values) = components.value {
      #expect(values.count == 3)
    } else {
      Issue.record("Expected listValue")
    }
  }

  @Test("Convert list FieldValue with mixed types to Components.FieldValue")
  func convertListWithMixedTypes() {
    let list: [FieldValue] = [
      .string("text"),
      .int64(42),
      .double(3.14),
      .boolean(true),
    ]
    let fieldValue = FieldValue.list(list)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .list)
    if case let .listValue(values) = components.value {
      #expect(values.count == 4)
    } else {
      Issue.record("Expected listValue")
    }
  }

  @Test("Convert empty list FieldValue to Components.FieldValue")
  func convertEmptyList() {
    let list: [FieldValue] = []
    let fieldValue = FieldValue.list(list)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .list)
    if case let .listValue(values) = components.value {
      #expect(values.isEmpty)
    } else {
      Issue.record("Expected listValue")
    }
  }

  @Test("Convert nested list FieldValue to Components.FieldValue")
  func convertNestedList() {
    let innerList: [FieldValue] = [.string("a"), .string("b")]
    let outerList: [FieldValue] = [.list(innerList), .string("c")]
    let fieldValue = FieldValue.list(outerList)
    let components = fieldValue.toComponentsFieldValue()

    #expect(components.type == .list)
    if case let .listValue(values) = components.value {
      #expect(values.count == 2)
    } else {
      Issue.record("Expected listValue")
    }
  }

  // MARK: - Edge Cases

  @Test("Convert zero values")
  func convertZeroValues() {
    let intZero = FieldValue.int64(0)
    let intComponents = intZero.toComponentsFieldValue()
    #expect(intComponents.type == .int64)

    let doubleZero = FieldValue.double(0.0)
    let doubleComponents = doubleZero.toComponentsFieldValue()
    #expect(doubleComponents.type == .double)
  }

  @Test("Convert negative values")
  func convertNegativeValues() {
    let negativeInt = FieldValue.int64(-100)
    let intComponents = negativeInt.toComponentsFieldValue()
    #expect(intComponents.type == .int64)

    let negativeDouble = FieldValue.double(-3.14)
    let doubleComponents = negativeDouble.toComponentsFieldValue()
    #expect(doubleComponents.type == .double)
  }

  @Test("Convert large numbers")
  func convertLargeNumbers() {
    let largeInt = FieldValue.int64(Int.max)
    let intComponents = largeInt.toComponentsFieldValue()
    #expect(intComponents.type == .int64)

    let largeDouble = FieldValue.double(Double.greatestFiniteMagnitude)
    let doubleComponents = largeDouble.toComponentsFieldValue()
    #expect(doubleComponents.type == .double)
  }

  @Test("Convert empty string")
  func convertEmptyString() {
    let emptyString = FieldValue.string("")
    let components = emptyString.toComponentsFieldValue()
    #expect(components.type == .string)
  }

  @Test("Convert string with special characters")
  func convertStringWithSpecialCharacters() {
    let specialString = FieldValue.string("Hello\nWorld\t🌍")
    let components = specialString.toComponentsFieldValue()
    #expect(components.type == .string)
  }
}
