import Foundation
import Testing

@testable import MistKit

extension FilterBuilderTests {
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
