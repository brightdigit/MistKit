//
//  SecureLogging.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

internal import Foundation

/// Utilities for secure logging that masks sensitive information
internal enum SecureLogging {
  /// Masks a token by showing only the first few and last few characters
  /// - Parameters:
  ///   - token: The token to mask
  ///   - prefixLength: Number of characters to show at the beginning (default: 8)
  ///   - suffixLength: Number of characters to show at the end (default: 4)
  ///   - maskCharacter: Character to use for masking (default: "*")
  /// - Returns: A masked version of the token
  internal static func maskToken(
    _ token: String,
    prefixLength: Int = 8,
    suffixLength: Int = 4,
    maskCharacter: Character = "*"
  ) -> String {
    guard token.count > prefixLength + suffixLength else {
      return String(repeating: maskCharacter, count: token.count)
    }

    let prefix = String(token.prefix(prefixLength))
    let suffix = String(token.suffix(suffixLength))
    let maskCount = token.count - prefixLength - suffixLength
    let mask = String(repeating: maskCharacter, count: maskCount)

    return "\(prefix)\(mask)\(suffix)"
  }

  /// Masks an API token with standard CloudKit format
  /// - Parameter apiToken: The API token to mask
  /// - Returns: A masked version of the API token
  internal static func maskAPIToken(_ apiToken: String) -> String {
    maskToken(apiToken, prefixLength: 8, suffixLength: 4)
  }

  /// Creates a safe logging string that masks sensitive information
  /// - Parameter message: The message to log
  /// - Returns: A safe version of the message with sensitive data masked
  internal static func safeLogMessage(_ message: String) -> String {
    // Allow disabling redaction for debugging via environment variable
    if ProcessInfo.processInfo.environment["MISTKIT_DISABLE_LOG_REDACTION"] != nil {
      return message
    }

    var safeMessage = message

    // Use static regex patterns for better performance
    let patterns: [(NSRegularExpression, String)] = [
      // API tokens (64 character hex strings)
      (NSRegularExpression.maskApiTokenRegex, "API_TOKEN_REDACTED"),
      // Web auth tokens (base64-like strings)
      (NSRegularExpression.maskWebAuthTokenRegex, "WEB_AUTH_TOKEN_REDACTED"),
      // Key IDs (alphanumeric strings)
      (NSRegularExpression.maskKeyIdRegex, "KEY_ID_REDACTED"),
      // Generic tokens
      (NSRegularExpression.maskGenericTokenRegex, "token=***REDACTED***"),
      (NSRegularExpression.maskGenericKeyRegex, "key=***REDACTED***"),
      (NSRegularExpression.maskGenericSecretRegex, "secret=***REDACTED***"),
    ]

    for (regex, replacement) in patterns {
      safeMessage = regex.stringByReplacingMatches(
        in: safeMessage,
        range: NSRange(location: 0, length: safeMessage.count),
        withTemplate: replacement
      )
    }

    return safeMessage
  }
}

/// Extension to provide safe logging methods for common types
extension String {
  /// Returns a masked API token version of this string
  public var maskedAPIToken: String {
    SecureLogging.maskAPIToken(self)
  }
}
