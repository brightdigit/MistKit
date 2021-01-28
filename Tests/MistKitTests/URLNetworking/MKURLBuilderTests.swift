@testable import MistKit
import XCTest
final class MKURLBuilderTests: XCTestCase {
  func testURL () {
    let container = String.random(ofLength: 32)
    let apiToken = String.random(ofLength: 32)
    let connection = MKDatabaseConnection(container: container, apiToken: apiToken, environment: .development)
    let builder = MKURLBuilder(tokenEncoder: nil, connection: connection)
    let parameters = builder.queryItems
    XCTAssertEqual(parameters["ckAPIToken"],apiToken)
    
  }
}
