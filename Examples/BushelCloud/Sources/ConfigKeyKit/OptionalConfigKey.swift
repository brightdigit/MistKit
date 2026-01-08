//
//  OptionalConfigKey.swift
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

import Foundation

// MARK: - Optional Configuration Key

/// Configuration key for optional values without defaults
///
/// Use `OptionalConfigKey` when a configuration value has no sensible default
/// and should be `nil` when not provided by the user. The `read()` method
/// will return an optional value.
///
/// Example:
/// ```swift
/// let apiKey = OptionalConfigKey<String>(base: "api.key")
/// // read(apiKey) returns String?
/// ```
public struct OptionalConfigKey<Value: Sendable>: ConfigurationKey, Sendable {
  private let baseKey: String?
  private let styles: [ConfigKeySource: any NamingStyle]
  private let explicitKeys: [ConfigKeySource: String]

  /// Initialize with explicit CLI and ENV keys (no default)
  public init(cli: String? = nil, env: String? = nil) {
    self.baseKey = nil
    self.styles = [:]
    var keys: [ConfigKeySource: String] = [:]
    if let cli = cli { keys[.commandLine] = cli }
    if let env = env { keys[.environment] = env }
    self.explicitKeys = keys
  }

  /// Initialize from a base key string with naming styles (no default)
  /// - Parameters:
  ///   - base: Base key string (e.g., "cloudkit.key_id")
  ///   - styles: Dictionary mapping sources to naming styles
  public init(
    base: String,
    styles: [ConfigKeySource: any NamingStyle]
  ) {
    self.baseKey = base
    self.styles = styles
    self.explicitKeys = [:]
  }

  /// Convenience initializer with standard naming conventions (no default)
  /// - Parameters:
  ///   - base: Base key string (e.g., "cloudkit.key_id")
  ///   - envPrefix: Prefix for environment variable (defaults to nil)
  public init(_ base: String, envPrefix: String? = nil) {
    self.baseKey = base
    self.styles = [
      .commandLine: StandardNamingStyle.dotSeparated,
      .environment: StandardNamingStyle.screamingSnakeCase(prefix: envPrefix),
    ]
    self.explicitKeys = [:]
  }

  public func key(for source: ConfigKeySource) -> String? {
    // Check for explicit key first
    if let explicit = explicitKeys[source] {
      return explicit
    }

    // Generate from base key and style
    guard let base = baseKey, let style = styles[source] else {
      return nil
    }

    return style.transform(base)
  }
}

extension OptionalConfigKey: CustomDebugStringConvertible {
  public var debugDescription: String {
    let cliKey = key(for: .commandLine) ?? "nil"
    let envKey = key(for: .environment) ?? "nil"
    return "OptionalConfigKey(cli: \(cliKey), env: \(envKey))"
  }
}

// MARK: - Convenience Initializers for BUSHEL Prefix

extension OptionalConfigKey {
  /// Convenience initializer for keys with BUSHEL prefix
  /// - Parameter base: Base key string (e.g., "sync.min_interval")
  public init(bushelPrefixed base: String) {
    self.init(base, envPrefix: "BUSHEL")
  }
}
