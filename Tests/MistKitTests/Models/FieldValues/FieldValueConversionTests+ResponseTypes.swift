internal import Foundation
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

extension FieldValueConversionTests {
  /// Read-path coverage for issue #375: an explicit CloudKit `type` must win over the
  /// undiscriminated `oneOf` decode (String → Int64 → Double → Bytes → Date), so that
  /// ambiguous scalars round-trip instead of reading back as the wrong domain case.
  @Suite("Response Type Conversions")
  internal struct ResponseTypes {
    private static func decode(_ json: String) throws -> FieldValue {
      let data = Data(json.utf8)
      let response = try JSONDecoder().decode(
        Components.Schemas.FieldValueResponse.self,
        from: data
      )
      return try FieldValue(response, fieldName: "field")
    }

    /// Expects decoding `json` to throw a `ConversionError`, with the DEBUG assertion
    /// trap suppressed so the throw is observed rather than trapped.
    private func expectThrows(_ json: String) {
      ConversionFailureReporter.$assertionHandler.withValue(
        { _, _, _ in },
        operation: {
          #expect(throws: ConversionError.self) {
            _ = try Self.decode(json)
          }
        }
      )
    }

    @Test("Whole-millisecond TIMESTAMP reads back as .date, not .int64")
    internal func wholeNumberTimestamp() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      // A whole number decodes as Int64Value, but type TIMESTAMP must recover .date.
      let value = try Self.decode(#"{"value": 1493382919000, "type": "TIMESTAMP"}"#)
      #expect(value == .date(Date(timeIntervalSince1970: 1_493_382_919)))
    }

    @Test("Fractional TIMESTAMP reads back as .date")
    internal func fractionalTimestamp() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let value = try Self.decode(#"{"value": 1000500.0, "type": "TIMESTAMP"}"#)
      #expect(value == .date(Date(timeIntervalSince1970: 1_000.5)))
    }

    @Test("BYTES with type reads back as .bytes, not .string")
    internal func bytesWithType() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let value = try Self.decode(#"{"value": "aGVsbG8=", "type": "BYTES"}"#)
      #expect(value == .bytes("aGVsbG8="))
    }

    @Test("Whole-valued DOUBLE with type reads back as .double, not .int64")
    internal func wholeValuedDouble() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let value = try Self.decode(#"{"value": 5, "type": "DOUBLE"}"#)
      #expect(value == .double(5.0))
    }

    @Test("Explicit STRING and INT64 types match their inferred value shape")
    internal func explicitStringAndInt() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      #expect(try Self.decode(#"{"value": "hello", "type": "STRING"}"#) == .string("hello"))
      #expect(try Self.decode(#"{"value": 42, "type": "INT64"}"#) == .int64(42))
    }

    @Test("A scalar type that contradicts the value's shape throws")
    internal func contradictingScalarTypeThrows() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      // A numeric scalar type over a non-numeric value, or a string scalar type over a
      // non-string value, is an internally inconsistent response and must not be coerced.
      expectThrows(#"{"value": "hello", "type": "TIMESTAMP"}"#)
      expectThrows(#"{"value": 42, "type": "BYTES"}"#)
      expectThrows(#"{"value": 42, "type": "STRING"}"#)
      expectThrows(#"{"value": "x", "type": "DOUBLE"}"#)
      expectThrows(#"{"value": "x", "type": "INT64"}"#)
      // A numeric scalar type over a complex value is likewise a contradiction.
      expectThrows(#"{"value": {"recordName": "r"}, "type": "TIMESTAMP"}"#)
    }

    @Test("INT64 over a numeric value defers to inference without truncating")
    internal func int64DefersToInference() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      // 3.5 satisfies the numeric category, so INT64 validates then defers to inference,
      // preserving .double rather than truncating to an integer.
      #expect(try Self.decode(#"{"value": 3.5, "type": "INT64"}"#) == .double(3.5))
    }

    @Test("A complex or list declared type that contradicts the value's shape throws")
    internal func complexTypeContradictionThrows() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      // Issue #376: complex/list tags are now validated against the decoded value the same
      // way scalar tags are. A REFERENCE/ASSET/LOCATION/*_LIST over an incompatible value is
      // an internally inconsistent response and must throw, not silently coerce to the shape.
      expectThrows(#"{"value": 42, "type": "REFERENCE"}"#)
      expectThrows(#"{"value": "text", "type": "ASSET"}"#)
      expectThrows(#"{"value": 42, "type": "LOCATION"}"#)
      expectThrows(#"{"value": 42, "type": "LIST"}"#)
      // A complex tag over the *wrong* complex value (LOCATION shape under a REFERENCE tag)
      // is likewise a contradiction.
      expectThrows(#"{"value": {"latitude": 1, "longitude": 2}, "type": "REFERENCE"}"#)
    }

    @Test("A complex or list declared type matching its value converts faithfully")
    internal func complexTypeMatchingValueConverts() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      // A declared complex/list type whose value satisfies it round-trips unchanged —
      // the validation only rejects contradictions, never well-formed responses.
      let reference = try Self.decode(#"{"value": {"recordName": "rec1"}, "type": "REFERENCE"}"#)
      #expect(reference == .reference(Reference(recordName: "rec1")))

      let locationJSON = #"{"value": {"latitude": 37.3, "longitude": -122}, "type": "LOCATION"}"#
      let location = try Self.decode(locationJSON)
      guard case .location(let loc) = location else {
        Issue.record("Expected .location, got \(location)")
        return
      }
      #expect(loc.latitude == 37.3)
      #expect(loc.longitude == -122)

      // ASSETID maps to the same AssetValue as ASSET.
      let assetJSON = #"{"value": {"fileChecksum": "chk"}, "type": "ASSETID"}"#
      let asset = try Self.decode(assetJSON)
      guard case .asset(let assetValue) = asset else {
        Issue.record("Expected .asset, got \(asset)")
        return
      }
      #expect(assetValue.fileChecksum == "chk")

      let list = try Self.decode(#"{"value": ["a", "b"], "type": "LIST"}"#)
      #expect(list == .list([.string("a"), .string("b")]))
    }

    @Test("Without a type, scalars fall back to first-match-wins inference")
    internal func inferenceWithoutType() throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      #expect(try Self.decode(#"{"value": "plain"}"#) == .string("plain"))
      #expect(try Self.decode(#"{"value": 42}"#) == .int64(42))
      #expect(try Self.decode(#"{"value": 3.5}"#) == .double(3.5))
    }
  }
}
