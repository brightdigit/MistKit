import Foundation
import Testing

@testable import MistKit

extension QueryFilterTests {
  @Suite("Complex Field Types")
  internal struct ComplexFields {
    @Test("QueryFilter handles boolean field values")
    internal func booleanFieldValue() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }

      let filter = QueryFilter.equals("isPublished", FieldValue(booleanValue: true))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .EQUALS)
      #expect(components.fieldName == "isPublished")
    }

    @Test("QueryFilter handles reference field values")
    internal func referenceFieldValue() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let reference = FieldValue.Reference(recordName: "parent-record-123")
      let filter = QueryFilter.equals("parentRef", .reference(reference))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .EQUALS)
      #expect(components.fieldName == "parentRef")
    }

    @Test("QueryFilter handles date comparisons")
    internal func dateComparison() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let now = Date()
      let filter = QueryFilter.lessThan("expiresAt", .date(now))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .LESS_THAN)
      #expect(components.fieldName == "expiresAt")
    }

    @Test("QueryFilter handles double comparisons")
    internal func doubleComparison() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.greaterThanOrEquals("temperature", .double(98.6))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .GREATER_THAN_OR_EQUALS)
      #expect(components.fieldName == "temperature")
    }
  }
}
