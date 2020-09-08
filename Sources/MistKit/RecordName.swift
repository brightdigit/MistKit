import Foundation

public struct RecordName: Decodable {
  public let uuid: UUID
  public init(from decoder: Decoder) throws {
    let uuidString = try decoder.singleValueContainer().decode(String.self)
    guard let uuid = RecordNameParser.uuid(fromRecordName: uuidString) else {
      throw MKError.invalidRecordName(uuidString)
    }
    self.uuid = uuid
  }
}
