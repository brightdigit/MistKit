import Foundation
import Testing

@testable import MistKit

extension QueryFilterTests {
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("QueryFilter handles empty string")
    internal func emptyStringFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.equals("emptyField", .string(""))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.fieldName == "emptyField")
    }

    @Test("QueryFilter handles special characters in field names")
    internal func specialCharactersInFieldName() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.equals("field_name_123", .string("value"))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.fieldName == "field_name_123")
    }

    @Test("QueryFilter handles zero values")
    internal func zeroValues() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let intFilter = QueryFilter.equals("count", .int64(0))
      let intComponents = Components.Schemas.Filter(from: intFilter)
      #expect(intComponents.fieldName == "count")

      let doubleFilter = QueryFilter.equals("amount", .double(0.0))
      let doubleComponents = Components.Schemas.Filter(from: doubleFilter)
      #expect(doubleComponents.fieldName == "amount")
    }

    @Test("QueryFilter handles negative values")
    internal func negativeValues() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.lessThan("balance", .int64(-100))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .LESS_THAN)
    }

    @Test("QueryFilter handles large numbers")
    internal func largeNumbers() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.greaterThan("views", .int64(1_000_000))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .GREATER_THAN)
    }
  }
}
