//
//  WebAuthTokenManager.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

/// Token manager for web authentication with API token + web auth token
/// Provides user-specific access to CloudKit Web Services
public final class WebAuthTokenManager: TokenManager, Sendable {
  private let apiToken: String
  private let webAuthToken: String
  private let tokenEncoder = CharacterMapEncoder()
  private let credentials: TokenCredentials

  /// Creates a new web authentication token manager
  /// - Parameters:
  ///   - apiToken: The CloudKit API token from Apple Developer Console
  ///   - webAuthToken: The web authentication token from CloudKit JS authentication
  public init(apiToken: String, webAuthToken: String) {
    self.apiToken = apiToken
    self.webAuthToken = webAuthToken
    self.credentials = TokenCredentials.webAuthToken(
      apiToken: apiToken,
      webToken: webAuthToken
    )
  }

  // MARK: - TokenManager Protocol

  public let supportsRefresh = false // Web tokens typically need re-authentication

  public var hasCredentials: Bool {
    get async {
      return !apiToken.isEmpty && !webAuthToken.isEmpty
    }
  }

  public func validateCredentials() async throws -> Bool {
    // Validate API token format
    guard !apiToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(reason: "API token is empty")
    }

    // Validate web auth token
    guard !webAuthToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(reason: "Web auth token is empty")
    }

    // Basic API token format validation
    let apiTokenPattern = "^[a-fA-F0-9]{64}$"
    let regex = try NSRegularExpression(pattern: apiTokenPattern)
    let range = NSRange(location: 0, length: apiToken.count)
    let matches = regex.matches(in: apiToken, range: range)

    guard !matches.isEmpty else {
      throw TokenManagerError.invalidCredentials(
        reason: "API token format is invalid (expected 64-character hex string)"
      )
    }

    // Web auth tokens are typically base64-encoded and longer
    // Just check it's not empty and has reasonable length
    guard webAuthToken.count >= 10 else {
      throw TokenManagerError.invalidCredentials(
        reason: "Web auth token appears to be too short"
      )
    }

    return true
  }

  public func getCurrentCredentials() async throws -> TokenCredentials? {
    // Validate first
    _ = try await validateCredentials()
    return credentials
  }

  public func refreshCredentials() async throws -> TokenCredentials? {
    throw TokenManagerError.refreshNotSupported
  }
}

// MARK: - Additional Web Auth Methods

extension WebAuthTokenManager {
  /// The API token value
  public var apiTokenValue: String {
    apiToken
  }

  /// The web authentication token value
  public var webAuthTokenValue: String {
    webAuthToken
  }

  /// Returns the encoded web auth token (using CharacterMapEncoder)
  public var encodedWebAuthToken: String {
    tokenEncoder.encode(webAuthToken)
  }

  /// Returns true if both tokens appear to be in valid format
  public var areTokensValidFormat: Bool {
    // Check API token format
    let apiTokenPattern = "^[a-fA-F0-9]{64}$"
    guard let regex = try? NSRegularExpression(pattern: apiTokenPattern) else {
      return false
    }
    let range = NSRange(location: 0, length: apiToken.count)
    let apiTokenMatches = regex.matches(in: apiToken, range: range)

    // Check web auth token has reasonable length
    let webTokenValid = webAuthToken.count >= 10

    return !apiTokenMatches.isEmpty && webTokenValid
  }

  /// Creates credentials with additional metadata
  /// - Parameter metadata: Additional metadata to include
  /// - Returns: TokenCredentials with metadata
  public func credentialsWithMetadata(_ metadata: [String: String]) -> TokenCredentials {
    TokenCredentials(
      method: .webAuthToken(apiToken: apiToken, webToken: webAuthToken),
      metadata: metadata
    )
  }

  /// Creates new credentials with updated web auth token (for token refresh scenarios)
  /// - Parameter newWebAuthToken: The new web authentication token
  /// - Returns: New TokenCredentials with updated web token
  /// - Note: This creates new credentials but doesn't update the manager's internal token
  public func credentialsWithUpdatedWebAuthToken(_ newWebAuthToken: String) -> TokenCredentials {
    return TokenCredentials.webAuthToken(
      apiToken: apiToken,
      webToken: newWebAuthToken
    )
  }
}