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
            "--cloudkit-private-key",
          ]
        )
      )
    )

    // Priority 2: Environment variables
    providers.append(EnvironmentVariablesProvider())

    self.configReader = ConfigReader(providers: providers)
  }

  /// Creates a loader over a pre-configured reader.
  ///
  /// Lets tests inject controlled configuration sources instead of mutating
  /// process-global environment variables.
  /// - Parameter configReader: Pre-configured reader to read from.
  internal init(configReader: ConfigReader) {
    self.configReader = configReader
  }

  /// Parses a CloudKit environment string, defaulting to `.development` when absent.
  ///
  /// An unrecognized value throws rather than silently degrading — a typo'd
  /// `CLOUDKIT_ENVIRONMENT` must not quietly run against the development
  /// container.
  private static func parseEnvironment(
    _ value: String?
  ) throws -> MistKit.Environment {
    guard let value else {
      return .development
    }
    guard let environment = MistKit.Environment(caseInsensitive: value) else {
      throw ConfigurationError(
        "Invalid CLOUDKIT_ENVIRONMENT: '\(value)'. Must be 'development' or 'production'",
        key: "cloudkit.environment"
      )
    }
    return environment
  }

  /// Load complete configuration with all defaults applied
  public func loadConfiguration() async throws -> CelestraConfiguration {
    // CloudKit configuration (automatic CLI → ENV → default fallback)
    let cloudkit = CloudKitConfiguration(
      containerID: configReader.read(ConfigurationKeys.CloudKit.containerID),
      keyID: configReader.read(ConfigurationKeys.CloudKit.keyID),
      privateKeyPath: configReader.read(ConfigurationKeys.CloudKit.privateKeyPath),
      privateKey: configReader.read(ConfigurationKeys.CloudKit.privateKey),
      environment: try Self.parseEnvironment(
        configReader.read(ConfigurationKeys.CloudKit.environment)
      )
    )

    // Update command configuration
    let update = UpdateCommandConfiguration(
      delay: configReader.read(ConfigurationKeys.Update.delay),
      skipRobotsCheck: configReader.read(ConfigurationKeys.Update.skipRobotsCheck),
      maxFailures: configReader.read(ConfigurationKeys.Update.maxFailures),
      minPopularity: configReader.read(ConfigurationKeys.Update.minPopularity),
      lastAttemptedBefore: configReader.read(ConfigurationKeys.Update.lastAttemptedBefore),
      limit: configReader.read(ConfigurationKeys.Update.limit),
      jsonOutputPath: configReader.read(ConfigurationKeys.Update.jsonOutputPath)
    )

    return CelestraConfiguration(
      cloudkit: cloudkit,
      update: update
    )
  }
}
