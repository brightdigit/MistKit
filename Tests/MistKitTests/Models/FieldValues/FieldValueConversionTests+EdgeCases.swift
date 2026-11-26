internal import Foundation
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

extension FieldValueConversionTests {
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("Convert zero values")
    internal func convertZeroValues() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let intZero = FieldValue.int64(.value(0))
      _ = Components.Schemas.FieldValueRequest(from: intZero)

      let doubleZero = FieldValue.double(.value(0.0))
      _ = Components.Schemas.FieldValueRequest(from: doubleZero)
    }

    @Test("Convert negative values")
    internal func convertNegativeValues() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let negativeInt = FieldValue.int64(.value(-100))
      _ = Components.Schemas.FieldValueRequest(from: negativeInt)

      let negativeDouble = FieldValue.double(.value(-3.14))
      _ = Components.Schemas.FieldValueRequest(from: negativeDouble)
    }

    @Test("Convert large numbers")
    internal func convertLargeNumbers() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let largeInt = FieldValue.int64(.value(Int.max))
      _ = Components.Schemas.FieldValueRequest(from: largeInt)

      let largeDouble = FieldValue.double(.value(Double.greatestFiniteMagnitude))
      _ = Components.Schemas.FieldValueRequest(from: largeDouble)
    }

    @Test("Convert empty string")
    internal func convertEmptyString() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let emptyString = FieldValue.string(.value(""))
      _ = Components.Schemas.FieldValueRequest(from: emptyString)
    }

    @Test("Convert string with special characters")
    internal func convertStringWithSpecialCharacters() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let specialString = FieldValue.string(.value("Hello\nWorld\t🌍"))
      _ = Components.Schemas.FieldValueRequest(from: specialString)
    }
  }
}
