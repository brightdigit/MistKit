//
//  FieldValueFormatter.swift
//  MistDemo
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
internal import MistKit

/// Utility for formatting FieldValue objects for display.
internal enum FieldValueFormatter {
  /// Extract the raw display string from a FieldValue.
  internal static func displayString(
    _ value: FieldValue
  ) -> String {
    switch value {
    case .string(let arity):
      return formatArity(arity, element: { $0 })
    case .int64(let arity):
      return formatArity(arity, element: { "\($0)" })
    case .double(let arity):
      return formatArity(arity, element: { "\($0)" })
    case .bytes(let arity):
      return formatArity(arity, element: { $0.base64EncodedString() })
    case .date(let arity):
      return formatArity(arity, element: formatDate)
    case .location(let arity):
      return formatArity(arity, element: { "(\($0.latitude), \($0.longitude))" })
    case .reference(let arity):
      return formatArity(arity, element: \.recordName)
    case .asset(let arity):
      return formatArity(arity, element: { $0.downloadURL ?? "no URL" })
    }
  }

  /// Format a single FieldValue for display.
  internal static func formatFieldValue(
    _ value: FieldValue
  ) -> String {
    switch value {
    case .string(let arity):
      return formatArity(arity, element: { "\"\($0)\"" })
    case .int64(let arity):
      return formatArity(arity, element: { "\($0)" })
    case .double(let arity):
      return formatArity(arity, element: { "\($0)" })
    case .bytes(let arity):
      return formatArity(arity) { bytes in
        "bytes(\(bytes.count) bytes, base64: \(bytes.base64EncodedString()))"
      }
    case .date(let arity):
      return formatArity(arity, element: { "date(\(formatDate($0)))" })
    case .location(let arity):
      return formatArity(arity) { location in
        "location(\(location.latitude), \(location.longitude))"
      }
    case .reference(let arity):
      return formatArity(arity, element: { "reference(\($0.recordName))" })
    case .asset(let arity):
      return formatArity(arity, element: { "asset(\($0.downloadURL ?? "no URL"))" })
    }
  }

  private static func formatArity<T>(
    _ arity: FieldValue.Arity<T>,
    element: (T) -> String
  ) -> String {
    switch arity {
    case .value(let value):
      return element(value)
    case .list(let values):
      return "[\(values.map(element).joined(separator: ", "))]"
    }
  }

  private static func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
