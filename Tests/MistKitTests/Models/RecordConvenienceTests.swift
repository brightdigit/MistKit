internal import Foundation
internal import MistKit
internal import Testing

@Suite("Record conveniences")
/// Tests `RecordInfo+Copying`, `RecordOperation+Saving`, `OperationResult.recordName`,
/// `CloudKitError+ModifyIncomplete`, `Database+Scope` and query errors' `fieldName`.
internal struct RecordConvenienceTests {
  private let record = RecordInfo(
    recordName: "n1",
    recordType: "Note",
    recordChangeTag: "t1",
    fields: ["title": .string(.value("Hi"))]
  )

  @Test("replacing keeps what it isn't given; zoneOrDefault fills a missing zone")
  internal func replacing() {
    let copy = record.replacing(recordChangeTag: "t2", fields: [:])
    #expect(copy.recordName == "n1")
    #expect(copy.recordType == "Note")
    #expect(copy.recordChangeTag == "t2")
    #expect(copy.fields.isEmpty)
    #expect(record.zoneOrDefault == .defaultZone)
    #expect(record.replacing(zoneID: ZoneID(zoneName: "Z")).zoneOrDefault == ZoneID(zoneName: "Z"))
  }

  @Test("saving is an update with a change tag and a create without one")
  internal func saving() {
    let update = RecordOperation.saving(record)
    #expect(update.operationType == .update)
    #expect(update.recordChangeTag == "t1")
    #expect(update.fields == record.fields)
    let create = RecordOperation.saving(
      RecordInfo(recordName: "n2", recordType: nil, fields: [:])
    )
    #expect(create.operationType == .create)
    #expect(create.recordType.isEmpty)
  }

  @Test("a result names its record, saved or failed")
  internal func resultRecordName() {
    #expect(RecordResult.success(record).recordName == "n1")
    let failure = RecordOperationFailure(identifier: "n2", serverErrorCode: .conflict)
    #expect(RecordResult.failure(failure).recordName == "n2")
  }

  @Test("modifyIncomplete exposes its completed results and unsent operations")
  internal func modifyIncomplete() {
    let unsent = [ZonedRecordOperation(.saving(record))]
    let error = CloudKitError.modifyIncomplete(
      completed: [.success(record)],
      unsent: unsent,
      underlying: .invalidResponse
    )
    #expect(error.completedResults.map(\.recordName) == ["n1"])
    #expect(error.unsentOperations.map(\.operation.recordName) == ["n1"])
    #expect(CloudKitError.invalidResponse.completedResults.isEmpty)
    #expect(CloudKitError.invalidResponse.unsentOperations.isEmpty)
  }

  @Test("a database scope codes as its path segment and round-trips")
  internal func databaseScope() throws {
    for scope in Database.Scope.allCases {
      let database = Database(scope, publicAuthentication: .prefers(.serverToServer))
      #expect(database.scope == scope)
      #expect(database.pathSegment == scope.rawValue)
    }
    let data = try JSONEncoder().encode([Database.Scope.private])
    #expect(String(decoding: data, as: UTF8.self) == #"["private"]"#)
  }

  @Test("query errors name their field")
  internal func queryErrorFieldName() {
    #expect(QueryDescriptorError.unsupportedValue(fieldName: "a").fieldName == "a")
    #expect(
      QueryDescriptorError.valueMismatch(fieldName: "b", comparator: .equals).fieldName == "b"
    )
    #expect(QueryPredicateFormatError.unrepresentableValue(fieldName: "c").fieldName == "c")
    #expect(
      QueryPredicateFormatError.unrepresentableComparator(fieldName: "d", comparator: .equals)
        .fieldName == "d"
    )
  }
}
