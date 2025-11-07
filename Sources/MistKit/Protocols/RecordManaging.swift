//
//  RecordManaging.swift
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

/// Protocol defining core CloudKit record management operations
///
/// This protocol provides a testable abstraction for CloudKit operations.
/// Conforming types must implement the two core operations, while all other
/// functionality (listing, syncing, deleting) is provided through protocol extensions.
public protocol RecordManaging {
  /// Query records of a specific type from CloudKit
  ///
  /// - Parameter recordType: The CloudKit record type to query
  /// - Returns: Array of record information for all matching records
  /// - Throws: CloudKit errors if the query fails
  func queryRecords(recordType: String) async throws -> [RecordInfo]

  /// Execute a batch of record operations
  ///
  /// Handles batching operations to respect CloudKit's 200 operations/request limit.
  /// Provides detailed progress reporting and error tracking.
  ///
  /// - Parameters:
  ///   - operations: Array of record operations to execute
  ///   - recordType: The record type being operated on (for logging)
  /// - Throws: CloudKit errors if the batch operations fail
  func executeBatchOperations(_ operations: [RecordOperation], recordType: String) async throws
}
