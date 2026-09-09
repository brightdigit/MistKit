//
//  AdaptiveTokenManager+Transitions.swift
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

internal import Foundation
internal import Logging

// MARK: - Transition Methods

extension AdaptiveTokenManager {
  /// Upgrades to web authentication by adding a web auth token.
  /// - Parameter webAuthToken: The web authentication token from CloudKit JS.
  /// - Returns: The web-auth authenticator that will be used for subsequent
  ///   requests.
  /// - Throws: `TokenManagerError` if the web token is invalid.
  @discardableResult
  public func upgradeToWebAuthentication(
    webAuthToken: String
  ) async throws(TokenManagerError) -> WebAuthTokenAuthenticator {
    let authenticator = try WebAuthTokenAuthenticator(
      apiToken: apiToken,
      webAuthToken: webAuthToken
    )
    self.webAuthToken = webAuthToken

    if let storage = storage {
      do {
        try await storage.store(authenticator, identifier: apiToken)
      } catch {
        // Don't fail the upgrade if storage fails — just log.
        Logger(subsystem: .auth).warning(
          "Failed to store credentials after upgrade: \(error.localizedDescription)"
        )
      }
    }

    return authenticator
  }

  /// Adopts a rotated web auth token from a CloudKit response header.
  public func didReceiveRotatedWebAuthToken(_ token: String) async throws(TokenManagerError) {
    guard webAuthToken != nil else {
      return
    }

    let authenticator = try WebAuthTokenAuthenticator(
      apiToken: apiToken,
      webAuthToken: token
    )
    self.webAuthToken = token

    if let storage = storage {
      do {
        try await storage.store(authenticator, identifier: apiToken)
      } catch {
        Logger(subsystem: .auth).warning(
          "Failed to store credentials after token rotation: \(error.localizedDescription)"
        )
      }
    }
  }
}
