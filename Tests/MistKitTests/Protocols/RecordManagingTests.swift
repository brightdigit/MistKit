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
  var queryCallCount = 0
  var executeCallCount = 0
  var lastExecutedOperations: [RecordOperation] = []
  var batchSizes: [Int] = []
  var recordsToReturn: [RecordInfo] = []

  func queryRecords(recordType: String) async throws -> [RecordInfo] {
    queryCallCount += 1
    return recordsToReturn
  }

  func executeBatchOperations(_ operations: [RecordOperation], recordType: String) async throws {
    executeCallCount += 1
    batchSizes.append(operations.count)
    lastExecutedOperations.append(contentsOf: operations)
  }

  func reset() {
    queryCallCount = 0
    executeCallCount = 0
    lastExecutedOperations = []
    batchSizes = []
    recordsToReturn = []
  }

  func setRecordsToReturn(_ records: [RecordInfo]) {
    recordsToReturn = records
  }
}

@Suite("RecordManaging Protocol")
/// Tests for RecordManaging protocol and its generic extensions
internal struct RecordManagingTests {
  @Test("sync() with small batch (<200 records)")
  internal func syncSmallBatch() async throws {
    let service = MockRecordManagingService()

    let records: [TestRecord] = (0..<50).map { index in
      TestRecord(
        recordName: "test-\(index)",
        name: "Record \(index)",
        count: index,
        isActive: true,
        score: nil,
        lastUpdated: nil
      )
    }

    try await service.sync(records)

    let executeCount = await service.executeCallCount
    let batchSizes = await service.batchSizes
    let lastOperations = await service.lastExecutedOperations

    #expect(executeCount == 1)  // Should be a single batch
    #expect(batchSizes == [50])
    #expect(lastOperations.count == 50)
    #expect(lastOperations.first?.recordName == "test-0")
    #expect(lastOperations.last?.recordName == "test-49")
  }

  @Test("sync() with large batch (>200 records) uses batching")
  internal func syncLargeBatchWithBatching() async throws {
    let service = MockRecordManagingService()

    // Create 450 records to test batching (should be split into 200, 200, 50)
    let records: [TestRecord] = (0..<450).map { index in
      TestRecord(
        recordName: "test-\(index)",
        name: "Record \(index)",
        count: index,
        isActive: true,
        score: nil,
        lastUpdated: nil
      )
    }

    try await service.sync(records)

    let executeCount = await service.executeCallCount
    let batchSizes = await service.batchSizes
    let lastOperations = await service.lastExecutedOperations

    #expect(executeCount == 3)  // Should be 3 batches
    #expect(batchSizes == [200, 200, 50])
    #expect(lastOperations.count == 450)
    #expect(lastOperations.first?.recordName == "test-0")
    #expect(lastOperations.last?.recordName == "test-449")
  }

  @Test("sync() operations have correct structure")
  internal func syncOperationsStructure() async throws {
    let service = MockRecordManagingService()

    let records = [
      TestRecord(
        recordName: "test-1",
        name: "First",
        count: 10,
        isActive: true,
        score: 95.5,
        lastUpdated: Date()
      )
    ]

    try await service.sync(records)

    let operations = await service.lastExecutedOperations

    #expect(operations.count == 1)

    let operation = operations[0]
    #expect(operation.recordType == "TestRecord")
    #expect(operation.recordName == "test-1")
    #expect(operation.operationType == .forceReplace)

    // Verify fields were converted correctly
    let fields = operation.fields
    #expect(fields["name"]?.stringValue == "First")
    #expect(fields["count"]?.intValue == 10)
    #expect(fields["isActive"]?.boolValue == true)
    #expect(fields["score"]?.doubleValue == 95.5)
  }

  @Test("query() returns parsed records")
  internal func queryReturnsParsedRecords() async throws {
    let service = MockRecordManagingService()

    // Set up mock data
    await service.reset()
    let mockRecords = [
      RecordInfo(
        recordName: "test-1",
        recordType: "TestRecord",
        fields: [
          "name": .string("First"),
          "count": .int64(10),
          "isActive": .from(true),
        ]
      ),
      RecordInfo(
        recordName: "test-2",
        recordType: "TestRecord",
        fields: [
          "name": .string("Second"),
          "count": .int64(20),
          "isActive": .from(false),
        ]
      ),
    ]
    await service.setRecordsToReturn(mockRecords)

    let results: [TestRecord] = try await service.query(TestRecord.self)

    #expect(results.count == 2)
    #expect(results[0].recordName == "test-1")
    #expect(results[0].name == "First")
    #expect(results[0].count == 10)
    #expect(results[1].recordName == "test-2")
    #expect(results[1].name == "Second")
    #expect(results[1].count == 20)

    let queryCount = await service.queryCallCount
    #expect(queryCount == 1)
  }

