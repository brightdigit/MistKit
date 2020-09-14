import Foundation

public enum ModifiedRecord: Decodable {
  enum CodingKeys: String, CodingKey {
    case deleted
    case recordName
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    guard try container.decode(Bool.self, forKey: .deleted) else {
      self = try .updated(MKAnyRecord(from: decoder))
      return
    }

    let recordNameString = try container.decode(String.self, forKey: .recordName)

    guard let recordName = UUID(uuidString: recordNameString) else {
      throw DecodingError.dataCorruptedError(forKey: .recordName, in: container, debugDescription: "Invalid Record Name")
    }

    self = .deleted(recordName)
  }

  case deleted(UUID)
  case updated(MKAnyRecord)
}
