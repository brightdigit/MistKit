internal import Foundation
internal import Testing

@testable import MistKit

extension QueryPredicateTests {
  /// Parse errors say what's wrong and where, so an editor can underline it.
  @Suite("Errors")
  internal struct Errors {
    @Test(
      "each error names its reason and range",
      arguments: [
        ("rating ~ 3", QueryPredicateParseError.Reason.unexpectedCharacter("~"), 7..<8),
        ("handle = \"mei", .unterminatedString, 9..<13),
        ("rating = 3 /* x", .unterminatedComment, 11..<15),
        ("= 3", .expectedField, 0..<1),
        ("rating 3", .expectedOperator, 7..<8),
        ("rating =", .expectedValue, 8..<8),
        ("rating = 3 OR handle = 1", .unsupportedConnective("OR"), 11..<13),
        ("rating = 3 || handle = 1", .unsupportedConnective("||"), 11..<13),
        ("NOT rating = 3", .unsupportedConnective("NOT"), 0..<3),
        ("!rating = 3", .unsupportedConnective("!"), 0..<1),
        ("rating = %@", .placeholder("%@"), 9..<11),
        ("rating = $value", .placeholder("$value"), 9..<15),
        ("startedAt > CAST(\"yesterday\", \"NSDate\")", .invalidDate("yesterday"), 17..<28),
        ("startedAt > CAST(\"x\", \"NSString\")", .unsupportedCast("NSString"), 22..<32),
        ("token = BYTES(\"%%%\")", .invalidBytes("%%%"), 14..<19),
        ("rating = 99999999999999999999", .invalidNumber("99999999999999999999"), 9..<29),
        ("rating = 3 handle", .expectedConnective, 11..<17),
        ("rating = 3 AND", .expectedField, 14..<14),
        ("handle = LIST(1)", .unknownFunction("LIST"), 9..<13),
        ("handle BEGINSWITH 3", .expectedString, 18..<19),
        ("venue = LOCATION(\"a\", 2)", .expectedNumber, 17..<20),
        ("distanceToLocation:fromLocation:(venue, 3) < 1", .expectedLocation, 40..<41),
        (
          "distanceToLocation:fromLocation:(venue, LOCATION(1, 2)) > 5", .expectedToken("<"),
          56..<57
        ),
      ]
    )
    internal func located(
      text: String,
      reason: QueryPredicateParseError.Reason,
      range: Range<Int>
    ) throws {
      let error = try #require(QueryPredicateTests.error(text))
      #expect(error.reason == reason)
      #expect(error.range == range)
      #expect(error.offset == range.lowerBound)
      #expect(!reason.message.isEmpty)
    }

    @Test("errors carry their line and column")
    internal func lineAndColumn() throws {
      let text = "rating = 3\nAND handle ~ 1"
      let error = try #require(QueryPredicateTests.error(text))
      #expect(error.line == 2)
      #expect(error.column == 12)
      #expect(error.range == 22..<23)
      #expect(error.errorDescription?.hasPrefix("Predicate line 2, column 12: ") == true)
    }

    @Test("ranges count characters, and convert to UTF-16 for text views")
    internal func utf16() throws {
      let text = "handle = \"🎲\" AND rating ~ 1"
      let error = try #require(QueryPredicateTests.error(text))
      #expect(error.range == 24..<25)
      #expect(error.utf16Range(in: text) == 25..<26)
    }
  }
}
