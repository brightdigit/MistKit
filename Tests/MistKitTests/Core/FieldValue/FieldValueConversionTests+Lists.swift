import Foundation
import Testing

@testable import MistKit

extension FieldValueConversionTests {
  @Suite("List Conversions")
  internal struct Lists {
    @Test("Convert list FieldValue with strings to Components.FieldValue")
    internal func convertListWithStrings() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let list: [FieldValue] = [.string("one"), .string("two"), .string("three")]
      let fieldValue = FieldValue.list(list)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(#expect(components.type == .type == nil)  // CloudKit API does not expect type field
    // #expect(#expect(components.type == .list)
      if case .listValue(let values) = components.value {
        #expect(values.count == 3)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("Convert list FieldValue with numbers to Components.FieldValue")
    internal func convertListWithNumbers() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let list: [FieldValue] = [.int64(1), .int64(2), .int64(3)]
      let fieldValue = FieldValue.list(list)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(#expect(components.type == .type == nil)  // CloudKit API does not expect type field
    // #expect(#expect(components.type == .list)
      if case .listValue(let values) = components.value {
        #expect(values.count == 3)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("Convert list FieldValue with mixed types to Components.FieldValue")
    internal func convertListWithMixedTypes() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let list: [FieldValue] = [
        .string("text"),
        .int64(42),
        .double(3.14),
        FieldValue(booleanValue: true),
      ]
      let fieldValue = FieldValue.list(list)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(#expect(components.type == .type == nil)  // CloudKit API does not expect type field
    // #expect(#expect(components.type == .list)
      if case .listValue(let values) = components.value {
        #expect(values.count == 4)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("Convert empty list FieldValue to Components.FieldValue")
    internal func convertEmptyList() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let list: [FieldValue] = []
      let fieldValue = FieldValue.list(list)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(#expect(components.type == .type == nil)  // CloudKit API does not expect type field
    // #expect(#expect(components.type == .list)
      if case .listValue(let values) = components.value {
        #expect(values.isEmpty)
      } else {
        Issue.record("Expected listValue")
      }
    }

    @Test("Convert nested list FieldValue to Components.FieldValue")
    internal func convertNestedList() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("FieldValue is not available on this operating system.")
        return
      }
      let innerList: [FieldValue] = [.string("a"), .string("b")]
      let outerList: [FieldValue] = [.list(innerList), .string("c")]
      let fieldValue = FieldValue.list(outerList)
      let components = Components.Schemas.FieldValue(from: fieldValue)

      #expect(#expect(components.type == .type == nil)  // CloudKit API does not expect type field
    // #expect(#expect(components.type == .list)
      if case .listValue(let values) = components.value {
        #expect(values.count == 2)
      } else {
        Issue.record("Expected listValue")
      }
    }
  }
}
