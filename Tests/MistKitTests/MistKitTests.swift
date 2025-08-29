public import XCTest

@testable import MistKit

/// Test suite for MistKit framework functionality
public final class MistKitTests: XCTestCase {
  /// Tests MistKitConfiguration initialization with required parameters
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

  /// Tests Environment enum raw values
  public func testEnvironmentRawValues() {
    XCTAssertEqual(Environment.development.rawValue, "development")
    XCTAssertEqual(Environment.production.rawValue, "production")
  }

  /// Tests Database enum raw values
  public func testDatabaseRawValues() {
    XCTAssertEqual(Database.public.rawValue, "public")
    XCTAssertEqual(Database.private.rawValue, "private")
    XCTAssertEqual(Database.shared.rawValue, "shared")
  }

  // MARK: - FieldValue Tests

  /// Tests FieldValue string type creation and equality
  public func testFieldValueString() {
    let value = FieldValue.string("test")
    XCTAssertEqual(value, .string("test"))
  }

  /// Tests FieldValue int64 type creation and equality
  public func testFieldValueInt64() {
    let value = FieldValue.int64(123)
    XCTAssertEqual(value, .int64(123))
  }

  /// Tests FieldValue double type creation and equality
  public func testFieldValueDouble() {
    let value = FieldValue.double(3.14)
    XCTAssertEqual(value, .double(3.14))
  }

  /// Tests FieldValue boolean type creation and equality
  public func testFieldValueBoolean() {
    let value = FieldValue.boolean(true)
    XCTAssertEqual(value, .boolean(true))
  }

  /// Tests FieldValue date type creation and equality
  public func testFieldValueDate() {
    let date = Date()
    let value = FieldValue.date(date)
    XCTAssertEqual(value, .date(date))
  }

  /// Tests FieldValue location type creation and equality
  public func testFieldValueLocation() {
    let location = FieldValue.Location(
      latitude: 37.7749,
      longitude: -122.4194,
      horizontalAccuracy: 10.0
    )
    let value = FieldValue.location(location)
    XCTAssertEqual(value, .location(location))
  }

  /// Tests FieldValue reference type creation and equality
  public func testFieldValueReference() {
    let reference = FieldValue.Reference(recordName: "test-record")
    let value = FieldValue.reference(reference)
    XCTAssertEqual(value, .reference(reference))
  }

  /// Tests FieldValue asset type creation and equality
  public func testFieldValueAsset() {
    let asset = FieldValue.Asset(
      fileChecksum: "abc123",
      size: 1_024,
      downloadURL: "https://example.com/file"
    )
    let value = FieldValue.asset(asset)
    XCTAssertEqual(value, .asset(asset))
  }

  /// Tests FieldValue list type creation and equality
  public func testFieldValueList() {
    let list = [FieldValue.string("item1"), FieldValue.int64(42)]
    let value = FieldValue.list(list)
    XCTAssertEqual(value, .list(list))
  }

  /// Tests FieldValue JSON encoding and decoding
  public func testFieldValueEncodable() throws {
    let value = FieldValue.string("test")
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(FieldValue.self, from: data)
    XCTAssertEqual(value, decoded)
  }

  // MARK: - RecordInfo Tests

  /// Tests RecordInfo initialization from Components.Schemas.Record
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

  /// Tests RecordInfo initialization with empty record data
  public func testRecordInfoWithUnknownRecord() {
    let mockRecord = Components.Schemas.Record()
    let recordInfo = RecordInfo(from: mockRecord)

    XCTAssertEqual(recordInfo.recordName, "Unknown")
    XCTAssertEqual(recordInfo.recordType, "Unknown")
    XCTAssertTrue(recordInfo.fields.isEmpty)
  }
}
