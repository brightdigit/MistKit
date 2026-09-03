//
//  RecordName.swift
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

/// A CloudKit record's identity within a zone.
///
/// Typical `recordName` values are opaque strings unique in that zone. CloudKit
/// auto-generated names are UUID strings; callers may also supply a custom
/// string. Both share the same JSON wire type (a single string).
///
/// This is a string-backed struct rather than a `typealias` or enum:
/// - The set of names is open (UUID or caller-chosen), so an enum is the wrong
///   model.
/// - `typealias RecordName = String` would not distinguish a record's identity
///   from owner names, zone names, or other strings.
///
/// ``UserRecordName`` stays a separate enum (`recordName` vs `nonDiscoverable`)
/// for user-identity lookup; do not merge the two types.
public struct RecordName: RawRepresentable, Hashable, Sendable, Codable,
  ExpressibleByStringLiteral, CustomStringConvertible, Comparable
{
  /// The record name string as it appears on the CloudKit wire.
  public let rawValue: String

  /// Creates a record name from its wire string.
  /// - Parameter rawValue: The CloudKit record name (UUID or custom string).
  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  /// Creates a record name from a string value (for interpolations and stored `String`s).
  public init(_ rawValue: String) {
    self.init(rawValue: rawValue)
  }

  /// Creates a record name from a string literal so `"foo"` still type-checks
  /// at call sites that take ``RecordName``.
  public init(stringLiteral value: String) {
    self.init(rawValue: value)
  }

  /// Decodes from a single JSON string (not a keyed object).
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(rawValue: try container.decode(String.self))
  }

  /// Encodes as a single JSON string (not a keyed object).
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }

  /// The record name string, suitable for logs and display.
  public var description: String { rawValue }

  public static func < (lhs: RecordName, rhs: RecordName) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
