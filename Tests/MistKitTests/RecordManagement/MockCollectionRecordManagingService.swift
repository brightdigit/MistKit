//
//  MockCollectionRecordManagingService.swift
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

internal import Foundation

@testable import MistKit

@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
internal actor MockCollectionRecordManagingService: RecordManaging, CloudKitRecordCollection {
  internal static let recordTypes = RecordTypeSet(TestRecord.self, AltTestRecord.self)

  internal var queryCallCount = 0
  internal var executeCallCount = 0
  internal var lastExecutedOperations: [RecordOperation] = []
  internal var batchSizes: [Int] = []
  internal var recordsByType: [String: [RecordInfo]] = [:]

  internal func queryAllRecords(recordType: String) async throws -> [RecordInfo] {
    queryCallCount += 1
    return recordsByType[recordType] ?? []
  }

  internal func executeBatchOperations(_ operations: [RecordOperation]) async throws {
    executeCallCount += 1
    batchSizes.append(operations.count)
    lastExecutedOperations.append(contentsOf: operations)
  }

  internal func setRecords(_ records: [RecordInfo], forRecordType recordType: String) {
    recordsByType[recordType] = records
  }
}
