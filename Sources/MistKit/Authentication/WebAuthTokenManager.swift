//
//  WebAuthTokenManager.swift
//  PackageDSLKit
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

/// Token manager for web authentication with API token + web auth token
/// Provides user-specific access to CloudKit Web Services
public final class WebAuthTokenManager: TokenManager, Sendable {
  internal let apiToken: String
  internal let webAuthToken: String
  internal let tokenEncoder = CharacterMapEncoder()
  internal let credentials: TokenCredentials
  internal let refreshPolicy: TokenRefreshPolicy
  internal let retryPolicy: RetryPolicy
  internal let storage: (any TokenStorage)?

  // Token refresh state
  internal let taskState = TaskState()
  internal let refreshSubject = AsyncStream<TokenRefreshEvent>.makeStream()

  /// Actor to manage task state safely
  internal actor TaskState {
    private var refreshTask: Task<Void, Never>?

    func setTask(_ task: Task<Void, Never>?) {
      refreshTask?.cancel()
      refreshTask = task
    }

    func cancelTask() {
      refreshTask?.cancel()
      refreshTask = nil
    }
  }

  /// Events emitted during token refresh operations
  public enum TokenRefreshEvent: Sendable {
    case refreshStarted(apiToken: String)
    case refreshCompleted(apiToken: String, newWebToken: String)
    case refreshFailed(apiToken: String, error: any Error)
    case refreshScheduled(apiToken: String, nextRefresh: Date)
  }

  /// Stream of token refresh events
  public var refreshEvents: AsyncStream<TokenRefreshEvent> {
    refreshSubject.stream
  }

  /// Creates a new web authentication token manager
  /// - Parameters:
  ///   - apiToken: The CloudKit API token from Apple Developer Console
  ///   - webAuthToken: The web authentication token from CloudKit JS authentication
  ///   - refreshPolicy: Token refresh policy (default: manual)
  ///   - retryPolicy: Retry policy for failed operations (default: .default)
  ///   - storage: Optional storage for persistence (default: nil for in-memory only)
  public init(
    apiToken: String,
    webAuthToken: String,
    refreshPolicy: TokenRefreshPolicy = .manual,
    retryPolicy: RetryPolicy = .default,
    storage: (any TokenStorage)? = nil
  ) {
    self.apiToken = apiToken
    self.webAuthToken = webAuthToken
    self.refreshPolicy = refreshPolicy
    self.retryPolicy = retryPolicy
    self.storage = storage
    self.credentials = TokenCredentials.webAuthToken(
      apiToken: apiToken,
      webToken: webAuthToken
    )

    // Start refresh scheduler if policy supports it
    if refreshPolicy.supportsAutomaticRefresh {
      startRefreshScheduler()
    }
  }

  deinit {
    let taskState = self.taskState
    Task.detached { await taskState.cancelTask() }
    refreshSubject.continuation.finish()
  }

  // MARK: - TokenManager Protocol

  public var supportsRefresh: Bool {
    // Support refresh if we have a refresh policy that supports it
    refreshPolicy.supportsAutomaticRefresh
  }

  public var hasCredentials: Bool {
    get async {
      !apiToken.isEmpty && !webAuthToken.isEmpty
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
    let regex = NSRegularExpression.apiTokenRegex
    let matches = regex.matches(in: apiToken)

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
    guard supportsRefresh else {
      throw TokenManagerError.refreshNotSupported
    }

    // Perform refresh with retry logic
    return try await performRefreshWithRetry()
  }
}
