import Foundation
import Testing

@testable import MistKit

@Suite("Database")
/// Tests for Database enum functionality
struct DatabaseTests {
  /// Tests Database enum raw values
  @Test("Database enum raw values")
  func databaseRawValues() {
    #expect(Database.public.rawValue == "public")
    #expect(Database.private.rawValue == "private")
    #expect(Database.shared.rawValue == "shared")
  }
}
