// swiftlint:disable:this file_name
import Foundation

public extension MKDatabaseConnection {
  var url: URL {
    baseURL.appendingPathComponent(
      version.rawValue
    )
    .appendingPathComponent(container)
    .appendingPathComponent(environment.rawValue)
  }
}
