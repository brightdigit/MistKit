//
//  FieldValueConversionTests+Lists.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

// swiftlint:disable file_length type_body_length
extension FieldValueConversionTests {
  /// Homogeneous-list request/response conversions (issue #481).
  ///
  /// Bodies are omitted on Windows × Swift 6.2 to stay under the MistKitTests
  /// emit tip-over (see `.claude/memory/reference_windows_62_mistkittests_emit_abort.md`).
  @Suite("List Conversions", .disabled(if: Platform.isWindowsSwift62))
  internal struct Lists {
    private static let windowsTipOverMessage =
      "Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over)."

    private static func withSuppressedConversionAssert(
      _ body: () throws -> Void
    ) rethrows {
      try ConversionFailureReporter.$assertionHandler.withValue(
        { _, _, _ in },
        operation: body
      )
    }

    // MARK: - Request encoding (*_LIST tags)

    @Test("Convert STRING_LIST FieldValue with strings tags STRING_LIST")
    internal func convertListWithStrings() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
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
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("Convert INT64_LIST FieldValue with numbers tags INT64_LIST")
    internal func convertListWithNumbers() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
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
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("Convert DOUBLE_LIST FieldValue tags DOUBLE_LIST")
    internal func convertDoubleList() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let components = Components.Schemas.FieldValueRequest(
          from: .double(.list([1.5, 2.25]))
        )
        #expect(components._type == .DOUBLE_LIST)
        guard case .ListValue(let values) = components.value else {
          Issue.record("Expected listValue")
          return
        }
        #expect(values.count == 2)
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("Convert BYTES_LIST FieldValue tags BYTES_LIST")
    internal func convertBytesList() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let payload = Data("hello".utf8)
        let components = Components.Schemas.FieldValueRequest(
          from: .bytes(.list([payload]))
        )
        #expect(components._type == .BYTES_LIST)
        guard case .ListValue(let values) = components.value,
          case .BytesValue(let encoded) = values.first
        else {
          Issue.record("Expected BytesValue list element")
          return
        }
        #expect(encoded == payload.base64EncodedString())
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("Convert empty STRING_LIST tags STRING_LIST")
    internal func convertEmptyList() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
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
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("Convert REFERENCE_LIST FieldValue tags REFERENCE_LIST")
    internal func convertReferenceList() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let references = [
          Reference(recordName: "a", action: .deleteSelf),
          Reference(recordName: "b", action: Reference.Action.none),
          Reference(recordName: "c", action: .validate),
          Reference(recordName: "d"),
        ]
        let components = Components.Schemas.FieldValueRequest(
          from: .reference(.list(references))
        )
        #expect(components._type == .REFERENCE_LIST)
        guard case .ListValue(let values) = components.value else {
          Issue.record("Expected listValue")
          return
        }
        #expect(values.count == 4)
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("Convert ASSET_LIST FieldValue tags ASSET_LIST")
    internal func convertAssetList() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let asset = Asset(fileChecksum: "c", size: 1, downloadURL: "https://example.com")
        let components = Components.Schemas.FieldValueRequest(
          from: .asset(.list([asset]))
        )
        #expect(components._type == .ASSET_LIST)
        guard case .ListValue(let values) = components.value,
          case .AssetValue(let value) = values.first
        else {
          Issue.record("Expected AssetValue list element")
          return
        }
        #expect(value.fileChecksum == "c")
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    /// A fractional millisecond inside a list must be rounded, exactly as the scalar
    /// `.date` case is. CloudKit rejects a fractional TIMESTAMP with
    /// `BAD_REQUEST "Invalid value, expected type TIMESTAMP"`.
    @Test("List .date elements round to whole milliseconds")
    internal func convertListWithDatesRoundsMilliseconds() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
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
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    /// `Location.timestamp` nested inside a list element is a second millisecond field
    /// under the same constraint.
    @Test("List .location elements round their timestamp to whole milliseconds")
    internal func convertListWithLocationRoundsTimestamp() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
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
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    // MARK: - Tagged response decoding

