import XCTest
@testable import MistKit

final class MistKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MistKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
