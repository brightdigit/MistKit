//
//  WebAuthTokenManager+Methods.swift
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

public import Foundation

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
    do {
      try BaseTokenManager.validateAPITokenFormat(apiToken)
      try BaseTokenManager.validateWebAuthTokenFormat(webAuthToken)
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
      method: .webAuthToken(apiToken: apiToken, webToken: webAuthToken),
      metadata: metadata
    )
  }

  /// Creates new credentials with updated web auth token (for token refresh scenarios)
  /// - Parameter newWebAuthToken: The new web authentication token
  /// - Returns: New TokenCredentials with updated web token
  /// - Note: This creates new credentials but doesn't update the manager's internal token
  public func credentialsWithUpdatedWebAuthToken(_ newWebAuthToken: String) -> TokenCredentials {
    TokenCredentials.webAuthToken(
      apiToken: apiToken,
      webToken: newWebAuthToken
    )
  }
}
