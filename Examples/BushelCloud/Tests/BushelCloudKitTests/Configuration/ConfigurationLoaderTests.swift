//
//  ConfigurationLoaderTests.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Configuration
internal import Foundation
internal import MistKit
internal import MistKitConfiguration
internal import Testing

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

    @Test("ENV var with surrounding whitespace is ignored (falls to default)")
    internal func testEnvWhitespace() async throws {
      // ConfigKeyKit#8: only exact "true"/"1"/"yes" (case-insensitive) are truthy;
      // padded values are unrecognized and fall through to the key's default.
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: ["BUSHEL_SYNC_VERBOSE": "  true  "]
      )

      let config = try await loader.loadConfiguration()
      #expect(config.sync?.verbose == false)
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
        cliArgs: ["cloudkit.container-id=iCloud.com.test.App"],
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
        cliArgs: ["cloudkit.container-id=iCloud.com.cli.App"],
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
        cliArgs: ["sync.min-interval=3600"],
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
          "CLOUDKIT_KEY_ID": ConfigurationLoaderTests.validKeyID,
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
          "CLOUDKIT_KEY_ID": ConfigurationLoaderTests.validKeyID,
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      #expect(validated.cloudKit.containerID == "iCloud.com.test.App")
      #expect(validated.cloudKit.keyID == ConfigurationLoaderTests.validKeyID)
      #expect(validated.cloudKit.privateKey.filePath == "/path/to/key.pem")
    }

    @Test("CloudKit privateKey from environment variable")
    internal func testPrivateKeyFromEnv() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": ConfigurationLoaderTests.validKeyID,
          "CLOUDKIT_PRIVATE_KEY":
            ConfigurationLoaderTests.validPEM,
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      guard case .raw(let pem) = validated.cloudKit.privateKey else {
        Issue.record("expected inline PEM material")
        return
      }
      #expect(pem.contains("BEGIN PRIVATE KEY"))
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
          "CLOUDKIT_KEY_ID": ConfigurationLoaderTests.validKeyID,
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
          "CLOUDKIT_KEY_ID": ConfigurationLoaderTests.validKeyID,
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
          "CLOUDKIT_KEY_ID": ConfigurationLoaderTests.validKeyID,
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
          "CLOUDKIT_KEY_ID": ConfigurationLoaderTests.validKeyID,
          "CLOUDKIT_PRIVATE_KEY": ConfigurationLoaderTests.validPEM,
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      // Both should be set in validated config
      // Inline PEM wins over a path when both are supplied.
      #expect(validated.cloudKit.privateKey.filePath == nil)
    }

    @Test("Empty CLOUDKIT_PRIVATE_KEY is treated as absent")
    internal func testEmptyPrivateKeyIsAbsent() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": ConfigurationLoaderTests.validKeyID,
          "CLOUDKIT_PRIVATE_KEY": "   ",  // Whitespace only
          "CLOUDKIT_PRIVATE_KEY_PATH": "/path/to/key.pem",
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      // Falls back to the path, since the inline key is effectively empty.
      #expect(validated.cloudKit.privateKey.filePath?.isEmpty == false)
    }

    @Test("Environment parsing is case-insensitive")
    internal func testEnvironmentCaseInsensitive() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [],
        env: [
          "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.App",
          "CLOUDKIT_KEY_ID": ConfigurationLoaderTests.validKeyID,
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
          "CLOUDKIT_KEY_ID": ConfigurationLoaderTests.validKeyID,
          "CLOUDKIT_PRIVATE_KEY":
            ConfigurationLoaderTests.validPEM,
          "CLOUDKIT_ENVIRONMENT": "production",
        ]
      )

      let config = try await loader.loadConfiguration()
      let validated = try config.validated()

      #expect(validated.cloudKit.containerID == "iCloud.com.test.App")
      #expect(validated.cloudKit.keyID == ConfigurationLoaderTests.validKeyID)
      #expect(validated.cloudKit.privateKey.filePath == nil)
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
          "export.signed-only",
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
          "list.restore-images",
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
          "sync.dry-run",
          "sync.min-interval=3600",
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

  /// Creates a loader backed by the same providers production uses, with
  /// their inputs injected instead of read from the process.
  ///
  /// Using `CommandLineArgumentsProvider` and `EnvironmentVariablesProvider`
  /// rather than `InMemoryProvider` keeps the double faithful on two behaviors
  /// the tests depend on: the environment provider normalizes `-` and `.` to
  /// `_` when encoding a key (so `CLOUDKIT_KEY-ID`, generated from the
  /// dash-case base `cloudkit.key-id`, resolves from a `CLOUDKIT_KEY_ID`
  /// variable), and both providers coerce their string-shaped input on demand
  /// (so one variable answers `string`, `int` and `double` reads).
  /// `InMemoryProvider` does neither — it matches keys literally and serves
  /// only the stored case.
  ///
  /// - Parameters:
  ///   - cliArgs: Simulated CLI arguments (format: "key=value", or "key" for flags).
  ///   - env: Simulated environment variables.
  /// - Returns: A loader reading from those inputs only.
  private static func createLoader(
    cliArgs: [String],
    env: [String: String]
  ) -> ConfigurationLoader {
    // Rebuild an argv from "key=value" / "key" (flag presence) entries.
    //
    // A bare `--flag` is spelled `--flag true` here. `CommandLineArgumentsProvider`
    // reports a valueless flag through `bool(forKey:)` but not `string(forKey:)`,
    // and ConfigKeyKit's boolean resolution detects flag presence via the string
    // read — so a truly bare flag resolves to its default. That gap predates the
    // `ConfigValueReading` migration (the hand-rolled `read(ConfigKey<Bool>)`
    // these tests previously exercised used the same string-based check); it was
    // masked because the former `InMemoryProvider` double stored flags as
    // `.string("true")`. Passing the value explicitly keeps these tests on the
    // path that works. See the follow-up issue on valueless-flag support.
    var arguments: [String] = ["bushel-cloud"]
    for arg in cliArgs {
      let parts = arg.split(separator: "=", maxSplits: 1)
      arguments.append("--" + parts[0].replacingOccurrences(of: ".", with: "-"))
      arguments.append(parts.count == 2 ? String(parts[1]) : "true")
    }

    let providers: [any ConfigProvider] = [
      CommandLineArgumentsProvider(arguments: arguments),  // Priority 1: CLI
      EnvironmentVariablesProvider(environmentVariables: env),  // Priority 2: ENV
    ]

    let configReader = ConfigReader(providers: providers)
    return ConfigurationLoader(configReader: configReader)
  }
}
