//
//  ConfigurationLoader.swift
//  CelestraCloud
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

internal import ConfigKeyKit
internal import Configuration
internal import Foundation
internal import MistKit

/// Loads and merges configuration from multiple sources
public actor ConfigurationLoader {
  private let configReader: ConfigReader

  /// Creates a new configuration loader with default providers.
  public init() {
    var providers: [any ConfigProvider] = []

    // Priority 1: Command-line arguments (highest)
    providers.append(
      CommandLineArgumentsProvider(
        secretsSpecifier: .specific(
          [
            "--cloudkit-key-id",
            "--cloudkit-private-key-path",
          ]
        )
      )
    )

    // Priority 2: Environment variables
    providers.append(EnvironmentVariablesProvider())

    self.configReader = ConfigReader(providers: providers)
  }

  /// Load complete configuration with all defaults applied
  public func loadConfiguration() async throws -> CelestraConfiguration {
    // CloudKit configuration (automatic CLI → ENV → default fallback)
    let cloudkit = CloudKitConfiguration(
      containerID: read(ConfigurationKeys.CloudKit.containerID),
      keyID: read(ConfigurationKeys.CloudKit.keyID),
      privateKeyPath: read(ConfigurationKeys.CloudKit.privateKeyPath),
      environment: parseEnvironment(read(ConfigurationKeys.CloudKit.environment))
    )

    // Update command configuration
    let update = UpdateCommandConfiguration(
      delay: read(ConfigurationKeys.Update.delay),
      skipRobotsCheck: read(ConfigurationKeys.Update.skipRobotsCheck),
      maxFailures: read(ConfigurationKeys.Update.maxFailures),
      minPopularity: read(ConfigurationKeys.Update.minPopularity),
      lastAttemptedBefore: read(ConfigurationKeys.Update.lastAttemptedBefore),
      limit: read(ConfigurationKeys.Update.limit),
      jsonOutputPath: read(ConfigurationKeys.Update.jsonOutputPath)
    )

    return CelestraConfiguration(
      cloudkit: cloudkit,
      update: update
    )
  }

  // MARK: - Per-key-string Primitives

  private func readString(forKey key: String) -> String? {
    configReader.string(forKey: ConfigKey(key))
  }

  private func readInt(forKey key: String) -> Int? {
    configReader.int(forKey: ConfigKey(key))
  }

  private func readDate(forKey key: String) -> Date? {
    // Swift Configuration automatically converts ISO8601 strings to Date
    configReader.string(forKey: ConfigKey(key), as: Date.self)
  }

  private func parseEnvironment(_ value: String?) -> MistKit.Environment {
    guard let value = value?.lowercased() else {
      return .development
    }
    return value == "production" ? .production : .development
  }

  // MARK: - Generic ConfigKey Helpers (required default → non-optional)

  /// Read a string value with automatic CLI → ENV → default fallback.
  private func read(_ key: ConfigKeyKit.ConfigKey<String>) -> String {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readString(forKey: keyString) {
        return value
      }
    }
    return key.defaultValue
  }

  /// Read a double value with automatic CLI → ENV → default fallback.
  private func read(_ key: ConfigKeyKit.ConfigKey<Double>) -> Double {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let stringValue = readString(forKey: keyString), let value = Double(stringValue) {
        return value
      }
    }
    return key.defaultValue
  }

  /// Read a boolean value with CLI flag-presence and ENV string parsing.
  ///
  /// - CLI: flag presence indicates `true` (e.g. `--update-skip-robots-check`).
  /// - ENV: accepts `true`/`1`/`yes` (case-insensitive); anything else is `false`.
  /// - Otherwise: the key's default.
  private func read(_ key: ConfigKeyKit.ConfigKey<Bool>) -> Bool {
    if let cliKey = key.key(for: .commandLine),
      configReader.string(forKey: ConfigKey(cliKey)) != nil
    {
      return true
    }

    if let envKey = key.key(for: .environment),
      let envValue = configReader.string(forKey: ConfigKey(envKey))
    {
      let lowercased = envValue.lowercased().trimmingCharacters(in: .whitespaces)
      return lowercased == "true" || lowercased == "1" || lowercased == "yes"
    }

    return key.defaultValue
  }

  // MARK: - Generic OptionalConfigKey Helpers (no default → optional)

  /// Read a string value with automatic CLI → ENV fallback.
  private func read(_ key: ConfigKeyKit.OptionalConfigKey<String>) -> String? {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readString(forKey: keyString) {
        return value
      }
    }
    return nil
  }

  /// Read an integer value with automatic CLI → ENV fallback.
  private func read(_ key: ConfigKeyKit.OptionalConfigKey<Int>) -> Int? {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readInt(forKey: keyString) {
        return value
      }
    }
    return nil
  }

  /// Read a date value (ISO8601) with automatic CLI → ENV fallback.
  private func read(_ key: ConfigKeyKit.OptionalConfigKey<Date>) -> Date? {
    for source in ConfigKeySource.allCases {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readDate(forKey: keyString) {
        return value
      }
    }
    return nil
  }
}
