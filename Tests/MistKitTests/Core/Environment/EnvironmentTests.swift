import Foundation
import Testing

@testable import MistKit

@Suite("Environment")
/// Tests for Environment enum functionality
public struct EnvironmentTests {
  /// Tests Environment enum raw values
  @Test("Environment enum raw values")
  public func environmentRawValues() {
    #expect(Environment.development.rawValue == "development")
    #expect(Environment.production.rawValue == "production")
  }
}
