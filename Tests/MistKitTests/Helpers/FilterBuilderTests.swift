import Foundation
import Testing

@testable import MistKit

@Suite("FilterBuilder Tests", .enabled(if: Platform.isCryptoAvailable))
internal struct FilterBuilderTests {
  // MARK: - Equality Filters

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

  // MARK: - Comparison Filters

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

  // MARK: - String Filters

  @Test("FilterBuilder creates BEGINS_WITH filter")
  internal func beginsWithFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let filter = FilterBuilder.beginsWith("title", "Hello")
    #expect(filter.comparator == .BEGINS_WITH)
    #expect(filter.fieldName == "title")
  }

  @Test("FilterBuilder creates NOT_BEGINS_WITH filter")
  internal func notBeginsWithFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let filter = FilterBuilder.notBeginsWith("email", "spam")
    #expect(filter.comparator == .NOT_BEGINS_WITH)
    #expect(filter.fieldName == "email")
  }

  @Test("FilterBuilder creates CONTAINS_ALL_TOKENS filter")
  internal func containsAllTokensFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let filter = FilterBuilder.containsAllTokens("description", "swift cloudkit")
    #expect(filter.comparator == .CONTAINS_ALL_TOKENS)
    #expect(filter.fieldName == "description")
  }

  // MARK: - List Filters

  @Test("FilterBuilder creates IN filter")
  internal func inFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let values: [FieldValue] = [.string("active"), .string("pending")]
    let filter = FilterBuilder.in("status", values)
    #expect(filter.comparator == .IN)
    #expect(filter.fieldName == "status")
  }

  @Test("FilterBuilder creates NOT_IN filter")
  internal func notInFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let values: [FieldValue] = [.string("deleted"), .string("archived")]
    let filter = FilterBuilder.notIn("status", values)
    #expect(filter.comparator == .NOT_IN)
    #expect(filter.fieldName == "status")
  }

  @Test("FilterBuilder creates IN filter with numbers")
  internal func inFilterWithNumbers() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let values: [FieldValue] = [.int64(1), .int64(2), .int64(3)]
    let filter = FilterBuilder.in("categoryId", values)
    #expect(filter.comparator == .IN)
    #expect(filter.fieldName == "categoryId")
  }

  // MARK: - List Member Filters

  @Test("FilterBuilder creates LIST_CONTAINS filter")
  internal func listContainsFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let filter = FilterBuilder.listContains("tags", .string("important"))
    #expect(filter.comparator == .LIST_CONTAINS)
    #expect(filter.fieldName == "tags")
  }

  @Test("FilterBuilder creates NOT_LIST_CONTAINS filter")
  internal func notListContainsFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let filter = FilterBuilder.notListContains("tags", .string("spam"))
    #expect(filter.comparator == .NOT_LIST_CONTAINS)
    #expect(filter.fieldName == "tags")
  }

  @Test("FilterBuilder creates LIST_MEMBER_BEGINS_WITH filter")
  internal func listMemberBeginsWithFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let filter = FilterBuilder.listMemberBeginsWith("emails", "admin@")
    #expect(filter.comparator == .LIST_MEMBER_BEGINS_WITH)
    #expect(filter.fieldName == "emails")
  }

  @Test("FilterBuilder creates NOT_LIST_MEMBER_BEGINS_WITH filter")
  internal func notListMemberBeginsWithFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let filter = FilterBuilder.notListMemberBeginsWith("domains", "spam")
    #expect(filter.comparator == .NOT_LIST_MEMBER_BEGINS_WITH)
    #expect(filter.fieldName == "domains")
  }

  // MARK: - Complex Value Tests

  @Test("FilterBuilder handles boolean values")
  internal func booleanValueFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let filter = FilterBuilder.equals("isActive", FieldValue(booleanValue: true))
    #expect(filter.comparator == .EQUALS)
    #expect(filter.fieldName == "isActive")
  }

  @Test("FilterBuilder handles reference values")
  internal func referenceValueFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let reference = FieldValue.Reference(recordName: "user-123")
    let filter = FilterBuilder.equals("owner", .reference(reference))
    #expect(filter.comparator == .EQUALS)
    #expect(filter.fieldName == "owner")
  }

  @Test("FilterBuilder handles location values")
  internal func locationValueFilter() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FilterBuilder is not available on this operating system.")
      return
    }
    let location = FieldValue.Location(
      latitude: 37.7749,
      longitude: -122.4194
    )
    let filter = FilterBuilder.equals("location", .location(location))
    #expect(filter.comparator == .EQUALS)
    #expect(filter.fieldName == "location")
  }
}
