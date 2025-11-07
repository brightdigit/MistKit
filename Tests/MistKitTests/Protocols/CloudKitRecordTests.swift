//
//  CloudKitRecordTests.swift
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

/// Test record conforming to CloudKitRecord for testing purposes
internal struct TestRecord: CloudKitRecord {
  static var cloudKitRecordType: String { "TestRecord" }

  var recordName: String
  var name: String
  var count: Int
  var isActive: Bool
  var score: Double?
  var lastUpdated: Date?

  func toCloudKitFields() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "name": .string(name),
      "count": .int64(count),
      "isActive": .boolean(isActive),
    ]

    if let score {
      fields["score"] = .double(score)
    }

    if let lastUpdated {
      fields["lastUpdated"] = .date(lastUpdated)
    }

    return fields
  }

  static func from(recordInfo: RecordInfo) -> TestRecord? {
    guard
      let name = recordInfo.fields["name"]?.stringValue,
      let isActive = recordInfo.fields["isActive"]?.boolValue
    else {
      return nil
    }

    let count = recordInfo.fields["count"]?.intValue ?? 0
    let score = recordInfo.fields["score"]?.doubleValue
    let lastUpdated = recordInfo.fields["lastUpdated"]?.dateValue

    return TestRecord(
      recordName: recordInfo.recordName,
      name: name,
      count: count,
      isActive: isActive,
      score: score,
      lastUpdated: lastUpdated
    )
  }

  static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let name = recordInfo.fields["name"]?.stringValue ?? "Unknown"
    let count = recordInfo.fields["count"]?.intValue ?? 0
    return "  \(recordInfo.recordName): \(name) (count: \(count))"
  }
}

@Suite("CloudKitRecord Protocol")
/// Tests for CloudKitRecord protocol conformance
internal struct CloudKitRecordTests {
  @Test("CloudKitRecord provides correct record type")
  internal func recordTypeProperty() {
    #expect(TestRecord.cloudKitRecordType == "TestRecord")
  }

  @Test("toCloudKitFields converts required fields correctly")
  internal func toCloudKitFieldsBasic() {
    let record = TestRecord(
      recordName: "test-1",
      name: "Test Record",
      count: 42,
      isActive: true,
      score: nil,
      lastUpdated: nil
    )

    let fields = record.toCloudKitFields()

    #expect(fields["name"]?.stringValue == "Test Record")
    #expect(fields["count"]?.intValue == 42)
    #expect(fields["isActive"]?.boolValue == true)
    #expect(fields["score"] == nil)
    #expect(fields["lastUpdated"] == nil)
  }

  @Test("toCloudKitFields includes optional fields when present")
  internal func toCloudKitFieldsWithOptionals() {
    let date = Date()
    let record = TestRecord(
      recordName: "test-2",
      name: "Test Record",
      count: 10,
      isActive: false,
      score: 98.5,
      lastUpdated: date
    )

    let fields = record.toCloudKitFields()

    #expect(fields["name"]?.stringValue == "Test Record")
    #expect(fields["count"]?.intValue == 10)
    #expect(fields["isActive"]?.boolValue == false)
    #expect(fields["score"]?.doubleValue == 98.5)
    #expect(fields["lastUpdated"]?.dateValue == date)
  }

  @Test("from(recordInfo:) parses valid record successfully")
  internal func fromRecordInfoSuccess() {
    let recordInfo = RecordInfo(
      recordName: "test-3",
      recordType: "TestRecord",
      fields: [
        "name": .string("Parsed Record"),
        "count": .int64(25),
        "isActive": .boolean(true),
        "score": .double(75.0),
      ]
    )

    let record = TestRecord.from(recordInfo: recordInfo)

    #expect(record?.recordName == "test-3")
    #expect(record?.name == "Parsed Record")
    #expect(record?.count == 25)
    #expect(record?.isActive == true)
    #expect(record?.score == 75.0)
  }

