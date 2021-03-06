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

public extension Data {
  static func random(withCount count: Int = 32) -> Data {
    let bytes = (1 ... count).map { _ in
      UInt8.random(in: 0 ... UInt8.max)
    }
    return Data(bytes)
  }
}

final class MKAnyRecordTests: XCTestCase {
  private let expectedRecordName = UUID()
  private let expectedTag = UUID().uuidString

  private let expectedIntField = UUID().uuidString
  private let expectedStrField = UUID().uuidString
  private let expectedDataField = UUID().uuidString

  private let expectedDateField = UUID().uuidString
  private let expectedDoubleField = UUID().uuidString
  private let expectedAssetField = UUID().uuidString
  private let expectedLocationField = UUID().uuidString

  private let expectedIntValue = Int64.random(in: 0 ... Int64.max)
  private let expectedStrValue = UUID().uuidString
  private let expectedDataValue = Data.random()

  private let expectedDateValue: Date = .init(
    timeIntervalSince1970: .random(in: 0 ... TimeInterval.greatestFiniteMagnitude)
  )
  private let expectedDoubleValue: Double = .random(in: 0 ... .greatestFiniteMagnitude)
  private let expectedAssetValue = MKAsset(
    fileChecksum: .random(),
    size: .random(in: 0 ... Int64.max),
    wrappingKey: Data.random(),
    referenceChecksum: .random(),
    downloadURL: MKAsset.URLBase(baseURL: URL.random()),
    receipt: .random()
  )
  private let expectedLocationValue = MKLocation(
    coordinate: MKLocationCoordinate2D(
      latitude: .random(in: 0 ... MKLocationDegrees.greatestFiniteMagnitude),
      longitude: .random(in: 0 ... MKLocationDegrees.greatestFiniteMagnitude)
    )
  )

  private var expectedFields: [String: MKValue]!
  private var record: MKAnyRecord!

  override public func setUp() {
    expectedFields = [
      expectedIntField: .integer(expectedIntValue),
      expectedStrField: .string(expectedStrValue),
      expectedDataField: .data(expectedDataValue),
      expectedDateField: .date(expectedDateValue),
      expectedDoubleField: .double(expectedDoubleValue),
      expectedAssetField: .asset(expectedAssetValue),
      expectedLocationField: .location(expectedLocationValue)
    ]

    record = MKAnyRecord(
      record: MockRecord(
        recordName: expectedRecordName,
        recordChangeTag: expectedTag,
        fields: expectedFields
      )
    )
  }

  public func valueTest(
    _ method: (MKAnyRecord) -> (String) throws -> Any,
    _ key: String = UUID().uuidString
  ) {
    var failedKey: String?
    do {
      _ = try method(record)(key)
    } catch let MKDecodingError.invalidKey(caughtKey) {
      failedKey = caughtKey
    } catch {
      XCTFail(error.localizedDescription)
    }

    XCTAssertEqual(key, failedKey)
  }

  public func testInit() {
    XCTAssertEqual(record.recordName, expectedRecordName)
    XCTAssertEqual(record.recordChangeTag, expectedTag)
    XCTAssertEqual(record.fields, expectedFields)
  }

  public func testValues() {
    XCTAssertEqual(try record.integer(fromKey: expectedIntField), expectedIntValue)
    XCTAssertEqual(try record.string(fromKey: expectedStrField), expectedStrValue)
    XCTAssertEqual(try record.data(fromKey: expectedDataField), expectedDataValue)
    XCTAssertEqual(try record.date(fromKey: expectedDateField), expectedDateValue)
    XCTAssertEqual(try record.double(fromKey: expectedDoubleField), expectedDoubleValue)
    XCTAssertEqual(try record.asset(fromKey: expectedAssetField), expectedAssetValue)
    XCTAssertEqual(
      try record.location(fromKey: expectedLocationField),
      expectedLocationValue
    )
  }

  public func testValuesIfExists() {
    XCTAssertEqual(
      try record.integerIfExists(fromKey: expectedIntField),
      expectedIntValue
    )
    XCTAssertEqual(
      try record.stringIfExists(fromKey: expectedStrField),
      expectedStrValue
    )
    XCTAssertEqual(
      try record.dataIfExists(fromKey: expectedDataField),
      expectedDataValue
    )
    XCTAssertEqual(
      try record.dateIfExists(fromKey: expectedDateField),
      expectedDateValue
    )
    XCTAssertEqual(
      try record.doubleIfExists(fromKey: expectedDoubleField),
      expectedDoubleValue
    )
    XCTAssertEqual(
      try record.assetIfExists(fromKey: expectedAssetField),
      expectedAssetValue
    )
    XCTAssertEqual(
      try record.locationIfExists(fromKey: expectedLocationField),
      expectedLocationValue
    )
  }

  public func testNilIfExists() {
    XCTAssertNil(try record.integerIfExists(fromKey: UUID().uuidString))
    XCTAssertNil(try record.stringIfExists(fromKey: UUID().uuidString))
    XCTAssertNil(try record.dataIfExists(fromKey: UUID().uuidString))
    XCTAssertNil(try record.dateIfExists(fromKey: UUID().uuidString))
    XCTAssertNil(try record.doubleIfExists(fromKey: UUID().uuidString))
    XCTAssertNil(try record.assetIfExists(fromKey: UUID().uuidString))
    XCTAssertNil(try record.locationIfExists(fromKey: UUID().uuidString))
  }

  public func testMissingFields() {
    valueTest(MKAnyRecord.integer, UUID().uuidString)
    valueTest(MKAnyRecord.string, UUID().uuidString)
    valueTest(MKAnyRecord.data, UUID().uuidString)
    valueTest(MKAnyRecord.date, UUID().uuidString)
    valueTest(MKAnyRecord.double, UUID().uuidString)
    valueTest(MKAnyRecord.asset, UUID().uuidString)
    valueTest(MKAnyRecord.location, UUID().uuidString)
  }
}
