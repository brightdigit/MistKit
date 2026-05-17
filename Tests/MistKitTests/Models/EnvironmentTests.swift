import Foundation
import Testing

@testable import MistKit

@Suite("Environment")
/// Tests for Environment enum functionality
internal struct EnvironmentTests {
  /// Tests Environment enum raw values
  @Test("Environment enum raw values")
  internal func environmentRawValues() {
    #expect(Environment.development.rawValue == "development")
    #expect(Environment.production.rawValue == "production")
  }

  @Test(
    "init?(caseInsensitive:) matches .production",
    arguments: ["production", "Production", "PRODUCTION", "PrOdUcTiOn"]
  )
  internal func caseInsensitiveProduction(raw: String) {
    #expect(Environment(caseInsensitive: raw) == .production)
  }

  @Test(
    "init?(caseInsensitive:) matches .development",
    arguments: ["development", "Development", "DEVELOPMENT", "DeVeLoPmEnT"]
  )
  internal func caseInsensitiveDevelopment(raw: String) {
    #expect(Environment(caseInsensitive: raw) == .development)
  }

  @Test(
    "init?(caseInsensitive:) returns nil for non-canonical values",
    arguments: ["staging", "prod", "dev", "test", "qa", " production ", ""]
  )
  internal func caseInsensitiveRejectsInvalidValues(raw: String) {
    #expect(Environment(caseInsensitive: raw) == nil)
  }
}
