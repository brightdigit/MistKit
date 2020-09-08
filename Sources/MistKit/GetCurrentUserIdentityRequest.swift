
public struct GetCurrentUserIdentityRequest : MKRequest {
  public let data: MKEmptyGet = .value
  
  public let database: MKDatabaseType = .public
  
  public let subpath: [String] = ["users","caller"]
  
  public typealias Response = UserIdentityResponse
  
  public typealias Data = MKEmptyGet
  
  public init () {
    
  }
  
}
