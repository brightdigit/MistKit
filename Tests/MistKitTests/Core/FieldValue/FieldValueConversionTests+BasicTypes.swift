import Foundation
import Testing

@testable import MistKit

extension FieldValueConversionTests {
  @Suite("Basic Type Conversions")
  internal struct BasicTypes {
    @Test("Convert string FieldValue to Components.FieldValue")
    internal func convertString() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let fieldValue = FieldValue.string("test string")
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .string)
      if case .stringValue(let value) = components.value {
        #expect(value == "test string")
      } else {
        Issue.record("Expected stringValue")
      }
    }

    @Test("Convert int64 FieldValue to Components.FieldValue")
    internal func convertInt64() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let fieldValue = FieldValue.int64(42)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .int64)
      if case .int64Value(let value) = components.value {
        #expect(value == 42)
      } else {
        Issue.record("Expected int64Value")
      }
    }

    @Test("Convert double FieldValue to Components.FieldValue")
    internal func convertDouble() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let fieldValue = FieldValue.double(3.14159)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .double)
      if case .doubleValue(let value) = components.value {
        #expect(value == 3.14159)
      } else {
        Issue.record("Expected doubleValue")
      }
    }

    @Test("Convert boolean FieldValue to Components.FieldValue")
    internal func convertBoolean() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let trueValue = FieldValue(booleanValue: true)
      let trueComponents = Components.Schemas.FieldValue(from: trueValue)
      #expect(trueComponents.type == .int64)
      if case .int64Value(let value) = trueComponents.value {
        #expect(value == 1)
      } else {
        Issue.record("Expected int64Value 1 for true")
      }

      let falseValue = FieldValue(booleanValue: false)
      let falseComponents = Components.Schemas.FieldValue(from: falseValue)

      #expect(falseComponents.type == .int64)
      if case .int64Value(let value) = falseComponents.value {
        #expect(value == 0)
      } else {
        Issue.record("Expected int64Value 0 for false")
      }
    }

    @Test("Convert bytes FieldValue to Components.FieldValue")
    internal func convertBytes() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let fieldValue = FieldValue.bytes("base64encodedstring")
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .bytes)
      if case .bytesValue(let value) = components.value {
        #expect(value == "base64encodedstring")
      } else {
        Issue.record("Expected bytesValue")
      }
    }

    @Test("Convert date FieldValue to Components.FieldValue")
    internal func convertDate() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let date = Date(timeIntervalSince1970: 1_000_000)
      let fieldValue = FieldValue.date(date)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(components.type == .timestamp)
      if case .dateValue(let value) = components.value {
        #expect(value == date.timeIntervalSince1970 * 1_000)
      } else {
        Issue.record("Expected dateValue")
      }
    }
  }
}
