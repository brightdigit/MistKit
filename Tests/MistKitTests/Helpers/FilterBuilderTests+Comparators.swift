import Foundation
import Testing

@testable import MistKit

extension FilterBuilderTests {
  @Suite("Comparators")
  internal struct Comparators {
    @Test("FilterBuilder creates EQUALS filter")
    internal func equalsFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FilterBuilder is not available on this operating system.")
        return
      }
      let filter = FilterBuilder.equals("name", .string("John"))
      #expect(filter.comparator == .EQUALS)
      #expect(filter.fieldName == "name")
    }

    @Test("FilterBuilder creates NOT_EQUALS filter")
    internal func notEqualsFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FilterBuilder is not available on this operating system.")
        return
      }
      let filter = FilterBuilder.notEquals("age", .int64(25))
      #expect(filter.comparator == .NOT_EQUALS)
      #expect(filter.fieldName == "age")
    }

    @Test("FilterBuilder creates LESS_THAN filter")
    internal func lessThanFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FilterBuilder is not available on this operating system.")
        return
      }
      let filter = FilterBuilder.lessThan("score", .double(100.0))
      #expect(filter.comparator == .LESS_THAN)
      #expect(filter.fieldName == "score")
    }

    @Test("FilterBuilder creates LESS_THAN_OR_EQUALS filter")
    internal func lessThanOrEqualsFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FilterBuilder is not available on this operating system.")
        return
      }
      let filter = FilterBuilder.lessThanOrEquals("count", .int64(50))
      #expect(filter.comparator == .LESS_THAN_OR_EQUALS)
      #expect(filter.fieldName == "count")
    }

    @Test("FilterBuilder creates GREATER_THAN filter")
    internal func greaterThanFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FilterBuilder is not available on this operating system.")
        return
      }
      let date = Date()
      let filter = FilterBuilder.greaterThan("createdAt", .date(date))
      #expect(filter.comparator == .GREATER_THAN)
      #expect(filter.fieldName == "createdAt")
    }

    @Test("FilterBuilder creates GREATER_THAN_OR_EQUALS filter")
    internal func greaterThanOrEqualsFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FilterBuilder is not available on this operating system.")
        return
      }
      let filter = FilterBuilder.greaterThanOrEquals("priority", .int64(3))
      #expect(filter.comparator == .GREATER_THAN_OR_EQUALS)
      #expect(filter.fieldName == "priority")
    }
  }
}
