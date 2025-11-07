//
//  CloudKitService+RecordManaging.swift
//  MistKit
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

/// CloudKitService conformance to RecordManaging protocol
///
/// This extension makes CloudKitService compatible with the generic RecordManaging
/// operations, enabling protocol-oriented patterns for CloudKit operations.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService: RecordManaging {
  /// Query records of a specific type from CloudKit
  ///
  /// This implementation uses a default limit of 200 records. For more control over
  /// query parameters (filters, sorting, custom limits), use the full `queryRecords`
  /// method directly on CloudKitService.
  ///
  /// - Parameter recordType: The CloudKit record type to query
  /// - Returns: Array of record information for matching records (up to 200)
  /// - Throws: CloudKit errors if the query fails
  public func queryRecords(recordType: String) async throws -> [RecordInfo] {
    do {
      return try await self.queryRecords(
        recordType: recordType,
        filters: nil,
        sortBy: nil,
        limit: 200
      )
    } catch let error as CloudKitError {
      throw error
    }
  }

  /// Execute a batch of record operations
  ///
  /// This implementation delegates to CloudKitService's `modifyRecords` method.
  /// The recordType parameter is provided for logging purposes but is not required
  /// by the underlying implementation (operation types are embedded in RecordOperation).
  ///
  /// Note: The caller is responsible for respecting CloudKit's 200 operations/request
  /// limit by batching operations. The RecordManaging generic extensions handle this
  /// automatically.
  ///
  /// - Parameters:
  ///   - operations: Array of record operations to execute
  ///   - recordType: The record type being operated on (for reference/logging)
  /// - Throws: CloudKit errors if the batch operations fail
  public func executeBatchOperations(
    _ operations: [RecordOperation],
    recordType: String
  ) async throws {
    do {
      _ = try await self.modifyRecords(operations)
    } catch let error as CloudKitError {
      throw error
    }
  }
}
