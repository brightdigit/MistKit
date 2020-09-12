import Foundation

public struct FetchRecordQuery<QueryType: MKQueryProtocol>: MKEncodable {
  public let query: QueryType
  public let desiredKeys: [String]?
  public let numbersAsStrings: Bool = true

  public init(query: QueryType) {
    self.query = query
    desiredKeys = query.desiredKeys
  }
}

public struct ModifyOperation: Encodable {}

public struct ModifyRecordQuery: MKEncodable {
  public let operations: [ModifyOperation]
  public let atomic = true
  public let desiredKeys: [String]?
  public let numbersAsStrings: Bool = true
}
