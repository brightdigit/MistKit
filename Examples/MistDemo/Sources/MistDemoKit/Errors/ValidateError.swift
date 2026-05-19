//
//  ValidateError.swift
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

public import Foundation

/// Errors that can occur during validate command execution.
public enum ValidateError: Error, LocalizedError {
  case missingCredentials(String)
  case networkCheckFailed(String)
  case testQueryFailed(String)

  /// A localized description of the error.
  public var errorDescription: String? {
    switch self {
    case .missingCredentials(let reason):
      return "Credential validation failed: \(reason)"
    case .networkCheckFailed(let reason):
      return "Network reachability check failed: \(reason)"
    case .testQueryFailed(let reason):
      return "Test query failed: \(reason)"
    }
  }

  /// A localized recovery suggestion.
  public var recoverySuggestion: String? {
    switch self {
    case .missingCredentials:
      return
        "Set CLOUDKIT_API_TOKEN + CLOUDKIT_WEB_AUTH_TOKEN for "
        + "private/shared databases, or CLOUDKIT_KEY_ID + "
        + "CLOUDKIT_PRIVATE_KEY[_PATH] for public."
    case .networkCheckFailed:
      return
        "Verify your credentials, container identifier, and "
        + "environment, then retry."
    case .testQueryFailed:
      return
        "Verify the configured database and record type, or "
        + "drop --test-query to validate credentials only."
    }
  }
}
