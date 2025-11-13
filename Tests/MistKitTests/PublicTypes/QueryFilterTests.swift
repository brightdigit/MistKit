import Foundation
import Testing

@testable import MistKit

@Suite("QueryFilter Tests")
internal struct QueryFilterTests {
  // MARK: - Equality Filters

  @Test("QueryFilter creates equals filter")
  func equalsFilter() {
    let filter = QueryFilter.equals("name", .string("Alice"))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .EQUALS)
    #expect(components.fieldName == "name")
  }

  @Test("QueryFilter creates notEquals filter")
  func notEqualsFilter() {
    let filter = QueryFilter.notEquals("status", .string("deleted"))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .NOT_EQUALS)
    #expect(components.fieldName == "status")
  }

  // MARK: - Comparison Filters

  @Test("QueryFilter creates lessThan filter")
  func lessThanFilter() {
    let filter = QueryFilter.lessThan("age", .int64(30))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .LESS_THAN)
    #expect(components.fieldName == "age")
  }

  @Test("QueryFilter creates lessThanOrEquals filter")
  func lessThanOrEqualsFilter() {
    let filter = QueryFilter.lessThanOrEquals("score", .double(85.5))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .LESS_THAN_OR_EQUALS)
    #expect(components.fieldName == "score")
  }

  @Test("QueryFilter creates greaterThan filter")
  func greaterThanFilter() {
    let date = Date()
    let filter = QueryFilter.greaterThan("updatedAt", .date(date))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .GREATER_THAN)
    #expect(components.fieldName == "updatedAt")
  }

  @Test("QueryFilter creates greaterThanOrEquals filter")
  func greaterThanOrEqualsFilter() {
    let filter = QueryFilter.greaterThanOrEquals("rating", .int64(4))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .GREATER_THAN_OR_EQUALS)
    #expect(components.fieldName == "rating")
  }

  // MARK: - String Filters

  @Test("QueryFilter creates beginsWith filter")
  func beginsWithFilter() {
    let filter = QueryFilter.beginsWith("username", "admin")
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .BEGINS_WITH)
    #expect(components.fieldName == "username")
  }

  @Test("QueryFilter creates notBeginsWith filter")
  func notBeginsWithFilter() {
    let filter = QueryFilter.notBeginsWith("email", "test")
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .NOT_BEGINS_WITH)
    #expect(components.fieldName == "email")
  }

  @Test("QueryFilter creates containsAllTokens filter")
  func containsAllTokensFilter() {
    let filter = QueryFilter.containsAllTokens("content", "apple swift ios")
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .CONTAINS_ALL_TOKENS)
    #expect(components.fieldName == "content")
  }

  // MARK: - List Filters

  @Test("QueryFilter creates in filter with strings")
  func inFilterStrings() {
    let values: [FieldValue] = [.string("draft"), .string("published")]
    let filter = QueryFilter.in("state", values)
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .IN)
    #expect(components.fieldName == "state")
  }

  @Test("QueryFilter creates notIn filter with numbers")
  func notInFilterNumbers() {
    let values: [FieldValue] = [.int64(0), .int64(-1)]
    let filter = QueryFilter.notIn("errorCode", values)
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .NOT_IN)
    #expect(components.fieldName == "errorCode")
  }

  @Test("QueryFilter creates in filter with empty array")
  func inFilterEmptyArray() {
    let values: [FieldValue] = []
    let filter = QueryFilter.in("tags", values)
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .IN)
    #expect(components.fieldName == "tags")
  }

  // MARK: - List Member Filters

  @Test("QueryFilter creates listContains filter")
  func listContainsFilter() {
    let filter = QueryFilter.listContains("categories", .string("technology"))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .LIST_CONTAINS)
    #expect(components.fieldName == "categories")
  }

  @Test("QueryFilter creates notListContains filter")
  func notListContainsFilter() {
    let filter = QueryFilter.notListContains("blockedUsers", .string("user-456"))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .NOT_LIST_CONTAINS)
    #expect(components.fieldName == "blockedUsers")
  }

  @Test("QueryFilter creates listMemberBeginsWith filter")
  func listMemberBeginsWithFilter() {
    let filter = QueryFilter.listMemberBeginsWith("urls", "https://")
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .LIST_MEMBER_BEGINS_WITH)
    #expect(components.fieldName == "urls")
  }

  @Test("QueryFilter creates notListMemberBeginsWith filter")
  func notListMemberBeginsWithFilter() {
    let filter = QueryFilter.notListMemberBeginsWith("paths", "/private")
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .NOT_LIST_MEMBER_BEGINS_WITH)
    #expect(components.fieldName == "paths")
  }

  // MARK: - Complex Field Types

  @Test("QueryFilter handles boolean field values")
  func booleanFieldValue() {
    let filter = QueryFilter.equals("isPublished", .boolean(true))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .EQUALS)
    #expect(components.fieldName == "isPublished")
  }

  @Test("QueryFilter handles reference field values")
  func referenceFieldValue() {
    let reference = FieldValue.Reference(recordName: "parent-record-123")
    let filter = QueryFilter.equals("parentRef", .reference(reference))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .EQUALS)
    #expect(components.fieldName == "parentRef")
  }

  @Test("QueryFilter handles date comparisons")
  func dateComparison() {
    let now = Date()
    let filter = QueryFilter.lessThan("expiresAt", .date(now))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .LESS_THAN)
    #expect(components.fieldName == "expiresAt")
  }

  @Test("QueryFilter handles double comparisons")
  func doubleComparison() {
    let filter = QueryFilter.greaterThanOrEquals("temperature", .double(98.6))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .GREATER_THAN_OR_EQUALS)
    #expect(components.fieldName == "temperature")
  }

  // MARK: - Edge Cases

  @Test("QueryFilter handles empty string")
  func emptyStringFilter() {
    let filter = QueryFilter.equals("emptyField", .string(""))
    let components = filter.toComponentsFilter()
    #expect(components.fieldName == "emptyField")
  }

  @Test("QueryFilter handles special characters in field names")
  func specialCharactersInFieldName() {
    let filter = QueryFilter.equals("field_name_123", .string("value"))
    let components = filter.toComponentsFilter()
    #expect(components.fieldName == "field_name_123")
  }

  @Test("QueryFilter handles zero values")
  func zeroValues() {
    let intFilter = QueryFilter.equals("count", .int64(0))
    #expect(intFilter.toComponentsFilter().fieldName == "count")

    let doubleFilter = QueryFilter.equals("amount", .double(0.0))
    #expect(doubleFilter.toComponentsFilter().fieldName == "amount")
  }

  @Test("QueryFilter handles negative values")
  func negativeValues() {
    let filter = QueryFilter.lessThan("balance", .int64(-100))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .LESS_THAN)
  }

  @Test("QueryFilter handles large numbers")
  func largeNumbers() {
    let filter = QueryFilter.greaterThan("views", .int64(1_000_000))
    let components = filter.toComponentsFilter()
    #expect(components.comparator == .GREATER_THAN)
  }
}
