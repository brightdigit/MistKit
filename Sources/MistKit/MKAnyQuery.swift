public struct MKAnyQuery: MKQueryProtocol {
  public let recordType: String
  public let desiredKeys: [String]?

  enum CodingKeys: String, CodingKey {
    case recordType
  }

  public init(recordType: String, desiredKeys: [String]? = nil) {
    self.recordType = recordType
    self.desiredKeys = desiredKeys
  }
}
