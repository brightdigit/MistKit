

public protocol MKRequest {
  var data : Data { get }
  var database : MKDatabaseType { get }
  var subpath : [String] { get }
  associatedtype Response : MKDecodable
  associatedtype Data : MKEncodable
}

public extension MKRequest {
  var relativePath : [String] {
    ([self.database.rawValue] + subpath)
  }
}
