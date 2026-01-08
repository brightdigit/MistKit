//
//  CloudKitRecordOperating.swift
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

public import MistKit

/// Protocol for CloudKit record operations, enabling testability via dependency injection
public protocol CloudKitRecordOperating: Sendable {
  /// Query records from CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to query
  ///   - filters: Optional query filters
  ///   - sortBy: Optional sort descriptors
  ///   - limit: Maximum number of records to return (optional)
  ///   - desiredKeys: Optional list of field keys to fetch
  /// - Returns: Array of matching record info
  /// - Throws: CloudKitError if the query fails
  func queryRecords(
    recordType: String,
    filters: [QueryFilter]?,
    sortBy: [QuerySort]?,
    limit: Int?,
    desiredKeys: [String]?
  ) async throws(CloudKitError) -> [RecordInfo]

  /// Modify records in CloudKit (create, update, delete)
  /// - Parameter operations: Array of record operations to perform
  /// - Returns: Array of modified record info
  /// - Throws: CloudKitError if the modification fails
  func modifyRecords(_ operations: [RecordOperation]) async throws(CloudKitError) -> [RecordInfo]
}

// MARK: - CloudKitService Conformance

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService: CloudKitRecordOperating {}
