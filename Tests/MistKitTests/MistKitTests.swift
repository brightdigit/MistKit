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
}