//
//  ConfigKey.swift
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
///   default: "iCloud.com.example.MyApp"
/// )
/// // read(containerID) returns String (non-optional)
/// ```
public struct ConfigKey<Value: Sendable>: ConfigurationKey, Sendable {
  internal let baseKey: String?
  internal let styles: [ConfigKeySource: any NamingStyle]
  internal let explicitKeys: [ConfigKeySource: String]
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

