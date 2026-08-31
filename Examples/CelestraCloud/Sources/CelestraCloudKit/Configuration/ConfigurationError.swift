//
//  ConfigurationError.swift
//  CelestraCloud
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

public import Foundation

/// A missing or malformed configuration value, naming the key at fault.
public struct ConfigurationError: LocalizedError, Sendable {
  /// The error message describing what went wrong.
  public let message: String

  /// The configuration key that caused the error, if applicable.
  public let key: String?

  /// A localized description of the error.
  public var errorDescription: String? {
    var parts = [message]
    if let key {
      parts.append("(key: \(key))")
    }
    return parts.joined(separator: " ")
  }

  /// Creates a new configuration error.
  ///
  /// - Parameters:
  ///   - message: The error message describing what went wrong.
  ///   - key: The configuration key that caused the error, if applicable.
  public init(_ message: String, key: String? = nil) {
    self.message = message
    self.key = key
  }
}
