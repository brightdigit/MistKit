import Foundation
import Testing

@testable import MistKit

@Suite("QuerySort Tests")
internal struct QuerySortTests {
  @Test("QuerySort creates ascending sort")
  func ascendingSort() {
    let sort = QuerySort.ascending("createdAt")
    let components = sort.toComponentsSort()
    #expect(components.fieldName == "createdAt")
    #expect(components.ascending == true)
  }

  @Test("QuerySort creates descending sort")
  func descendingSort() {
    let sort = QuerySort.descending("updatedAt")
    let components = sort.toComponentsSort()
    #expect(components.fieldName == "updatedAt")
    #expect(components.ascending == false)
  }

  @Test("QuerySort creates sort with explicit ascending direction")
  func sortExplicitAscending() {
    let sort = QuerySort.sort("name", ascending: true)
    let components = sort.toComponentsSort()
    #expect(components.fieldName == "name")
    #expect(components.ascending == true)
  }

  @Test("QuerySort creates sort with explicit descending direction")
  func sortExplicitDescending() {
    let sort = QuerySort.sort("score", ascending: false)
    let components = sort.toComponentsSort()
    #expect(components.fieldName == "score")
    #expect(components.ascending == false)
  }

  @Test("QuerySort defaults to ascending when using sort method")
  func sortDefaultsToAscending() {
    let sort = QuerySort.sort("title")
    let components = sort.toComponentsSort()
    #expect(components.fieldName == "title")
    #expect(components.ascending == true)
  }

  @Test("QuerySort handles field names with underscores")
  func sortFieldWithUnderscores() {
    let sort = QuerySort.ascending("user_id")
    let components = sort.toComponentsSort()
    #expect(components.fieldName == "user_id")
  }

  @Test("QuerySort handles field names with numbers")
  func sortFieldWithNumbers() {
    let sort = QuerySort.descending("field123")
    let components = sort.toComponentsSort()
    #expect(components.fieldName == "field123")
  }

  @Test("QuerySort handles camelCase field names")
  func sortCamelCaseField() {
    let sort = QuerySort.ascending("createdAtTimestamp")
    let components = sort.toComponentsSort()
    #expect(components.fieldName == "createdAtTimestamp")
  }
}
