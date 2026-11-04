//
//  SchemaPrimitiveType.swift
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

/// A primitive type in CloudKit Schema Language.
public enum SchemaPrimitiveType: Sendable, Hashable, Codable {
  /// `ASSET`
  case asset
  /// `BYTES`
  case bytes
  /// `DOUBLE`
  case double
  /// `INT64`
  case int64
  /// `LOCATION`
  case location
  /// `NUMBER`, which CloudKit adds when a sandbox write implicitly creates a
  /// numeric field. `preferredAs` carries a `PREFERRED AS` clause.
  case number(preferredAs: SchemaNumberPreference?)
  /// `REFERENCE`
  case reference
  /// `STRING`
  case string
  /// `TIMESTAMP`
  case timestamp

  /// The one-word keyword for each primitive except `NUMBER`.
  internal static let keywords: [String: Self] = [
    "ASSET": .asset,
    "BYTES": .bytes,
    "DOUBLE": .double,
    "INT64": .int64,
    "LOCATION": .location,
    "REFERENCE": .reference,
    "STRING": .string,
    "TIMESTAMP": .timestamp,
  ]

  /// Whether the language allows `ENCRYPTED` in front of this type.
  ///
  /// CloudKit encrypts `BYTES`, `DOUBLE`, `INT64`, `LOCATION`, `STRING` and
  /// `TIMESTAMP` values; `ASSET` (encrypted already), `REFERENCE` and `NUMBER`
  /// can't be declared `ENCRYPTED`.
  public var canBeEncrypted: Bool {
    switch self {
    case .bytes, .double, .int64, .location, .string, .timestamp:
      return true
    case .asset, .number, .reference:
      return false
    }
  }

  /// The type as the language writes it, such as `INT64` or
  /// `NUMBER PREFERRED AS DOUBLE`.
  public var schemaText: String {
    switch self {
    case .asset: return "ASSET"
    case .bytes: return "BYTES"
    case .double: return "DOUBLE"
    case .int64: return "INT64"
    case .location: return "LOCATION"
    case .number(let preference):
      return preference.map { "NUMBER PREFERRED AS \($0.rawValue)" } ?? "NUMBER"
    case .reference: return "REFERENCE"
    case .string: return "STRING"
    case .timestamp: return "TIMESTAMP"
    }
  }
}
