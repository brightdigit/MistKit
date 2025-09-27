//
//  APITokenManager.swift
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

import Foundation

/// Token manager for simple API token authentication
/// Provides container-level access to CloudKit Web Services
public final class APITokenManager: TokenManager, Sendable {
  private let apiToken: String
  private let credentials: TokenCredentials

  // MARK: - TokenManager Protocol

  /// Indicates whether valid credentials are currently available
  public var hasCredentials: Bool {
    get async {
      !apiToken.isEmpty
    }
  }

  /// Creates a new API token manager
  /// - Parameter apiToken: The CloudKit API token from Apple Developer Console
  public init(apiToken: String) {
    self.apiToken = apiToken
    self.credentials = TokenCredentials.apiToken(apiToken)
  }

  /// Validates the stored credentials for format and completeness
  /// - Returns: true if credentials are valid, false otherwise
  /// - Throws: TokenManagerError if credentials are invalid
  public func validateCredentials() async throws(TokenManagerError) -> Bool {
    try Self.validateAPITokenFormat(apiToken)
    return true
  }

  /// Retrieves the current credentials for authentication
  /// - Returns: The current token credentials, or nil if not available
  /// - Throws: TokenManagerError if credentials are invalid
  public func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    // Validate first
    _ = try await validateCredentials()
    return credentials
  }
}

// MARK: - Additional API Token Methods

extension APITokenManager {
  /// The API token value
  public var token: String {
    apiToken
  }

  /// Returns true if the token appears to be in valid format
  public var isValidFormat: Bool {
    do {
      try Self.validateAPITokenFormat(apiToken)
      return true
    } catch {
      return false
    }
  }

  /// Creates credentials with additional metadata
  /// - Parameter metadata: Additional metadata to include
  /// - Returns: TokenCredentials with metadata
  public func credentialsWithMetadata(_ metadata: [String: String]) -> TokenCredentials {
    TokenCredentials(
      method: .apiToken(apiToken),
      metadata: metadata
    )
  }
}
