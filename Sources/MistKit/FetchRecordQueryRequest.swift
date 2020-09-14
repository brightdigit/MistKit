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

public struct ModifyRecordQueryRequest<RecordType: MKQueryRecord>: MKRequest {
  public let database: MKDatabaseType
  public let data: ModifyRecordQuery<RecordType>

  public let subpath = ["records", "modify"]

  public typealias Response = ModifiedRecordQueryResponse

  public typealias Data = ModifyRecordQuery<RecordType>

  public init(database: MKDatabaseType, query: ModifyRecordQuery<RecordType>) {
    self.database = database
    data = query
  }
}

public struct LookupRecordQueryRequest<RecordType: MKQueryRecord>: MKRequest {
  public let database: MKDatabaseType
  public let data: LookupRecordQuery<RecordType>

  public let subpath = ["records", "lookup"]

  public typealias Response = FetchRecordQueryResponse

  public typealias Data = LookupRecordQuery<RecordType>

  public init(database: MKDatabaseType, query: LookupRecordQuery<RecordType>) {
    self.database = database
    data = query
  }
}
