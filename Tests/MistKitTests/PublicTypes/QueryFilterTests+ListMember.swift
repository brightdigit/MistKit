import Foundation
import Testing

@testable import MistKit

extension QueryFilterTests {
  @Suite("List Member Filters")
  internal struct ListMember {
    @Test("QueryFilter creates listContains filter")
    internal func listContainsFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.listContains("categories", .string("technology"))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .LIST_CONTAINS)
      #expect(components.fieldName == "categories")
    }

    @Test("QueryFilter creates notListContains filter")
    internal func notListContainsFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.notListContains("blockedUsers", .string("user-456"))
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .NOT_LIST_CONTAINS)
      #expect(components.fieldName == "blockedUsers")
    }

    @Test("QueryFilter creates listMemberBeginsWith filter")
    internal func listMemberBeginsWithFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.listMemberBeginsWith("urls", "https://")
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .LIST_MEMBER_BEGINS_WITH)
      #expect(components.fieldName == "urls")
    }

    @Test("QueryFilter creates notListMemberBeginsWith filter")
    internal func notListMemberBeginsWithFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.notListMemberBeginsWith("paths", "/private")
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .NOT_LIST_MEMBER_BEGINS_WITH)
      #expect(components.fieldName == "paths")
    }
  }
}
