//
//  ErrorOutput.swift
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

/// JSON-formatted error output for consistent error reporting
public struct ErrorOutput: Sendable, Codable {
  // MARK: Lifecycle

  public init(code: String, message: String, details: [String: String]? = nil, suggestion: String? = nil) {
    self.error = ErrorDetail(code: code, message: message, details: details, suggestion: suggestion)
  }

  // MARK: Public

  /// The error details
  public let error: ErrorDetail

  // MARK: - Error Detail

  /// Detailed error information
  public struct ErrorDetail: Sendable, Codable {
    // MARK: Lifecycle

    public init(code: String, message: String, details: [String: String]? = nil, suggestion: String? = nil) {
      self.code = code
      self.message = message
      self.details = details
      self.suggestion = suggestion
    }

    // MARK: Public

    /// Error code (machine-readable)
    public let code: String

    /// Human-readable error message
    public let message: String

    /// Optional additional details about the error
    public let details: [String: String]?

    /// Optional suggestion for recovery
    public let suggestion: String?
  }
}

