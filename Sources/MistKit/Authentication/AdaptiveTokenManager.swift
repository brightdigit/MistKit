//
//  AdaptiveTokenManager.swift
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

/// Adaptive token manager that can transition between API-only and Web authentication
/// Starts with API token and can be upgraded to include web authentication
public actor AdaptiveTokenManager: TokenManager {
  private let apiToken: String
  private var webAuthToken: String?

  /// Creates an adaptive token manager starting with API token only
  /// - Parameter apiToken: The CloudKit API token
  public init(apiToken: String) {
    self.apiToken = apiToken
    self.webAuthToken = nil
  }

  // MARK: - TokenManager Protocol

  nonisolated public let supportsRefresh = false

  public var hasCredentials: Bool {
    get async {
      return !apiToken.isEmpty
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
    throw TokenManagerError.refreshNotSupported
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

    self.webAuthToken = webAuthToken
    return try await getCurrentCredentials()!
  }

  /// Downgrades to API-only authentication (removes web auth token)
  /// - Returns: New credentials with API-only authentication
  public func downgradeToAPIOnly() async throws -> TokenCredentials {
    self.webAuthToken = nil
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