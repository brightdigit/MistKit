import Foundation
import Testing

@testable import MistKit

extension QueryFilterTests {
  @Suite("List Filters")
  internal struct List {
    @Test("QueryFilter creates in filter with strings")
    internal func inFilterStrings() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let values: [FieldValue] = [.string("draft"), .string("published")]
      let filter = QueryFilter.in("state", values)
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .IN)
      #expect(components.fieldName == "state")
    }

    @Test("QueryFilter creates notIn filter with numbers")
    internal func notInFilterNumbers() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let values: [FieldValue] = [.int64(0), .int64(-1)]
      let filter = QueryFilter.notIn("errorCode", values)
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .NOT_IN)
      #expect(components.fieldName == "errorCode")
    }

    @Test("QueryFilter creates in filter with empty array")
    internal func inFilterEmptyArray() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let values: [FieldValue] = []
      let filter = QueryFilter.in("tags", values)
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .IN)
      #expect(components.fieldName == "tags")
    }
  }
}
