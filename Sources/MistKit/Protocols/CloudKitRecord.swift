//
//  CloudKitRecord.swift
//  MistKit
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

/// Protocol for types that can be serialized to and from CloudKit records
///
/// Conforming types can be automatically synced, queried, and listed using
/// generic `RecordManaging` extension methods, eliminating the need for
/// model-specific implementations.
///
/// ## Example Conformance
///
/// ```swift
/// extension MyRecord: CloudKitRecord {
///     static var cloudKitRecordType: String { "MyRecord" }
///
///     func toCloudKitFields() -> [String: FieldValue] {
///         var fields: [String: FieldValue] = [
///             "name": .string(name),
///             "count": .int64(Int64(count))
///         ]
///         if let optional { fields["optional"] = .string(optional) }
///         return fields
///     }
///
///     static func from(recordInfo: RecordInfo) -> Self? {
///         guard let name = recordInfo.fields["name"]?.stringValue else {
///             return nil
///         }
///         return MyRecord(name: name, count: recordInfo.fields["count"]?.intValue ?? 0)
///     }
///
///     static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
///         let name = recordInfo.fields["name"]?.stringValue ?? "Unknown"
///         return "  \(name)"
///     }
/// }
/// ```
public protocol CloudKitRecord: Codable, Sendable {
  /// The CloudKit record type name
  ///
  /// This must match the record type defined in your CloudKit schema.
  /// For example: "RestoreImage", "XcodeVersion", "SwiftVersion"
  static var cloudKitRecordType: String { get }

  /// The unique CloudKit record name for this instance
  ///
  /// This is typically computed from the model's primary key or unique identifier.
  /// For example: "RestoreImage-23C71" or "XcodeVersion-15.2"
  var recordName: String { get }

  /// Convert this model to CloudKit field values
  ///
  /// Map each property to its corresponding `FieldValue` enum case:
  /// - String properties → `.string(value)`
  /// - Int properties → `.int64(Int64(value))`
  /// - Double properties → `.double(value)`
  /// - Bool properties → `.boolean(value)`
  /// - Date properties → `.date(value)`
  /// - References → `.reference(recordName: "OtherRecord-ID")`
  ///
  /// Handle optional properties with conditional field assignment:
  /// ```swift
  /// if let optionalValue { fields["optional"] = .string(optionalValue) }
  /// ```
  ///
  /// - Returns: Dictionary mapping CloudKit field names to their values
  func toCloudKitFields() -> [String: FieldValue]

  /// Parse a CloudKit record into a model instance
  ///
  /// Extract required fields using `FieldValue` convenience properties:
  /// - `.stringValue` for String fields
  /// - `.intValue` for Int fields
  /// - `.doubleValue` for Double fields
  /// - `.boolValue` for Bool fields (handles CloudKit's int64 boolean representation)
  /// - `.dateValue` for Date fields
  ///
  /// Return `nil` if required fields are missing or invalid.
  ///
  /// - Parameter recordInfo: The CloudKit record information to parse
  /// - Returns: A model instance, or `nil` if parsing fails
  static func from(recordInfo: RecordInfo) -> Self?

  /// Format a CloudKit record for display output
  ///
  /// Generate a human-readable string representation for console output.
  /// This is used by `list<T>()` methods to display query results.
  ///
  /// - Parameter recordInfo: The CloudKit record to format
  /// - Returns: A formatted string (typically 1-3 lines with indentation)
  static func formatForDisplay(_ recordInfo: RecordInfo) -> String
}
