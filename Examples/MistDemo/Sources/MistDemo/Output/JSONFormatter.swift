//
//  JSONFormatter.swift
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

import Foundation

/// Formatter for JSON output
public struct JSONFormatter: OutputFormatter {
  // MARK: Lifecycle

  public init(pretty: Bool = false) {
    self.pretty = pretty
  }

  // MARK: Public

  /// Whether to use pretty printing
  public let pretty: Bool

  public func format<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    if pretty {
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }
    let data = try encoder.encode(value)
    guard let string = String(data: data, encoding: .utf8) else {
      throw FormattingError.encodingFailed
    }
    return string
  }
}

// MARK: - Formatting Errors

enum FormattingError: LocalizedError {
  case encodingFailed
  case invalidStructure(String)

  // MARK: Internal

  var errorDescription: String? {
    switch self {
    case .encodingFailed:
      "Failed to encode data to UTF-8 string"
    case let .invalidStructure(message):
      "Invalid data structure: \(message)"
    }
  }
}
