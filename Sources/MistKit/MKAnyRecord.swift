import Foundation

public struct MKAnyRecord: Codable {
  public let recordType: String
  public let recordName: UUID
  public let recordChangeTag: String
  public let fields: [String: MKField]
}

public extension MKAnyRecord {
  func uuid(fromKey key: String) throws -> UUID {
    let value = try string(fromKey: key)

    guard let uuid = Data(base64Encoded: value).flatMap(UUID.init(data:)) else {
      throw MKDecodingError.invalidData(value)
    }

    return uuid
  }

  func string(fromKey key: String) throws -> String {
    guard let field = fields[key] else {
      throw MKDecodingError.missingKey(key)
    }

    return field.value
  }

  func integer(fromKey key: String) throws -> Int {
    let value = try string(fromKey: key)

    guard let integer = Int(value) else {
      throw MKDecodingError.invalidData(value)
    }

    return integer
  }
}
