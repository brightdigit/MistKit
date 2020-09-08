

public struct FetchRecordQueryRequest : MKRequest {
  public let database: MKDatabaseType
  public let data: FetchRecordQuery

  
  public let subpath = ["records","query"]

  
  
  public typealias Response = FetchRecordQueryResponse
  
  public typealias Data = FetchRecordQuery
  
  public init (database: MKDatabaseType, query: FetchRecordQuery) {
    self.database = database
    self.data = query
  }
}
