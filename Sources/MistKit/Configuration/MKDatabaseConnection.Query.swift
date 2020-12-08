import Foundation

public extension MKDatabaseConnection {
  var url: URL {
    Self.baseURL.appendingPathComponent(version.rawValue).appendingPathComponent(container).appendingPathComponent(environment.rawValue)
  }
}
