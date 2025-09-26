import Foundation
import Testing

@testable import MistKit

/// Test suite for Database enum functionality and behavior validation
@Suite("Database")
internal struct DatabaseTests {
  /// Tests Database enum raw values
  @Test("Database enum raw values")
  internal func databaseRawValues() {
    #expect(Database.public.rawValue == "public")
    #expect(Database.private.rawValue == "private")
    #expect(Database.shared.rawValue == "shared")
  }
}
