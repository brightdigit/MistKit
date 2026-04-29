//
//  FieldValue+Codable.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

// MARK: - Codable

extension FieldValue {
  private static let millisecondsPerSecond: Double = 1_000

  /// Initialize field value from decoder
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let value = try Self.decodeBasicTypes(from: container) {
      self = value
      return
    }

    if let value = try Self.decodeComplexTypes(from: container) {
      self = value
      return
    }

    throw DecodingError.dataCorruptedError(
      in: container,
      debugDescription: "Unable to decode FieldValue"
    )
  }

  /// Decode basic field value types (string, int64, double)
  private static func decodeBasicTypes(from container: any SingleValueDecodingContainer) throws
    -> FieldValue?
  {
    if let value = try? container.decode(String.self) {
      return .string(value)
    }
    if let value = try? container.decode(Int.self) {
      return .int64(value)
    }
    if let value = try? container.decode(Double.self) {
      return .double(value)
    }
    return nil
  }

  /// Decode complex field value types (list, location, reference, asset, date)
  private static func decodeComplexTypes(from container: any SingleValueDecodingContainer) throws
    -> FieldValue?
  {
    if let value = try? container.decode([FieldValue].self) {
      return .list(value)
    }
    if let value = try? container.decode(Location.self) {
      return .location(value)
    }
    if let value = try? container.decode(Reference.self) {
      return .reference(value)
    }
    if let value = try? container.decode(Asset.self) {
      return .asset(value)
    }
    // Try to decode as date (milliseconds since epoch)
    if let value = try? container.decode(Double.self) {
      return .date(Date(timeIntervalSince1970: value / Self.millisecondsPerSecond))
    }
    return nil
  }

  /// Encode field value to encoder
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try encodeValue(to: &container)
  }

  // swiftlint:disable:next cyclomatic_complexity
  private func encodeValue(to container: inout any SingleValueEncodingContainer) throws {
    switch self {
    case .string(let val), .bytes(let val):
      try container.encode(val)
    case .int64(let val):
      try container.encode(val)
    case .double(let val):
      try container.encode(val)
    case .date(let val):
      try container.encode(val.timeIntervalSince1970 * Self.millisecondsPerSecond)
    case .location(let val):
      try container.encode(val)
    case .reference(let val):
      try container.encode(val)
    case .asset(let val):
      try container.encode(val)
    case .list(let val):
      try container.encode(val)
    }
  }
}

// MARK: - Helper Methods

extension FieldValue {
  /// Create an int64 FieldValue from a Bool
  ///
  /// CloudKit represents booleans as INT64 (0/1) on the wire.
  /// Creates a FieldValue from a Swift Bool value.
  ///
  /// This initializer converts Swift Bool to the appropriate int64 representation
  /// used by CloudKit (1 for true, 0 for false).
  ///
  /// - Parameter booleanValue: The boolean value to convert
  public init(booleanValue: Bool) {
    self = .int64(booleanValue ? 1 : 0)
  }
}
