@testable import MistKit
import XCTest
final class StringTests: XCTestCase {
  func testNilIfEmpty() {
    let withContent = String.random(ofLength: 32)
    let emptyString = ""
    XCTAssertNil(emptyString.nilIfEmpty)
    XCTAssertEqual(withContent.nilIfEmpty, withContent)
  }
}
