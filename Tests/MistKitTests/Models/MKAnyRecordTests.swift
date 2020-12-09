@testable import MistKit
import XCTest

class MockRecord: MKQueryRecord {
  static var recordType: String = UUID().uuidString

  static var desiredKeys: [String] = (0 ..< 3).map { _ in UUID().uuidString }

  let recordName: UUID?

  let recordChangeTag: String?

  let fields: [String: MKValue]

  internal init(recordName: UUID?, recordChangeTag: String?, fields: [String: MKValue]) {
    self.recordName = recordName
    self.recordChangeTag = recordChangeTag
    self.fields = fields
  }

  required init(record: MKAnyRecord) throws {
    fields = record.fields
    recordName = nil
    recordChangeTag = nil
  }
}

extension Data {
  static func random(withCount count: Int = 32) -> Data {
    let bytes = (1 ... count).map { _ in
      UInt8.random(in: 0 ... UInt8.max)
    }
    return Data(bytes)
  }
}

final class MKAnyRecordTests: XCTestCase {
  let expectedRecordName = UUID()
  let expectedTag = UUID().uuidString

  let expectedIntField = UUID().uuidString
  let expectedStrField = UUID().uuidString
  let expectedDataField = UUID().uuidString

  let expectedIntValue = Int64.random(in: 0 ... Int64.max)
  let expectedStrValue = UUID().uuidString
  let expectedDataValue = Data.random()

  var expectedFields: [String: MKValue]!
  var record: MKAnyRecord!

  override func setUp() {
    expectedFields = [
      expectedIntField: .integer(expectedIntValue),
      expectedStrField: .string(expectedStrValue),
      expectedDataField: .data(expectedDataValue)
    ]

    record = MKAnyRecord(
      record: MockRecord(
        recordName: expectedRecordName,
        recordChangeTag: expectedTag,
        fields: expectedFields
      )
    )
  }

  func testInit() {
    XCTAssertEqual(record.recordName, expectedRecordName)
    XCTAssertEqual(record.recordChangeTag, expectedTag)
    XCTAssertEqual(record.fields, expectedFields)

    do {
      try XCTAssertEqual(record.integer(fromKey: expectedIntField), expectedIntValue)
      try XCTAssertEqual(record.string(fromKey: expectedStrField), expectedStrValue)
      try XCTAssertEqual(record.data(fromKey: expectedDataField), expectedDataValue)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }

  func expectFailure(_ closure: @escaping () throws -> Void) {
    var error: Error?

    XCTAssertThrowsError(closure) {
      error = $0
    }

    XCTAssertNotNil(error)
  }

  func testData() {}

  func testString() {}

  func testInteger() {}
}
