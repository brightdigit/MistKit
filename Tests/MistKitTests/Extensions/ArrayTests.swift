@testable import MistKit
import XCTest
final class ArrayTests: XCTestCase {
  func testUUID() {
    let count = 40
    let expectedUUIDs = (1 ... count).map { _ in
      UUID()
    }
    let arrays = expectedUUIDs.map { uuid -> [UInt8] in
      let array = Array(uuid: uuid)
      XCTAssertEqual(array.count, 16)
      return array
    }
    let actualUUIDs = arrays.map { array -> UUID in
      UUID(data: Data(array))
    }

    XCTAssertEqual(expectedUUIDs, actualUUIDs)
  }
}
