import XCTest
@testable import MistKit

final class MistKitTests: XCTestCase {
    func testConfigurationInitialization() {
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
    
    func testEnvironmentRawValues() {
        XCTAssertEqual(Environment.development.rawValue, "development")
        XCTAssertEqual(Environment.production.rawValue, "production")
    }
    
    func testDatabaseRawValues() {
        XCTAssertEqual(Database.public.rawValue, "public")
        XCTAssertEqual(Database.private.rawValue, "private")
        XCTAssertEqual(Database.shared.rawValue, "shared")
    }
    
    // MARK: - CKValue Tests
    
    func testCKValueString() {
        let value = CKValue.string("test")
        XCTAssertEqual(value, .string("test"))
    }
    
    func testCKValueInt64() {
        let value = CKValue.int64(123)
        XCTAssertEqual(value, .int64(123))
    }
    
    func testCKValueDouble() {
        let value = CKValue.double(3.14)
        XCTAssertEqual(value, .double(3.14))
    }
    
    func testCKValueBoolean() {
        let value = CKValue.boolean(true)
        XCTAssertEqual(value, .boolean(true))
    }
    
    func testCKValueDate() {
        let date = Date()
        let value = CKValue.date(date)
        XCTAssertEqual(value, .date(date))
    }
    
    func testCKValueLocation() {
        let location = CKValue.Location(
            latitude: 37.7749,
            longitude: -122.4194,
            horizontalAccuracy: 10.0
        )
        let value = CKValue.location(location)
        XCTAssertEqual(value, .location(location))
    }
    
    func testCKValueReference() {
        let reference = CKValue.Reference(recordName: "test-record")
        let value = CKValue.reference(reference)
        XCTAssertEqual(value, .reference(reference))
    }
    
    func testCKValueAsset() {
        let asset = CKValue.Asset(
            fileChecksum: "abc123",
            size: 1024,
            downloadURL: "https://example.com/file"
        )
        let value = CKValue.asset(asset)
        XCTAssertEqual(value, .asset(asset))
    }
    
    func testCKValueList() {
        let list = [CKValue.string("item1"), CKValue.int64(42)]
        let value = CKValue.list(list)
        XCTAssertEqual(value, .list(list))
    }
    
    func testCKValueEncodable() throws {
        let value = CKValue.string("test")
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(CKValue.self, from: data)
        XCTAssertEqual(value, decoded)
    }
    
    // MARK: - RecordInfo Tests
    
    func testRecordInfoInitialization() {
        // Create a mock record with fields
        let mockRecord = Components.Schemas.Record(
            recordName: "test-record",
            recordType: "TestType",
            fields: Components.Schemas.Record.fieldsPayload(
                additionalProperties: [
                    "name": Components.Schemas.Record.fieldsPayload.additionalPropertiesPayload(
                        value: .case1("Test Name"),
                        _type: .STRING
                    ),
                    "count": Components.Schemas.Record.fieldsPayload.additionalPropertiesPayload(
                        value: .case2(42.0),
                        _type: .INT64
                    )
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
    
    func testRecordInfoWithUnknownRecord() {
        let mockRecord = Components.Schemas.Record()
        let recordInfo = RecordInfo(from: mockRecord)
        
        XCTAssertEqual(recordInfo.recordName, "Unknown")
        XCTAssertEqual(recordInfo.recordType, "Unknown")
        XCTAssertTrue(recordInfo.fields.isEmpty)
    }
}