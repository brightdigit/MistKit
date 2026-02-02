//
//  RecordManagingTests.swift
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

import Foundation
import Testing

@testable import MistKit

/// Mock implementation of RecordManaging for testing
internal actor MockRecordManagingService: RecordManaging {
  internal var queryCallCount = 0
  internal var executeCallCount = 0
  internal var lastExecutedOperations: [RecordOperation] = []
  internal var batchSizes: [Int] = []
  internal var recordsToReturn: [RecordInfo] = []

  internal func queryRecords(recordType: String) async throws -> [RecordInfo] {
    queryCallCount += 1
    return recordsToReturn
  }

  internal func executeBatchOperations(_ operations: [RecordOperation], recordType: String)
    async throws
  {
    executeCallCount += 1
    batchSizes.append(operations.count)
    lastExecutedOperations.append(contentsOf: operations)
  }

  internal func reset() {
    queryCallCount = 0
    executeCallCount = 0
    lastExecutedOperations = []
    batchSizes = []
    recordsToReturn = []
  }

  internal func setRecordsToReturn(_ records: [RecordInfo]) {
    recordsToReturn = records
  }
}

@Suite("RecordManaging Protocol")
internal enum RecordManagingTests {}
