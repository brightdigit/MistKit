//
//  WebAuthTokenManager.swift
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

#if canImport(Foundation)
  import Foundation
#endif

/// Token manager for web authentication with API token + web auth token
/// Provides user-specific access to CloudKit Web Services
public final class WebAuthTokenManager: TokenManager, Sendable {
  internal let apiToken: String
  internal let webAuthToken: String
  internal let tokenEncoder = CharacterMapEncoder()
  internal let credentials: TokenCredentials
  internal let storage: (any TokenStorage)?

  // MARK: - TokenManager Protocol

  public var hasCredentials: Bool {
    get async {
      // Check if tokens are non-empty and have valid format
      guard !apiToken.isEmpty && !webAuthToken.isEmpty else {
        return
          false
      }

      // Check API token format (64-character hex string)
      let regex = NSRegularExpression.apiTokenRegex
      let matches = regex.matches(in: apiToken)
      guard !matches.isEmpty else {
        return
          false
      }

      // Check web auth token length (at least 10 characters)
      guard webAuthToken.count >= 10 else {
        return
          false
      }

      return true
    }
  }

  /// Creates a new web authentication token manager
  /// - Parameters:
  ///   - apiToken: The CloudKit API token from Apple Developer Console
  ///   - webAuthToken: The web authentication token from CloudKit JS authentication
  ///   - storage: Optional storage for persistence (default: nil for in-memory only)
  public init(
    apiToken: String,
    webAuthToken: String,
    storage: (any TokenStorage)? = nil
  ) {
    self.apiToken = apiToken
    self.webAuthToken = webAuthToken
    self.storage = storage
    self.credentials = TokenCredentials.webAuthToken(
      apiToken: apiToken,
      webToken: webAuthToken
    )
  }

  public func validateCredentials() async throws(TokenManagerError) -> Bool {
    // Validate API token format
    guard !apiToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(.apiTokenEmpty)
    }

    let regex = NSRegularExpression.apiTokenRegex
    let matches = regex.matches(in: apiToken)

    guard !matches.isEmpty else {
      throw TokenManagerError.invalidCredentials(.apiTokenInvalidFormat)
    }

    // Validate web auth token
    guard !webAuthToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(.webAuthTokenEmpty)
    }

    guard webAuthToken.count >= 10 else {
      throw TokenManagerError.invalidCredentials(.webAuthTokenTooShort)
    }

    return true
  }

  public func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    // Validate first
    _ = try await validateCredentials()
    return credentials
  }

  deinit {
    // Clean up any resources
  }
}
