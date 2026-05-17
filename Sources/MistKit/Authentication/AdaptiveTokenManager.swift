//
//  AdaptiveTokenManager.swift
//  MistKit
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

/// Adaptive token manager that can transition between API-only and Web authentication.
///
/// Starts with API token only and can be upgraded to include web authentication.
/// On each request it vends whichever authenticator matches its current state —
/// `APITokenAuthenticator` while API-only, `WebAuthTokenAuthenticator` after
/// upgrade.
public actor AdaptiveTokenManager: TokenManager {
  internal let apiToken: String
  internal var webAuthToken: String?

  internal let storage: (any TokenStorage)?

  // MARK: - TokenManager Protocol

  /// Indicates whether valid credentials are currently available.
  public var hasCredentials: Bool {
    get async {
      !apiToken.isEmpty
    }
  }

  /// Creates an adaptive token manager starting with API token only.
  /// - Parameters:
  ///   - apiToken: The CloudKit API token.
  ///   - storage: Optional storage for persistence (default: nil for in-memory only).
  public init(
    apiToken: String,
    storage: (any TokenStorage)? = nil
  ) {
    self.apiToken = apiToken
    self.webAuthToken = nil
    self.storage = storage
  }

  /// Validates the stored credentials for format and completeness.
  public func validateCredentials() async throws(TokenManagerError) -> Bool {
    if let webToken = webAuthToken {
      _ = try WebAuthTokenAuthenticator(apiToken: apiToken, webAuthToken: webToken)
    } else {
      _ = try APITokenAuthenticator(token: apiToken)
    }
    return true
  }

  /// Returns the authenticator matching the current authentication mode.
  public func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    if let webToken = webAuthToken {
      return try WebAuthTokenAuthenticator(apiToken: apiToken, webAuthToken: webToken)
    }
    return try APITokenAuthenticator(token: apiToken)
  }
}
