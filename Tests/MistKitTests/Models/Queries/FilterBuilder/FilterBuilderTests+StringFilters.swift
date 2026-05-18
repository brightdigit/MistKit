internal import Foundation
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

extension FilterBuilderTests {
  @Suite("String Filters")
  internal struct StringFilters {
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
  }
}
