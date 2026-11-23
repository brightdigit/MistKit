internal import Foundation
internal import Testing

@testable import MistKit

extension QueryPredicateTests {
  /// Reading format strings such as `startedAt >= CAST("2026-10-01T00:00:00Z", "NSDate")`.
  @Suite("Parser")
  internal struct Parser {
    @Test(
      "comparison operators",
      arguments: [
        ("rating = 1500", QueryDescriptor.Comparator.equals),
        ("rating == 1500", .equals),
        ("rating != 1500", .notEquals),
        ("rating <> 1500", .notEquals),
        ("rating < 1500", .lessThan),
        ("rating <= 1500", .lessThanOrEquals),
        ("rating =< 1500", .lessThanOrEquals),
        ("rating > 1500", .greaterThan),
        ("rating >= 1500", .greaterThanOrEquals),
        ("rating => 1500", .greaterThanOrEquals),
      ]
    )
    internal func comparisons(text: String, comparator: QueryDescriptor.Comparator) throws {
      #expect(
        try QueryPredicate.parse(text) == [
          QueryPredicateTests.condition("rating", comparator, .int64(.value(1_500)))
        ]
      )
    }

    @Test("literal values")
    internal func literals() throws {
      let text = """
        score = -2.5 AND displayName BEGINSWITH "Ka \\"K\\"" \
        AND startedAt >= CAST("2026-10-01T00:00:00Z", "NSDate") \
        AND winner = REFERENCE("player-mei") AND players CONTAINS REFERENCE("p-1") \
        AND token = BYTES("AQI=") AND handle = 'mei'
        """
      let player = Reference(recordName: "p-1")
      #expect(
        try QueryPredicate.parse(text) == [
          QueryPredicateTests.condition("score", .equals, .double(.value(-2.5))),
          QueryPredicateTests.condition(
            "displayName",
            .beginsWith,
            .string(.value("Ka \"K\""))
          ),
          QueryPredicateTests.condition(
            "startedAt",
            .greaterThanOrEquals,
            .date(.value(QueryPredicateTests.october))
          ),
          QueryPredicateTests.condition(
            "winner",
            .equals,
            .reference(.value(Reference(recordName: "player-mei")))
          ),
          QueryPredicateTests.condition("players", .listContains, .reference(.value(player))),
          QueryPredicateTests.condition("token", .equals, .bytes(.value(Data([1, 2])))),
          QueryPredicateTests.condition("handle", .equals, .string(.value("mei"))),
        ]
      )
    }

    @Test("distanceToLocation:fromLocation: is NEAR, in kilometres")
    internal func location() throws {
      let text = "distanceToLocation:fromLocation:(venue, LOCATION(51.5, -0.12)) < 25"
      let center = Location(latitude: 51.5, longitude: -0.12)
      #expect(
        try QueryPredicate.parse(text) == [
          QueryPredicateTests.condition("venue", .near(meters: 25_000), .location(.value(center)))
        ]
      )
      let inclusive = "distanceToLocation:fromLocation:(venue, LOCATION(1, 2)) <= 0.0015"
      #expect(try QueryPredicate.parse(inclusive).first?.comparator == .near(meters: 1.5))
    }

    @Test("keywords ignore case, && joins, comments and TRUEPREDICATE are skipped")
    internal func lenient() throws {
      #expect(try QueryPredicate.parse("").isEmpty)
      #expect(try QueryPredicate.parse("  TRUEPREDICATE ").isEmpty)
      let text = "rating > 1 && handle beginswith \"m\" /* note */ and #AND = 2"
      #expect(
        try QueryPredicate.parse(text) == [
          QueryPredicateTests.condition("rating", .greaterThan, .int64(.value(1))),
          QueryPredicateTests.condition("handle", .beginsWith, .string(.value("m"))),
          QueryPredicateTests.condition("AND", .equals, .int64(.value(2))),
        ]
      )
    }

    @Test("with a record type, whole numbers on DOUBLE fields become doubles")
    internal func coercion() throws {
      let type = SchemaRecordType(
        name: "Shot",
        fields: [SchemaField(name: "speed", type: SchemaFieldType(.double), isQueryable: true)]
      )
      #expect(
        try QueryPredicate.parse("speed > 3", recordType: type) == [
          QueryPredicateTests.condition("speed", .greaterThan, .double(.value(3)))
        ]
      )
    }
  }
}
