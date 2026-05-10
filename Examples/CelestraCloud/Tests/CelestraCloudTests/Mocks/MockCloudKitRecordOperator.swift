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
import Synchronization

@testable import CelestraCloudKit

/// Mock implementation of CloudKitRecordOperating for testing.
///
/// Thread-safe under Swift Testing's default parallel test execution: all
/// mutable state is guarded by an internal `Mutex` from the Synchronization
/// module, so concurrent suites can drive the same mock or per-test mocks
/// without data races. Test sites use the same property syntax as before.
internal final class MockCloudKitRecordOperator: CloudKitRecordOperating, Sendable {
  // MARK: - Subtypes

  internal struct QueryCall: Sendable {
    internal let recordType: String
    internal let filters: [QueryFilter]?
    internal let sortBy: [QuerySort]?
    internal let limit: Int?
    internal let desiredKeys: [String]?
  }

  internal struct ModifyCall: Sendable {
    internal let operations: [RecordOperation]
  }

  private struct State {
    var queryCalls: [QueryCall] = []
    var modifyCalls: [ModifyCall] = []
    var queryRecordsResult: Result<[RecordInfo], CloudKitError> = .success([])
    var modifyRecordsResult: Result<[RecordInfo], CloudKitError> = .success([])
  }

  // MARK: - Properties

  private let state = Mutex(State())

  internal var queryCalls: [QueryCall] {
    state.withLock { $0.queryCalls }
  }

  internal var modifyCalls: [ModifyCall] {
    state.withLock { $0.modifyCalls }
  }

  internal var queryRecordsResult: Result<[RecordInfo], CloudKitError> {
    get { state.withLock { $0.queryRecordsResult } }
    set { state.withLock { $0.queryRecordsResult = newValue } }
  }

  internal var modifyRecordsResult: Result<[RecordInfo], CloudKitError> {
    get { state.withLock { $0.modifyRecordsResult } }
    set { state.withLock { $0.modifyRecordsResult = newValue } }
  }

  // MARK: - CloudKitRecordOperating

  internal func queryRecords(
    recordType: String,
    filters: [QueryFilter]?,
    sortBy: [QuerySort]?,
    limit: Int?,
    desiredKeys: [String]?
  ) async throws(CloudKitError) -> [RecordInfo] {
    let result = state.withLock { state -> Result<[RecordInfo], CloudKitError> in
      state.queryCalls.append(
        QueryCall(
          recordType: recordType,
          filters: filters,
          sortBy: sortBy,
          limit: limit,
          desiredKeys: desiredKeys
        )
      )
      return state.queryRecordsResult
    }
    return try result.get()
  }

  internal func modifyRecords(_ operations: [RecordOperation]) async throws(CloudKitError)
    -> [RecordInfo]
  {
    let result = state.withLock { state -> Result<[RecordInfo], CloudKitError> in
      state.modifyCalls.append(ModifyCall(operations: operations))
      return state.modifyRecordsResult
    }
    return try result.get()
  }

  internal func queryAllRecords(
    recordType: String,
    filters: [QueryFilter]?,
    sortBy: [QuerySort]?,
    pageSize: Int?,
    desiredKeys: [String]?,
    maxPages: Int
  ) async throws(CloudKitError) -> [RecordInfo] {
    let result = state.withLock { state -> Result<[RecordInfo], CloudKitError> in
      state.queryCalls.append(
        QueryCall(
          recordType: recordType,
          filters: filters,
          sortBy: sortBy,
          limit: pageSize,
          desiredKeys: desiredKeys
        )
      )
      return state.queryRecordsResult
    }
    return try result.get()
  }
}
