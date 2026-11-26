internal import Foundation
internal import Testing

@testable import MistKit

extension QueryValidationTests {
  /// CloudKit's index rules: QUERYABLE filters, SORTABLE sorts and ranges,
  /// SEARCHABLE token filters.
  @Suite("Indexes")
  internal struct Indexes {
    private let schema = QueryFixtures.tabletop

    @Test("a query on indexed fields is valid")
    internal func valid() {
      let result = QueryValidationTests.player(
        [Condition(fieldName: "rating", comparator: .greaterThan, value: .int64(.value(1_500)))],
        sorts: [Sort(fieldName: "displayName")]
      )
      .validate(against: schema)
      #expect(result.issues.isEmpty)
      #expect(result.isValid)
    }

    @Test("a filter on a non-Queryable field blocks the query")
    internal func notQueryable() throws {
      let result = QueryValidationTests.player(
        [Condition(fieldName: "country", comparator: .equals, value: .string(.value("JP")))]
      )
      .validate(against: schema)
      #expect(!result.isValid)
      #expect(result.issues == [.notQueryable("country", condition: 0)])
      let issue = try #require(result.issues.first)
      #expect(issue.target == .condition(0))
      #expect(issue.fieldName == "country")
      #expect(issue.isBlocking)
    }

    @Test("a sort on a non-Sortable field blocks the query")
    internal func notSortable() throws {
      let result = QueryValidationTests.player(sorts: [Sort(fieldName: "handle")])
        .validate(against: schema)
      #expect(!result.isValid)
      #expect(result.issues == [.notSortable("handle", target: .sort(0))])
      #expect(result.issues(for: .sort(0)).count == 1)
    }

    @Test("a range filter on a Queryable but not Sortable field blocks the query")
    internal func rangeNeedsSortable() throws {
      let schema = CloudKitSchema(
        recordTypes: [
          SchemaRecordType(
            name: "Player",
            fields: [QueryFixtures.field("score", .int64, queryable: true)]
          )
        ]
      )
      let range = QueryValidationTests.player(
        [Condition(fieldName: "score", comparator: .lessThan, value: .int64(.value(5)))]
      )
      .validate(against: schema)
      #expect(range.issues == [.notSortable("score", target: .condition(0))])
      let equality = QueryValidationTests.player(
        [Condition(fieldName: "score", comparator: .equals, value: .int64(.value(5)))]
      )
      #expect(equality.validate(against: schema).isValid)
    }

    @Test("token filters need SEARCHABLE, not QUERYABLE")
    internal func searchable() {
      let tokens = QueryValidationTests.player(
        [
          Condition(
            fieldName: "displayName",
            comparator: .containsAnyTokens,
            value: .string(.value("mei ka"))
          ),
          Condition(
            fieldName: "handle",
            comparator: .containsAllTokens,
            value: .string(.value("mei"))
          ),
        ]
      )
      .validate(against: schema)
      #expect(tokens.issues == [.notSearchable("handle", condition: 1)])
    }

    @Test("___recordID is Queryable but not Sortable when the schema says so")
    internal func recordName() {
      let filter = QueryValidationTests.player(
        [Condition(fieldName: "___recordID", comparator: .equals, value: .string(.value("p-1")))]
      )
      #expect(filter.validate(against: schema).isValid)
      let sorted = QueryValidationTests.player(sorts: [Sort(fieldName: "___recordID")])
      #expect(
        sorted.validate(against: schema).issues == [.notSortable("___recordID", target: .sort(0))]
      )
      let undeclared = CloudKitSchema(recordTypes: [SchemaRecordType(name: "Player")])
      #expect(
        filter.validate(against: undeclared).issues == [.notQueryable("___recordID", condition: 0)]
      )
    }

    @Test("each offending condition and sort is reported, in order")
    internal func several() {
      let result = QueryValidationTests.player(
        [
          Condition(fieldName: "country", comparator: .equals, value: .string(.value("JP"))),
          Condition(fieldName: "rating", comparator: .lessThan, value: .int64(.value(9))),
          Condition(fieldName: "settings", comparator: .equals, value: .string(.value("{}"))),
        ],
        sorts: [Sort(fieldName: "handle")]
      )
      .validate(against: schema)
      #expect(result.issues.map(\.target) == [.condition(0), .condition(2), .sort(0)])
    }
  }
}
