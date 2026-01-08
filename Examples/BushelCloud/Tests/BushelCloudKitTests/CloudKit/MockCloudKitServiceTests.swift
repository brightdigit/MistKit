//
//  MockCloudKitServiceTests.swift
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

import BushelFoundation
import Foundation
import MistKit
import Testing

@testable import BushelCloudKit

// MARK: - Mock CloudKit Service Tests

@Suite("Mock CloudKit Service Tests")
internal struct MockCloudKitServiceTests {
  @Test("Query returns empty array initially")
  internal func testQueryEmptyInitially() async throws {
    let service = MockCloudKitService()

    let results = try await service.queryRecords(recordType: "RestoreImage")

    #expect(results.isEmpty)
  }

  @Test("Create operation stores record")
  internal func testCreateOperationStoresRecord() async throws {
    let service = MockCloudKitService()
    let record = TestFixtures.sonoma1421

    let operation = RecordOperation(
      operationType: .create,
      recordType: "RestoreImage",
      recordName: "RestoreImage-\(record.buildNumber)",
      fields: record.toCloudKitFields()
    )

    try await service.executeBatchOperations([operation], recordType: "RestoreImage")

    let storedRecords = await service.getStoredRecords(ofType: "RestoreImage")
    #expect(storedRecords.count == 1)
    #expect(storedRecords[0].recordName == "RestoreImage-23C71")
  }

  @Test("ForceReplace operation replaces existing record")
  internal func testForceReplaceOperation() async throws {
    let service = MockCloudKitService()
    let recordName = "RestoreImage-23C71"

    // Create initial record
    let initialRecord = TestFixtures.sonoma1421
    let createOp = RecordOperation(
      operationType: .create,
      recordType: "RestoreImage",
      recordName: recordName,
      fields: initialRecord.toCloudKitFields()
    )
    try await service.executeBatchOperations([createOp], recordType: "RestoreImage")

    // Replace with updated record
    let updatedRecord = RestoreImageRecord(
      version: "14.2.1 Updated",
      buildNumber: "23C71",
      releaseDate: initialRecord.releaseDate,
      downloadURL: initialRecord.downloadURL,
      fileSize: 99_999,
      sha256Hash: initialRecord.sha256Hash,
      sha1Hash: initialRecord.sha1Hash,
      isSigned: false,
      isPrerelease: false,
      source: "updated-source",
      notes: "Updated record",
      sourceUpdatedAt: nil
    )

    let replaceOp = RecordOperation(
      operationType: .forceReplace,
      recordType: "RestoreImage",
      recordName: recordName,
      fields: updatedRecord.toCloudKitFields()
    )
    try await service.executeBatchOperations([replaceOp], recordType: "RestoreImage")

    // Verify only one record exists with updated data
    let storedRecords = await service.getStoredRecords(ofType: "RestoreImage")
    #expect(storedRecords.count == 1)

    let storedFields = storedRecords[0].fields
    if case .int64(let fileSize) = storedFields["fileSize"] {
      #expect(fileSize == 99_999)
    } else {
      Issue.record("fileSize field not found or wrong type")
    }
  }

  @Test("Delete operation removes record")
  internal func testDeleteOperation() async throws {
    let service = MockCloudKitService()
    let recordName = "RestoreImage-23C71"

    // Create record
    let record = TestFixtures.sonoma1421
    let createOp = RecordOperation(
      operationType: .create,
      recordType: "RestoreImage",
      recordName: recordName,
      fields: record.toCloudKitFields()
    )
    try await service.executeBatchOperations([createOp], recordType: "RestoreImage")

    // Delete record
    let deleteOp = RecordOperation(
      operationType: .delete,
      recordType: "RestoreImage",
      recordName: recordName
    )
    try await service.executeBatchOperations([deleteOp], recordType: "RestoreImage")

    // Verify record is gone
    let storedRecords = await service.getStoredRecords(ofType: "RestoreImage")
    #expect(storedRecords.isEmpty)
  }

