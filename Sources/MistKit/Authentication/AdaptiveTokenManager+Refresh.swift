//
//  AdaptiveTokenManager+Refresh.swift
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

// MARK: - Token Refresh Implementation

extension AdaptiveTokenManager {
  /// Starts the automatic token refresh scheduler (only in web auth mode)
  internal func startRefreshScheduler() {
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
  internal func performRefreshWithRetry() async throws -> TokenCredentials {
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
  internal func stopRefreshScheduler() {
    refreshTask?.cancel()
    refreshTask = nil
  }
}
