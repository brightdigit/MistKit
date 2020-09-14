import Foundation

public struct MKAnyRecord: Codable {
  public let recordType: String
  public let recordName: UUID?
  public let recordChangeTag: String?
  public let fields: [String: MKValue]

  internal init(recordType: String, recordName: UUID) {
    self.recordType = recordType
    self.recordName = recordName
    recordChangeTag = nil
    fields = [String: MKValue]()
  }

  public init<RecordType: MKQueryRecord>(record: RecordType) {
    recordType = RecordType.recordType
    recordName = record.recordName
    recordChangeTag = record.recordChangeTag
    fields = record.fields
  }
}

public extension MKAnyRecord {
  func data(fromKey key: String) throws -> Data {
    switch fields[key] {
    case let .data(value):
      return value
    default:
      throw MKDecodingError.invalidKey(key)
    }
  }

  func string(fromKey key: String) throws -> String {
    switch fields[key] {
    case let .string(value):
      return value
    default:
      throw MKDecodingError.invalidKey(key)
    }
  }

  func integer(fromKey key: String) throws -> Int64 {
    switch fields[key] {
    case let .integer(value):
      return value
    default:
      throw MKDecodingError.invalidKey(key)
    }
  }
}
