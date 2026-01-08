//
//  ConfigKey.swift
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

// MARK: - Generic Configuration Key

/// Configuration key for values with default fallbacks
///
/// Use `ConfigKey` when a configuration value has a sensible default
/// that should be used when not provided by the user. The `read()` method
/// will always return a non-optional value.
///
/// Example:
/// ```swift
/// let containerID = ConfigKey<String>(
///   base: "cloudkit.container_id",
///   default: "iCloud.com.brightdigit.Bushel"
/// )
/// // read(containerID) returns String (non-optional)
/// ```
public struct ConfigKey<Value: Sendable>: ConfigurationKey, Sendable {
  private let baseKey: String?
  private let styles: [ConfigKeySource: any NamingStyle]
  private let explicitKeys: [ConfigKeySource: String]
  public let defaultValue: Value  // Non-optional!

  /// Initialize with explicit CLI and ENV keys and required default
  public init(cli: String? = nil, env: String? = nil, default defaultVal: Value) {
    self.baseKey = nil
    self.styles = [:]
    var keys: [ConfigKeySource: String] = [:]
    if let cli = cli { keys[.commandLine] = cli }
    if let env = env { keys[.environment] = env }
    self.explicitKeys = keys
    self.defaultValue = defaultVal
  }

  /// Initialize from a base key string with naming styles and required default
  /// - Parameters:
  ///   - base: Base key string (e.g., "cloudkit.container_id")
  ///   - styles: Dictionary mapping sources to naming styles
  ///   - defaultVal: Required default value
  public init(
    base: String,
    styles: [ConfigKeySource: any NamingStyle],
    default defaultVal: Value
  ) {
    self.baseKey = base
    self.styles = styles
    self.explicitKeys = [:]
    self.defaultValue = defaultVal
  }

  /// Convenience initializer with standard naming conventions and required default
  /// - Parameters:
  ///   - base: Base key string (e.g., "cloudkit.container_id")
  ///   - envPrefix: Prefix for environment variable (defaults to nil)
  ///   - defaultVal: Required default value
  public init(_ base: String, envPrefix: String? = nil, default defaultVal: Value) {
    self.baseKey = base
    self.styles = [
      .commandLine: StandardNamingStyle.dotSeparated,
      .environment: StandardNamingStyle.screamingSnakeCase(prefix: envPrefix),
    ]
    self.explicitKeys = [:]
    self.defaultValue = defaultVal
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

extension ConfigKey: CustomDebugStringConvertible {
  public var debugDescription: String {
    let cliKey = key(for: .commandLine) ?? "nil"
    let envKey = key(for: .environment) ?? "nil"
    return "ConfigKey(cli: \(cliKey), env: \(envKey), default: \(defaultValue))"
  }
}

// MARK: - Convenience Initializers for BUSHEL Prefix

extension ConfigKey {
  /// Convenience initializer for keys with BUSHEL prefix
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.dry_run")
  ///   - defaultVal: Required default value
  public init(bushelPrefixed base: String, default defaultVal: Value) {
    self.init(base, envPrefix: "BUSHEL", default: defaultVal)
  }
}

// MARK: - Specialized Initializers for Booleans

extension ConfigKey where Value == Bool {
  /// Non-optional default value accessor for booleans
  @available(*, deprecated, message: "Use defaultValue directly instead")
  public var boolDefault: Bool {
    defaultValue  // Already non-optional!
  }

  /// Initialize a boolean configuration key with non-optional default
  /// - Parameters:
  ///   - cli: Command-line argument name
  ///   - env: Environment variable name
  ///   - defaultVal: Default value (defaults to false)
  public init(cli: String, env: String, default defaultVal: Bool = false) {
    self.baseKey = nil
    self.styles = [:]
    var keys: [ConfigKeySource: String] = [:]
    keys[.commandLine] = cli
    keys[.environment] = env
    self.explicitKeys = keys
    self.defaultValue = defaultVal
  }

  /// Initialize a boolean configuration key from base string
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.verbose")
  ///   - envPrefix: Prefix for environment variable (defaults to nil)
  ///   - defaultVal: Default value (defaults to false)
  public init(_ base: String, envPrefix: String? = nil, default defaultVal: Bool = false) {
    self.baseKey = base
    self.styles = [
      .commandLine: StandardNamingStyle.dotSeparated,
      .environment: StandardNamingStyle.screamingSnakeCase(prefix: envPrefix),
    ]
    self.explicitKeys = [:]
    self.defaultValue = defaultVal
  }
}

// MARK: - BUSHEL Prefix Convenience

extension ConfigKey where Value == Bool {
  /// Convenience initializer for boolean keys with BUSHEL prefix
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.verbose")
  ///   - defaultVal: Default value (defaults to false)
  public init(bushelPrefixed base: String, default defaultVal: Bool = false) {
    self.init(base, envPrefix: "BUSHEL", default: defaultVal)
  }
}
