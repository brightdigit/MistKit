internal import Foundation
internal import Testing

@testable import MistKit

extension QueryPredicateTests {
  /// `IN {…}` lists.
  @Suite("Lists")
  internal struct Lists {
    @Test("IN reads a homogeneous list")
    internal func homogeneous() throws {
      #expect(
        try QueryPredicate.parse(#"status IN {"open", 'full'}"#) == [
          QueryPredicateTests.condition("status", .in, .string(.list(["open", "full"])))
        ]
      )
      #expect(
        try QueryPredicate.parse("rating in {1, 2.5}") == [
          QueryPredicateTests.condition("rating", .in, .double(.list([1, 2.5])))
        ]
      )
      let references = #"winner IN {REFERENCE("a"), REFERENCE("b")}"#
      #expect(
        try QueryPredicate.parse(references).first?.value
          == .reference(.list([Reference(recordName: "a"), Reference(recordName: "b")]))
      )
    }

    @Test("an empty list takes the field's type, and needs one")
    internal func empty() throws {
      let type = SchemaRecordType(
        name: "Player",
        fields: [SchemaField(name: "handle", type: SchemaFieldType(.string))]
      )
      #expect(
        try QueryPredicate.parse("handle IN {}", recordType: type).first?.value
          == .string(.list([]))
      )
      let error = try #require(QueryPredicateTests.error("handle IN {}"))
      #expect(error.reason == .untypedEmptyList)
      #expect(error.range == 10..<12)
    }

    @Test("a list mixing types is an error")
    internal func mixed() throws {
      let error = try #require(QueryPredicateTests.error(#"handle IN {"a", 1, 2}"#))
      #expect(error.reason == .mixedList)
      #expect(error.range == 10..<21)
    }
  }
}
