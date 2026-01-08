//
//  BatchOperationResult.swift
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

public import CelestraKit
public import Foundation
public import MistKit

/// Result of a batch CloudKit operation
public struct BatchOperationResult: Sendable {
  /// Successfully created/updated records
  public var successfulRecords: [RecordInfo] = []

  /// Records that failed to process
  public var failedRecords: [(article: Article, error: any Error)] = []

  /// Total number of records processed (success + failure)
  public var totalProcessed: Int {
    successfulRecords.count + failedRecords.count
  }

  /// Number of successful operations
  public var successCount: Int {
    successfulRecords.count
  }

  /// Number of failed operations
  public var failureCount: Int {
    failedRecords.count
  }

  /// Success rate as a percentage (0-100)
  public var successRate: Double {
    guard totalProcessed > 0 else {
      return 0
    }
    return Double(successCount) / Double(totalProcessed) * 100
  }

  /// Whether all operations succeeded
  public var isFullSuccess: Bool {
    failureCount == 0 && successCount > 0
  }

  /// Whether all operations failed
  public var isFullFailure: Bool {
    successCount == 0 && failureCount > 0
  }

  // MARK: - Initializers

  /// Creates an empty batch operation result.
  public init() {}

  // MARK: - Mutation

  /// Append results from another batch operation
  public mutating func append(_ other: BatchOperationResult) {
    successfulRecords.append(contentsOf: other.successfulRecords)
    failedRecords.append(contentsOf: other.failedRecords)
  }

  /// Append successful records
  public mutating func appendSuccesses(_ records: [RecordInfo]) {
    successfulRecords.append(contentsOf: records)
  }

  /// Append a failure
  public mutating func appendFailure(article: Article, error: any Error) {
    failedRecords.append((article, error))
  }
}
