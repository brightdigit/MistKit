//
//  AdaptiveTokenManager+Transitions.swift
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

public import Foundation

// MARK: - Transition Methods

extension AdaptiveTokenManager {
  /// Current authentication mode
  public var authenticationMode: AuthenticationMode {
    webAuthToken != nil ? .webAuthenticated : .apiOnly
  }

  /// Returns true if currently supports user-specific operations
  public var supportsUserOperations: Bool {
    webAuthToken != nil
  }

  /// Returns the current API token
  public var currentAPIToken: String {
    apiToken
  }

  /// Returns the current web auth token (if any)
  public var currentWebAuthToken: String? {
    webAuthToken
  }

  /// Upgrades to web authentication by adding a web auth token
  /// - Parameter webAuthToken: The web authentication token from CloudKit JS
  /// - Returns: New credentials with web authentication
  /// - Throws: TokenManagerError if the web token is invalid
  public func upgradeToWebAuthentication(webAuthToken: String) async throws(TokenManagerError)
    -> TokenCredentials
  {
    guard !webAuthToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(.webAuthTokenEmpty)
    }

    guard webAuthToken.count >= 10 else {
      throw TokenManagerError.invalidCredentials(.webAuthTokenTooShort)
    }

    self.webAuthToken = webAuthToken

    // Mode changed to web authentication

    // Store credentials if storage is available
    if let storage = storage {
      guard let credentials = try await getCurrentCredentials() else {
        throw TokenManagerError.internalError(.failedCredentialRetrievalAfterUpgrade)
      }
      do {
        try await storage.store(credentials, identifier: apiToken)
      } catch {
        // Don't fail silently - log the storage error but continue with the upgrade
        // This ensures the authentication upgrade succeeds even if storage fails
        MistKitLogger.logWarning(
          "Failed to store credentials after upgrade: \(error.localizedDescription)",
          logger: MistKitLogger.auth
        )
        // Could also throw here if storage failure should be fatal:
        // throw TokenManagerError.internalError(
        //   reason: "Failed to store credentials: \(error.localizedDescription)"
        // )
      }
    }

    guard let finalCredentials = try await getCurrentCredentials() else {
      throw TokenManagerError.internalError(.failedCredentialRetrievalAfterUpgrade)
    }
    return finalCredentials
  }

  /// Downgrades to API-only authentication (removes web auth token)
  /// - Returns: New credentials with API-only authentication
  public func downgradeToAPIOnly() async throws(TokenManagerError) -> TokenCredentials {
    self.webAuthToken = nil

    // Mode changed to API-only

    guard let finalCredentials = try await getCurrentCredentials() else {
      throw TokenManagerError.internalError(.failedCredentialRetrievalAfterDowngrade)
    }
    return finalCredentials
  }

  /// Updates the web auth token (for token refresh scenarios)
  /// - Parameter newWebAuthToken: The new web authentication token
  /// - Returns: Updated credentials
  /// - Throws: TokenManagerError if not in web auth mode or token is invalid
  public func updateWebAuthToken(_ newWebAuthToken: String) async throws(TokenManagerError)
    -> TokenCredentials
  {
    guard webAuthToken != nil else {
      throw TokenManagerError.invalidCredentials(.authenticationModeMismatch)
    }

    return try await upgradeToWebAuthentication(webAuthToken: newWebAuthToken)
  }
}
