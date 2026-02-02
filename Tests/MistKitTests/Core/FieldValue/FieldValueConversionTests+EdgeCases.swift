import Foundation
import Testing

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
      let intZero = FieldValue.int64(0)
      let intComponents = Components.Schemas.FieldValue(from: intZero)
      #expect(intComponents.type == .int64)

      let doubleZero = FieldValue.double(0.0)
      let doubleComponents = Components.Schemas.FieldValue(from: doubleZero)
      #expect(doubleComponents.type == .double)
    }

    @Test("Convert negative values")
    internal func convertNegativeValues() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let negativeInt = FieldValue.int64(-100)
      let intComponents = Components.Schemas.FieldValue(from: negativeInt)
      #expect(intComponents.type == .int64)

      let negativeDouble = FieldValue.double(-3.14)
      let doubleComponents = Components.Schemas.FieldValue(from: negativeDouble)
      #expect(doubleComponents.type == .double)
    }

    @Test("Convert large numbers")
    internal func convertLargeNumbers() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let largeInt = FieldValue.int64(Int.max)
      let intComponents = Components.Schemas.FieldValue(from: largeInt)
      #expect(intComponents.type == .int64)

      let largeDouble = FieldValue.double(Double.greatestFiniteMagnitude)
      let doubleComponents = Components.Schemas.FieldValue(from: largeDouble)
      #expect(doubleComponents.type == .double)
    }

    @Test("Convert empty string")
    internal func convertEmptyString() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let emptyString = FieldValue.string("")
      let components = Components.Schemas.FieldValue(from: emptyString)
      #expect(components.type == .string)
    }

    @Test("Convert string with special characters")
    internal func convertStringWithSpecialCharacters() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let specialString = FieldValue.string("Hello\nWorld\t🌍")
      let components = Components.Schemas.FieldValue(from: specialString)
      #expect(components.type == .string)
    }
  }
}
