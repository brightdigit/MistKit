import Foundation

public enum MKValue: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: MKValue.CodingKeys.self)

    let fieldType = try container.decode(MKFieldType.self, forKey: .type)

    switch fieldType {
    case .string:
      self = try .string(container.decode(String.self, forKey: .value))
    case .bytes:
      let base64Encoded = try container.decode(String.self, forKey: .value)
      guard let data = Data(base64Encoded: base64Encoded) else {
        throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid Base64 String.")
      }
      self = .data(data)
    case .integer:
      do {
        let integer = try container.decode(Int64.self, forKey: .value)
        self = .integer(integer)
      } catch {
        let string = try container.decode(String.self, forKey: .value)
        guard let integer = Int64(string) else {
          throw error
        }
        self = .integer(integer)
      }
    }
  }

  enum CodingKeys: String, CodingKey {
    case value
    case type
  }

  case string(String)
  case integer(Int64)
  case data(Data)
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: MKValue.CodingKeys.self)
    switch self {
    case let .string(string):
      try container.encode(string, forKey: .value)
      try container.encode(MKFieldType.string, forKey: .type)
    case let .integer(integer):
      try container.encode(integer, forKey: .value)
      try container.encode(MKFieldType.integer, forKey: .type)
    case let .data(data):
      try container.encode(data.base64EncodedData(), forKey: .value)
      try container.encode(MKFieldType.bytes, forKey: .type)
    }
  }
}
