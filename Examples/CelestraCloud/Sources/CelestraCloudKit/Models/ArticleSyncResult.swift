//
//  ArticleSyncResult.swift
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

/// Result of article synchronization including creation and update statistics
public struct ArticleSyncResult: Sendable {
  /// Result of creating new articles
  public let created: BatchOperationResult

  /// Result of updating modified articles
  public let updated: BatchOperationResult

  /// Number of successfully created articles
  public var newCount: Int { created.successCount }

  /// Number of successfully updated articles
  public var modifiedCount: Int { updated.successCount }

  /// Total articles processed (created + updated)
  public var totalProcessed: Int {
    created.totalProcessed + updated.totalProcessed
  }

  /// Total successful operations (created + updated)
  public var successCount: Int {
    created.successCount + updated.successCount
  }

  /// Total failed operations
  public var failureCount: Int {
    created.failureCount + updated.failureCount
  }

  /// Initialize article sync result
  /// - Parameters:
  ///   - created: Creation operation result
  ///   - updated: Update operation result
  public init(created: BatchOperationResult, updated: BatchOperationResult) {
    self.created = created
    self.updated = updated
  }
}
