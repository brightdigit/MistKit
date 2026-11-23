//
//  PredicateLiteral.swift
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

/// Spells literals the way ``PredicateLexer`` reads them.
internal enum PredicateLiteral {
  private static let escapes: [Character: String] = [
    "\"": "\\\"", "\\": "\\\\", "\n": "\\n", "\r": "\\r", "\t": "\\t",
  ]

  /// A double-quoted string with `\"`, `\\`, `\n`, `\r` and `\t` escapes.
  internal static func quoted(_ string: String) -> String {
    "\"" + string.map { escapes[$0] ?? String($0) }.joined() + "\""
  }

  /// A finite number in Swift's shortest round-tripping form; `nil` otherwise.
  internal static func number(_ double: Double) -> String? {
    double.isFinite ? String(double) : nil
  }

  /// `CAST("<ISO 8601>", "NSDate")`.
  internal static func date(_ date: Date) -> String {
    "CAST(\(quoted(PredicateDateFormat.string(from: date))), \"NSDate\")"
  }

  /// `LOCATION(lat, lon)`; `nil` for non-finite coordinates.
  internal static func location(_ location: Location) -> String? {
    guard let latitude = number(location.latitude),
      let longitude = number(location.longitude)
    else {
      return nil
    }
    return "LOCATION(\(latitude), \(longitude))"
  }
}
