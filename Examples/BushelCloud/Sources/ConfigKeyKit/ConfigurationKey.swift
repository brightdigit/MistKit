//
//  ConfigurationKey.swift
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

// MARK: - Configuration Key Source

/// Source for configuration keys (CLI arguments or environment variables)
public enum ConfigKeySource: CaseIterable, Sendable {
  /// Command-line arguments (e.g., --cloudkit-container-id)
  case commandLine

  /// Environment variables (e.g., CLOUDKIT_CONTAINER_ID)
  case environment
}

// MARK: - Naming Style

/// Protocol for transforming base key strings into different naming conventions
public protocol NamingStyle: Sendable {
  /// Transform a base key string according to this naming style
  /// - Parameter base: Base key string (e.g., "cloudkit.container_id")
  /// - Returns: Transformed key string
  func transform(_ base: String) -> String
}

/// Common naming styles for configuration keys
public enum StandardNamingStyle: NamingStyle, Sendable {
  /// Dot-separated lowercase (e.g., "cloudkit.container_id")
  case dotSeparated

  /// Screaming snake case with prefix (e.g., "BUSHEL_CLOUDKIT_CONTAINER_ID")
  case screamingSnakeCase(prefix: String?)

  public func transform(_ base: String) -> String {
    switch self {
    case .dotSeparated:
      return base

    case .screamingSnakeCase(let prefix):
      let snakeCase = base.uppercased().replacingOccurrences(of: ".", with: "_")
      if let prefix = prefix {
        return "\(prefix)_\(snakeCase)"
      }
      return snakeCase
    }
  }
}

// MARK: - Configuration Key Protocol

/// Protocol for configuration keys that support multiple sources
public protocol ConfigurationKey: Sendable {
  /// Get the key string for a specific source
  /// - Parameter source: The configuration source (CLI or ENV)
  /// - Returns: The key string for that source, or nil if the key doesn't support that source
  func key(for source: ConfigKeySource) -> String?
}
