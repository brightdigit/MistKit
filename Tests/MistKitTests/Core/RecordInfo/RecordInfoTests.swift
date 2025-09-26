import Foundation
import Testing

@testable import MistKit

@Suite("Record Info", .serialized)
/// Tests for RecordInfo functionality
internal struct RecordInfoTests {
  /// Tests RecordInfo initialization with empty record data
  @Test("RecordInfo initialization with empty record data")
  internal func recordInfoWithUnknownRecord() {
    let mockRecord = Components.Schemas.Record()
    let recordInfo = RecordInfo(from: mockRecord)

    #expect(recordInfo.recordName == "Unknown")
    #expect(recordInfo.recordType == "Unknown")
    #expect(recordInfo.fields.isEmpty)
  }
}
