//
//  QueryPredicateParseError.Reason.swift
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

extension QueryPredicateParseError {
  /// What's wrong with a predicate format string.
  public enum Reason: Hashable, Sendable {
    /// A character the syntax doesn't use.
    case unexpectedCharacter(Character)
    /// A string literal without its closing quote.
    case unterminatedString
    /// A `/*` comment without its `*/`.
    case unterminatedComment
    /// A field name was expected; keywords need `#name`.
    case expectedField
    /// A comparison operator was expected.
    case expectedOperator
    /// A value was expected.
    case expectedValue
    /// A quoted string was expected, as `BEGINSWITH` and the functions take.
    case expectedString
    /// A number was expected.
    case expectedNumber
    /// `LOCATION(latitude, longitude)` was expected.
    case expectedLocation
    /// This token, such as `(` or `<`, was expected.
    case expectedToken(String)
    /// Conditions must be joined with `AND`.
    case expectedConnective
    /// `OR`, `||`, `NOT` or `!`, which CloudKit queries don't support.
    case unsupportedConnective(String)
    /// A format placeholder such as `%@` or `$name` instead of a value.
    case placeholder(String)
    /// A `CAST(…, "NSDate")` string that isn't an ISO 8601 date.
    case invalidDate(String)
    /// A `BYTES(…)` string that isn't base64.
    case invalidBytes(String)
    /// A number that doesn't fit its type.
    case invalidNumber(String)
    /// A `CAST` to a type other than `"NSDate"`.
    case unsupportedCast(String)
    /// A function other than `CAST`, `REFERENCE`, `LOCATION` or `BYTES`.
    case unknownFunction(String)
    /// An `IN` list whose values aren't all of one type.
    case mixedList
    /// An empty `IN {}` list on a field whose type isn't known.
    case untypedEmptyList
  }
}
