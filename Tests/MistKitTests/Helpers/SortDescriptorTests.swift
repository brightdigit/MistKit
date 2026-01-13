import Foundation
import Testing

@testable import MistKit

@Suite("SortDescriptor Tests", .enabled(if: Platform.isCryptoAvailable))
internal struct SortDescriptorTests {
  @Test("SortDescriptor creates ascending sort")
  internal func ascendingSort() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("SortDescriptor is not available on this operating system.")
      return
    }
    let sort = SortDescriptor.ascending("name")
    #expect(sort.fieldName == "name")
    #expect(sort.ascending == true)
  }

  @Test("SortDescriptor creates descending sort")
  internal func descendingSort() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("SortDescriptor is not available on this operating system.")
      return
    }
    let sort = SortDescriptor.descending("age")
    #expect(sort.fieldName == "age")
    #expect(sort.ascending == false)
  }

  @Test("SortDescriptor creates sort with ascending true")
  internal func sortAscendingTrue() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("SortDescriptor is not available on this operating system.")
      return
    }
    let sort = SortDescriptor.sort("score", ascending: true)
    #expect(sort.fieldName == "score")
    #expect(sort.ascending == true)
  }

  @Test("SortDescriptor creates sort with ascending false")
  internal func sortAscendingFalse() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("SortDescriptor is not available on this operating system.")
      return
    }
    let sort = SortDescriptor.sort("rating", ascending: false)
    #expect(sort.fieldName == "rating")
    #expect(sort.ascending == false)
  }

  @Test("SortDescriptor defaults to ascending")
  internal func sortDefaultAscending() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("SortDescriptor is not available on this operating system.")
      return
    }
    let sort = SortDescriptor.sort("title")
    #expect(sort.fieldName == "title")
    #expect(sort.ascending == true)
  }

  @Test("SortDescriptor handles various field name formats")
  internal func variousFieldNameFormats() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("SortDescriptor is not available on this operating system.")
      return
    }
    let sort1 = SortDescriptor.ascending("simple")
    #expect(sort1.fieldName == "simple")

    let sort2 = SortDescriptor.ascending("camelCase")
    #expect(sort2.fieldName == "camelCase")

    let sort3 = SortDescriptor.ascending("snake_case")
    #expect(sort3.fieldName == "snake_case")

    let sort4 = SortDescriptor.ascending("with123Numbers")
    #expect(sort4.fieldName == "with123Numbers")
  }
}
