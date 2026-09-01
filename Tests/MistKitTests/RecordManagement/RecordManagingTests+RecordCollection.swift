//
//  RecordManagingTests+RecordCollection.swift
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
internal import Testing

@testable import MistKit

extension RecordManagingTests {
  @Suite("Record Collection Operations")
  internal struct RecordCollection {
    @Test("syncAllRecords batches each non-empty record type")
    internal func syncAllRecordsBatchesPerType() async throws {
      guard #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *) else {
        Issue.record("Record collection operations are not available on this operating system.")
        return
      }

      let service = MockCollectionRecordManagingService()
      let testRecords = [
        TestRecord(
          recordName: "test-1",
          name: "One",
          count: 1,
          isActive: true,
          score: nil,
          lastUpdated: nil
        ),
      ]
      let altRecords = [
        AltTestRecord(recordName: "alt-1", title: "Alt One"),
        AltTestRecord(recordName: "alt-2", title: "Alt Two"),
      ]

      try await service.syncAllRecords(testRecords, altRecords)

      let executeCount = await service.executeCallCount
      let batchSizes = await service.batchSizes
      let operations = await service.lastExecutedOperations

      #expect(executeCount == 2)
      #expect(batchSizes == [1, 2])
      #expect(operations.count == 3)
      #expect(operations.filter { $0.recordType == "TestRecord" }.count == 1)
      #expect(operations.filter { $0.recordType == "AltTestRecord" }.count == 2)
      #expect(operations.allSatisfy { $0.operationType == .forceReplace })
    }

    @Test("deleteAllRecords issues delete operations for every managed type")
    internal func deleteAllRecordsDeletesAcrossTypes() async throws {
      guard #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *) else {
        Issue.record("Record collection operations are not available on this operating system.")
        return
      }

      let service = MockCollectionRecordManagingService()
      await service.setRecords(
        [RecordInfo(recordName: "test-1", recordType: "TestRecord", fields: [:])],
        forRecordType: "TestRecord"
      )
      await service.setRecords(
        [RecordInfo(recordName: "alt-1", recordType: "AltTestRecord", fields: [:])],
        forRecordType: "AltTestRecord"
      )

      try await service.deleteAllRecords()

      let executeCount = await service.executeCallCount
      let operations = await service.lastExecutedOperations
      let queryCount = await service.queryCallCount

      #expect(queryCount == 2)
      #expect(executeCount == 2)
      #expect(operations.count == 2)
      #expect(operations.allSatisfy { $0.operationType == .delete })
    }

    @Test("listAllRecords queries every managed type")
    internal func listAllRecordsQueriesEveryType() async throws {
      guard #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *) else {
        Issue.record("Record collection operations are not available on this operating system.")
        return
      }

      let service = MockCollectionRecordManagingService()
      await service.setRecords(
        [RecordInfo(recordName: "test-1", recordType: "TestRecord", fields: [:])],
        forRecordType: "TestRecord"
      )

      try await service.listAllRecords()

      let queryCount = await service.queryCallCount
      #expect(queryCount == 2)
    }
  }
}
