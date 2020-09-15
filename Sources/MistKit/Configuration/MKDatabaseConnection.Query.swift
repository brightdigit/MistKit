import Foundation

extension MKDatabaseConnection {
  var url: URL {
    return Self.baseURL.appendingPathComponent(version.rawValue).appendingPathComponent(container).appendingPathComponent(environment.rawValue)
  }
}
