internal import Foundation
internal import MistKit
internal import Testing

@Suite("FieldValue list elements")
/// Tests the public list helpers in `FieldValue+ListElements`.
internal struct FieldValueListElementsTests {
  @Test("a list splits into single values and joins back")
  internal func listElements() {
    let list = FieldValue.int64(.list([1, 2]))
    #expect(list.isList)
    #expect(list.listElements == [.int64(.value(1)), .int64(.value(2))])
    #expect(FieldValue.list(of: [.int64(.value(1)), .int64(.value(2))]) == list)
  }

  @Test("a single value is not a list; an empty list still is")
  internal func singleValues() {
    #expect(!FieldValue.string(.value("a")).isList)
    #expect(FieldValue.string(.value("a")).listElements == nil)
    #expect(FieldValue.string(.list([])).isList)
    #expect(FieldValue.string(.list([])).listElements?.isEmpty == true)
  }

  @Test("list(of:) refuses empty, mixed and nested elements")
  internal func listOfRefuses() {
    #expect(FieldValue.list(of: []) == nil)
    #expect(FieldValue.list(of: [.string(.value("a")), .int64(.value(1))]) == nil)
    #expect(FieldValue.list(of: [.string(.list(["a"]))]) == nil)
  }

  @Test("emptyList(of:) takes a list type or its element type")
  internal func emptyList() {
    #expect(FieldValue.emptyList(of: .timestamp) == .date(.list([])))
    #expect(FieldValue.emptyList(of: .list(.timestamp)) == .date(.list([])))
    #expect(FieldValue.emptyList(of: .reference) == .reference(.list([])))
    #expect(FieldValue.emptyList(of: .list(.list(.string))) == nil)
  }
}
