//
//  MockCloudKitService.swift
//  BushelCloud
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

// MARK: - Mock CloudKit Errors

internal enum MockCloudKitError: Error, Sendable {
  case authenticationFailed
  case accessDenied
  case quotaExceeded
  case validatingReferenceError
  case conflict
  case networkError
  case unknownError(String)
}

// MARK: - Mock CloudKit Service

/// Mock CloudKit service for testing without real CloudKit calls
internal actor MockCloudKitService: RecordManaging {
  // MARK: - Storage

  private var storedRecords: [String: [RecordInfo]] = [:]
  private var operationHistory: [[RecordOperation]] = []

  // MARK: - Configuration

  internal var shouldFailQuery: Bool = false
  internal var shouldFailModify: Bool = false
  internal var queryError: (any Error)?
  internal var modifyError: (any Error)?

  // MARK: - Inspection Methods

  internal func getStoredRecords(ofType recordType: String) -> [RecordInfo] {
    storedRecords[recordType] ?? []
  }

  internal func getOperationHistory() -> [[RecordOperation]] {
    operationHistory
  }

  internal func clearStorage() {
    storedRecords.removeAll()
    operationHistory.removeAll()
  }

  // MARK: - RecordManaging Protocol

  internal func queryRecords(recordType: String) async throws -> [RecordInfo] {
    if shouldFailQuery {
      throw queryError ?? MockCloudKitError.networkError
    }
    return storedRecords[recordType] ?? []
  }

  internal func executeBatchOperations(
    _ operations: [RecordOperation],
    recordType: String
  ) async throws {
    operationHistory.append(operations)

    if shouldFailModify {
      throw modifyError ?? MockCloudKitError.networkError
    }

    // Process operations
    for operation in operations {
      switch operation.operationType {
      case .create, .forceReplace:
        handleCreateOrReplace(operation, recordType: recordType)
      case .delete, .forceDelete:
        handleDelete(operation, recordType: recordType)
      case .update:
        handleUpdate(operation, recordType: recordType)
      case .forceUpdate:
        handleForceUpdate(operation, recordType: recordType)
      case .replace:
        handleReplace(operation, recordType: recordType)
      }
    }
  }

  // MARK: - Operation Handlers

  private func handleCreateOrReplace(_ operation: RecordOperation, recordType: String) {
    let recordInfo = createRecordInfo(from: operation)
    var records = storedRecords[recordType] ?? []

    // For forceReplace, remove existing record with same name
    if operation.operationType == .forceReplace {
      records.removeAll { $0.recordName == operation.recordName }
    }

    records.append(recordInfo)
    storedRecords[recordType] = records
  }

  private func handleDelete(_ operation: RecordOperation, recordType: String) {
    guard let recordName = operation.recordName else {
      return
    }
    storedRecords[recordType]?.removeAll { $0.recordName == recordName }
  }

  private func handleUpdate(_ operation: RecordOperation, recordType: String) {
    guard let recordName = operation.recordName,
      let index = storedRecords[recordType]?.firstIndex(where: { $0.recordName == recordName })
    else { return }

    let updatedRecordInfo = createRecordInfo(from: operation)
    storedRecords[recordType]?[index] = updatedRecordInfo
  }

  private func handleForceUpdate(_ operation: RecordOperation, recordType: String) {
    guard let recordName = operation.recordName else {
      return
    }
    let updatedRecordInfo = createRecordInfo(from: operation)

    if let index = storedRecords[recordType]?.firstIndex(where: { $0.recordName == recordName }) {
      storedRecords[recordType]?[index] = updatedRecordInfo
    } else {
      var records = storedRecords[recordType] ?? []
      records.append(updatedRecordInfo)
      storedRecords[recordType] = records
    }
  }

  private func handleReplace(_ operation: RecordOperation, recordType: String) {
    guard let recordName = operation.recordName,
      let index = storedRecords[recordType]?.firstIndex(where: { $0.recordName == recordName })
    else { return }

    let updatedRecordInfo = createRecordInfo(from: operation)
    storedRecords[recordType]?[index] = updatedRecordInfo
  }

  // MARK: - Helper Methods

  private func createRecordInfo(from operation: RecordOperation) -> RecordInfo {
    RecordInfo(
      recordName: operation.recordName ?? UUID().uuidString,
      recordType: operation.recordType,
      recordChangeTag: UUID().uuidString,
      fields: operation.fields
    )
  }
}
