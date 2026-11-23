internal import Foundation
internal import Testing

@testable import MistKit

extension QueryValidationTests {
  /// Comparators, values, unknown names, the limit and inferred schemas.
  @Suite("Rules")
  internal struct Rules {
    private let schema = QueryFixtures.tabletop

    @Test("a comparator the field's type doesn't take")
    internal func unsupportedComparator() throws {
      let result = QueryValidationTests.player(
        [Condition(fieldName: "rating", comparator: .beginsWith, value: .string(.value("1")))]
      )
      .validate(against: schema)
      let rating = try #require(QueryFixtures.player.field(named: "rating"))
      #expect(result.issues == [.unsupportedComparator(.beginsWith, field: rating, condition: 0)])
      #expect(!result.isValid)
    }

    @Test("encrypted fields can't be filtered")
    internal func encrypted() {
      let result = QueryValidationTests.player(
        [Condition(fieldName: "secret", comparator: .equals, value: .string(.value("x")))]
      )
      .validate(against: schema)
      #expect(result.issues.map(\.target) == [.condition(0), .condition(0)])
      #expect(result.issues.first == .notQueryable("secret", condition: 0))
    }

    @Test("a value of the wrong type")
    internal func valueMismatch() throws {
      let result = QueryValidationTests.player(
        [Condition(fieldName: "rating", comparator: .equals, value: .string(.value("high")))]
      )
      .validate(against: schema)
      let rating = try #require(QueryFixtures.player.field(named: "rating"))
      #expect(result.issues == [.valueMismatch(field: rating, valueType: .string, condition: 0)])
    }

    @Test("list comparators take the element type; IN takes a list")
    internal func elementTypes() {
      let reference = FieldValue.reference(.value(Reference(recordName: "p-1")))
      let contains = QueryValidationTests.match(
        [Condition(fieldName: "players", comparator: .listContains, value: reference)]
      )
      #expect(contains.validate(against: schema).isValid)
      let member = QueryValidationTests.player(
        [
          Condition(
            fieldName: "tags",
            comparator: .listMemberBeginsWith,
            value: .string(.value("ra"))
          )
        ]
      )
      #expect(member.validate(against: schema).isValid)
      let inList = QueryValidationTests.player(
        [Condition(fieldName: "rating", comparator: .in, value: .int64(.list([1, 2])))]
      )
      #expect(inList.validate(against: schema).isValid)
      let inScalar = QueryValidationTests.player(
        [Condition(fieldName: "rating", comparator: .in, value: .int64(.value(1)))]
      )
      #expect(inScalar.validate(against: schema).issues.count == 1)
    }

    @Test("NUMBER fields take either number type")
    internal func number() {
      for value in [FieldValue.int64(.value(1)), .double(.value(1.5))] {
        let query = QueryValidationTests.player(
          [Condition(fieldName: "weight", comparator: .equals, value: value)]
        )
        #expect(query.validate(against: schema).isValid)
      }
    }

    @Test("location filters are valid (MistKit sends NEAR)")
    internal func near() {
      let center = FieldValue.location(.value(Location(latitude: 51.5, longitude: -0.12)))
      let result = QueryValidationTests.match(
        [Condition(fieldName: "venue", comparator: .near(meters: 25_000), value: center)]
      )
      .validate(against: schema)
      #expect(result.issues.isEmpty)
    }
  }
}
