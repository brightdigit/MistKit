//
//  ConfigurationError.swift
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

/// Configuration errors.
internal enum ConfigurationError: LocalizedError {
  case invalidEnvironment(String)
  case invalidDatabase(String)
  case missingRequired(String, suggestion: String)
  case unsupportedPlatform(String)
  case badCredentialsOnPublicDB

  // MARK: Internal

  internal var errorDescription: String? {
    switch self {
    case .invalidEnvironment(let env):
      "Invalid environment '\(env)'. Must be 'development' or 'production'"
    case .invalidDatabase(let database):
      "Invalid database '\(database)'. "
        + "Must be 'public', 'private', or 'shared'"
    case .missingRequired(let field, let suggestion):
      "Missing required configuration: \(field). \(suggestion)"
    case .unsupportedPlatform(let message):
      "Unsupported platform: \(message)"
    case .badCredentialsOnPublicDB:
      "The bad-credentials error demo is only supported on the "
        + "private and shared databases (it uses web auth). "
        + "Re-run with `--database private`."
    }
  }
}
