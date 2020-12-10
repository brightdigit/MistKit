@testable import MistKit
import XCTest
final class MKDatabaseConnectionTests: XCTestCase {
  func testDefaultInit() {
    let container = UUID().uuidString
    let apiToken = UUID().uuidString
    let environment = MKEnvironment.development
    let connection = MKDatabaseConnection(
      container: container,
      apiToken: apiToken,
      environment: environment
    )
    XCTAssertEqual(connection.baseURL, MKDatabaseConnection.baseURL)
    XCTAssertEqual(connection.version, .v1)
  }

  func testURL() {
    let container = UUID().uuidString
    let apiToken = UUID().uuidString
    let baseURL = URL.random()
    let environment = MKEnvironment.development
    let connection = MKDatabaseConnection(
      container: container,
      apiToken: apiToken,
      environment: environment,
      baseURL: baseURL,
      version: .v1
    )
    let expected = baseURL.appendingPathComponent(
      MKAPIVersion.v1.rawValue
    )
    .appendingPathComponent(container)
    .appendingPathComponent(environment.rawValue)
    XCTAssertEqual(connection.url, expected)
  }
}