    @Test("STRING_LIST response empty array decodes as .string(.list([]))")
    internal func decodeEmptyStringList() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
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
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("STRING_LIST response filled array decodes as .string(.list)")
    internal func decodeFilledStringList() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
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
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("INT64_LIST response decodes as .int64(.list)")
    internal func decodeInt64List() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let value = try FieldValue(
          listValue: [.Int64Value(1), .Int64Value(2)],
          elementKind: .int64,
          fieldName: "nums"
        )
        #expect(value == .int64(.list([1, 2])))
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("DOUBLE_LIST accepts DoubleValue and Int64Value elements")
    internal func decodeDoubleListCoercingInt64() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let value = try FieldValue(
          listValue: [.DoubleValue(1.5), .Int64Value(3)],
          elementKind: .double,
          fieldName: "scores"
        )
        #expect(value == .double(.list([1.5, 3.0])))
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("BYTES_LIST element that is not valid base64 throws typeValueMismatch")
    internal func malformedBytesListElementThrows() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        Self.withSuppressedConversionAssert {
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
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("BYTES_LIST accepts BytesValue and StringValue base64 elements")
    internal func validBytesListElement() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let hello = Data("hello".utf8)
        let value = try FieldValue(
          listValue: [
            .BytesValue("aGVsbG8="),
            .StringValue(hello.base64EncodedString()),
          ],
          elementKind: .bytes,
          fieldName: "field"
        )
        #expect(value == .bytes(.list([hello, hello])))
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("TIMESTAMP_LIST accepts DateValue, Int64Value, and DoubleValue elements")
    internal func decodeTimestampListNumericShapes() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let value = try FieldValue(
          listValue: [
            .DateValue(1_000),
            .Int64Value(2_000),
            .DoubleValue(3_000),
          ],
          elementKind: .date,
          fieldName: "dates"
        )
        #expect(
          value
            == .date(
              .list([
                Date(timeIntervalSince1970: 1),
                Date(timeIntervalSince1970: 2),
                Date(timeIntervalSince1970: 3),
              ])
            )
        )
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("LOCATION_LIST / REFERENCE_LIST / ASSET_LIST decode matching payloads")
    internal func decodeComplexLists() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let locationPayload = Components.Schemas.LocationValue(
          latitude: 1,
          longitude: 2
        )
        let locationValue = try FieldValue(
          listValue: [.LocationValue(locationPayload)],
          elementKind: .location,
          fieldName: "locs"
        )
        #expect(locationValue.locationListValue?.first?.latitude == 1)

        let referenceValue = try FieldValue(
          listValue: [
            .ReferenceValue(.init(recordName: "r1", action: .DELETE_SELF))
          ],
          elementKind: .reference,
          fieldName: "refs"
        )
        #expect(referenceValue.referenceListValue?.first?.recordName == "r1")

        let assetValue = try FieldValue(
          listValue: [
            .AssetValue(
              .init(fileChecksum: "chk", size: 9, downloadURL: "https://example.com")
            )
          ],
          elementKind: .asset,
          fieldName: "assets"
        )
        #expect(assetValue.assetListValue?.first?.fileChecksum == "chk")
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    // MARK: - Untagged inference + mismatches

