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

internal import ConfigKeyKit
internal import Configuration
internal import Foundation
internal import SystemPackage

/// Swift Configuration-based setup for MistDemo.
///
/// Wraps a `ConfigReader` and resolves ``MistDemoKeys`` values through ConfigKeyKit's
/// ``ConfigValueReading``, which consults the command line first and then the
/// environment before falling back to each key's own default.
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

    // No `prefixKeys(with: "cloudkit")`: the `CLOUDKIT_` namespace now rides on each
    // key via `envPrefix` (or a `cloudkit.` base), so prefixing here would produce
    // `CLOUDKIT_CLOUDKIT_*`. No `InMemoryProvider` either — defaults live on the keys.
    self.configReader = ConfigReader(providers: [
      CommandLineArgumentsProvider(),
      EnvironmentVariablesProvider(),
      envProvider,
    ])
  }

  /// Creates an instance over an injected reader.
  ///
  /// Tests use this with the real providers over injected argv/environment, so key
  /// normalization and value coercion behave exactly as they do in production.
  internal init(configReader: ConfigReader) {
    self.configReader = configReader
  }

  // MARK: Internal

  /// Reads a required string value.
  internal func read(_ key: ConfigKeyKit.ConfigKey<String>) -> String { configReader.read(key) }

  /// Reads an optional string value.
  internal func read(_ key: ConfigKeyKit.OptionalConfigKey<String>) -> String? {
    configReader.read(key)
  }

  /// Reads a required integer value.
  internal func read(_ key: ConfigKeyKit.ConfigKey<Int>) -> Int { configReader.read(key) }

  /// Reads an optional integer value.
  internal func read(_ key: ConfigKeyKit.OptionalConfigKey<Int>) -> Int? { configReader.read(key) }

  /// Reads a required boolean value.
  ///
  /// Deliberately **not** ConfigKeyKit's `read(_:)`: that resolves booleans by probing
  /// `string(forKey:)`, and swift-configuration's CLI provider surfaces a valueless flag
  /// only through `bool(forKey:)`. Routing through the string path would make every bare
  /// flag (`--force`, `--stdin`, `--verbose`, …) silently read as its default.
  internal func read(_ key: ConfigKeyKit.ConfigKey<Bool>) -> Bool {
    resolveBool(key) ?? key.defaultValue
  }

  // swiftlint:disable:next discouraged_optional_boolean
  /// Reads an optional boolean, distinguishing "flag absent" from an explicit `false`.
  internal func read(_ key: ConfigKeyKit.OptionalConfigKey<Bool>) -> Bool? {
    resolveBool(key)
  }

  /// Reads a comma-separated list, or `nil` when the key is absent.
  internal func commaSeparatedList(_ key: ConfigKeyKit.OptionalConfigKey<String>) -> [String]? {
    read(key)?
      .split(separator: ",")
      .map { String($0).trimmingCharacters(in: .whitespaces) }
  }

  /// Reads a pipe-separated list, empty when the key is absent.
  internal func filterStrings(_ key: ConfigKeyKit.OptionalConfigKey<String>) -> [String] {
    read(key)?
      .split(separator: "|")
      .map { String($0).trimmingCharacters(in: .whitespaces) } ?? []
  }

  // MARK: Private

  // swiftlint:disable:next discouraged_optional_boolean
  /// Resolves a boolean across sources via `bool(forKey:)`, which reports a valueless
  /// command-line flag as `true`, an absent key as `nil`, and `false`/`no`/`0` as `false`.
  private func resolveBool(_ key: any ConfigurationKey) -> Bool? {
    for source in ConfigKeySource.priority {
      guard let keyString = key.key(for: source) else { continue }
      if let value = configReader.bool(forKey: Configuration.ConfigKey(keyString)) {
        return value
      }
    }
    return nil
  }
}
