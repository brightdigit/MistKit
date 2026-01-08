//
//  ConfigKeyTests.swift
//  ConfigKeyKit
//
//  Tests for ConfigKey configuration
//

import Testing

@testable import ConfigKeyKit

@Suite("ConfigKey Tests")
internal struct ConfigKeyTests {
  @Test("ConfigKey with explicit keys and default")
  internal func explicitKeys() {
    let key = ConfigKey<String>(cli: "test.key", env: "TEST_KEY", default: "default-value")

    #expect(key.key(for: .commandLine) == "test.key")
    #expect(key.key(for: .environment) == "TEST_KEY")
    #expect(key.defaultValue == "default-value")
  }

  @Test("ConfigKey with base string and default prefix")
  internal func baseStringWithDefaultPrefix() {
    let key = ConfigKey<String>(
      bushelPrefixed: "cloudkit.container_id", default: "iCloud.com.example.App"
    )

    #expect(key.key(for: .commandLine) == "cloudkit.container_id")
    #expect(key.key(for: .environment) == "BUSHEL_CLOUDKIT_CONTAINER_ID")
    #expect(key.defaultValue == "iCloud.com.example.App")
  }

  @Test("ConfigKey with base string and no prefix")
  internal func baseStringNoPrefix() {
    let key = ConfigKey<String>(
      "cloudkit.container_id", envPrefix: nil, default: "iCloud.com.example.App"
    )

    #expect(key.key(for: .commandLine) == "cloudkit.container_id")
    #expect(key.key(for: .environment) == "CLOUDKIT_CONTAINER_ID")
    #expect(key.defaultValue == "iCloud.com.example.App")
  }

  @Test("ConfigKey with default value")
  internal func defaultValue() {
    let key = ConfigKey<String>(cli: "test.key", env: "TEST_KEY", default: "default-value")

    #expect(key.defaultValue == "default-value")
  }

  @Test("Boolean ConfigKey with default")
  internal func booleanDefaultValue() {
    let key = ConfigKey<Bool>(bushelPrefixed: "sync.verbose", default: false)

    #expect(key.defaultValue == false)
  }
}
