//
//  NSRegularExpression+CommonPatterns.swift
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

// MARK: - Common Regex Patterns
extension NSRegularExpression {
  /// CloudKit API token pattern (64-character hex string)
  private static let apiTokenPattern = "^[a-fA-F0-9]{64}$"

  /// CloudKit web auth token pattern
  private static let webAuthTokenPattern = "^[A-Za-z0-9+/=_]{100,}$"

  /// CloudKit key ID pattern (64-character hex string)
  private static let keyIDPattern = "^[a-fA-F0-9]{64}$"

  // MARK: - Secure Logging Patterns
  /// API tokens (64 character hex strings) for masking
  private static let maskApiTokenPattern = "[a-fA-F0-9]{64}"

  /// Web auth tokens (base64-like strings) for masking
  private static let maskWebAuthTokenPattern = "[A-Za-z0-9+/]{20,}={0,2}"

  /// Key IDs (alphanumeric strings) for masking
  private static let maskKeyIdPattern = "[A-Za-z0-9]{8,}"

  /// Generic token patterns for masking
  private static let maskGenericTokenPattern = "token[=:][\\s]*[A-Za-z0-9+/=]+"
  private static let maskGenericKeyPattern = "key[=:][\\s]*[A-Za-z0-9+/=]+"
  private static let maskGenericSecretPattern = "secret[=:][\\s]*[A-Za-z0-9+/=]+"
}

// swiftlint:disable force_try
// swift-format-ignore: NeverUseForceTry
extension NSRegularExpression {
  /// Compiled regex for API token validation
  public static let apiTokenRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: apiTokenPattern)
  }()

  /// Compiled regex for web auth token validation
  public static let webAuthTokenRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: webAuthTokenPattern)
  }()

  /// Compiled regex for key ID validation
  public static let keyIDRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: keyIDPattern)
  }()

  // MARK: - Secure Logging Regexes
  /// Compiled regex for masking API tokens in logs
  public static let maskApiTokenRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: maskApiTokenPattern)
  }()

  /// Compiled regex for masking web auth tokens in logs
  public static let maskWebAuthTokenRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: maskWebAuthTokenPattern)
  }()

  /// Compiled regex for masking key IDs in logs
  public static let maskKeyIdRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: maskKeyIdPattern)
  }()

  /// Compiled regex for masking generic tokens in logs
  public static let maskGenericTokenRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: maskGenericTokenPattern)
  }()

  /// Compiled regex for masking generic keys in logs
  public static let maskGenericKeyRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: maskGenericKeyPattern)
  }()

  /// Compiled regex for masking generic secrets in logs
  public static let maskGenericSecretRegex: NSRegularExpression = {
    try! NSRegularExpression(pattern: maskGenericSecretPattern)
  }()
}
// swiftlint:enable force_try

// MARK: - Convenience Methods
extension NSRegularExpression {
  /// Convenience method to match against the entire string
  /// - Parameter string: The string to search in
  /// - Returns: Array of NSTextCheckingResult objects
  public func matches(in string: String) -> [NSTextCheckingResult] {
    matches(in: string, range: NSRange(location: 0, length: string.count))
  }
}

// MARK: - Performance Extensions
extension String {
  /// Returns the full NSRange for the string to avoid repeated allocations
  private var fullNSRange: NSRange {
    NSRange(location: 0, length: count)
  }
}
