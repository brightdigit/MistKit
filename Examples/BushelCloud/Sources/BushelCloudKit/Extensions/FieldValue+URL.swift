//
//  FieldValue+URL.swift
//  BushelCloud
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
public import MistKit

extension FieldValue {
  /// Extract a URL from a FieldValue
  ///
  /// This convenience property attempts to convert a string FieldValue back to a URL.
  /// Returns `nil` if the FieldValue is not a string type or if the string cannot be
  /// parsed as a valid URL.
  ///
  /// ## Usage
  /// ```swift
  /// let fieldValue: FieldValue = .string("https://example.com/file.dmg")
  /// if let url = fieldValue.urlValue {
  ///   print(url.absoluteString) // "https://example.com/file.dmg"
  /// }
  /// ```
  ///
  /// - Returns: The URL if this is a string FieldValue with a valid URL format, otherwise `nil`
  public var urlValue: URL? {
    if case .string(let value) = self {
      return URL(string: value)
    }
    return nil
  }

  /// Create a string FieldValue from a URL
  ///
  /// This convenience initializer converts a URL to its absolute string representation
  /// for storage in CloudKit. CloudKit stores URLs as STRING fields, so this provides
  /// automatic conversion.
  ///
  /// ## Usage
  /// ```swift
  /// let url = URL(string: "https://example.com/file.dmg")!
  /// let fieldValue = FieldValue(url: url)
  /// // Equivalent to: FieldValue.string("https://example.com/file.dmg")
  /// ```
  ///
  /// - Parameter url: The URL to convert to a FieldValue
  public init(url: URL) {
    self = .string(url.absoluteString)
  }
}
