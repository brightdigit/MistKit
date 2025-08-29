//
//  RecordInfo.swift
//  PackageDSLKit
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

/// Record information from CloudKit
public struct RecordInfo: Encodable {
  /// The record name
  public let recordName: String
  /// The record type
  public let recordType: String
  /// The record fields
  public let fields: [String: FieldValue]

  internal init(from record: Components.Schemas.Record) {
    self.recordName = record.recordName ?? "Unknown"
    self.recordType = record.recordType ?? "Unknown"

    // Convert fields to FieldValue representation
    var convertedFields: [String: FieldValue] = [:]

    if let fieldsPayload = record.fields {
      for (fieldName, fieldData) in fieldsPayload.additionalProperties {
        if let fieldValue = RecordFieldConverter.convertToFieldValue(fieldData) {
          convertedFields[fieldName] = fieldValue
        }
      }
    }

    self.fields = convertedFields
  }
}
