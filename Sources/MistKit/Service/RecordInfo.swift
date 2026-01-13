//
//  RecordInfo.swift
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

internal import Foundation

/// Record information from CloudKit
///
/// ## Error Detection Pattern
/// CloudKit Web Services returns error responses as records with nil `recordType` and `recordName`.
/// This implementation uses "Unknown" as a sentinel value for error responses, which can be detected
/// using the `isError` property. While this is a fragile pattern, it matches CloudKit's API behavior
/// where failed operations in a batch return incomplete record data.
///
/// Example:
/// ```swift
/// let results = try await service.modifyRecords(operations)
/// let successfulRecords = results.filter { !$0.isError }
/// let failedRecords = results.filter { $0.isError }
/// ```
public struct RecordInfo: Encodable, Sendable {
  /// The record name
  public let recordName: String
  /// The record type
  public let recordType: String
  /// The record change tag for optimistic locking
  public let recordChangeTag: String?
  /// The record fields
  public let fields: [String: FieldValue]

  /// Indicates whether this RecordInfo represents an error response
  ///
  /// CloudKit returns error responses with nil recordType/recordName, which are converted
  /// to "Unknown" during initialization. Use this property to detect failed operations
  /// in batch modify responses.
  public var isError: Bool {
    recordType == "Unknown"
  }

  internal init(from record: Components.Schemas.Record) {
    self.recordName = record.recordName ?? "Unknown"
    self.recordType = record.recordType ?? "Unknown"
    self.recordChangeTag = record.recordChangeTag

    // Convert fields to FieldValue representation
    var convertedFields: [String: FieldValue] = [:]

    if let fieldsPayload = record.fields {
      for (fieldName, fieldData) in fieldsPayload.additionalProperties {
        if let fieldValue = FieldValue(fieldData) {
          convertedFields[fieldName] = fieldValue
        }
      }
    }

    self.fields = convertedFields
  }

  /// Public initializer for creating RecordInfo instances
  ///
  /// This initializer is primarily intended for testing and cases where you need to
  /// construct RecordInfo manually rather than receiving it from CloudKit responses.
  ///
  /// - Parameters:
  ///   - recordName: The unique record name
  ///   - recordType: The CloudKit record type
  ///   - recordChangeTag: Optional change tag for optimistic locking
  ///   - fields: Dictionary of field names to their values
  public init(
    recordName: String,
    recordType: String,
    recordChangeTag: String? = nil,
    fields: [String: FieldValue]
  ) {
    self.recordName = recordName
    self.recordType = recordType
    self.recordChangeTag = recordChangeTag
    self.fields = fields
  }
}
