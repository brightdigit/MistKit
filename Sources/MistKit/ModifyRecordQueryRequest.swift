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
