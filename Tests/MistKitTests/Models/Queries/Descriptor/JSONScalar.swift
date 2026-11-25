internal import Foundation

/// A JSON value as the query tests compare it.
internal enum JSONScalar: Decodable, Equatable {
  case number(Double)
  case string(String)
  case object([String: JSONScalar])
  case array([JSONScalar])
  case null

  internal init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let number = try? container.decode(Double.self) {
      self = .number(number)
    } else if let string = try? container.decode(String.self) {
      self = .string(string)
    } else if let array = try? container.decode([Self].self) {
      self = .array(array)
    } else {
      self = .object(try container.decode([String: Self].self))
    }
  }
}
