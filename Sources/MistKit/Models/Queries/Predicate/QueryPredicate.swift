//
//  QueryPredicate.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation

/// Reads and writes query conditions as an NSPredicate format string, the
/// subset `CKQuery` accepts.
///
/// ```
/// startedAt >= CAST("2026-10-01T00:00:00Z", "NSDate")
/// AND players CONTAINS REFERENCE("p-1")
/// AND displayName BEGINSWITH "Ka"
/// AND status IN {"open", "full"}
/// AND distanceToLocation:fromLocation:(venue, LOCATION(51.5, -0.12)) < 25.0
/// ```
///
/// - Operators: `=` (`==`), `!=` (`<>`), `<`, `<=` (`=<`), `>`, `>=` (`=>`),
///   `BEGINSWITH`, `CONTAINS` (a list field contains the value) and `IN`
///   (`{…}`); keywords ignore case.
/// - Conditions join with `AND` (`&&`). `OR` (`||`) and `NOT` (`!`) are
///   errors, because CloudKit queries don't support them.
/// - Values: numbers, quoted strings (`"…"` or `'…'`),
///   `CAST("<ISO 8601>", "NSDate")`, `REFERENCE("<recordName>")`,
///   `LOCATION(<latitude>, <longitude>)` and `BYTES("<base64>")`.
/// - Distances are in kilometres, as with `CKQuery`;
///   ``QueryDescriptor/Comparator/near(meters:)`` stores metres. `<=` reads
///   the same as `<`.
/// - Dates keep millisecond precision, as CloudKit stores them.
/// - A field named like a keyword is written `#name`. `/* … */` comments are
///   skipped. Empty text and `TRUEPREDICATE` mean no conditions.
public enum QueryPredicate {
  /// Reads conditions from a predicate format string.
  ///
  /// - Parameters:
  ///   - text: The format string.
  ///   - recordType: When given, whole numbers compared with `DOUBLE` fields
  ///     are read as doubles, and an empty `IN {}` list takes the field's type.
  /// - Returns: The conditions, in order; empty for empty text and
  ///   `TRUEPREDICATE`.
  /// - Throws: ``QueryPredicateParseError`` with the offending range.
  public static func parse(
    _ text: String,
    recordType: SchemaRecordType? = nil
  ) throws(QueryPredicateParseError) -> [QueryDescriptor.Condition] {
    do throws(PredicateSyntaxError) {
      var lexer = PredicateLexer(text)
      var parser = PredicateParser(tokens: try lexer.tokens(), recordType: recordType)
      return try parser.parse()
    } catch {
      throw QueryPredicateParseError(reason: error.reason, range: error.range, in: text)
    }
  }

  /// Writes conditions as a canonical predicate format string, one condition
  /// per line.
  ///
  /// Parsing the result gives back the same conditions.
  /// - Parameter conditions: The conditions to write.
  /// - Returns: The format string; empty for no conditions.
  /// - Throws: ``QueryPredicateFormatError`` for a value or comparator the
  ///   syntax can't express.
  public static func format(
    _ conditions: [QueryDescriptor.Condition]
  ) throws(QueryPredicateFormatError) -> String {
    try PredicateFormatter.format(conditions)
  }
}
