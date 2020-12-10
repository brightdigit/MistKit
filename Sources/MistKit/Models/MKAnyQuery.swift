public struct MKAnyQuery: MKQueryProtocol {
  public enum CodingKeys: String, CodingKey {
    case recordType
  }

  public let recordType: String
  public let desiredKeys: [String]?

  public init(recordType: String, desiredKeys: [String]? = nil) {
    self.recordType = recordType
    self.desiredKeys = desiredKeys
  }
}
