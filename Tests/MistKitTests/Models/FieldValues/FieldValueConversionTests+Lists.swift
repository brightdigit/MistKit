internal import Foundation
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

extension FieldValueConversionTests {
  @Suite("List Conversions")
  internal struct Lists {
    @Test("Convert STRING_LIST FieldValue with strings tags STRING_LIST")
    internal func convertListWithStrings() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let fieldValue = FieldValue.string(.list(["one", "two", "three"]))
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      #expect(components._type == .STRING_LIST)
      if case .ListValue(let values) = components.value {
        #expect(values.count == 3)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("Convert INT64_LIST FieldValue with numbers tags INT64_LIST")
    internal func convertListWithNumbers() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let fieldValue = FieldValue.int64(.list([1, 2, 3]))
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      #expect(components._type == .INT64_LIST)
      if case .ListValue(let values) = components.value {
        #expect(values.count == 3)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("Convert empty STRING_LIST tags STRING_LIST")
    internal func convertEmptyList() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let fieldValue = FieldValue.string(.list([]))
      let components = Components.Schemas.FieldValueRequest(from: fieldValue)

      #expect(components._type == .STRING_LIST)
      if case .ListValue(let values) = components.value {
        #expect(values.isEmpty)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("STRING_LIST response empty array decodes as .string(.list([]))")
    internal func decodeEmptyStringList() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let data = Data(#"{"value": [], "type": "STRING_LIST"}"#.utf8)
      let response = try JSONDecoder().decode(
        Components.Schemas.FieldValueResponse.self,
        from: data
      )
      let value = try FieldValue(response, fieldName: "tags")
      #expect(value == .string(.list([])))
    }

    @Test("STRING_LIST response filled array decodes as .string(.value(.list))")
    internal func decodeFilledStringList() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let data = Data(#"{"value": ["a", "b"], "type": "STRING_LIST"}"#.utf8)
      let response = try JSONDecoder().decode(
        Components.Schemas.FieldValueResponse.self,
        from: data
      )
      let value = try FieldValue(response, fieldName: "tags")
      #expect(value == .string(.list(["a", "b"])))
    }

    @Test("BYTES_LIST element that is not valid base64 throws typeValueMismatch")
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
              declaredType: "BYTES_LIST",
              value: "not!valid!"
            )
          ) {
            _ = try FieldValue(
              listValue: [.BytesValue("not!valid!")],
              elementKind: .bytes,
              fieldName: "field"
            )
          }
        }
      )
    }

    @Test("BYTES_LIST element with valid base64 reads as .bytes(.value(.list))")
    internal func validBytesListElement() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let value = try FieldValue(
        listValue: [.BytesValue("aGVsbG8=")],
        elementKind: .bytes,
        fieldName: "field"
      )
      #expect(value == .bytes(.list([Data("hello".utf8)])))
    }

    /// A fractional millisecond inside a list must be rounded, exactly as the scalar
    /// `.date` case is. CloudKit rejects a fractional TIMESTAMP with
    /// `BAD_REQUEST "Invalid value, expected type TIMESTAMP"`.
    @Test("List .date elements round to whole milliseconds")
    internal func convertListWithDatesRoundsMilliseconds() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let date = Date(timeIntervalSince1970: 1_747_999_812.3478923)
      let components = Components.Schemas.FieldValueRequest(
        from: .date(.list([date]))
      )

      #expect(components._type == .TIMESTAMP_LIST)
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
      let components = Components.Schemas.FieldValueRequest(
        from: .location(.list([location]))
      )

      #expect(components._type == .LOCATION_LIST)
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

    @Test("STRING_LIST tag over non-list value throws typeValueMismatch")
    internal func stringListOverScalarThrows() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      ConversionFailureReporter.$assertionHandler.withValue(
        { _, _, _ in },
        operation: {
          #expect(throws: ConversionError.self) {
            let data = Data(#"{"value": "plain", "type": "STRING_LIST"}"#.utf8)
            let response = try JSONDecoder().decode(
              Components.Schemas.FieldValueResponse.self,
              from: data
            )
            _ = try FieldValue(response, fieldName: "field")
          }
        }
      )
    }
  }
}
