import Foundation
import Testing

@testable import MistKit

@Suite("QuerySort Tests", .enabled(if: Platform.isCryptoAvailable))
internal struct QuerySortTests {
  @Test("QuerySort creates ascending sort")
  func ascendingSort() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("QuerySort is not available on this operating system.")
      return
    }
    let sort = QuerySort.ascending("createdAt")
    let components = Components.Schemas.Sort(from: sort)
    #expect(components.fieldName == "createdAt")
    #expect(components.ascending == true)
  }

  @Test("QuerySort creates descending sort")
  func descendingSort() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("QuerySort is not available on this operating system.")
      return
    }
    let sort = QuerySort.descending("updatedAt")
    let components = Components.Schemas.Sort(from: sort)
    #expect(components.fieldName == "updatedAt")
    #expect(components.ascending == false)
  }

  @Test("QuerySort creates sort with explicit ascending direction")
  func sortExplicitAscending() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("QuerySort is not available on this operating system.")
      return
    }
    let sort = QuerySort.sort("name", ascending: true)
    let components = Components.Schemas.Sort(from: sort)
    #expect(components.fieldName == "name")
    #expect(components.ascending == true)
  }

  @Test("QuerySort creates sort with explicit descending direction")
  func sortExplicitDescending() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("QuerySort is not available on this operating system.")
      return
    }
    let sort = QuerySort.sort("score", ascending: false)
    let components = Components.Schemas.Sort(from: sort)
    #expect(components.fieldName == "score")
    #expect(components.ascending == false)
  }

  @Test("QuerySort defaults to ascending when using sort method")
  func sortDefaultsToAscending() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("QuerySort is not available on this operating system.")
      return
    }
    let sort = QuerySort.sort("title")
    let components = Components.Schemas.Sort(from: sort)
    #expect(components.fieldName == "title")
    #expect(components.ascending == true)
  }

  @Test("QuerySort handles field names with underscores")
  func sortFieldWithUnderscores() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("QuerySort is not available on this operating system.")
      return
    }
    let sort = QuerySort.ascending("user_id")
    let components = Components.Schemas.Sort(from: sort)
    #expect(components.fieldName == "user_id")
  }

  @Test("QuerySort handles field names with numbers")
  func sortFieldWithNumbers() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("QuerySort is not available on this operating system.")
      return
    }
    let sort = QuerySort.descending("field123")
    let components = Components.Schemas.Sort(from: sort)
    #expect(components.fieldName == "field123")
  }

  @Test("QuerySort handles camelCase field names")
  func sortCamelCaseField() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("QuerySort is not available on this operating system.")
      return
    }
    let sort = QuerySort.ascending("createdAtTimestamp")
    let components = Components.Schemas.Sort(from: sort)
    #expect(components.fieldName == "createdAtTimestamp")
  }
}
