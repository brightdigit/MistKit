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
  private let apiToken: String
  private var webAuthToken: String?
  private let refreshPolicy: TokenRefreshPolicy
  private let retryPolicy: RetryPolicy
  private let storage: (any TokenStorage)?

  // Refresh state (only used in web authentication mode)
  private var refreshTask: Task<Void, Never>?
  private let refreshSubject = AsyncStream<TokenRefreshEvent>.makeStream()

  /// Events emitted during token refresh operations
  public enum TokenRefreshEvent: Sendable {
    case refreshStarted(apiToken: String)
    case refreshCompleted(apiToken: String, newWebToken: String)
    case refreshFailed(apiToken: String, error: any Error)
    case refreshScheduled(apiToken: String, nextRefresh: Date)
    case modeChanged(from: AuthenticationMode, to: AuthenticationMode)
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

// MARK: - Transition Methods

extension AdaptiveTokenManager {
  /// Current authentication mode
  public var authenticationMode: AuthenticationMode {
    webAuthToken != nil ? .webAuthenticated : .apiOnly
  }

  /// Upgrades to web authentication by adding a web auth token
  /// - Parameter webAuthToken: The web authentication token from CloudKit JS
  /// - Returns: New credentials with web authentication
  /// - Throws: TokenManagerError if the web token is invalid
  public func upgradeToWebAuthentication(webAuthToken: String) async throws -> TokenCredentials {
    guard !webAuthToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(reason: "Web auth token cannot be empty")
    }

    guard webAuthToken.count >= 10 else {
      throw TokenManagerError.invalidCredentials(reason: "Web auth token too short")
    }

    let oldMode = authenticationMode
    self.webAuthToken = webAuthToken
    let newMode = authenticationMode

    // Emit mode change event
    refreshSubject.continuation.yield(.modeChanged(from: oldMode, to: newMode))

    // Start refresh scheduler if policy supports it and we're now in web auth mode
    if newMode == .webAuthenticated && refreshPolicy.supportsAutomaticRefresh {
      startRefreshScheduler()
    }

    // Store credentials if storage is available
    if let storage = storage {
      let credentials = try await getCurrentCredentials()!
      try await storage.store(credentials, identifier: apiToken)
    }

    return try await getCurrentCredentials()!
  }

  /// Downgrades to API-only authentication (removes web auth token)
  /// - Returns: New credentials with API-only authentication
  public func downgradeToAPIOnly() async throws -> TokenCredentials {
    let oldMode = authenticationMode
    self.webAuthToken = nil
    let newMode = authenticationMode

    // Emit mode change event
    refreshSubject.continuation.yield(.modeChanged(from: oldMode, to: newMode))

    // Stop refresh scheduler since we're no longer in web auth mode
    stopRefreshScheduler()

    return try await getCurrentCredentials()!
  }

  /// Updates the web auth token (for token refresh scenarios)
  /// - Parameter newWebAuthToken: The new web authentication token
  /// - Returns: Updated credentials
  /// - Throws: TokenManagerError if not in web auth mode or token is invalid
  public func updateWebAuthToken(_ newWebAuthToken: String) async throws -> TokenCredentials {
    guard webAuthToken != nil else {
      throw TokenManagerError.invalidCredentials(
        reason: "Cannot update web auth token when not in web authentication mode"
      )
    }

    return try await upgradeToWebAuthentication(webAuthToken: newWebAuthToken)
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

  /// Returns the current refresh policy
  public var currentRefreshPolicy: TokenRefreshPolicy {
    refreshPolicy
  }

  /// Returns the current retry policy
  public var currentRetryPolicy: RetryPolicy {
    retryPolicy
  }
}

// MARK: - Token Refresh Implementation

extension AdaptiveTokenManager {
  /// Starts the automatic token refresh scheduler (only in web auth mode)
  private func startRefreshScheduler() {
    guard authenticationMode == .webAuthenticated && refreshPolicy.supportsAutomaticRefresh else {
      return
    }

    refreshTask = Task { [weak self] in
      await self?.runRefreshScheduler()
    }
  }

  /// Runs the token refresh scheduler loop
  private func runRefreshScheduler() async {
    while !Task.isCancelled && authenticationMode == .webAuthenticated {
      do {
        let nextRefreshDate = calculateNextRefreshDate()

        // Emit scheduled event
        refreshSubject.continuation.yield(
          .refreshScheduled(apiToken: apiToken, nextRefresh: nextRefreshDate))

        // Wait until the scheduled refresh time
        let now = Date()
        if nextRefreshDate > now {
          let delay = nextRefreshDate.timeIntervalSince(now)
          let nanoseconds = UInt64(delay * 1_000_000_000)
          try await Task.sleep(nanoseconds: nanoseconds)
        }

        // Check if we're still running and in web auth mode after sleep
        guard !Task.isCancelled && authenticationMode == .webAuthenticated else { break }

        // Perform token refresh
        await performScheduledRefresh()
      } catch {
        // If sleeping was cancelled, exit gracefully
        if error is CancellationError {
          break
        }

        // For other errors, wait a bit before retrying
        try? await Task.sleep(nanoseconds: 60_000_000_000)  // 60 seconds
      }
    }
  }

  /// Calculates the next refresh date based on refresh policy
  private func calculateNextRefreshDate() -> Date {
    let now = Date()

    switch refreshPolicy {
    case .periodic(let interval):
      return now.addingTimeInterval(interval)
    case .onExpiry:
      // For web auth tokens, assume 1 hour expiry by default
      return now.addingTimeInterval(60 * 60)
    case .manual:
      // This shouldn't be called for manual policy
      return now.addingTimeInterval(Double.greatestFiniteMagnitude)
    }
  }

  /// Performs scheduled token refresh
  private func performScheduledRefresh() async {
    do {
      _ = try await performRefreshWithRetry()
    } catch {
      refreshSubject.continuation.yield(.refreshFailed(apiToken: apiToken, error: error))
    }
  }

  /// Performs token refresh with retry logic
  private func performRefreshWithRetry() async throws -> TokenCredentials {
    var lastError: (any Error)?

    for attempt in 1...retryPolicy.maxAttempts {
      do {
        refreshSubject.continuation.yield(.refreshStarted(apiToken: apiToken))

        // In a real implementation, this would make a request to CloudKit's token refresh endpoint
        // For now, we'll simulate a refresh by creating new credentials with existing tokens
        guard let currentWebToken = webAuthToken else {
          throw TokenManagerError.invalidCredentials(
            reason: "No web auth token available for refresh")
        }

        let refreshedCredentials = TokenCredentials.webAuthToken(
          apiToken: apiToken,
          webToken: currentWebToken
        )

        // Store refreshed credentials if storage is available
        if let storage = storage {
          try await storage.store(refreshedCredentials, identifier: apiToken)
        }

        refreshSubject.continuation.yield(
          .refreshCompleted(apiToken: apiToken, newWebToken: currentWebToken))

        return refreshedCredentials
      } catch {
        lastError = error

        // Don't retry on the last attempt
        guard attempt < retryPolicy.maxAttempts else { break }

        // Wait before retrying with exponential backoff
        let delay = retryPolicy.delay(for: attempt)
        let nanoseconds = UInt64(delay * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
      }
    }

    // If we get here, all attempts failed
    let finalError =
      lastError
      ?? TokenManagerError.internalError(reason: "Refresh failed after all retry attempts")
    refreshSubject.continuation.yield(.refreshFailed(apiToken: apiToken, error: finalError))
    throw finalError
  }

  /// Manually triggers token refresh with new web auth token
  /// - Parameter newWebAuthToken: The new web authentication token to use
  /// - Returns: New TokenCredentials with refreshed web token
  public func refreshToken(with newWebAuthToken: String) async throws -> TokenCredentials {
    refreshSubject.continuation.yield(.refreshStarted(apiToken: apiToken))

    do {
      // Update the web auth token
      _ = webAuthToken
      webAuthToken = newWebAuthToken

      // Create new credentials with refreshed web token
      let newCredentials = try await getCurrentCredentials()!

      // Store new credentials if storage is available
      if let storage = storage {
        try await storage.store(newCredentials, identifier: apiToken)
      }

      refreshSubject.continuation.yield(
        .refreshCompleted(apiToken: apiToken, newWebToken: newWebAuthToken))

      return newCredentials
    } catch {
      refreshSubject.continuation.yield(.refreshFailed(apiToken: apiToken, error: error))
      throw error
    }
  }

  /// Stops the automatic token refresh scheduler
  private func stopRefreshScheduler() {
    refreshTask?.cancel()
    refreshTask = nil
  }
}

// MARK: - Authentication Mode

/// Represents the current authentication mode
public enum AuthenticationMode: Sendable, Equatable {
  /// API token only - container-level access
  case apiOnly

  /// API + Web token - user-specific access
  case webAuthenticated

  /// Human-readable description
  public var description: String {
    switch self {
    case .apiOnly:
      return "API Token Only (Container Access)"
    case .webAuthenticated:
      return "Web Authenticated (User Access)"
    }
  }

  /// Returns true if this mode supports user operations
  public var supportsUserOperations: Bool {
    switch self {
    case .apiOnly:
      return false
    case .webAuthenticated:
      return true
    }
  }
}
