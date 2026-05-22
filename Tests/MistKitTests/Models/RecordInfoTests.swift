internal import Foundation
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

@Suite("Record Info")
/// Tests for RecordInfo functionality
internal struct RecordInfoTests {
  /// A response with no `recordName` is a conversion failure, not an "Unknown"
  /// record. The assertion handler is suppressed so the throw is observable in
  /// DEBUG instead of trapping the test process.
  @Test("RecordInfo throws when the response is missing its recordName")
  internal func recordInfoMissingIdentifiersThrows() {
    let mockRecord = Components.Schemas.RecordResponse()
    ConversionFailureReporter.$assertionHandler.withValue(
      { _, _, _ in },
      operation: {
        #expect(throws: ConversionError.self) {
          _ = try RecordInfo(from: mockRecord)
        }
      }
    )
  }

  /// A well-formed response converts to a RecordInfo with its identifiers.
  @Test("RecordInfo converts a well-formed response")
  internal func recordInfoFromValidRecord() throws {
    let mockRecord = Components.Schemas.RecordResponse(
      recordName: "rec-1",
      recordType: "Article"
    )
    let recordInfo = try RecordInfo(from: mockRecord)

    #expect(recordInfo.recordName == "rec-1")
    #expect(recordInfo.recordType == "Article")
    #expect(recordInfo.fields.isEmpty)
  }

  /// CloudKit omits `recordType` for tombstones (deleted records) and other
  /// typeless responses. Such a record must convert to a `RecordInfo` with a
  /// `nil` recordType rather than trapping — this is the regression that crashed
  /// the delete/cleanup and `fetchRecordChanges` paths.
  @Test("RecordInfo converts a typeless (deleted) response without a recordType")
  internal func recordInfoFromTypelessRecord() throws {
    let mockRecord = Components.Schemas.RecordResponse(
      recordName: "rec-deleted",
      deleted: true
    )
    let recordInfo = try RecordInfo(from: mockRecord)

    #expect(recordInfo.recordName == "rec-deleted")
    #expect(recordInfo.recordType == nil)
    #expect(recordInfo.deleted)
  }
}
