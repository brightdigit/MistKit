//
//  EnhancedConfigurationReader.swift
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

/// Configuration reader implementing hierarchical resolution (CLI → ENV → defaults)
struct EnhancedConfigurationReader {
  // MARK: Lifecycle

  init() {}

  // MARK: Internal

  /// Read string value with hierarchy: command line → environment → default
  func string(
    key: String,
    environmentKey: String? = nil,
    default: String? = nil,
    isSecret: Bool = false
  ) -> String? {
    // 1. Check command line arguments
    if let value = getCommandLineValue(for: key) {
      return value
    }

    // 2. Check environment variables
    if let envKey = environmentKey, let value = ProcessInfo.processInfo.environment[envKey] {
      return value
    }

    // 3. Return default
    return `default`
  }

  /// Read int value with hierarchy
  func int(key: String, environmentKey: String? = nil, default: Int? = nil) -> Int? {
    if let stringValue = string(
      key: key,
      environmentKey: environmentKey,
      default: `default`.map(String.init)
    ) {
      return Int(stringValue)
    }
    return nil
  }

  /// Read bool value with hierarchy
  func bool(key: String, environmentKey: String? = nil, default: Bool = false) -> Bool {
    if let stringValue = string(key: key, environmentKey: environmentKey, default: String(`default`))
    {
      return stringValue.lowercased() == "true" || stringValue == "1"
    }
    return `default`
  }

  // MARK: Private

  /// Get value from command line arguments
  private func getCommandLineValue(for key: String) -> String? {
    let args = CommandLine.arguments

    // Convert key to command line format (e.g., "api.token" -> "--api-token")
    let argName = "--" + key.replacingOccurrences(of: ".", with: "-")

    if let index = args.firstIndex(of: argName), index + 1 < args.count {
      return args[index + 1]
    }

    // Also check for alternative argument names
    let alternativeNames = getAlternativeArgNames(for: key)
    for altName in alternativeNames {
      if let index = args.firstIndex(of: altName), index + 1 < args.count {
        return args[index + 1]
      }
    }

    // Check for flags (boolean values)
    if args.contains(argName) {
      return "true"
    }

    // Check alternative flags
    for altName in alternativeNames {
      if args.contains(altName) {
        return "true"
      }
    }

    return nil
  }

  /// Get alternative command line argument names for common keys
  private func getAlternativeArgNames(for key: String) -> [String] {
    switch key {
    case "container.identifier":
      ["--container-identifier", "-c"]
    case "api.token":
      ["--api-token", "-a"]
    case "web.auth.token":
      ["--web-auth-token"]
    case "private.key.file":
      ["--private-key-file"]
    case "private.key":
      ["--private-key"]
    case "key.id":
      ["--key-id"]
    case "skip.auth":
      ["--skip-auth"]
    case "test.all.auth":
      ["--test-all-auth"]
    case "test.api.only":
      ["--test-api-only"]
    case "test.adaptive":
      ["--test-adaptive"]
    case "test.server.to.server":
      ["--test-server-to-server"]
    case "port":
      ["-p"]
    default:
      []
    }
  }
}
