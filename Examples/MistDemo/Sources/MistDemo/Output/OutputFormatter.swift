//
//  OutputFormatter.swift
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

/// Protocol for formatting output in different formats
public protocol OutputFormatter: Sendable {
  /// Format an encodable value to a string
  func format<T: Encodable>(_ value: T) throws -> String
}

/// Supported output formats
public enum OutputFormat: String, Sendable, CaseIterable {
  case json
  case table
  case csv
  case yaml

  // MARK: Public

  /// Create the appropriate formatter for this format
  public func createFormatter(pretty: Bool = false) throws -> any OutputFormatter {
    switch self {
    case .json:
      JSONFormatter(pretty: pretty)
    case .table, .csv, .yaml:
      throw FormattingError.unsupportedFormat(self)
    }
  }
}
