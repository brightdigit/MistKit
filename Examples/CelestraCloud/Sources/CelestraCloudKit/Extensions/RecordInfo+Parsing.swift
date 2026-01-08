//
//  RecordInfo+Parsing.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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
public import MistKit

/// Extension providing convenient field parsing methods for CloudKit records.
///
/// These methods simplify extracting typed values from RecordInfo fields,
/// handling the FieldValue enum pattern matching internally.
extension RecordInfo {
  /// Extracts a required string field from the record.
  ///
  /// - Parameters:
  ///   - key: The field key to extract.
  ///   - recordType: The record type name for error messages.
  /// - Returns: The string value.
  /// - Throws: `CloudKitConversionError.missingRequiredField` if the field
  ///   is missing or empty.
  public func requiredString(
    forKey key: String,
    recordType: String
  ) throws -> String {
    guard case .string(let value) = fields[key], !value.isEmpty else {
      throw CloudKitConversionError.missingRequiredField(
        fieldName: key,
        recordType: recordType
      )
    }
    return value
  }

  /// Extracts an optional string field from the record.
  ///
  /// - Parameter key: The field key to extract.
  /// - Returns: The string value, or nil if the field is missing.
  public func optionalString(forKey key: String) -> String? {
    guard case .string(let value) = fields[key] else {
      return nil
    }
    return value
  }

  /// Extracts a boolean field from the record (stored as Int64).
  ///
  /// - Parameters:
  ///   - key: The field key to extract.
  ///   - defaultValue: The default value if the field is missing.
  /// - Returns: The boolean value, or the default if the field is missing.
  public func bool(forKey key: String, default defaultValue: Bool = false) -> Bool {
    guard case .int64(let value) = fields[key] else {
      return defaultValue
    }
    return value != 0
  }

  /// Extracts an Int64 field from the record.
  ///
  /// - Parameters:
  ///   - key: The field key to extract.
  ///   - defaultValue: The default value if the field is missing.
  /// - Returns: The Int64 value, or the default if the field is missing.
  public func int64(forKey key: String, default defaultValue: Int64 = 0) -> Int64 {
    guard case .int64(let value) = fields[key] else {
      return defaultValue
    }
    return Int64(value)
  }

  /// Extracts an Int field from the record.
  ///
  /// - Parameters:
  ///   - key: The field key to extract.
  ///   - defaultValue: The default value if the field is missing.
  /// - Returns: The Int value, or the default if the field is missing.
  public func int(forKey key: String, default defaultValue: Int = 0) -> Int {
    guard case .int64(let value) = fields[key] else {
      return defaultValue
    }
    return Int(value)
  }

  /// Extracts an optional Date field from the record.
  ///
  /// - Parameter key: The field key to extract.
  /// - Returns: The Date value, or nil if the field is missing.
  public func optionalDate(forKey key: String) -> Date? {
    guard case .date(let value) = fields[key] else {
      return nil
    }
    return value
  }

  /// Extracts a Date field with a default value from the record.
  ///
  /// - Parameters:
  ///   - key: The field key to extract.
  ///   - defaultValue: The default value if the field is missing.
  /// - Returns: The Date value, or the default if the field is missing.
  public func date(forKey key: String, default defaultValue: Date) -> Date {
    guard case .date(let value) = fields[key] else {
      return defaultValue
    }
    return value
  }

  /// Extracts an optional Double field from the record.
  ///
  /// - Parameter key: The field key to extract.
  /// - Returns: The Double value, or nil if the field is missing.
  public func optionalDouble(forKey key: String) -> Double? {
    guard case .double(let value) = fields[key] else {
      return nil
    }
    return value
  }

  /// Extracts an optional Int field from the record.
  ///
  /// - Parameter key: The field key to extract.
  /// - Returns: The Int value, or nil if the field is missing.
  public func optionalInt(forKey key: String) -> Int? {
    guard case .int64(let value) = fields[key] else {
      return nil
    }
    return Int(value)
  }

  /// Extracts a string array field from the record.
  ///
  /// - Parameter key: The field key to extract.
  /// - Returns: The array of strings, or an empty array if the field is missing.
  public func stringArray(forKey key: String) -> [String] {
    guard case .list(let values) = fields[key] else {
      return []
    }
    return values.compactMap { fieldValue in
      guard case .string(let str) = fieldValue else {
        return nil
      }
      return str
    }
  }
}
