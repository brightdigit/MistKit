//
//  MockCloudKitRecordOperator.swift
//  CelestraCloud
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
import MistKit

@testable import CelestraCloudKit

/// Mock implementation of CloudKitRecordOperating for testing
internal final class MockCloudKitRecordOperator: CloudKitRecordOperating, @unchecked Sendable {
  // MARK: - Recorded Calls

  internal struct QueryCall {
    internal let recordType: String
    internal let filters: [QueryFilter]?
    internal let sortBy: [QuerySort]?
    internal let limit: Int?
    internal let desiredKeys: [String]?
  }

  internal struct ModifyCall {
    internal let operations: [RecordOperation]
  }

  internal private(set) var queryCalls: [QueryCall] = []
  internal private(set) var modifyCalls: [ModifyCall] = []

  // MARK: - Stubbed Results

  internal var queryRecordsResult: Result<[RecordInfo], CloudKitError> = .success([])
  internal var modifyRecordsResult: Result<[RecordInfo], CloudKitError> = .success([])

  // MARK: - CloudKitRecordOperating

  internal func queryRecords(
    recordType: String,
    filters: [QueryFilter]?,
    sortBy: [QuerySort]?,
    limit: Int?,
    desiredKeys: [String]?
  ) async throws(CloudKitError) -> [RecordInfo] {
    queryCalls.append(
      QueryCall(
        recordType: recordType,
        filters: filters,
        sortBy: sortBy,
        limit: limit,
        desiredKeys: desiredKeys
      )
    )
    return try queryRecordsResult.get()
  }

  internal func modifyRecords(_ operations: [RecordOperation]) async throws(CloudKitError)
    -> [RecordInfo]
  {
    modifyCalls.append(ModifyCall(operations: operations))
    return try modifyRecordsResult.get()
  }
}
