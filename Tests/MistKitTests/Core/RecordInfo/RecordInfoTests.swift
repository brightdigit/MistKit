import Foundation
import Testing

@testable import MistKit

@Suite("Record Info")
/// Tests for RecordInfo functionality
struct RecordInfoTests {
  /// Tests RecordInfo initialization from Components.Schemas.Record
  @Test("RecordInfo initialization from Components.Schemas.Record")
  func recordInfoInitialization() {
    // Create a mock record with fields
    let mockRecord = Components.Schemas.Record(
      recordName: "test-record",
      recordType: "TestType",
      fields: Components.Schemas.Record.fieldsPayload(
        additionalProperties: [
          "name": Components.Schemas.FieldValue(stringValue: "Test Name"),
          "count": Components.Schemas.FieldValue(int64Value: 42),
        ]
      )
    )

    let recordInfo = RecordInfo(from: mockRecord)

    #expect(recordInfo.recordName == "test-record")
    #expect(recordInfo.recordType == "TestType")
    #expect(recordInfo.fields.count == 2)

    if case .string(let name) = recordInfo.fields["name"] {
      #expect(name == "Test Name")
    } else {
      Issue.record("Expected string value for 'name' field")
    }

    if case .int64(let count) = recordInfo.fields["count"] {
      #expect(count == 42)
    } else {
      Issue.record("Expected int64 value for 'count' field")
    }
  }

  /// Tests RecordInfo initialization with empty record data
  @Test("RecordInfo initialization with empty record data")
  func recordInfoWithUnknownRecord() {
    let mockRecord = Components.Schemas.Record()
    let recordInfo = RecordInfo(from: mockRecord)

    #expect(recordInfo.recordName == "Unknown")
    #expect(recordInfo.recordType == "Unknown")
    #expect(recordInfo.fields.isEmpty)
  }
}
