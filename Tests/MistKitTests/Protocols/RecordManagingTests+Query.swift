//
//  RecordManagingTests+Query.swift
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

extension RecordManagingTests {
  @Suite("Query Operations")
  internal struct Query {
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
            "isActive": FieldValue(booleanValue: true),
          ]
        ),
        RecordInfo(
          recordName: "test-2",
          recordType: "TestRecord",
          fields: [
            "name": .string("Second"),
            "count": .int64(20),
            "isActive": FieldValue(booleanValue: false),
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
            "isActive": FieldValue(booleanValue: true),
          ]
        ),
        RecordInfo(
          recordName: "test-2",
          recordType: "TestRecord",
          fields: [
            "name": .string("Inactive"),
            "isActive": FieldValue(booleanValue: false),
          ]
        ),
        RecordInfo(
          recordName: "test-3",
          recordType: "TestRecord",
          fields: [
            "name": .string("Also Active"),
            "isActive": FieldValue(booleanValue: true),
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
            "isActive": FieldValue(booleanValue: true),
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
            "isActive": FieldValue(booleanValue: false),
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
  }
}