    @Test("Empty untagged list becomes .string(.list([]))")
    internal func emptyUntaggedListDefaultsToString() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let value = try FieldValue(
          listValue: [],
          elementKind: nil,
          fieldName: "empty"
        )
        #expect(value == .string(.list([])))
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("Untagged list infers element kind from the first payload")
    internal func untaggedListInfersKind() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        #expect(
          try FieldValue(
            listValue: [.StringValue("a")],
            elementKind: nil,
            fieldName: "s"
          ) == .string(.list(["a"]))
        )
        #expect(
          try FieldValue(
            listValue: [.Int64Value(9)],
            elementKind: nil,
            fieldName: "i"
          ) == .int64(.list([9]))
        )
        #expect(
          try FieldValue(
            listValue: [.DoubleValue(1.25)],
            elementKind: nil,
            fieldName: "d"
          ) == .double(.list([1.25]))
        )
        #expect(
          try FieldValue(
            listValue: [.BytesValue("aGVsbG8=")],
            elementKind: nil,
            fieldName: "b"
          ) == .bytes(.list([Data("hello".utf8)]))
        )
        #expect(
          try FieldValue(
            listValue: [.DateValue(5_000)],
            elementKind: nil,
            fieldName: "t"
          ) == .date(.list([Date(timeIntervalSince1970: 5)]))
        )
        #expect(
          try FieldValue(
            listValue: [.LocationValue(.init(latitude: 3, longitude: 4))],
            elementKind: nil,
            fieldName: "l"
          ).locationListValue?.first?.longitude == 4
        )
        #expect(
          try FieldValue(
            listValue: [.ReferenceValue(.init(recordName: "x"))],
            elementKind: nil,
            fieldName: "r"
          ).referenceListValue?.first?.recordName == "x"
        )
        #expect(
          try FieldValue(
            listValue: [
              .AssetValue(.init(fileChecksum: "z", size: 1, downloadURL: "https://e.com"))
            ],
            elementKind: nil,
            fieldName: "a"
          ).assetListValue?.first?.fileChecksum == "z"
        )
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("Nested ListValue payload is unmappable")
    internal func nestedListValueThrows() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        Self.withSuppressedConversionAssert {
          #expect(throws: ConversionError.self) {
            _ = try FieldValue(
              listValue: [.ListValue([.StringValue("nested")])],
              elementKind: nil,
              fieldName: "bad"
            )
          }
        }
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("STRING_LIST tag over non-list value throws typeValueMismatch")
    internal func stringListOverScalarThrows() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        Self.withSuppressedConversionAssert {
          #expect(throws: ConversionError.self) {
            let data = Data(#"{"value": "plain", "type": "STRING_LIST"}"#.utf8)
            let response = try JSONDecoder().decode(
              Components.Schemas.FieldValueResponse.self,
              from: data
            )
            _ = try FieldValue(response, fieldName: "field")
          }
        }
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("Element kind mismatch throws typeValueMismatch for each require*")
    internal func elementKindMismatchThrows() {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        // STRING is accepted by BYTES_LIST (wire base64), so use a numeric wrong
        // payload for the bytes mismatch and a string wrong payload for the rest.
        Self.withSuppressedConversionAssert {
          #expect(throws: ConversionError.self) {
            _ = try FieldValue(
              listValue: [.Int64Value(1)],
              elementKind: .string,
              fieldName: "field"
            )
          }
          #expect(throws: ConversionError.self) {
            _ = try FieldValue(
              listValue: [.StringValue("nope")],
              elementKind: .int64,
              fieldName: "field"
            )
          }
          #expect(throws: ConversionError.self) {
            _ = try FieldValue(
              listValue: [.StringValue("nope")],
              elementKind: .double,
              fieldName: "field"
            )
          }
          #expect(throws: ConversionError.self) {
            _ = try FieldValue(
              listValue: [.Int64Value(1)],
              elementKind: .bytes,
              fieldName: "field"
            )
          }
          #expect(throws: ConversionError.self) {
            _ = try FieldValue(
              listValue: [.StringValue("nope")],
              elementKind: .date,
              fieldName: "field"
            )
          }
          #expect(throws: ConversionError.self) {
            _ = try FieldValue(
              listValue: [.StringValue("nope")],
              elementKind: .location,
              fieldName: "field"
            )
          }
          #expect(throws: ConversionError.self) {
            _ = try FieldValue(
              listValue: [.StringValue("nope")],
              elementKind: .reference,
              fieldName: "field"
            )
          }
          #expect(throws: ConversionError.self) {
            _ = try FieldValue(
              listValue: [.StringValue("nope")],
              elementKind: .asset,
              fieldName: "field"
            )
          }
        }
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }

    @Test("Homogeneous list JSON Codable round-trips for non-bytes kinds")
    internal func listCodableRoundTrip() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
          Issue.record("FieldValue is not available on this operating system.")
          return
        }
        let cases: [FieldValue] = [
          .string(.list(["a", "b"])),
          .int64(.list([1, 2])),
          .double(.list([1.5, 2.5])),
          .location(.list([Location(latitude: 1, longitude: 2)])),
          .reference(.list([Reference(recordName: "r")])),
          .asset(
            .list([
              Asset(fileChecksum: "c", size: 1, downloadURL: "https://example.com")
            ])
          ),
        ]
        for value in cases {
          let data = try JSONEncoder().encode(value)
          let decoded = try JSONDecoder().decode(FieldValue.self, from: data)
          #expect(decoded == value)
        }
      #else
        Issue.record(Self.windowsTipOverMessage)
      #endif
    }
  }
}
// swiftlint:enable file_length type_body_length
