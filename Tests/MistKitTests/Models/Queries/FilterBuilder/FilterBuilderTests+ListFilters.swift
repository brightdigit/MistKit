internal import Foundation
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

extension FilterBuilderTests {
  @Suite("List Filters")
  internal struct ListFilters {
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
      #expect(filter.fieldValue?._type == .STRING_LIST)
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
      #expect(filter.fieldValue?._type == .STRING_LIST)
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
      #expect(filter.fieldValue?._type == .INT64_LIST)
    }

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
  }
}
