//
//  AdaptiveTokenManager.swift
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

/// Adaptive token manager that can transition between API-only and Web authentication
/// Starts with API token and can be upgraded to include web authentication
/// Supports refresh policies and storage when upgraded to web authentication
public actor AdaptiveTokenManager: TokenManager {
  internal let apiToken: String
  internal var webAuthToken: String?
  internal let refreshPolicy: TokenRefreshPolicy
  internal let retryPolicy: RetryPolicy
  internal let storage: (any TokenStorage)?

  // Refresh state (only used in web authentication mode)
  internal var refreshTask: Task<Void, Never>?
  internal let refreshSubject = AsyncStream<TokenRefreshEvent>.makeStream()

  /// Events emitted during token refresh operations
  public enum TokenRefreshEvent: Sendable {
    case refreshStarted(apiToken: String)
    case refreshCompleted(apiToken: String, newWebToken: String)
    case refreshFailed(apiToken: String, error: any Error)
    case refreshScheduled(apiToken: String, nextRefresh: Date)
    case modeChanged(from: AuthenticationMode, toMode: AuthenticationMode)
  }

  /// Stream of token refresh events
  nonisolated public var refreshEvents: AsyncStream<TokenRefreshEvent> {
    refreshSubject.stream
  }

  /// Creates an adaptive token manager starting with API token only
  /// - Parameters:
  ///   - apiToken: The CloudKit API token
  ///   - refreshPolicy: Token refresh policy (default: manual)
  ///   - retryPolicy: Retry policy for failed operations (default: .default)
  ///   - storage: Optional storage for persistence (default: nil for in-memory only)
  public init(
    apiToken: String,
    refreshPolicy: TokenRefreshPolicy = .manual,
    retryPolicy: RetryPolicy = .default,
    storage: (any TokenStorage)? = nil
  ) {
    self.apiToken = apiToken
    self.webAuthToken = nil
    self.refreshPolicy = refreshPolicy
    self.retryPolicy = retryPolicy
    self.storage = storage
  }

  deinit {
    refreshTask?.cancel()
    refreshSubject.continuation.finish()
  }

  // MARK: - TokenManager Protocol

  nonisolated public var supportsRefresh: Bool {
    // Support refresh only in web authentication mode with appropriate policy
    refreshPolicy.supportsAutomaticRefresh
  }

  public var hasCredentials: Bool {
    get async {
      !apiToken.isEmpty
    }
  }

  public func validateCredentials() async throws -> Bool {
    // Validate API token
    guard !apiToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(reason: "API token is empty")
    }

    let tokenPattern = "^[a-fA-F0-9]{64}$"
    let regex = try NSRegularExpression(pattern: tokenPattern)
    let range = NSRange(location: 0, length: apiToken.count)
    let matches = regex.matches(in: apiToken, range: range)

    guard !matches.isEmpty else {
      throw TokenManagerError.invalidCredentials(
        reason: "API token format is invalid"
      )
    }

    // Validate web token if present
    if let webToken = webAuthToken {
      guard webToken.count >= 10 else {
        throw TokenManagerError.invalidCredentials(
          reason: "Web auth token appears to be too short"
        )
      }
    }

    return true
  }

  public func getCurrentCredentials() async throws -> TokenCredentials? {
    _ = try await validateCredentials()

    if let webToken = webAuthToken {
      return TokenCredentials.webAuthToken(apiToken: apiToken, webToken: webToken)
    } else {
      return TokenCredentials.apiToken(apiToken)
    }
  }

  public func refreshCredentials() async throws -> TokenCredentials? {
    guard webAuthToken != nil else {
      throw TokenManagerError.refreshNotSupported
    }

    guard supportsRefresh else {
      throw TokenManagerError.refreshNotSupported
    }

    // Perform refresh with retry logic (similar to WebAuthTokenManager)
    return try await performRefreshWithRetry()
  }
}
