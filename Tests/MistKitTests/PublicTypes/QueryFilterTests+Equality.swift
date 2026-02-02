import Foundation
import Testing

@testable import MistKit

extension QueryFilterTests {
  @Suite("Equality Filters")
  internal struct Equality {
    @Test("QueryFilter creates equals filter")
    internal func equalsFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.equals("name", .string("Alice"))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .EQUALS)
      #expect(components.fieldName == "name")
    }

    @Test("QueryFilter creates notEquals filter")
    internal func notEqualsFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.notEquals("status", .string("deleted"))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .NOT_EQUALS)
      #expect(components.fieldName == "status")
    }
  }
}
