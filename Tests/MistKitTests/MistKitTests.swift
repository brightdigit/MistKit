public import XCTest

@testable import MistKit

public final class MistKitTests: XCTestCase {
  public func testConfigurationInitialization() {
    // Given
    let container = "iCloud.com.example.app"
    let apiToken = "test-token"

    // When
    let configuration = MistKitConfiguration(
      container: container,
      environment: .development,
      apiToken: apiToken
    )

    // Then
    XCTAssertEqual(configuration.container, container)
    XCTAssertEqual(configuration.environment, .development)
    XCTAssertEqual(configuration.database, .private)
    XCTAssertEqual(configuration.apiToken, apiToken)
    XCTAssertNil(configuration.webAuthToken)
    XCTAssertEqual(configuration.version, "1")
    XCTAssertEqual(configuration.serverURL.absoluteString, "https://api.apple-cloudkit.com")
  }

  public func testEnvironmentRawValues() {
    XCTAssertEqual(Environment.development.rawValue, "development")
    XCTAssertEqual(Environment.production.rawValue, "production")
  }

  public func testDatabaseRawValues() {
    XCTAssertEqual(Database.public.rawValue, "public")
    XCTAssertEqual(Database.private.rawValue, "private")
    XCTAssertEqual(Database.shared.rawValue, "shared")
  }

  // MARK: - FieldValue Tests

  public func testFieldValueString() {
    let value = FieldValue.string("test")
    XCTAssertEqual(value, .string("test"))
  }

  public func testFieldValueInt64() {
    let value = FieldValue.int64(123)
    XCTAssertEqual(value, .int64(123))
  }

  public func testFieldValueDouble() {
    let value = FieldValue.double(3.14)
    XCTAssertEqual(value, .double(3.14))
  }

  public func testFieldValueBoolean() {
    let value = FieldValue.boolean(true)
    XCTAssertEqual(value, .boolean(true))
  }

  public func testFieldValueDate() {
    let date = Date()
    let value = FieldValue.date(date)
    XCTAssertEqual(value, .date(date))
  }

  public func testFieldValueLocation() {
    let location = FieldValue.Location(
      latitude: 37.7749,
      longitude: -122.4194,
      horizontalAccuracy: 10.0
    )
    let value = FieldValue.location(location)
    XCTAssertEqual(value, .location(location))
  }

  public func testFieldValueReference() {
    let reference = FieldValue.Reference(recordName: "test-record")
    let value = FieldValue.reference(reference)
    XCTAssertEqual(value, .reference(reference))
  }

  public func testFieldValueAsset() {
    let asset = FieldValue.Asset(
      fileChecksum: "abc123",
      size: 1_024,
      downloadURL: "https://example.com/file"
    )
    let value = FieldValue.asset(asset)
    XCTAssertEqual(value, .asset(asset))
  }

  public func testFieldValueList() {
    let list = [FieldValue.string("item1"), FieldValue.int64(42)]
    let value = FieldValue.list(list)
    XCTAssertEqual(value, .list(list))
  }

  public func testFieldValueEncodable() throws {
    let value = FieldValue.string("test")
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(FieldValue.self, from: data)
    XCTAssertEqual(value, decoded)
  }

  // MARK: - RecordInfo Tests

  public func testRecordInfoInitialization() {
    // Create a mock record with fields
    let mockRecord = Components.Schemas.Record(
      recordName: "test-record",
      recordType: "TestType",
      fields: Components.Schemas.Record.fieldsPayload(
        additionalProperties: [
          "name": Components.Schemas.FieldValue(stringValue: "Test Name"),
          "count": Components.Schemas.FieldValue(int64Value: 42),
        ]
      )
    )

    let recordInfo = RecordInfo(from: mockRecord)

    XCTAssertEqual(recordInfo.recordName, "test-record")
    XCTAssertEqual(recordInfo.recordType, "TestType")
    XCTAssertEqual(recordInfo.fields.count, 2)

    if case .string(let name) = recordInfo.fields["name"] {
      XCTAssertEqual(name, "Test Name")
    } else {
      XCTFail("Expected string value for 'name' field")
    }

    if case .int64(let count) = recordInfo.fields["count"] {
      XCTAssertEqual(count, 42)
    } else {
      XCTFail("Expected int64 value for 'count' field")
    }
  }

  public func testRecordInfoWithUnknownRecord() {
    let mockRecord = Components.Schemas.Record()
    let recordInfo = RecordInfo(from: mockRecord)

    XCTAssertEqual(recordInfo.recordName, "Unknown")
    XCTAssertEqual(recordInfo.recordType, "Unknown")
    XCTAssertTrue(recordInfo.fields.isEmpty)
  }
}
