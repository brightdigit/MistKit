//
//  NamingStyleTests.swift
//  ConfigKeyKit
//
//  Tests for naming style transformations
//

import Testing

@testable import ConfigKeyKit

@Suite("NamingStyle Tests")
internal struct NamingStyleTests {
  @Test("Dot-separated style")
  internal func dotSeparatedStyle() {
    let style = StandardNamingStyle.dotSeparated
    #expect(style.transform("cloudkit.container_id") == "cloudkit.container_id")
  }

  @Test("Screaming snake case with prefix")
  internal func screamingSnakeCaseWithPrefix() {
    let style = StandardNamingStyle.screamingSnakeCase(prefix: "BUSHEL")
    #expect(style.transform("cloudkit.container_id") == "BUSHEL_CLOUDKIT_CONTAINER_ID")
  }

  @Test("Screaming snake case without prefix")
  internal func screamingSnakeCaseNoPrefix() {
    let style = StandardNamingStyle.screamingSnakeCase(prefix: nil)
    #expect(style.transform("cloudkit.container_id") == "CLOUDKIT_CONTAINER_ID")
  }

  @Test("Screaming snake case with nil prefix")
  internal func screamingSnakeCaseNilPrefix() {
    let style = StandardNamingStyle.screamingSnakeCase(prefix: nil)
    #expect(style.transform("sync.verbose") == "SYNC_VERBOSE")
  }
}
