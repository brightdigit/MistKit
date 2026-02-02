import Foundation
import Testing

@testable import MistKit

extension QueryFilterTests {
  @Suite("String Filters")
  internal struct String {
    @Test("QueryFilter creates beginsWith filter")
    internal func beginsWithFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.beginsWith("username", "admin")
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .BEGINS_WITH)
      #expect(components.fieldName == "username")
    }

    @Test("QueryFilter creates notBeginsWith filter")
    internal func notBeginsWithFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.notBeginsWith("email", "test")
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .NOT_BEGINS_WITH)
      #expect(components.fieldName == "email")
    }

    @Test("QueryFilter creates containsAllTokens filter")
    internal func containsAllTokensFilter() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("QueryFilter is not available on this operating system.")
        return
      }
      let filter = QueryFilter.containsAllTokens("content", "apple swift ios")
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == .CONTAINS_ALL_TOKENS)
      #expect(components.fieldName == "content")
    }
  }
}
