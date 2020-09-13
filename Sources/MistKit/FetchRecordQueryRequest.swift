public struct FetchRecordQueryRequest<QueryType: MKQueryProtocol>: MKRequest {
  public let database: MKDatabaseType
  public let data: FetchRecordQuery<QueryType>

  public let subpath = ["records", "query"]

  public typealias Response = FetchRecordQueryResponse

  public typealias Data = FetchRecordQuery

  public init(database: MKDatabaseType, query: FetchRecordQuery<QueryType>) {
    self.database = database
    data = query
  }
}

public struct ModifyRecordQueryRequest: MKRequest {
  public let database: MKDatabaseType
  public let data: ModifyRecordQuery

  public let subpath = ["records", "modify"]

  public typealias Response = FetchRecordQueryResponse

  public typealias Data = ModifyRecordQuery

  public init(database: MKDatabaseType, query: ModifyRecordQuery) {
    self.database = database
    data = query
  }
}
