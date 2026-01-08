//
//  ConfigurationLoaderTests.swift
//  BushelCloud
//
//  Comprehensive tests for ConfigurationLoader
//

import Configuration
import Foundation
import MistKit
import Testing

@testable import BushelCloudKit
@testable import BushelFoundation

/// Comprehensive tests for ConfigurationLoader
///
/// Tests the configuration loading pipeline from CLI arguments and environment
/// variables through to the final BushelConfiguration structure.
@Suite("ConfigurationLoader Tests")
internal struct ConfigurationLoaderTests {
  // MARK: - Boolean Parsing Tests

  @Suite("Boolean Parsing")
  internal struct BooleanParsingTests {
    @Test("CLI flag presence sets boolean to true")
    internal func testCLIFlagPresence() async throws {
      // Simulate: bushel-cloud sync --verbose
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync.verbose"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == true)
    }

    @Test("ENV var 'true' sets boolean to true")
    internal func testEnvTrue() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": "true"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == true)
    }

    @Test("ENV var '1' sets boolean to true")
    internal func testEnvOne() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": "1"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == true)
    }

    @Test(
      "ENV var 'yes' (case-insensitive) sets boolean to true",
      arguments: ["yes", "YES", "Yes", "yEs"]
    )
    internal func testEnvYes(value: String) async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": value]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == true)
    }

    @Test("ENV var 'false' sets boolean to false")
    internal func testEnvFalse() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": "false"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == false)
    }

    @Test("ENV var '0' sets boolean to false")
    internal func testEnvZero() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": "0"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == false)
    }

    @Test("ENV var 'no' sets boolean to false")
    internal func testEnvNo() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": "no"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == false)
    }

    @Test("Empty ENV var uses default value")
    internal func testEnvEmpty() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": ""]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == false)  // Default
    }

    @Test("Invalid ENV var value uses default")
    internal func testEnvInvalid() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": "maybe"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == false)  // Default
    }

    @Test("ENV var with whitespace is trimmed and parsed")
    internal func testEnvWhitespace() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": "  true  "]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == true)
    }
  }

  // MARK: - Source Precedence Tests

  @Suite("Source Precedence")
  internal struct SourcePrecedenceTests {
    @Test("CLI flag overrides ENV false")
    internal func testCLIOverridesEnvFalse() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync.verbose"],
        env: ["BUSHEL_SYNC_VERBOSE": "false"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == true)  // CLI wins
    }

    @Test("Absence of CLI flag respects ENV true")
    internal func testNoCLIRespectsEnvTrue() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": "true"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == true)  // ENV used
    }
  }

  // MARK: - String Parsing Tests

  @Suite("String Parsing")
  internal struct StringParsingTests {
    @Test("String value from CLI arguments")
    internal func testStringFromCLI() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["cloudkit.container_id=iCloud.com.test.App"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.cloudKit?.containerID == "iCloud.com.test.App")
    }

    @Test("String value from environment variable")
    internal func testStringFromEnv() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["CLOUDKIT_CONTAINER_ID": "iCloud.com.env.App"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.cloudKit?.containerID == "iCloud.com.env.App")
    }

    @Test("CLI string overrides ENV string")
    internal func testStringCLIPrecedence() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["cloudkit.container_id=iCloud.com.cli.App"],
        env: ["CLOUDKIT_CONTAINER_ID": "iCloud.com.env.App"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.cloudKit?.containerID == "iCloud.com.cli.App")
    }

    @Test("String uses default when not provided")
    internal func testStringDefault() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [:]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.cloudKit?.containerID == "iCloud.com.brightdigit.Bushel")
    }
  }

  // MARK: - Integer Parsing Tests

  @Suite("Integer Parsing")
  internal struct IntegerParsingTests {
    @Test("Valid integer from CLI")
    internal func testValidIntFromCLI() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync.min_interval=3600"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.minInterval == 3_600)
    }

    @Test("Valid integer from ENV")
    internal func testValidIntFromEnv() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_MIN_INTERVAL": "7200"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.minInterval == 7_200)
    }

    @Test("Invalid integer string returns nil")
    internal func testInvalidInt() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_MIN_INTERVAL": "not-a-number"]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.minInterval == nil)
    }

    @Test("Empty string for integer returns nil")
    internal func testEmptyInt() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_MIN_INTERVAL": ""]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.minInterval == nil)
    }
  }

  // MARK: - Double Parsing Tests

  @Suite("Double Parsing")
  internal struct DoubleParsingTests {
    @Test("Valid double from CLI")
    internal func testValidDoubleFromCLI() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["fetch.interval.appledb_dev=3600.5"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()
      let interval = config.fetch?.perSourceIntervals["appledb.dev"]
      #expect(interval == 3_600.5)
    }

    @Test("Invalid double string returns nil")
    internal func testInvalidDouble() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["FETCH_INTERVAL_APPLEDB_DEV": "invalid"]
      )

      let config = try await loader.loadConfiguration()
      let interval = config.fetch?.perSourceIntervals["appledb.dev"]
      #expect(interval == nil)
    }
  }

  // MARK: - CloudKit Configuration Tests

  @Suite("CloudKit Configuration")
  internal struct CloudKitConfigurationTests {
    @Test("Missing CloudKit key ID throws error")
    internal func testMissingKeyID() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
            // Missing CLOUDKIT_KEY_ID
        ]
      )

      let config = try await loader.loadConfiguration()

      // Should fail validation
      #expect(throws: ConfigurationError.self) {
        try config.validated()
      }
    }

    @Test("Missing CloudKit private key path throws error")
    internal func testMissingPrivateKeyPath() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key-id",
            // Missing CLOUDKIT_PRIVATE_KEY_PATH
        ]
      )

      let config = try await loader.loadConfiguration()

      #expect(throws: ConfigurationError.self) {
        try config.validated()
      }
    }

    @Test("All CloudKit fields present passes validation")
    internal func testAllCloudKitFieldsPresent() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key-id",
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      #expect(validated.cloudKit.containerID == "iCloud.com.test.App")
      #expect(validated.cloudKit.keyID == "test-key-id")
      #expect(validated.cloudKit.privateKeyPath == "/path/to/key.pem")
    }

    @Test("CloudKit privateKey from environment variable")
    internal func testPrivateKeyFromEnv() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key-id",
          "CLOUDKIT_PRIVATE_KEY":
            "-----BEGIN PRIVATE KEY-----\nMIGH...\n-----END PRIVATE KEY-----",
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      #expect(validated.cloudKit.privateKey != nil)
      #expect(validated.cloudKit.privateKey?.contains("BEGIN PRIVATE KEY") == true)
    }

    @Test(
      "CloudKit environment from environment variable",
      arguments: ["development", "production"]
    )
    internal func testEnvironmentFromEnv(environment: String) async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key-id",
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
          "CLOUDKIT_ENVIRONMENT": environment,
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      #expect(validated.cloudKit.environment.rawValue == environment)
    }

    @Test("Invalid CloudKit environment throws error")
    internal func testInvalidEnvironment() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key-id",
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
          "CLOUDKIT_ENVIRONMENT": "staging",  // Invalid
        ]
      )

      let config = try await loader.loadConfiguration()

      #expect(throws: ConfigurationError.self) {
        try config.validated()
      }
    }

    @Test("Missing both privateKey and privateKeyPath throws error")
    internal func testMissingBothCredentials() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key-id",
            // Missing both CLOUDKIT_PRIVATE_KEY and CLOUDKIT_PRIVATE_KEY_PATH
        ]
      )

      let config = try await loader.loadConfiguration()

      #expect(throws: ConfigurationError.self) {
        try config.validated()
      }
    }

    @Test("privateKey takes precedence over privateKeyPath when both are set")
    internal func testPrivateKeyPrecedence() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key-id",
          "CLOUDKIT_PRIVATE_KEY":
            "-----BEGIN PRIVATE KEY-----\nfrom-env\n-----END PRIVATE KEY-----",
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      // Both should be set in validated config
      #expect(validated.cloudKit.privateKey != nil)
      #expect(!validated.cloudKit.privateKeyPath.isEmpty)
      // SyncEngine will prefer privateKey when initializing
    }

    @Test("Empty CLOUDKIT_PRIVATE_KEY is treated as absent")
    internal func testEmptyPrivateKeyIsAbsent() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key-id",
          "CLOUDKIT_PRIVATE_KEY": "   ",  // Whitespace only
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      // Should use privateKeyPath since privateKey is effectively empty
      #expect(validated.cloudKit.privateKey == nil)
      #expect(!validated.cloudKit.privateKeyPath.isEmpty)
    }

    @Test("Environment parsing is case-insensitive")
    internal func testEnvironmentCaseInsensitive() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key-id",
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
          "CLOUDKIT_ENVIRONMENT": "Production",  // Mixed case
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      #expect(validated.cloudKit.environment == .production)
    }

    @Test("All CloudKit fields present with privateKey passes validation")
    internal func testAllCloudKitFieldsWithPrivateKey() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key-id",
          "CLOUDKIT_PRIVATE_KEY":
            "-----BEGIN PRIVATE KEY-----\ntest\n-----END PRIVATE KEY-----",
          "CLOUDKIT_ENVIRONMENT": "production",
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      #expect(validated.cloudKit.containerID == "iCloud.com.test.App")
      #expect(validated.cloudKit.keyID == "test-key-id")
      #expect(validated.cloudKit.privateKey != nil)
      #expect(validated.cloudKit.environment == .production)
    }
  }

  // MARK: - Command Configuration Tests

  @Suite("Command Configurations")
  internal struct CommandConfigurationTests {
    @Test("Sync configuration uses defaults when not provided")
    internal func testSyncDefaults() async throws {
      let loader = ConfigurationLoaderTests.createLoader(cliArgs: [], env: [:])

      let config = try await loader.loadConfiguration()

      #expect(config.sync?.dryRun == false)
      #expect(config.sync?.verbose == false)
      #expect(config.sync?.force == false)
      #expect(config.sync?.minInterval == nil)
    }

    @Test("Export configuration from CLI arguments")
    internal func testExportFromCLI() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [
          "export.output=/tmp/export.json",
          "export.pretty",
          "export.signed_only",
        ],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.export?.output == "/tmp/export.json")
      #expect(config.export?.pretty == true)
      #expect(config.export?.signedOnly == true)
    }

    @Test("Multiple command configurations coexist")
    internal func testMultipleCommandConfigs() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [
          "sync.verbose",
          "export.pretty",
          "list.restore_images",
        ],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.sync?.verbose == true)
      #expect(config.export?.pretty == true)
      #expect(config.list?.restoreImages == true)
    }
  }

  // MARK: - Integration Tests

  @Suite("Integration Tests")
  internal struct IntegrationTests {
    @Test("Complete sync configuration from multiple sources")
    internal func testCompleteSyncConfig() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [
          "sync.verbose",
          "sync.dry_run",
          "sync.min_interval=3600",
        ],
        env: [
          "BUSHEL_SYNC_NO_BETAS": "true",
          "BUSHEL_SYNC_SOURCE": "ipsw.me",
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": "test-key",
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
        ]
      )

      let config = try await loader.loadConfiguration()

      // From CLI
      #expect(config.sync?.verbose == true)
      #expect(config.sync?.dryRun == true)
      #expect(config.sync?.minInterval == 3_600)

      // From ENV
      #expect(config.sync?.noBetas == true)
      #expect(config.sync?.source == "ipsw.me")

      // CloudKit from ENV
      #expect(config.cloudKit?.containerID == "iCloud.com.test.App")
    }

    @Test("Fetch configuration with per-source intervals")
    internal func testFetchPerSourceIntervals() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "FETCH_INTERVAL_APPLEDB_DEV": "7200",
          "FETCH_INTERVAL_IPSW_ME": "10800",
        ]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.fetch?.perSourceIntervals["appledb.dev"] == 7_200)
      #expect(config.fetch?.perSourceIntervals["ipsw.me"] == 10_800)
    }
  }

  // MARK: - Test Utilities

  /// Create a ConfigurationLoader with simulated CLI args and environment variables
  ///
  /// - Parameters:
  ///   - cliArgs: Simulated CLI arguments (format: "key=value" or "key" for flags)
  ///   - env: Simulated environment variables
  /// - Returns: ConfigurationLoader with controlled inputs
  private static func createLoader(
    cliArgs: [String],
    env: [String: String]
  ) -> ConfigurationLoader {
    // Parse CLI args: "key=value" or "key" for flags
    var cliValues: [AbsoluteConfigKey: ConfigValue] = [:]
    for arg in cliArgs {
      if arg.contains("=") {
        let parts = arg.split(separator: "=", maxSplits: 1)
        if parts.count == 2 {
          let key = AbsoluteConfigKey(stringLiteral: String(parts[0]))
          cliValues[key] = .init(.string(String(parts[1])), isSecret: false)
        }
      } else {
        // Flag presence (boolean)
        let key = AbsoluteConfigKey(stringLiteral: arg)
        cliValues[key] = .init(.string("true"), isSecret: false)
      }
    }

    // ENV vars as-is
    var envValues: [AbsoluteConfigKey: ConfigValue] = [:]
    for (key, value) in env {
      let configKey = AbsoluteConfigKey(stringLiteral: key)
      envValues[configKey] = .init(.string(value), isSecret: false)
    }

    let providers: [any ConfigProvider] = [
      InMemoryProvider(values: cliValues),  // Priority 1: CLI
      InMemoryProvider(values: envValues),  // Priority 2: ENV
    ]

    let configReader = ConfigReader(providers: providers)
    return ConfigurationLoader(configReader: configReader)
  }
}
