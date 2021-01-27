@testable import MistKit
import XCTest
final class UUIDTests: XCTestCase {
  func testArray() {
    let count = 40
    let uuidByteSize = 16
    let expectedDatas = (1 ... count).map { _ in
      (1 ... uuidByteSize).map { _ in
        UInt8.random(in: 0 ... 255)
      }
    }.map(Data.init(_:))
    let uuids = expectedDatas.map(UUID.init(data:))
    let actualDatas = uuids.map(Array.init(uuid:)).map(Data.init(_:))
    let actualDataProps = uuids.map { $0.data }.map { $0 as Data }
    XCTAssertEqual(expectedDatas, actualDatas)
    XCTAssertEqual(expectedDatas, actualDataProps)
  }
}
