import Foundation

public struct FetchRecordQuery<QueryType: MKQueryProtocol>: MKEncodable {
  public let query: QueryType
  public let desiredKeys: [String]?
  public let numbersAsStrings = true

  public init(query: QueryType) {
    self.query = query
    desiredKeys = query.desiredKeys
  }
}
