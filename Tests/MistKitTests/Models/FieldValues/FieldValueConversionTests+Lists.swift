internal import Foundation
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

extension FieldValueConversionTests {
  @Suite("List Conversions")
  internal struct Lists {
    @Test("Convert list FieldValue with strings to Components.FieldValue")
    internal func convertListWithStrings() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let list: [FieldValue] = [.string("one"), .string("two"), .string("three")]
      let fieldValue = FieldValue.list(list)
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      if case .ListValue(let values) = components.value {
        #expect(values.count == 3)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("Convert list FieldValue with numbers to Components.FieldValue")
    internal func convertListWithNumbers() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let list: [FieldValue] = [.int64(1), .int64(2), .int64(3)]
      let fieldValue = FieldValue.list(list)
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      if case .ListValue(let values) = components.value {
        #expect(values.count == 3)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("Convert list FieldValue with mixed types to Components.FieldValue")
    internal func convertListWithMixedTypes() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let list: [FieldValue] = [
        .string("text"),
        .int64(42),
        .double(3.14),
        FieldValue(booleanValue: true),
      ]
      let fieldValue = FieldValue.list(list)
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      if case .ListValue(let values) = components.value {
        #expect(values.count == 4)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("Convert empty list FieldValue to Components.FieldValue")
    internal func convertEmptyList() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let list: [FieldValue] = []
      let fieldValue = FieldValue.list(list)
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      if case .ListValue(let values) = components.value {
        #expect(values.isEmpty)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("Convert nested list FieldValue to Components.FieldValue")
    internal func convertNestedList() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let innerList: [FieldValue] = [.string("a"), .string("b")]
      let outerList: [FieldValue] = [.list(innerList), .string("c")]
      let fieldValue = FieldValue.list(outerList)
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      // FieldValueRequest does not have a type field - CloudKit infers type from structure
      if case .ListValue(let values) = components.value {
        #expect(values.count == 2)
      } else {
        Issue.record("Expected ListValue")
      }
    }

    @Test("BYTES list element that is not valid base64 throws typeValueMismatch")
    internal func malformedBytesListElementThrows() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      ConversionFailureReporter.$assertionHandler.withValue(
        { _, _, _ in },
        operation: {
          #expect(
            throws: ConversionError.typeValueMismatch(
              fieldName: "field",
              declaredType: "BYTES",
              value: "not!valid!"
            )
          ) {
            _ = try FieldValue(listItem: .BytesValue("not!valid!"), fieldName: "field")
          }
        }
      )
    }

    @Test("Nested BYTES list element that is not valid base64 throws typeValueMismatch")
    internal func malformedBytesNestedListElementThrows() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      ConversionFailureReporter.$assertionHandler.withValue(
        { _, _, _ in },
        operation: {
          #expect(
            throws: ConversionError.typeValueMismatch(
              fieldName: "field",
              declaredType: "BYTES",
              value: "not!valid!"
            )
          ) {
            _ = try FieldValue(
              nestedListValue: [.BytesValue("not!valid!")],
              fieldName: "field"
            )
          }
        }
      )
    }

    @Test("BYTES list element with valid base64 reads as .bytes Data")
    internal func validBytesListElement() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let value = try FieldValue(listItem: .BytesValue("aGVsbG8="), fieldName: "field")
      #expect(value == .bytes(Data("hello".utf8)))
    }

    /// A fractional millisecond inside a list must be rounded, exactly as the scalar
    /// `.date` case is. CloudKit rejects a fractional TIMESTAMP with
    /// `BAD_REQUEST "Invalid value, expected type TIMESTAMP"`, and list elements carry no
    /// `type` tag of their own — so the value's shape is all CloudKit has to go on.
    @Test("List .date elements round to whole milliseconds")
    internal func convertListWithDatesRoundsMilliseconds() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let date = Date(timeIntervalSince1970: 1_747_999_812.3478923)
      let components = Components.Schemas.FieldValueRequest(from: .list([.date(date)]))

      guard case .ListValue(let values) = components.value, let first = values.first else {
        Issue.record("Expected a ListValue with one element")
        return
      }
      guard case .DateValue(let milliseconds) = first else {
        Issue.record("Expected a DateValue element")
        return
      }
      #expect(milliseconds == 1_747_999_812_348)
      #expect(milliseconds == milliseconds.rounded())
    }

    /// `Location.timestamp` nested inside a list element is a second millisecond field
    /// under the same constraint.
    @Test("List .location elements round their timestamp to whole milliseconds")
    internal func convertListWithLocationRoundsTimestamp() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let location = Location(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: Date(timeIntervalSince1970: 1_747_999_812.3478923)
      )
      let components = Components.Schemas.FieldValueRequest(from: .list([.location(location)]))

      guard case .ListValue(let values) = components.value, let first = values.first else {
        Issue.record("Expected a ListValue with one element")
        return
      }
      guard case .LocationValue(let locationValue) = first else {
        Issue.record("Expected a LocationValue element")
        return
      }
      guard let timestamp = locationValue.timestamp else {
        Issue.record("Expected a timestamp on the LocationValue")
        return
      }
      #expect(timestamp == 1_747_999_812_348)
      #expect(timestamp == timestamp.rounded())
    }
  }
}
