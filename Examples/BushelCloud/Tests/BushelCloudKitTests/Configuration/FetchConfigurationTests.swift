//
//  FetchConfigurationTests.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//

import Foundation
import Testing

@testable import BushelFoundation

@Suite("FetchConfiguration Logic")
internal struct FetchConfigurationTests {
  // MARK: - Minimum Interval Tests

  @Test("Per-source interval overrides global")
  internal func testPerSourceOverridesGlobal() {
    let config = FetchConfiguration(
      globalMinimumFetchInterval: 3_600,  // 1 hour
      perSourceIntervals: ["appledb.dev": 7_200]  // 2 hours
    )

    #expect(config.minimumInterval(for: "appledb.dev") == 7_200)
    #expect(config.minimumInterval(for: "ipsw.me") == 3_600)
  }

  @Test("Global interval used when no per-source interval")
  internal func testGlobalInterval() {
    let config = FetchConfiguration(
      globalMinimumFetchInterval: 5_400  // 1.5 hours
    )

    #expect(config.minimumInterval(for: "appledb.dev") == 5_400)
    #expect(config.minimumInterval(for: "unknown.source") == 5_400)
  }

  @Test("Default intervals used when enabled")
  internal func testDefaultIntervals() {
    let config = FetchConfiguration(useDefaults: true)

    // 6 hours
    #expect(config.minimumInterval(for: "appledb.dev") == TimeInterval(6 * 3_600))
    // 12 hours
    #expect(config.minimumInterval(for: "ipsw.me") == TimeInterval(12 * 3_600))
    // 1 hour
    #expect(config.minimumInterval(for: "mesu.apple.com") == TimeInterval(1 * 3_600))
    // 12 hours
    #expect(config.minimumInterval(for: "xcodereleases.com") == TimeInterval(12 * 3_600))
  }

  @Test("Default intervals not used when disabled")
  internal func testDefaultIntervalsDisabled() {
    let config = FetchConfiguration(useDefaults: false)

    #expect(config.minimumInterval(for: "appledb.dev") == nil)
    #expect(config.minimumInterval(for: "ipsw.me") == nil)
  }

  @Test("Per-source overrides defaults")
  internal func testPerSourceOverridesDefaults() {
    let config = FetchConfiguration(
      perSourceIntervals: ["appledb.dev": 1_800],  // 30 minutes
      useDefaults: true
    )

    // Per-source should override default
    #expect(config.minimumInterval(for: "appledb.dev") == 1_800)
    // Default should be used for other sources
    #expect(config.minimumInterval(for: "ipsw.me") == TimeInterval(12 * 3_600))
  }

  @Test("Global overrides defaults")
  internal func testGlobalOverridesDefaults() {
    let config = FetchConfiguration(
      globalMinimumFetchInterval: 7_200,  // 2 hours
      useDefaults: true
    )

    // Global should override defaults
    #expect(config.minimumInterval(for: "appledb.dev") == 7_200)
    #expect(config.minimumInterval(for: "ipsw.me") == 7_200)
  }

  @Test("Unknown source with no configuration returns nil")
  internal func testUnknownSourceNoConfig() {
    let config = FetchConfiguration(useDefaults: false)

    #expect(config.minimumInterval(for: "unknown.source") == nil)
  }

  // MARK: - Should Fetch Tests

  @Test("Should fetch when force is true")
  internal func testForceFetch() {
    let config = FetchConfiguration(globalMinimumFetchInterval: 3_600)
    let lastFetch = Date(timeIntervalSinceNow: -1_800)  // 30 min ago (less than 1 hour)

    let result = config.shouldFetch(
      source: "ipsw.me",
      lastFetchedAt: lastFetch,
      force: true
    )

    #expect(result == true)
  }

  @Test("Should fetch when never fetched before")
  internal func testNeverFetchedBefore() {
    let config = FetchConfiguration(globalMinimumFetchInterval: 3_600)

    let result = config.shouldFetch(
      source: "ipsw.me",
      lastFetchedAt: nil,
      force: false
    )

    #expect(result == true)
  }

  @Test("Should not fetch when interval not elapsed")
  internal func testThrottling() {
    let config = FetchConfiguration(globalMinimumFetchInterval: 3_600)  // 1 hour
    let lastFetch = Date(timeIntervalSinceNow: -1_800)  // 30 min ago (less than 1 hour)

    let result = config.shouldFetch(
      source: "ipsw.me",
      lastFetchedAt: lastFetch,
      force: false
    )

    #expect(result == false)
  }

