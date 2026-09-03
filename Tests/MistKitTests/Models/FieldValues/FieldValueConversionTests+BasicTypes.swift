internal import Foundation
internal import MistKitOpenAPI
internal import Testing

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
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      if case .StringValue(let value) = components.value {
        #expect(value == "test string")
      } else {
        Issue.record("Expected stringValue")
      }
      // A string is unambiguous on the wire, so no type tag is sent.
      #expect(components._type == nil)
    }

    @Test("Convert int64 FieldValue to Components.FieldValue")
    internal func convertInt64() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let fieldValue = FieldValue.int64(42)
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      if case .Int64Value(let value) = components.value {
        #expect(value == 42)
      } else {
        Issue.record("Expected int64Value")
      }
      // An integer is the default inference for a whole number, so no type tag is sent.
      #expect(components._type == nil)
    }

    @Test("Convert double FieldValue to Components.FieldValue")
    internal func convertDouble() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let fieldValue = FieldValue.double(3.14159)
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      if case .DoubleValue(let value) = components.value {
        #expect(value == 3.14159)
      } else {
        Issue.record("Expected doubleValue")
      }
      // A whole-valued double would otherwise be inferred as INT64, so DOUBLE is tagged.
      #expect(components._type == .DOUBLE)
    }

    @Test("Convert boolean FieldValue to Components.FieldValue")
    internal func convertBoolean() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let trueValue = FieldValue(booleanValue: true)
      let trueComponents = Components.Schemas.FieldValueRequest(from: trueValue)
      if case .Int64Value(let value) = trueComponents.value {
        #expect(value == 1)
      } else {
        Issue.record("Expected int64Value 1 for true")
      }

      let falseValue = FieldValue(booleanValue: false)
      let falseComponents = Components.Schemas.FieldValueRequest(from: falseValue)

      if case .Int64Value(let value) = falseComponents.value {
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
      let payload = Data("hello".utf8)
      let fieldValue = FieldValue.bytes(payload)
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      if case .BytesValue(let value) = components.value {
        #expect(value == payload.base64EncodedString())
      } else {
        Issue.record("Expected bytesValue")
      }
      // A base64 string would otherwise be inferred as STRING, so BYTES is tagged.
      #expect(components._type == .BYTES)
    }

    @Test("Convert date FieldValue to Components.FieldValue")
    internal func convertDate() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let date = Date(timeIntervalSince1970: 1_000_000)
      let fieldValue = FieldValue.date(date)
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      if case .DateValue(let value) = components.value {
        #expect(value == date.timeIntervalSince1970 * 1_000)
      } else {
        Issue.record("Expected dateValue")
      }
      // Without TIMESTAMP, CloudKit infers INT64 and rejects the write (issue #375).
      #expect(components._type == .TIMESTAMP)
    }

    @Test("Convert fractional date rounds to whole milliseconds")
    internal func convertFractionalDate() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      // Date carries sub-millisecond precision; CloudKit rejects a fractional TIMESTAMP
      // value with BAD_REQUEST, so the millisecond value must be a whole number.
      let date = Date(timeIntervalSince1970: 1_747_999_812.3478923)
      let components = Components.Schemas.FieldValueRequest(from: .date(date))

      if case .DateValue(let value) = components.value {
        #expect(value == 1_747_999_812_348)
        #expect(value == value.rounded())
      } else {
        Issue.record("Expected dateValue")
      }
      #expect(components._type == .TIMESTAMP)
    }
  }
}
