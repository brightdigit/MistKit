//
//  PredicateDateFormat.swift
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

/// ISO 8601 dates in UTC, with fractional seconds only when there are any.
///
/// Uses `ISO8601DateFormatter`, not `Date.ISO8601FormatStyle`, which needs
/// macOS 12. Formatters aren't `Sendable`, so each call makes its own.
internal enum PredicateDateFormat {
  internal static func date(from text: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: text) {
      return date
    }
    formatter.formatOptions.insert(.withFractionalSeconds)
    return formatter.date(from: text)
  }

  internal static func string(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    let seconds = date.timeIntervalSince1970
    if seconds.rounded(.down) != seconds {
      formatter.formatOptions.insert(.withFractionalSeconds)
    }
    return formatter.string(from: date)
  }
}
