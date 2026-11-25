internal import Foundation
internal import Testing

@testable import MistKit

extension QueryPredicateTests {
  /// Conditions → text → conditions must not change a query.
  @Suite("Round trip")
  internal struct RoundTrip {
    @Test("conditions → text → conditions round-trips every operator and value")
    internal func fromConditions() throws {
      let october = QueryPredicateTests.october
      let rows: [QueryDescriptor.Condition] = [
        QueryPredicateTests.condition("rating", .equals, .int64(.value(1_500))),
        QueryPredicateTests.condition("rating", .notEquals, .int64(.value(-3))),
        QueryPredicateTests.condition("score", .lessThan, .double(.value(2.5))),
        QueryPredicateTests.condition("score", .lessThanOrEquals, .double(.value(1e-5))),
        QueryPredicateTests.condition("startedAt", .greaterThan, .date(.value(october))),
        QueryPredicateTests.condition(
          "startedAt",
          .greaterThanOrEquals,
          .date(.value(Date(timeIntervalSince1970: 0.25)))
        ),
        QueryPredicateTests.condition(
          "displayName",
          .beginsWith,
          .string(.value("Mei \"T\" \\ \n"))
        ),
        QueryPredicateTests.condition(
          "winner",
          .equals,
          .reference(.value(Reference(recordName: "p-1")))
        ),
        QueryPredicateTests.condition("tags", .listContains, .string(.value("ranked"))),
        QueryPredicateTests.condition("status", .in, .string(.list(["open", "full"]))),
        QueryPredicateTests.condition("rating", .in, .int64(.list([1, 2]))),
        QueryPredicateTests.condition(
          "venue",
          .near(meters: 1_500),
          .location(.value(Location(latitude: 1, longitude: 2)))
        ),
        QueryPredicateTests.condition("token", .equals, .bytes(.value(Data([0, 255])))),
        QueryPredicateTests.condition("AND", .equals, .string(.value("escaped field"))),
      ]
      let text = try QueryPredicate.format(rows)
      #expect(try QueryPredicate.parse(text) == rows)
    }

    @Test("text → conditions → text gives the canonical form")
    internal func fromText() throws {
      let canonical = """
        startedAt >= CAST("2026-10-01T00:00:00Z", "NSDate")
        AND players CONTAINS REFERENCE("p-1")
        AND displayName BEGINSWITH "Ka"
        AND status IN {"open", "full"}
        AND distanceToLocation:fromLocation:(venue, LOCATION(51.5, -0.12)) < 25.0
        """
      #expect(try QueryPredicate.format(QueryPredicate.parse(canonical)) == canonical)
      let loose = "rating==3 && handle <> 'x'"
      #expect(
        try QueryPredicate.format(QueryPredicate.parse(loose)) == "rating = 3\nAND handle != \"x\""
      )
      #expect(try QueryPredicate.format([]).isEmpty)
    }

    @Test("values text can't hold are reported by field")
    internal func unrepresentableValues() {
      #expect(throws: QueryPredicateFormatError.unrepresentableValue(fieldName: "avatar")) {
        try QueryPredicate.format([
          QueryPredicateTests.condition("avatar", .equals, .asset(.value(Asset())))
        ])
      }
      #expect(throws: QueryPredicateFormatError.unrepresentableValue(fieldName: "handle")) {
        try QueryPredicate.format([
          QueryPredicateTests.condition("handle", .in, .string(.list([])))
        ])
      }
      #expect(throws: QueryPredicateFormatError.unrepresentableValue(fieldName: "score")) {
        try QueryPredicate.format([
          QueryPredicateTests.condition("score", .equals, .double(.value(.infinity)))
        ])
      }
    }

    @Test(
      "comparators without an NSPredicate spelling are reported",
      arguments: [
        QueryDescriptor.Comparator.notBeginsWith, .containsAllTokens, .containsAnyTokens,
        .notListContains, .listMemberBeginsWith, .notListMemberBeginsWith,
      ]
    )
    internal func unrepresentableComparators(comparator: QueryDescriptor.Comparator) {
      #expect(
        throws: QueryPredicateFormatError.unrepresentableComparator(
          fieldName: "handle",
          comparator: comparator.filterComparator
        )
      ) {
        try QueryPredicate.format([
          QueryPredicateTests.condition("handle", comparator, .string(.value("x")))
        ])
      }
    }
  }
}
