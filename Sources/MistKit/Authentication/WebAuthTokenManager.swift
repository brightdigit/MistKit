//
//  WebAuthTokenManager.swift
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

/// Token manager for web authentication with API token + web auth token.
/// Provides user-specific access to CloudKit Web Services.
public final class WebAuthTokenManager: TokenManager, Sendable {
  internal let apiToken: String
  internal let webAuthToken: String

  // MARK: - TokenManager Protocol

  /// Indicates whether valid credentials are currently available.
  public var hasCredentials: Bool {
    get async {
      (try? WebAuthTokenAuthenticator(apiToken: apiToken, webAuthToken: webAuthToken)) != nil
    }
  }

  /// Creates a new web authentication token manager.
  /// - Parameters:
  ///   - apiToken: The CloudKit API token from Apple Developer Console.
  ///   - webAuthToken: The web authentication token from CloudKit JS authentication.
  public init(
    apiToken: String,
    webAuthToken: String
  ) {
    self.apiToken = apiToken
    self.webAuthToken = webAuthToken
  }

  /// Validates the stored credentials for format and completeness.
  public func validateCredentials() async throws(TokenManagerError) -> Bool {
    _ = try WebAuthTokenAuthenticator(apiToken: apiToken, webAuthToken: webAuthToken)
    return true
  }

  /// Returns the web-auth authenticator, after validation.
  public func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    try WebAuthTokenAuthenticator(apiToken: apiToken, webAuthToken: webAuthToken)
  }
}
