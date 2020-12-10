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

  func dateIfExists(fromKey key: String) throws -> Date? {
    switch fields[key] {
    case let .date(value):
      return value

    case .none:
      return nil

    default:
      throw MKDecodingError.invalidKey(key)
    }
  }
}

public extension Array where Element == MKAnyRecord {
  var information: String {
    let header = "\(count) results"
    let items = [header] + map { $0.information }
    let minlength = items.map {
      $0.components(separatedBy: .newlines)
        .map { $0.count }
        .max()
    }
    .compactMap { $0 }
    .max() ?? 0
    let separator = String(repeating: "=", count: minlength + 3)
    return items.joined(separator: "\n\(separator)\n")
  }
}

public extension MKAnyRecord {
  var information: String {
    let fieldString = fields.map {
      "  \($0.key): \($0.value)"
    }
    .joined(separator: "\n")

    return """
    recordName: \(recordName?.uuidString ?? "")
    recordChangeTag: \(recordChangeTag ?? "")
    fields:
    \(fieldString)
    """
  }
}
