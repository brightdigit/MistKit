//
//  AdaptiveTokenManager.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

/// Adaptive token manager that can transition between API-only and Web authentication
/// Starts with API token and can be upgraded to include web authentication
/// Supports storage when upgraded to web authentication
public actor AdaptiveTokenManager: TokenManager {
  internal let apiToken: String
  internal var webAuthToken: String?

  internal let storage: (any TokenStorage)?

  // MARK: - TokenManager Protocol

  /// Indicates whether valid credentials are currently available
  public var hasCredentials: Bool {
    get async {
      !apiToken.isEmpty
    }
  }

  /// Creates an adaptive token manager starting with API token only
  /// - Parameters:
  ///   - apiToken: The CloudKit API token
  ///   - storage: Optional storage for persistence (default: nil for in-memory only)
  public init(
    apiToken: String,
    storage: (any TokenStorage)? = nil
  ) {
    self.apiToken = apiToken
    self.webAuthToken = nil
    self.storage = storage
  }

  /// Validates the stored credentials for format and completeness
  /// - Returns: true if credentials are valid, false otherwise
  /// - Throws: TokenManagerError if credentials are invalid
  public func validateCredentials() async throws(TokenManagerError) -> Bool {
    // Validate API token using common validation
    try Self.validateAPITokenFormat(apiToken)

    // Validate web token if present
    if let webToken = webAuthToken {
      try Self.validateWebAuthTokenFormat(webToken)
    }

    return true
  }

  /// Retrieves the current credentials for authentication
  /// - Returns: The current token credentials, or nil if not available
  /// - Throws: TokenManagerError if credentials are invalid
  public func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    _ = try await validateCredentials()

    if let webToken = webAuthToken {
      return TokenCredentials.webAuthToken(apiToken: apiToken, webToken: webToken)
    } else {
      return TokenCredentials.apiToken(apiToken)
    }
  }
}
