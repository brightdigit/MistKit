//
//  MockRecordInfo.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

/// Helper to create RecordInfo from field dictionaries for testing roundtrips
public enum MockRecordInfo: Sendable {
  /// Creates a RecordInfo with the specified fields for testing
  ///
  /// - Parameters:
  ///   - recordType: CloudKit record type (e.g., "RestoreImage")
  ///   - recordName: CloudKit record name (e.g., "RestoreImage-23C71")
  ///   - fields: Dictionary of CloudKit field values
  /// - Returns: A RecordInfo suitable for testing `from(recordInfo:)` methods
  public static func create(
    recordType: String,
    recordName: String,
    fields: [String: FieldValue]
  ) -> RecordInfo {
    RecordInfo(
      recordName: recordName,
      recordType: recordType,
      recordChangeTag: nil,
      fields: fields
    )
  }

  /// Creates a RecordInfo with an error for testing error handling
  ///
  /// - Parameters:
  ///   - recordName: CloudKit record name
  ///   - errorCode: Server error code (stored in fields for test verification)
  ///   - reason: Error reason message (stored in fields for test verification)
  /// - Returns: A RecordInfo marked as an error (isError == true)
  public static func createError(
    recordType _: String,
    recordName: String,
    errorCode: String,
    reason: String
  ) -> RecordInfo {
    RecordInfo(
      recordName: recordName,
      recordType: "Unknown",  // Marks this as an error (isError will be true)
      recordChangeTag: nil,
      fields: [
        "serverErrorCode": .string(errorCode),
        "reason": .string(reason),
      ]
    )
  }
}
