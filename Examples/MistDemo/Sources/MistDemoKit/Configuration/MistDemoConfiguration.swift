//
//  MistDemoConfiguration.swift
//  MistDemo
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
internal import SystemPackage

/// Swift Configuration-based setup for MistDemo.
public struct MistDemoConfiguration: Sendable {
  // MARK: Private

  private let configReader: ConfigReader

  // MARK: Lifecycle

  /// Creates a new instance from environment and CLI providers.
  public init() async throws {
    let envProvider = try await EnvironmentVariablesProvider(
      environmentFilePath: FilePath(".env"),
      allowMissing: true
    )

    self.configReader = ConfigReader(providers: [
      // 1. Command line arguments (highest priority)
      CommandLineArgumentsProvider(),

      // 2. Process environment variables (CLOUDKIT_ prefix)
      EnvironmentVariablesProvider().prefixKeys(with: "cloudkit"),

      // 3. .env file variables (CLOUDKIT_ prefix)
      envProvider.prefixKeys(with: "cloudkit"),

      // 4. In-memory defaults (lowest priority)
      InMemoryProvider(values: [
        "port": 8_080,
        "skip.auth": false,
        "test.all.auth": false,
        "test.api.only": false,
        "test.adaptive": false,
        "test.server.to.server": false,
      ]),
    ])
  }

  /// Internal initializer for testing with InMemoryProvider.
  internal init(testProvider: InMemoryProvider) {
    self.configReader = ConfigReader(providers: [
      testProvider
    ])
  }

  // MARK: Public

  /// Read string value with hierarchy: CLI -> ENV -> defaults.
  public func string(
    forKey key: String,
    default defaultValue: String? = nil,
    isSecret: Bool = false
  ) -> String? {
    if let defaultValue = defaultValue {
      return configReader.string(
        forKey: Configuration.ConfigKey(key),
        isSecret: isSecret,
        default: defaultValue
      )
    } else {
      return configReader.string(
        forKey: Configuration.ConfigKey(key),
        isSecret: isSecret
      )
    }
  }

  /// Read required string value.
  public func requiredString(
    forKey key: String,
    isSecret: Bool = false
  ) throws -> String {
    try configReader.requiredString(
      forKey: Configuration.ConfigKey(key),
      isSecret: isSecret
    )
  }

  /// Read int value with hierarchy.
  public func int(
    forKey key: String,
    default defaultValue: Int? = nil
  ) -> Int? {
    if let defaultValue = defaultValue {
      return configReader.int(
        forKey: Configuration.ConfigKey(key),
        default: defaultValue
      )
    } else {
      return configReader.int(
        forKey: Configuration.ConfigKey(key)
      )
    }
  }

  /// Read required int value.
  public func requiredInt(forKey key: String) throws -> Int {
    try configReader.requiredInt(
      forKey: Configuration.ConfigKey(key)
    )
  }

  /// Read bool value with hierarchy.
  public func bool(
    forKey key: String,
    default defaultValue: Bool = false
  ) -> Bool {
    configReader.bool(
      forKey: Configuration.ConfigKey(key),
      default: defaultValue
    )
  }

  /// Read an optional bool: `nil` when the key is absent, else its parsed value.
  ///
  /// Distinguishes "flag not provided" (`nil` → omit from the request) from an
  /// explicit `false`, unlike `bool(forKey:default:)` which collapses both.
  public func optionalBool(forKey key: String) -> Bool? {
    string(forKey: key) != nil ? bool(forKey: key) : nil
  }

  /// Read a comma-separated list of strings, or `nil` when the key is absent.
  public func commaSeparatedList(forKey key: String) -> [String]? {
    string(forKey: key)?
      .split(separator: ",")
      .map { String($0).trimmingCharacters(in: .whitespaces) }
  }

  /// Read a pipe-separated list of strings from configuration.
  public func filterStrings(forKey key: String) -> [String] {
    string(forKey: key)?
      .split(separator: "|")
      .map { String($0).trimmingCharacters(in: .whitespaces) } ?? []
  }
}
