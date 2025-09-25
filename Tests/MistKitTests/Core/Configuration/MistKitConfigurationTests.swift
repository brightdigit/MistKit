import Foundation
import Testing

@testable import MistKit

@Suite("MistKit Configuration")
/// Tests for MistKitConfiguration functionality
internal struct MistKitConfigurationTests {
  /// Tests MistKitConfiguration initialization with required parameters
  @Test("MistKitConfiguration initialization with required parameters")
  internal func configurationInitialization() {
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
}
