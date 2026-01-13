//
//  EnvironmentConfig.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

import Foundation

/// Environment configuration utilities for CloudKit
public enum EnvironmentConfig {
  /// Environment variable keys
  public enum Keys {
    /// CloudKit API token environment variable key
    public static let cloudKitAPIToken = "CLOUDKIT_API_TOKEN"
  }

  /// CloudKit-specific environment utilities
  public enum CloudKit {
    /// Get a masked version of environment variables for safe logging
    /// - Returns: Dictionary of masked environment values
    public static func getMaskedEnvironment() -> [String: String] {
      var maskedEnv: [String: String] = [:]

      // Check for CloudKit-related environment variables
      let cloudKitKeys = [
        "CLOUDKIT_API_TOKEN",
        "CLOUDKIT_CONTAINER_ID",
        "CLOUDKIT_ENVIRONMENT",
        "CLOUDKIT_DATABASE",
      ]

      for key in cloudKitKeys {
        if let value = ProcessInfo.processInfo.environment[key] {
          maskedEnv[key] = value.isEmpty ? "(empty)" : "\(String(value.prefix(8)))***"
        } else {
          maskedEnv[key] = "(not set)"
        }
      }

      return maskedEnv
    }
  }

  /// Get an optional environment variable value
  /// - Parameter key: The environment variable key
  /// - Returns: The environment variable value, or nil if not set
  public static func getOptional(_ key: String) -> String? {
    ProcessInfo.processInfo.environment[key]
  }
}
