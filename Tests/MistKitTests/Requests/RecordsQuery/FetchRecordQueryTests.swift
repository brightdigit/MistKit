@testable import MistKit
import XCTest

public struct MockQuery: MKQueryProtocol {
  public let recordType: String
  public let desiredKeys: [String]?
}

final class FetchRecordQueryTests: XCTestCase {
  func testInit() {
    let recordType = UUID().uuidString
    let desiredKeys = (0 ... 3).map { _ in UUID().uuidString }
    let query = FetchRecordQuery(
      query: MockQuery(recordType: recordType, desiredKeys: desiredKeys)
    )
    XCTAssertEqual(query.desiredKeys, desiredKeys)
    XCTAssertEqual(query.query.recordType, recordType)
  }
}
