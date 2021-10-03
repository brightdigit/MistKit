public protocol MKRequest {
  associatedtype Response: MKDecodable
  associatedtype Data: MKEncodable

  var data: Data { get }
  var database: MKDatabaseType { get }
  var subpath: [String] { get }
}

public extension MKRequest {
  var relativePath: [String] {
    [database.rawValue] + subpath
  }
}
