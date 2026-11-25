//
//  PredicateParser+Functions.swift
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

extension PredicateParser {
  /// The value of `name(…)`, with the opening parenthesis consumed.
  internal mutating func function(
    _ name: String,
    range: Range<Int>
  ) throws(PredicateSyntaxError) -> FieldValue {
    switch name.uppercased() {
    case "CAST":
      return .date(.value(try castDate()))
    case "REFERENCE":
      return .reference(.value(Reference(recordName: try string(advance()))))
    case "LOCATION":
      let latitude = try double(advance())
      try expect(",")
      let longitude = try double(advance())
      return .location(.value(Location(latitude: latitude, longitude: longitude)))
    case "BYTES":
      let token = advance()
      let text = try string(token)
      guard let data = Data(base64Encoded: text) else {
        throw PredicateSyntaxError(.invalidBytes(text), token.range)
      }
      return .bytes(.value(data))
    default:
      throw PredicateSyntaxError(.unknownFunction(name), range)
    }
  }

  /// `CAST("2026-10-01T00:00:00Z", "NSDate")`.
  private mutating func castDate() throws(PredicateSyntaxError) -> Date {
    let token = advance()
    let text = try string(token)
    try expect(",")
    let typeToken = advance()
    let type = try string(typeToken)
    guard type == "NSDate" else {
      throw PredicateSyntaxError(.unsupportedCast(type), typeToken.range)
    }
    guard let date = PredicateDateFormat.date(from: text) else {
      throw PredicateSyntaxError(.invalidDate(text), token.range)
    }
    return date
  }
}
