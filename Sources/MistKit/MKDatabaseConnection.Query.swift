import Foundation

extension MKDatabaseConnection {
  var url: URL {
    // return URL(string: "https://api.apple-cloudkit.com/database/1/\(container)/\(environment)")
    return Self.baseURL.appendingPathComponent(version.rawValue).appendingPathComponent(container).appendingPathComponent(environment.rawValue)
  }
}
