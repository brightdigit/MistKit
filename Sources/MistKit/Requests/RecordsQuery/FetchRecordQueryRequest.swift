public struct FetchRecordQueryRequest<QueryType: MKQueryProtocol>: MKRequest {
  public typealias Response = FetchRecordQueryResponse

  public typealias Data = FetchRecordQuery

  public let database: MKDatabaseType
  public let data: FetchRecordQuery<QueryType>

  public let subpath = ["records", "query"]

  public init(database: MKDatabaseType, query: FetchRecordQuery<QueryType>) {
    self.database = database
    data = query
  }
}
