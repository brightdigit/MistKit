public struct MKQuery<RecordType: MKQueryRecord>: MKQueryProtocol {
  public let recordType: String
  public let desiredKeys: [String]?

  enum CodingKeys: String, CodingKey {
    case recordType
  }

  public init(recordType: RecordType.Type) {
    self.recordType = recordType.recordType
    desiredKeys = recordType.desiredKeys
  }
}
