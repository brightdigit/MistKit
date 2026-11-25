internal import Foundation
internal import Testing

@testable import MistKit

extension QueryValidationTests {
  /// Unknown names, the limit, inferred schemas and comparator lists.
  @Suite("Names")
  internal struct Names {
    private let schema = QueryFixtures.tabletop

    @Test("unknown record types and fields")
    internal func unknown() {
      let noType = QueryDescriptor(recordType: "Ghost").validate(against: schema)
      #expect(noType.issues == [.unknownRecordType("Ghost")])
      #expect(noType.issues.first?.target == .query)
      let noField = QueryValidationTests.player(
        [Condition(fieldName: "nickname", comparator: .equals, value: .string(.value("x")))],
        sorts: [Sort(fieldName: "rank")]
      )
      .validate(against: schema)
      #expect(
        noField.issues == [
          .unknownField("nickname", target: .condition(0)),
          .unknownField("rank", target: .sort(0)),
        ]
      )
    }

    @Test("an unknown desired key doesn't block the query")
    internal func desiredKeys() {
      var query = QueryValidationTests.player()
      query.desiredKeys = ["displayName", "nickname", "___modTime"]
      let result = query.validate(against: schema)
      #expect(result.issues == [.unknownDesiredKey("nickname", index: 1)])
      #expect(result.issues.first?.target == .desiredKey(1))
      #expect(result.issues.first?.fieldName == "nickname")
      #expect(result.isValid)
    }

    @Test("the limit stays within one page", arguments: [0, 201])
    internal func limit(value: Int) {
      var query = QueryValidationTests.player()
      query.limit = value
      let result = query.validate(against: schema)
      #expect(result.issues == [.limitOutOfRange(value, allowed: 1...200)])
      #expect(!result.isValid)
    }

    @Test("an inferred schema can't check indexes, so it warns once and doesn't block")
    internal func inferred() {
      let inferred = InferredSchema(schema: schema)
      let result = QueryValidationTests.player(
        [
          Condition(fieldName: "country", comparator: .equals, value: .string(.value("JP"))),
          Condition(fieldName: "nickname", comparator: .equals, value: .string(.value("x"))),
        ],
        sorts: [Sort(fieldName: "handle")]
      )
      .validate(against: inferred)
      #expect(result.issues == [.indexesUnknown])
      #expect(result.issues.first?.fieldName == nil)
      #expect(result.isValid)
    }

    @Test("a record type lists each field's comparators, implicit fields included")
    internal func comparators() {
      let player = QueryFixtures.player
      #expect(player.allowedComparators(forField: "venue").isEmpty)
      #expect(QueryFixtures.match.allowedComparators(forField: "venue") == [.near])
      #expect(player.allowedComparators(forField: "rating").contains(.lessThan))
      #expect(player.allowedComparators(forField: "secret").isEmpty)
      let recordID = SchemaRecordType(name: "Bare").allowedComparators(forField: "___recordID")
      #expect(recordID == [.equals, .notEquals, .in, .notIn])
      #expect(SchemaRecordType(name: "Bare").queryField(named: "___etag")?.type == .init(.string))
    }
  }
}
