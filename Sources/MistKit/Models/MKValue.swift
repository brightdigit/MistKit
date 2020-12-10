import Foundation

public enum MKValue: Codable, Equatable {
  case string(String)
  case integer(Int64)
  case data(Data)
  case date(Date)
  case double(Double)
  case location(MKLocation)
  case asset(MKAsset)

  public enum CodingKeys: String, CodingKey {
    case value
    case type
  }

  // swiftlint:disable:next function_body_length cyclomatic_complexity
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: MKValue.CodingKeys.self)

    let fieldType = try container.decode(MKFieldType.self, forKey: .type)

    switch fieldType {
    case .string:
      self = try .string(container.decode(String.self, forKey: .value))

    case .bytes:
      let base64Encoded = try container.decode(String.self, forKey: .value)
      guard let data = Data(base64Encoded: base64Encoded) else {
        throw DecodingError.dataCorruptedError(
          forKey: .value,
          in: container,
          debugDescription: "Invalid Base64 String."
        )
      }
      self = .data(data)

    case .integer:

      let integer: Int64
      do {
        integer = try container.decode(Int64.self, forKey: .value)
      } catch {
        let string = try container.decode(String.self, forKey: .value)
        guard let intstr = Int64(string) else {
          throw error
        }
        integer = intstr
      }
      self = .integer(integer)

    case .timestamp:
      let integer: Int64
      do {
        integer = try container.decode(Int64.self, forKey: .value)
      } catch {
        let string = try container.decode(String.self, forKey: .value)
        guard let intstr = Int64(string) else {
          throw error
        }
        integer = intstr
      }
      let millisecondsSince = TimeInterval(integer)
      self = .date(Date(timeIntervalSince1970: millisecondsSince / 1_000.0))

    case .double:
      let double: Double
      do {
        double = try container.decode(Double.self, forKey: .value)
      } catch {
        let string = try container.decode(String.self, forKey: .value)
        guard let strdbl = Double(string) else {
          throw error
        }
        double = strdbl
      }
      self = .double(double)

    case .location:
      let location = try container.decode(MKLocation.self, forKey: .value)
      self = .location(location)

    case .asset:
      let asset = try container.decode(MKAsset.self, forKey: .value)
      self = .asset(asset)
    }
  }

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

    case let .date(date):
      try container.encode(Int64(date.timeIntervalSince1970 * 1_000.0), forKey: .value)
      try container.encode(MKFieldType.timestamp, forKey: .type)

    case let .double(double):
      try container.encode(double, forKey: .value)
      try container.encode(MKFieldType.double, forKey: .type)

    case let .location(location):
      try container.encode(location, forKey: .value)
      try container.encode(MKFieldType.location, forKey: .type)

    case let .asset(asset):
      try container.encode(asset, forKey: .value)
      try container.encode(MKFieldType.asset, forKey: .type)
    }
  }
}