  @Test("Batch operations process multiple records")
  internal func testBatchOperations() async throws {
    let service = MockCloudKitService()

    let operations = [
      RecordOperation(
        operationType: .create,
        recordType: "RestoreImage",
        recordName: "RestoreImage-23C71",
        fields: TestFixtures.sonoma1421.toCloudKitFields()
      ),
      RecordOperation(
        operationType: .create,
        recordType: "RestoreImage",
        recordName: "RestoreImage-24A5264n",
        fields: TestFixtures.sequoia150Beta.toCloudKitFields()
      ),
      RecordOperation(
        operationType: .create,
        recordType: "XcodeVersion",
        recordName: "XcodeVersion-15C65",
        fields: TestFixtures.xcode151.toCloudKitFields()
      ),
    ]

    try await service.executeBatchOperations(
      Array(operations[0...1]),
      recordType: "RestoreImage"
    )
    try await service.executeBatchOperations([operations[2]], recordType: "XcodeVersion")

    let restoreImages = await service.getStoredRecords(ofType: "RestoreImage")
    let xcodeVersions = await service.getStoredRecords(ofType: "XcodeVersion")

    #expect(restoreImages.count == 2)
    #expect(xcodeVersions.count == 1)
  }

  @Test("Query error throws expected error")
  internal func testQueryError() async {
    let service = MockCloudKitService()
    await service.setShouldFailQuery(true)
    await service.setQueryError(MockCloudKitError.networkError)

    do {
      _ = try await service.queryRecords(recordType: "RestoreImage")
      Issue.record("Expected error to be thrown")
    } catch is MockCloudKitError {
      // Success - error was thrown as expected
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Modify error throws expected error")
  internal func testModifyError() async {
    let service = MockCloudKitService()
    await service.setShouldFailModify(true)
    await service.setModifyError(MockCloudKitError.authenticationFailed)

    let operation = RecordOperation(
      operationType: .create,
      recordType: "RestoreImage",
      recordName: "test",
      fields: TestFixtures.sonoma1421.toCloudKitFields()
    )

    do {
      try await service.executeBatchOperations([operation], recordType: "RestoreImage")
      Issue.record("Expected error to be thrown")
    } catch is MockCloudKitError {
      // Success - error was thrown as expected
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Operation history tracks all operations")
  internal func testOperationHistory() async throws {
    let service = MockCloudKitService()

    let batch1 = [
      RecordOperation(
        operationType: .create,
        recordType: "RestoreImage",
        recordName: "test1",
        fields: TestFixtures.sonoma1421.toCloudKitFields()
      )
    ]

    let batch2 = [
      RecordOperation(
        operationType: .create,
        recordType: "XcodeVersion",
        recordName: "test2",
        fields: TestFixtures.xcode151.toCloudKitFields()
      )
    ]

    try await service.executeBatchOperations(batch1, recordType: "RestoreImage")
    try await service.executeBatchOperations(batch2, recordType: "XcodeVersion")

    let history = await service.getOperationHistory()
    #expect(history.count == 2)
    #expect(history[0].count == 1)
    #expect(history[1].count == 1)
  }

  @Test("Clear storage removes all records")
  internal func testClearStorage() async throws {
    let service = MockCloudKitService()

    // Add some records
    let operation = RecordOperation(
      operationType: .create,
      recordType: "RestoreImage",
      recordName: "test",
      fields: TestFixtures.sonoma1421.toCloudKitFields()
    )
    try await service.executeBatchOperations([operation], recordType: "RestoreImage")

    // Clear storage
    await service.clearStorage()

    // Verify everything is cleared
    let storedRecords = await service.getStoredRecords(ofType: "RestoreImage")
    let history = await service.getOperationHistory()

    #expect(storedRecords.isEmpty)
    #expect(history.isEmpty)
  }
}

// MARK: - Helper Extensions for Actor

extension MockCloudKitService {
  internal func setShouldFailQuery(_ value: Bool) {
    self.shouldFailQuery = value
  }

  internal func setShouldFailModify(_ value: Bool) {
    self.shouldFailModify = value
  }

  internal func setQueryError(_ error: (any Error)?) {
    self.queryError = error
  }

  internal func setModifyError(_ error: (any Error)?) {
    self.modifyError = error
  }
}
