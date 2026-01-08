//
//  ConfigurationLoader.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
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

/// Loads and merges configuration from multiple sources
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
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
    // CloudKit configuration
    let cloudkit = CloudKitConfiguration(
      containerID: readString(forKey: ConfigurationKeys.CloudKit.containerID)
        ?? readString(forKey: ConfigurationKeys.CloudKit.containerIDEnv)
        ?? CloudKitConfiguration.defaultContainerID,
      keyID: readString(forKey: ConfigurationKeys.CloudKit.keyID)
        ?? readString(forKey: ConfigurationKeys.CloudKit.keyIDEnv),
      privateKeyPath: readString(forKey: ConfigurationKeys.CloudKit.privateKeyPath)
        ?? readString(forKey: ConfigurationKeys.CloudKit.privateKeyPathEnv),
      environment: parseEnvironment(
        readString(forKey: ConfigurationKeys.CloudKit.environment)
          ?? readString(forKey: ConfigurationKeys.CloudKit.environmentEnv)
      )
    )

    // Update command configuration
    let delay =
      readDouble(forKey: ConfigurationKeys.Update.delay)
      ?? readDouble(forKey: ConfigurationKeys.Update.delayEnv)
      ?? 2.0
    let skipRobotsCheck =
      readBool(forKey: ConfigurationKeys.Update.skipRobotsCheck)
      ?? readBool(forKey: ConfigurationKeys.Update.skipRobotsCheckEnv)
      ?? false
    let maxFailures =
      readInt(forKey: ConfigurationKeys.Update.maxFailures)
      ?? readInt(forKey: ConfigurationKeys.Update.maxFailuresEnv)
    let minPopularity =
      readInt(forKey: ConfigurationKeys.Update.minPopularity)
      ?? readInt(forKey: ConfigurationKeys.Update.minPopularityEnv)
    let lastAttemptedBefore =
      readDate(forKey: ConfigurationKeys.Update.lastAttemptedBefore)
      ?? readDate(forKey: ConfigurationKeys.Update.lastAttemptedBeforeEnv)
    let limit =
      readInt(forKey: ConfigurationKeys.Update.limit)
      ?? readInt(forKey: ConfigurationKeys.Update.limitEnv)
    let jsonOutputPath =
      readString(forKey: ConfigurationKeys.Update.jsonOutputPath)
      ?? readString(forKey: ConfigurationKeys.Update.jsonOutputPathEnv)

    let update = UpdateCommandConfiguration(
      delay: delay,
      skipRobotsCheck: skipRobotsCheck,
      maxFailures: maxFailures,
      minPopularity: minPopularity,
      lastAttemptedBefore: lastAttemptedBefore,
      limit: limit,
      jsonOutputPath: jsonOutputPath
    )

    return CelestraConfiguration(
      cloudkit: cloudkit,
      update: update
    )
  }

  // MARK: - Private Helpers

  private func readString(forKey key: String) -> String? {
    configReader.string(forKey: ConfigKey(key))
  }

  private func readDouble(forKey key: String) -> Double? {
    configReader.double(forKey: ConfigKey(key))
  }

  // swiftlint:disable:next discouraged_optional_boolean
  private func readBool(forKey key: String) -> Bool? {
    configReader.bool(forKey: ConfigKey(key))
  }

  private func readInt(forKey key: String) -> Int? {
    configReader.int(forKey: ConfigKey(key))
  }

  private func parseEnvironment(_ value: String?) -> MistKit.Environment {
    guard let value = value?.lowercased() else {
      return .development
    }
    return value == "production" ? .production : .development
  }

  private func readDate(forKey key: String) -> Date? {
    // Swift Configuration automatically converts ISO8601 strings to Date
    configReader.string(forKey: ConfigKey(key), as: Date.self)
  }
}
