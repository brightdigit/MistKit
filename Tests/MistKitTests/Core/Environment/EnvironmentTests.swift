import Foundation
import Testing

@testable import MistKit

@Suite("Environment", .disabledOniOSWithXcode16_2OrOlder())
/// Tests for Environment enum functionality
internal struct EnvironmentTests {
  /// Tests Environment enum raw values
  @Test("Environment enum raw values")
  internal func environmentRawValues() {
    #expect(Environment.development.rawValue == "development")
    #expect(Environment.production.rawValue == "production")
  }
}
