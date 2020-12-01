import Foundation

public struct ModifiedRecordQueryContent<EncodedType: Codable>: Codable {
  public let deleted: [UUID]
  public let updated: [EncodedType]

  public init<RecordType: MKContentRecord>(from result: ModifiedRecordQueryResult<RecordType>) where RecordType.ContentType == EncodedType {
    deleted = result.deleted
    updated = result.updated.map(RecordType.content(fromRecord:))
  }
}
