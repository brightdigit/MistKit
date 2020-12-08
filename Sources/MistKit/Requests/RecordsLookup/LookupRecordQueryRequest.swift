public struct LookupRecordQueryRequest<RecordType: MKQueryRecord>: MKRequest {
  public typealias Response = FetchRecordQueryResponse

  public typealias Data = LookupRecordQuery<RecordType>

  public let database: MKDatabaseType
  public let data: LookupRecordQuery<RecordType>

  public let subpath = ["records", "lookup"]

  public init(database: MKDatabaseType, query: LookupRecordQuery<RecordType>) {
    self.database = database
    data = query
  }
}