  @Test("Should fetch when interval has elapsed")
  internal func testFetchWhenIntervalElapsed() {
    let config = FetchConfiguration(globalMinimumFetchInterval: 3_600)  // 1 hour
    let lastFetch = Date(timeIntervalSinceNow: -7_200)  // 2 hours ago (more than 1 hour)

    let result = config.shouldFetch(
      source: "ipsw.me",
      lastFetchedAt: lastFetch,
      force: false
    )

    #expect(result == true)
  }

  @Test("Should fetch when no interval configured")
  internal func testNoIntervalConfigured() {
    let config = FetchConfiguration(useDefaults: false)
    let lastFetch = Date(timeIntervalSinceNow: -60)  // 1 minute ago

    let result = config.shouldFetch(
      source: "unknown.source",
      lastFetchedAt: lastFetch,
      force: false
    )

    #expect(result == true)
  }

  @Test("Should respect per-source intervals in shouldFetch")
  internal func testPerSourceIntervalInShouldFetch() {
    let config = FetchConfiguration(
      globalMinimumFetchInterval: 3_600,  // 1 hour
      perSourceIntervals: ["appledb.dev": 7_200]  // 2 hours
    )

    // appledb.dev needs 2 hours, but only 1.5 hours passed
    let lastFetch1 = Date(timeIntervalSinceNow: -5_400)  // 1.5 hours ago
    #expect(config.shouldFetch(source: "appledb.dev", lastFetchedAt: lastFetch1) == false)

    // ipsw.me needs 1 hour (global), 1.5 hours passed
    let lastFetch2 = Date(timeIntervalSinceNow: -5_400)  // 1.5 hours ago
    #expect(config.shouldFetch(source: "ipsw.me", lastFetchedAt: lastFetch2) == true)
  }

  // MARK: - Default Intervals Tests

  @Test("Default intervals contain expected sources")
  internal func testDefaultIntervalsExist() {
    let defaults = FetchConfiguration.defaultIntervals

    #expect(defaults["appledb.dev"] != nil)
    #expect(defaults["ipsw.me"] != nil)
    #expect(defaults["mesu.apple.com"] != nil)
    #expect(defaults["mrmacintosh.com"] != nil)
    #expect(defaults["xcodereleases.com"] != nil)
    #expect(defaults["swiftversion.net"] != nil)
  }

  @Test("Default intervals have reasonable values")
  internal func testDefaultIntervalValues() {
    let defaults = FetchConfiguration.defaultIntervals

    // All intervals should be positive
    for (_, interval) in defaults {
      #expect(interval > 0)
    }

    // MESU should have shortest interval (signing changes frequently)
    #expect(defaults["mesu.apple.com"] == TimeInterval(1 * 3_600))

    // AppleDB should be moderate (6 hours)
    #expect(defaults["appledb.dev"] == TimeInterval(6 * 3_600))

    // Most others should be 12 hours or more
    #expect(defaults["ipsw.me"] == TimeInterval(12 * 3_600))
    #expect(defaults["mrmacintosh.com"] == TimeInterval(12 * 3_600))
  }

  // MARK: - Codable Tests

  @Test("Configuration is encodable and decodable")
  internal func testCodable() throws {
    let original = FetchConfiguration(
      globalMinimumFetchInterval: 5_400,
      perSourceIntervals: ["appledb.dev": 7_200, "ipsw.me": 10_800],
      useDefaults: false
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(original)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(FetchConfiguration.self, from: data)

    #expect(decoded.globalMinimumFetchInterval == original.globalMinimumFetchInterval)
    #expect(decoded.perSourceIntervals == original.perSourceIntervals)
    #expect(decoded.useDefaults == original.useDefaults)
  }

  // MARK: - Edge Cases

  @Test("Zero interval allows immediate refetch")
  internal func testZeroInterval() {
    let config = FetchConfiguration(globalMinimumFetchInterval: 0)
    let lastFetch = Date(timeIntervalSinceNow: -1)  // 1 second ago

    #expect(config.shouldFetch(source: "ipsw.me", lastFetchedAt: lastFetch) == true)
  }

  @Test("Boundary condition: exactly at interval")
  internal func testExactlyAtInterval() {
    let config = FetchConfiguration(globalMinimumFetchInterval: 3_600)  // 1 hour
    let lastFetch = Date(timeIntervalSinceNow: -3_600)  // exactly 1 hour ago

    // Should allow fetch when time >= interval
    #expect(config.shouldFetch(source: "ipsw.me", lastFetchedAt: lastFetch) == true)
  }
}
