internal import Foundation
internal import Testing

@testable import MistKit

/// Test suite for Database enum functionality and behavior validation
@Suite("Database")
internal struct DatabaseTests {
  /// Tests that each Database scope produces the expected URL path segment.
  @Test("Database pathSegment values")
  internal func databasePathSegments() {
    #expect(Database.public(.prefers(.serverToServer)).pathSegment == "public")
    #expect(Database.public(.requires(.webAuth)).pathSegment == "public")
    #expect(Database.private.pathSegment == "private")
    #expect(Database.shared.pathSegment == "shared")
  }
}
