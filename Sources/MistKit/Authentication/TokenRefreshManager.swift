//
//  TokenRefreshManager.swift
//  PackageDSLKit
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

/// Protocol for managing token refresh operations
public protocol TokenRefreshManager: Sendable {
  /// Refreshes the current token if needed
  /// - Returns: Updated TokenCredentials or nil if no refresh needed
  /// - Throws: TokenManagerError if refresh fails
  func refreshTokenIfNeeded() async throws -> TokenCredentials?
  
  /// Forces a token refresh regardless of expiry
  /// - Returns: Updated TokenCredentials
  /// - Throws: TokenManagerError if refresh fails
  func forceRefreshToken() async throws -> TokenCredentials
  
  /// Checks if token refresh is needed
  /// - Returns: True if refresh is needed
  func isRefreshNeeded() async -> Bool
}

/// Token refresh events for notification system
public enum TokenRefreshEvent: Sendable {
  case refreshStarted
  case refreshCompleted(TokenCredentials)
  case refreshFailed(any Error)
  case refreshSkipped(reason: String)
}

/// Protocol for token refresh notifications
public protocol TokenRefreshNotifier: Sendable {
  /// AsyncStream of token refresh events
  var refreshEvents: AsyncStream<TokenRefreshEvent> { get async }
  
  /// Notify of a token refresh event
  /// - Parameter event: The refresh event
  func notify(_ event: TokenRefreshEvent) async
}

/// Default implementation of token refresh manager
public final class DefaultTokenRefreshManager: TokenRefreshManager, TokenRefreshNotifier {
  private let tokenManager: any TokenManager
  private let storage: (any TokenStorage)?
  private let refreshThreshold: TimeInterval
  private let lastRefreshKey = "last_token_refresh"
  private let tokenExpiryKey = "token_expiry"
  
  private let eventContinuation: AsyncStream<TokenRefreshEvent>.Continuation
  public let refreshEvents: AsyncStream<TokenRefreshEvent>
  
  /// Creates a new token refresh manager
  /// - Parameters:
  ///   - tokenManager: The token manager to refresh
  ///   - storage: Optional storage for tracking refresh state
  ///   - refreshThreshold: Time threshold before expiry to trigger refresh (default: 300 seconds)
  public init(
    tokenManager: any TokenManager,
    storage: (any TokenStorage)? = nil,
    refreshThreshold: TimeInterval = 300
  ) {
    self.tokenManager = tokenManager
    self.storage = storage
    self.refreshThreshold = refreshThreshold
    
    let (stream, continuation) = AsyncStream.makeStream(of: TokenRefreshEvent.self)
    self.refreshEvents = stream
    self.eventContinuation = continuation
  }
  
  deinit {
    eventContinuation.finish()
  }
  
  // MARK: - TokenRefreshManager
  
  public func refreshTokenIfNeeded() async throws -> TokenCredentials? {
    guard await isRefreshNeeded() else {
      await notify(.refreshSkipped(reason: "Token is still valid"))
      return nil
    }
    
    return try await performRefresh()
  }
  
  public func forceRefreshToken() async throws -> TokenCredentials {
    return try await performRefresh()
  }
  
  public func isRefreshNeeded() async -> Bool {
    // For now, always return false as most token types don't have expiry
    // This can be extended based on token type and metadata
    return false
  }
  
  // MARK: - TokenRefreshNotifier
  
  public func notify(_ event: TokenRefreshEvent) async {
    eventContinuation.yield(event)
  }
  
  // MARK: - Private Methods
  
  private func performRefresh() async throws -> TokenCredentials {
    await notify(.refreshStarted)
    
    do {
      // For now, just validate and return current credentials
      // In a real implementation, this would make API calls to refresh
      guard let credentials = try await tokenManager.getCurrentCredentials() else {
        throw TokenManagerError.internalError(reason: "No credentials available")
      }
      
      await notify(.refreshCompleted(credentials))
      return credentials
    } catch {
      await notify(.refreshFailed(error))
      throw error
    }
  }
}
