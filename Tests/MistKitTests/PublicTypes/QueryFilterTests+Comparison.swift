import Foundation
import Testing

@testable import MistKit

extension QueryFilterTests {
  @Suite("Comparison Filters")
  internal struct Comparison {
    @Test("QueryFilter creates lessThan filter")
    internal func lessThanFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.lessThan("age", .int64(30))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .LESS_THAN)
      #expect(components.fieldName == "age")
    }

    @Test("QueryFilter creates lessThanOrEquals filter")
    internal func lessThanOrEqualsFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.lessThanOrEquals("score", .double(85.5))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .LESS_THAN_OR_EQUALS)
      #expect(components.fieldName == "score")
    }

    @Test("QueryFilter creates greaterThan filter")
    internal func greaterThanFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let date = Date()
      let filter = QueryFilter.greaterThan("updatedAt", .date(date))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .GREATER_THAN)
      #expect(components.fieldName == "updatedAt")
    }

    @Test("QueryFilter creates greaterThanOrEquals filter")
    internal func greaterThanOrEqualsFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.greaterThanOrEquals("rating", .int64(4))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .GREATER_THAN_OR_EQUALS)
      #expect(components.fieldName == "rating")
    }
  }
}
