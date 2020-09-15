import Foundation

public struct LookupRecordQuery<RecordType: MKQueryRecord>: MKEncodable {
  public let records: [LookupRecord]
  public let desiredKeys: [String]?
  public let numbersAsStrings: Bool = true

  public init(_: RecordType.Type, recordNames: [UUID]) {
    records = recordNames.map(LookupRecord.init(recordName:))
    desiredKeys = RecordType.desiredKeys
  }
}
