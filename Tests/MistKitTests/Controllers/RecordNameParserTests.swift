@testable import MistKit
import XCTest
final class RecordNameParserTests: XCTestCase {
  func testUUIDs() {
    let uuid = UUID()
    let recordName = "_" + uuid.uuidString.replacingOccurrences(of: "-", with: "")
    XCTAssertEqual(uuid, RecordNameParser.uuid(fromRecordName: recordName))
  }
}
