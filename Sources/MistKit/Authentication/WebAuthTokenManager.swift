//
//  WebAuthTokenManager.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

public import Foundation

/// Token manager for web authentication with API token + web auth token
/// Provides user-specific access to CloudKit Web Services
public final class WebAuthTokenManager: TokenManager, Sendable {
  private let apiToken: String
  private let webAuthToken: String
  private let tokenEncoder = CharacterMapEncoder()
  private let credentials: TokenCredentials
  private let refreshPolicy: TokenRefreshPolicy
  private let retryPolicy: RetryPolicy
  private let storage: (any TokenStorage)?

  // Token refresh state
  private let taskState = TaskState()
  private let refreshSubject = AsyncStream<TokenRefreshEvent>.makeStream()

  /// Actor to manage task state safely
  private actor TaskState {
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
      return !apiToken.isEmpty && !webAuthToken.isEmpty
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
    let apiTokenPattern = "^[a-fA-F0-9]{64}$"
    let regex = try NSRegularExpression(pattern: apiTokenPattern)
    let range = NSRange(location: 0, length: apiToken.count)
    let matches = regex.matches(in: apiToken, range: range)

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

// MARK: - Token Refresh Implementation

extension WebAuthTokenManager {
  /// Starts the automatic token refresh scheduler based on refresh policy
  private func startRefreshScheduler() {
    guard refreshPolicy.supportsAutomaticRefresh else { return }

    let task = Task<Void, Never> { [weak self] in
      await self?.runRefreshScheduler()
    }
    Task { await taskState.setTask(task) }
  }

  /// Runs the token refresh scheduler loop
  private func runRefreshScheduler() async {
    while !Task.isCancelled {
      do {
        let nextRefreshDate = calculateNextRefreshDate()

        // Emit scheduled event
        refreshSubject.continuation.yield(.refreshScheduled(apiToken: apiToken, nextRefresh: nextRefreshDate))

        // Wait until the scheduled refresh time
        let now = Date()
        if nextRefreshDate > now {
          let delay = nextRefreshDate.timeIntervalSince(now)
          let nanoseconds = UInt64(delay * 1_000_000_000)
          try await Task.sleep(nanoseconds: nanoseconds)
        }

        // Check if we're still running after sleep
        guard !Task.isCancelled else { break }

        // Perform token refresh
        await performScheduledRefresh()

      } catch {
        // If sleeping was cancelled, exit gracefully
        if error is CancellationError {
          break
        }

        // For other errors, wait a bit before retrying
        try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
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
      // In a real implementation, this would parse the token expiry
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

        // In a real implementation, this would:
        // 1. Make a request to CloudKit's token refresh endpoint
        // 2. Parse the new web auth token from the response
        // 3. Update internal state with the new token

        // For now, we'll simulate a refresh by creating new credentials
        // with the existing tokens (since we can't actually refresh without external API)
        let refreshedCredentials = TokenCredentials.webAuthToken(
          apiToken: apiToken,
          webToken: webAuthToken
        )

        // Store refreshed credentials if storage is available
        if let storage = storage {
          try await storage.store(refreshedCredentials, identifier: apiToken)
        }

        refreshSubject.continuation.yield(.refreshCompleted(apiToken: apiToken, newWebToken: webAuthToken))

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
    let finalError = lastError ?? TokenManagerError.internalError(reason: "Refresh failed after all retry attempts")
    refreshSubject.continuation.yield(.refreshFailed(apiToken: apiToken, error: finalError))
    throw finalError
  }

  /// Manually triggers token refresh (can be called regardless of refresh policy)
  /// - Parameter newWebAuthToken: The new web authentication token to use
  /// - Returns: New TokenCredentials with refreshed web token
  public func refreshToken(with newWebAuthToken: String) async throws -> TokenCredentials {
    refreshSubject.continuation.yield(.refreshStarted(apiToken: apiToken))

    do {
      // Create new credentials with refreshed web token
      let newCredentials = TokenCredentials.webAuthToken(
        apiToken: apiToken,
        webToken: newWebAuthToken
      )

      // Store new credentials if storage is available
      if let storage = storage {
        try await storage.store(newCredentials, identifier: apiToken)
      }

      refreshSubject.continuation.yield(.refreshCompleted(apiToken: apiToken, newWebToken: newWebAuthToken))

      return newCredentials

    } catch {
      refreshSubject.continuation.yield(.refreshFailed(apiToken: apiToken, error: error))
      throw error
    }
  }

  /// Stops the automatic token refresh scheduler
  public func stopRefreshScheduler() {
    Task { await taskState.cancelTask() }
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
    // Check API token format
    let apiTokenPattern = "^[a-fA-F0-9]{64}$"
    guard let regex = try? NSRegularExpression(pattern: apiTokenPattern) else {
      return false
    }
    let range = NSRange(location: 0, length: apiToken.count)
    let apiTokenMatches = regex.matches(in: apiToken, range: range)

    // Check web auth token has reasonable length
    let webTokenValid = webAuthToken.count >= 10

    return !apiTokenMatches.isEmpty && webTokenValid
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
    return TokenCredentials.webAuthToken(
      apiToken: apiToken,
      webToken: newWebAuthToken
    )
  }
}