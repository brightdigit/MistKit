//
//  CloudKitService+RecordManaging.swift
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

import Foundation

/// CloudKitService conformance to RecordManaging protocol
///
/// This extension makes CloudKitService compatible with the generic RecordManaging
/// operations, enabling protocol-oriented patterns for CloudKit operations.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService: RecordManaging {
  /// Query records of a specific type from CloudKit (deprecated single-page form)
  @available(
    *, deprecated,
    message:
      "Returns at most one page (silently truncates at the server limit). Use queryAllRecords(recordType:) to fetch all pages, or call queryRecords(...) -> QueryResult to handle pagination explicitly."
  )
  public func queryRecords(recordType: String) async throws -> [RecordInfo] {
    let result: QueryResult = try await self.queryRecords(
      recordType: recordType,
      filters: nil,
      sortBy: nil,
      limit: 200,
      desiredKeys: nil,
      continuationMarker: nil
    )
    return result.records
  }

  public func executeBatchOperations(
    _ operations: [RecordOperation],
    recordType: String
  ) async throws {
    _ = try await self.modifyRecords(operations)
  }

  /// Query all records of a specific type, automatically paginating
  public func queryAllRecords(recordType: String) async throws -> [RecordInfo] {
    try await self.queryAllRecords(
      recordType: recordType,
      filters: nil,
      sortBy: nil,
      pageSize: nil
    )
  }
}
