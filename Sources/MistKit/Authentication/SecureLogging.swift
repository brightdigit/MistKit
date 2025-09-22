//
//  SecureLogging.swift
//  PackageDSLKit
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

public import Foundation

/// Utilities for secure logging that masks sensitive information
public enum SecureLogging {
  /// Masks a token by showing only the first few and last few characters
  /// - Parameters:
  ///   - token: The token to mask
  ///   - prefixLength: Number of characters to show at the beginning (default: 8)
  ///   - suffixLength: Number of characters to show at the end (default: 4)
  ///   - maskCharacter: Character to use for masking (default: "*")
  /// - Returns: A masked version of the token
  public static func maskToken(
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
  public static func maskAPIToken(_ apiToken: String) -> String {
    maskToken(apiToken, prefixLength: 8, suffixLength: 4)
  }

  /// Masks a web auth token
  /// - Parameter webAuthToken: The web auth token to mask
  /// - Returns: A masked version of the web auth token
  public static func maskWebAuthToken(_ webAuthToken: String) -> String {
    maskToken(webAuthToken, prefixLength: 12, suffixLength: 8)
  }

  /// Masks a key ID
  /// - Parameter keyID: The key ID to mask
  /// - Returns: A masked version of the key ID
  public static func maskKeyID(_ keyID: String) -> String {
    maskToken(keyID, prefixLength: 4, suffixLength: 2)
  }

  /// Masks private key data by showing only the first few bytes
  /// - Parameter privateKey: The private key data to mask
  /// - Returns: A masked representation of the private key
  public static func maskPrivateKey(_ privateKey: Data) -> String {
    let prefixLength = min(4, privateKey.count)
    let prefix = privateKey.prefix(prefixLength).map { String(format: "%02x", $0) }.joined()
    let maskCount = max(0, privateKey.count - prefixLength)
    let mask = String(repeating: "*", count: maskCount * 2)  // Each byte is 2 hex chars
    return "\(prefix)\(mask)"
  }

  /// Masks sensitive data in a dictionary for logging
  /// - Parameter dictionary: The dictionary to mask
  /// - Returns: A dictionary with sensitive values masked
  public static func maskSensitiveDictionary(_ dictionary: [String: Any]) -> [String: Any] {
    var maskedDictionary: [String: Any] = [:]

    for (key, value) in dictionary {
      let lowercasedKey = key.lowercased()

      // Check if this key contains sensitive information
      if lowercasedKey.contains("token") || lowercasedKey.contains("key")
        || lowercasedKey.contains("secret") || lowercasedKey.contains("password")
        || lowercasedKey.contains("auth")
      {
        if let stringValue = value as? String {
          if lowercasedKey.contains("api") {
            maskedDictionary[key] = maskAPIToken(stringValue)
          } else if lowercasedKey.contains("web") {
            maskedDictionary[key] = maskWebAuthToken(stringValue)
          } else if lowercasedKey.contains("keyid") {
            maskedDictionary[key] = maskKeyID(stringValue)
          } else {
            maskedDictionary[key] = maskToken(stringValue)
          }
        } else if let dataValue = value as? Data {
          maskedDictionary[key] = maskPrivateKey(dataValue)
        } else {
          maskedDictionary[key] = "***REDACTED***"
        }
      } else {
        maskedDictionary[key] = value
      }
    }

    return maskedDictionary
  }

  /// Creates a safe logging string that masks sensitive information
  /// - Parameter message: The message to log
  /// - Returns: A safe version of the message with sensitive data masked
  public static func safeLogMessage(_ message: String) -> String {
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
  /// Returns a safely masked version of this string for logging
  public var safeForLogging: String {
    SecureLogging.safeLogMessage(self)
  }

  /// Returns a masked API token version of this string
  public var maskedAPIToken: String {
    SecureLogging.maskAPIToken(self)
  }

  /// Returns a masked web auth token version of this string
  public var maskedWebAuthToken: String {
    SecureLogging.maskWebAuthToken(self)
  }

  /// Returns a masked key ID version of this string
  public var maskedKeyID: String {
    SecureLogging.maskKeyID(self)
  }
}

/// Extension to provide safe logging methods for Data
extension Data {
  /// Returns a masked representation of this data for logging
  public var maskedForLogging: String {
    SecureLogging.maskPrivateKey(self)
  }
}
