//
//  ConfigError.swift
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

/// Configuration-specific errors
enum ConfigError: LocalizedError, Sendable {
  case missingAPIToken
  case invalidEnvironment(String)
  case fileNotFound(String)
  case invalidFormat(String, details: String)
  case profileNotFound(String)

  // MARK: Internal

  var errorDescription: String? {
    switch self {
    case .missingAPIToken:
      "CloudKit API token is required"
    case let .invalidEnvironment(env):
      "Invalid environment: \(env)"
    case let .fileNotFound(path):
      "Configuration file not found: \(path)"
    case let .invalidFormat(format, details):
      "Invalid \(format) format: \(details)"
    case let .profileNotFound(profile):
      "Profile not found: \(profile)"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .missingAPIToken:
      "Set CLOUDKIT_API_TOKEN environment variable or use --api-token flag"
    case let .invalidEnvironment(env):
      "Use 'development' or 'production' instead of '\(env)'"
    case let .fileNotFound(path):
      "Create a configuration file at \(path)"
    case let .invalidFormat(format, _):
      "Check your \(format) configuration file syntax"
    case let .profileNotFound(profile):
      "Check available profiles or create '\(profile)' profile"
    }
  }
}
