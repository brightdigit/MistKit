import Testing
import Foundation
@testable import MistKit

/// Test suite for MistKit framework functionality
struct MistKitTests {
  /// Tests MistKitConfiguration initialization with required parameters
  @Test
  func configurationInitialization() {
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
    #expect(configuration.container == container)
    #expect(configuration.environment == .development)
    #expect(configuration.database == .private)
    #expect(configuration.apiToken == apiToken)
    #expect(configuration.webAuthToken == nil)
    #expect(configuration.version == "1")
    #expect(configuration.serverURL.absoluteString == "https://api.apple-cloudkit.com")
  }

  /// Tests Environment enum raw values
  @Test
  func environmentRawValues() {
    #expect(Environment.development.rawValue == "development")
    #expect(Environment.production.rawValue == "production")
  }

  /// Tests Database enum raw values
  @Test
  func databaseRawValues() {
    #expect(Database.public.rawValue == "public")
    #expect(Database.private.rawValue == "private")
    #expect(Database.shared.rawValue == "shared")
  }

  // MARK: - FieldValue Tests

  /// Tests FieldValue string type creation and equality
  @Test
  func fieldValueString() {
    let value = FieldValue.string("test")
    #expect(value == .string("test"))
  }

  /// Tests FieldValue int64 type creation and equality
  @Test
  func fieldValueInt64() {
    let value = FieldValue.int64(123)
    #expect(value == .int64(123))
  }

  /// Tests FieldValue double type creation and equality
  @Test
  func fieldValueDouble() {
    let value = FieldValue.double(3.14)
    #expect(value == .double(3.14))
  }

  /// Tests FieldValue boolean type creation and equality
  @Test
  func fieldValueBoolean() {
    let value = FieldValue.boolean(true)
    #expect(value == .boolean(true))
  }

  /// Tests FieldValue date type creation and equality
  @Test
  func fieldValueDate() {
    let date = Date()
    let value = FieldValue.date(date)
    #expect(value == .date(date))
  }

  /// Tests FieldValue location type creation and equality
  @Test
  func fieldValueLocation() {
    let location = FieldValue.Location(
      latitude: 37.7749,
      longitude: -122.4194,
      horizontalAccuracy: 10.0
    )
    let value = FieldValue.location(location)
    #expect(value == .location(location))
  }

  /// Tests FieldValue reference type creation and equality
  @Test
  func fieldValueReference() {
    let reference = FieldValue.Reference(recordName: "test-record")
    let value = FieldValue.reference(reference)
    #expect(value == .reference(reference))
  }

  /// Tests FieldValue asset type creation and equality
  @Test
  func fieldValueAsset() {
    let asset = FieldValue.Asset(
      fileChecksum: "abc123",
      size: 1_024,
      downloadURL: "https://example.com/file"
    )
    let value = FieldValue.asset(asset)
    #expect(value == .asset(asset))
  }

  /// Tests FieldValue list type creation and equality
  @Test
  func fieldValueList() {
    let list = [FieldValue.string("item1"), FieldValue.int64(42)]
    let value = FieldValue.list(list)
    #expect(value == .list(list))
  }

  /// Tests FieldValue JSON encoding and decoding
  @Test
  func fieldValueEncodable() throws {
    let value = FieldValue.string("test")
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(FieldValue.self, from: data)
    #expect(value == decoded)
  }

  // MARK: - RecordInfo Tests

  /// Tests RecordInfo initialization from Components.Schemas.Record
  @Test
  func recordInfoInitialization() {
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

    #expect(recordInfo.recordName == "test-record")
    #expect(recordInfo.recordType == "TestType")
    #expect(recordInfo.fields.count == 2)

    if case .string(let name) = recordInfo.fields["name"] {
      #expect(name == "Test Name")
    } else {
      Issue.record("Expected string value for 'name' field")
    }

    if case .int64(let count) = recordInfo.fields["count"] {
      #expect(count == 42)
    } else {
      Issue.record("Expected int64 value for 'count' field")
    }
  }

  /// Tests RecordInfo initialization with empty record data
  @Test
  func recordInfoWithUnknownRecord() {
    let mockRecord = Components.Schemas.Record()
    let recordInfo = RecordInfo(from: mockRecord)

    #expect(recordInfo.recordName == "Unknown")
    #expect(recordInfo.recordType == "Unknown")
    #expect(recordInfo.fields.isEmpty)
  }
}
