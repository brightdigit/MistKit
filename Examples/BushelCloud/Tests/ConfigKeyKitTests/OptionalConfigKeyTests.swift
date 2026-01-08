//
//  OptionalConfigKeyTests.swift
//  ConfigKeyKit
//
//  Tests for OptionalConfigKey configuration
//

import Testing

@testable import ConfigKeyKit

@Suite("OptionalConfigKey Tests")
internal struct OptionalConfigKeyTests {
  @Test("OptionalConfigKey with explicit keys")
  internal func explicitKeys() {
    let key = OptionalConfigKey<String>(cli: "test.key", env: "TEST_KEY")

    #expect(key.key(for: .commandLine) == "test.key")
    #expect(key.key(for: .environment) == "TEST_KEY")
  }

  @Test("OptionalConfigKey with base string and default prefix")
  internal func baseStringWithDefaultPrefix() {
    let key = OptionalConfigKey<String>(bushelPrefixed: "cloudkit.key_id")

    #expect(key.key(for: .commandLine) == "cloudkit.key_id")
    #expect(key.key(for: .environment) == "BUSHEL_CLOUDKIT_KEY_ID")
  }

  @Test("OptionalConfigKey with base string and no prefix")
  internal func baseStringNoPrefix() {
    let key = OptionalConfigKey<String>("cloudkit.key_id", envPrefix: nil)

    #expect(key.key(for: .commandLine) == "cloudkit.key_id")
    #expect(key.key(for: .environment) == "CLOUDKIT_KEY_ID")
  }

  @Test("OptionalConfigKey and ConfigKey generate identical keys")
  internal func keyGenerationParity() {
    let optional = OptionalConfigKey<String>(bushelPrefixed: "test.key")
    let withDefault = ConfigKey<String>(bushelPrefixed: "test.key", default: "default")

    #expect(optional.key(for: .commandLine) == withDefault.key(for: .commandLine))
    #expect(optional.key(for: .environment) == withDefault.key(for: .environment))
  }

  @Test("OptionalConfigKey for Int type")
  internal func intOptionalKey() {
    let key = OptionalConfigKey<Int>(bushelPrefixed: "sync.min_interval")

    #expect(key.key(for: .commandLine) == "sync.min_interval")
    #expect(key.key(for: .environment) == "BUSHEL_SYNC_MIN_INTERVAL")
  }

  @Test("OptionalConfigKey for Double type")
  internal func doubleOptionalKey() {
    let key = OptionalConfigKey<Double>(bushelPrefixed: "fetch.interval_global")

    #expect(key.key(for: .commandLine) == "fetch.interval_global")
    #expect(key.key(for: .environment) == "BUSHEL_FETCH_INTERVAL_GLOBAL")
  }
}