  @Test("from(recordInfo:) handles missing optional fields")
  internal func fromRecordInfoWithMissingOptionals() {
    let recordInfo = RecordInfo(
      recordName: "test-4",
      recordType: "TestRecord",
      fields: [
        "name": .string("Minimal Record"),
        "isActive": .boolean(false),
      ]
    )

    let record = TestRecord.from(recordInfo: recordInfo)

    #expect(record?.recordName == "test-4")
    #expect(record?.name == "Minimal Record")
    #expect(record?.isEmpty)  // Default value
    #expect(record?.isActive == false)
    #expect(record?.score == nil)
    #expect(record?.lastUpdated == nil)
  }

  @Test("from(recordInfo:) returns nil when required fields missing")
  internal func fromRecordInfoMissingRequiredFields() {
    let recordInfo = RecordInfo(
      recordName: "test-5",
      recordType: "TestRecord",
      fields: [
        "count": .int64(10)
        // Missing required "name" and "isActive" fields
      ]
    )

    let record = TestRecord.from(recordInfo: recordInfo)
    #expect(record == nil)
  }

  @Test("from(recordInfo:) handles legacy int64 boolean encoding")
  internal func fromRecordInfoWithLegacyBooleans() {
    let recordInfo = RecordInfo(
      recordName: "test-6",
      recordType: "TestRecord",
      fields: [
        "name": .string("Legacy Record"),
        "isActive": .int64(1),  // Legacy boolean as int64
      ]
    )

    let record = TestRecord.from(recordInfo: recordInfo)

    #expect(record?.isActive == true)
  }

  @Test("formatForDisplay generates expected output")
  internal func formatForDisplay() {
    let recordInfo = RecordInfo(
      recordName: "test-7",
      recordType: "TestRecord",
      fields: [
        "name": .string("Display Record"),
        "count": .int64(99),
      ]
    )

    let formatted = TestRecord.formatForDisplay(recordInfo)
    #expect(formatted.contains("test-7"))
    #expect(formatted.contains("Display Record"))
    #expect(formatted.contains("99"))
  }

  @Test("Round-trip: record -> fields -> record")
  internal func roundTripConversion() {
    let original = TestRecord(
      recordName: "test-8",
      name: "Round Trip",
      count: 50,
      isActive: true,
      score: 88.8,
      lastUpdated: Date()
    )

    let fields = original.toCloudKitFields()
    let recordInfo = RecordInfo(
      recordName: original.recordName,
      recordType: TestRecord.cloudKitRecordType,
      fields: fields
    )

    let reconstructed = TestRecord.from(recordInfo: recordInfo)

    #expect(reconstructed?.recordName == original.recordName)
    #expect(reconstructed?.name == original.name)
    #expect(reconstructed?.count == original.count)
    #expect(reconstructed?.isActive == original.isActive)
    #expect(reconstructed?.score == original.score)
  }

  @Test("CloudKitRecord conforms to Codable")
  internal func codableConformance() throws {
    let record = TestRecord(
      recordName: "test-9",
      name: "Codable Test",
      count: 123,
      isActive: true,
      score: 99.9,
      lastUpdated: Date()
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(record)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(TestRecord.self, from: data)

    #expect(decoded.recordName == record.recordName)
    #expect(decoded.name == record.name)
    #expect(decoded.count == record.count)
    #expect(decoded.isActive == record.isActive)
  }

  @Test("CloudKitRecord conforms to Sendable")
  internal func sendableConformance() async {
    let record = TestRecord(
      recordName: "test-10",
      name: "Sendable Test",
      count: 1,
      isActive: true,
      score: nil,
      lastUpdated: nil
    )

    // This test verifies that TestRecord (CloudKitRecord) is Sendable
    // by being able to pass it across async/await boundaries
    let task = Task {
      record.name
    }

    let name = await task.value
    #expect(name == "Sendable Test")
  }
}
