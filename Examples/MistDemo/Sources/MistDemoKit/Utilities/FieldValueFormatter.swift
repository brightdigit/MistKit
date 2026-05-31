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
  // Extract the raw display string from a FieldValue.
  // swiftlint:disable:next cyclomatic_complexity
  internal static func displayString(
    _ value: FieldValue
  ) -> String {
    switch value {
    case .string(let string):
      return string
    case .int64(let int):
      return "\(int)"
    case .double(let double):
      return "\(double)"
    case .bytes(let bytes):
      return bytes
    case .date(let date):
      return formatDate(date)
    case .location(let location):
      return "(\(location.latitude), \(location.longitude))"
    case .reference(let reference):
      return reference.recordName
    case .asset(let asset):
      return asset.downloadURL ?? "no URL"
    case .list(let values):
      let items = values.map { displayString($0) }
      return "[\(items.joined(separator: ", "))]"
    }
  }

  // Format a single FieldValue for display.
  // swiftlint:disable:next cyclomatic_complexity
  internal static func formatFieldValue(
    _ value: FieldValue
  ) -> String {
    switch value {
    case .string(let string):
      return "\"\(string)\""
    case .int64(let int):
      return "\(int)"
    case .double(let double):
      return "\(double)"
    case .bytes(let bytes):
      return "bytes(\(bytes.count) chars, base64: \(bytes))"
    case .date(let date):
      return "date(\(formatDate(date)))"
    case .location(let location):
      return "location(\(location.latitude), \(location.longitude))"
    case .reference(let reference):
      return "reference(\(reference.recordName))"
    case .asset(let asset):
      return "asset(\(asset.downloadURL ?? "no URL"))"
    case .list(let values):
      let items = values.map { formatFieldValue($0) }
      return "[\(items.joined(separator: ", "))]"
    }
  }

  private static func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