  @Test("query() with filter applies filtering")
  internal func queryWithFilter() async throws {
    let service = MockRecordManagingService()

    await service.reset()
    let mockRecords = [
      RecordInfo(
        recordName: "test-1",
        recordType: "TestRecord",
        fields: [
          "name": .string("Active"),
          "isActive": .from(true),
        ]
      ),
      RecordInfo(
        recordName: "test-2",
        recordType: "TestRecord",
        fields: [
          "name": .string("Inactive"),
          "isActive": .from(false),
        ]
      ),
      RecordInfo(
        recordName: "test-3",
        recordType: "TestRecord",
        fields: [
          "name": .string("Also Active"),
          "isActive": .from(true),
        ]
      ),
    ]
    await service.setRecordsToReturn(mockRecords)

    // Query only active records
    let results: [TestRecord] = try await service.query(TestRecord.self) { record in
      record.fields["isActive"]?.boolValue == true
    }

    #expect(results.count == 2)
    #expect(results[0].name == "Active")
    #expect(results[1].name == "Also Active")
    #expect(results.allSatisfy { $0.isActive })
  }

  @Test("query() filters out nil parse results")
  internal func queryFiltersOutInvalidRecords() async throws {
    let service = MockRecordManagingService()

    await service.reset()
    let mockRecords = [
      RecordInfo(
        recordName: "test-1",
        recordType: "TestRecord",
        fields: [
          "name": .string("Valid"),
          "isActive": .from(true),
        ]
      ),
      RecordInfo(
        recordName: "test-2",
        recordType: "TestRecord",
        fields: [
          // Missing required "name" and "isActive" fields
          "count": .int64(10)
        ]
      ),
      RecordInfo(
        recordName: "test-3",
        recordType: "TestRecord",
        fields: [
          "name": .string("Also Valid"),
          "isActive": .from(false),
        ]
      ),
    ]
    await service.setRecordsToReturn(mockRecords)

    let results: [TestRecord] = try await service.query(TestRecord.self)

    // Should only get 2 valid records (test-2 will fail to parse)
    #expect(results.count == 2)
    #expect(results[0].name == "Valid")
    #expect(results[1].name == "Also Valid")
  }

  @Test("sync() with empty array doesn't call executeBatchOperations")
  internal func syncWithEmptyArray() async throws {
    let service = MockRecordManagingService()

    let records: [TestRecord] = []
    try await service.sync(records)

    let executeCount = await service.executeCallCount
    #expect(executeCount == 0)
  }

  @Test("query() with no results returns empty array")
  internal func queryWithNoResults() async throws {
    let service = MockRecordManagingService()

    await service.reset()
    await service.setRecordsToReturn([])

    let results: [TestRecord] = try await service.query(TestRecord.self)

    #expect(results.isEmpty)

    let queryCount = await service.queryCallCount
    #expect(queryCount == 1)
  }

  @Test("list() calls queryRecords and doesn't throw")
  internal func listCallsQueryRecords() async throws {
    let service = MockRecordManagingService()

    await service.reset()
    let mockRecords = [
      RecordInfo(
        recordName: "test-1",
        recordType: "TestRecord",
        fields: [
          "name": .string("First"),
          "count": .int64(1),
          "isActive": .from(true),
        ]
      )
    ]
    await service.setRecordsToReturn(mockRecords)

    // list() outputs to console, so we just verify it doesn't throw
    try await service.list(TestRecord.self)

    let queryCount = await service.queryCallCount
    #expect(queryCount == 1)
  }

  @Test("Batch size calculation at boundary (exactly 200)")
  internal func syncExactly200Records() async throws {
    let service = MockRecordManagingService()

    let records: [TestRecord] = (0..<200).map { index in
      TestRecord(
        recordName: "test-\(index)",
        name: "Record \(index)",
        count: index,
        isActive: true,
        score: nil,
        lastUpdated: nil
      )
    }

    try await service.sync(records)

    let executeCount = await service.executeCallCount
    let batchSizes = await service.batchSizes

    #expect(executeCount == 1)  // Exactly 200 should be 1 batch
    #expect(batchSizes == [200])
  }

  @Test("Batch size calculation at boundary (201 records)")
  internal func sync201Records() async throws {
    let service = MockRecordManagingService()

    let records: [TestRecord] = (0..<201).map { index in
      TestRecord(
        recordName: "test-\(index)",
        name: "Record \(index)",
        count: index,
        isActive: true,
        score: nil,
        lastUpdated: nil
      )
    }

    try await service.sync(records)

    let executeCount = await service.executeCallCount
    let batchSizes = await service.batchSizes

    #expect(executeCount == 2)  // 201 should be 2 batches
    #expect(batchSizes == [200, 1])
  }
}
