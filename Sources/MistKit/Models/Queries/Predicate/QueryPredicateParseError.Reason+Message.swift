//
//  QueryPredicateParseError.Reason+Message.swift
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

extension QueryPredicateParseError.Reason {
  /// A sentence describing the problem.
  public var message: String {
    switch self {
    case .unexpectedCharacter(let character):
      "\"\(character)\" isn't part of a CloudKit predicate"
    case .unterminatedString: "The string has no closing quote"
    case .unterminatedComment: "The comment has no closing */"
    case .expectedField: "Expected a field name (write #name for a field named like a keyword)"
    case .expectedOperator: "Expected an operator: = != < <= > >= BEGINSWITH CONTAINS IN"
    case .expectedValue: "Expected a value"
    case .expectedString: "Expected a quoted string"
    case .expectedNumber: "Expected a number"
    case .expectedLocation: "Expected LOCATION(latitude, longitude)"
    case .expectedToken(let token): "Expected \"\(token)\""
    case .expectedConnective: "Expected AND between conditions"
    case .unsupportedConnective(let word):
      "CloudKit queries combine conditions with AND only, not \(word)"
    case .placeholder(let placeholder): "Replace the placeholder \(placeholder) with a value"
    case .invalidDate(let text): "\"\(text)\" isn't an ISO 8601 date"
    case .invalidBytes(let text): "\"\(text)\" isn't base64"
    case .invalidNumber(let text): "\(text) doesn't fit its type"
    case .unsupportedCast(let type): "CAST converts to \"NSDate\" only, not \"\(type)\""
    case .unknownFunction(let name): "\(name) isn't CAST, REFERENCE, LOCATION or BYTES"
    case .mixedList: "The list's values must all be one type"
    case .untypedEmptyList: "An empty list needs a field of known type"
    }
  }
}
