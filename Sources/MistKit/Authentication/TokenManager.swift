//
//  TokenManager.swift
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

// MARK: - Authentication Method

/// Represents the different authentication methods supported by CloudKit Web Services
public enum AuthenticationMethod: Sendable, Equatable {
  /// Simple API token authentication
  case apiToken(String)

  /// API token with web authentication token for user-specific operations
  case webAuthToken(apiToken: String, webToken: String)

  /// Server-to-server authentication using ECDSA P-256 private key
  case serverToServer(keyID: String, privateKey: Data)
}

// MARK: - Token Credentials

/// Encapsulates authentication credentials for CloudKit Web Services
public struct TokenCredentials: Sendable, Equatable {
  /// The authentication method and associated credentials
  public let method: AuthenticationMethod

  /// Optional metadata for tracking token creation or expiry
  public let metadata: [String: String]

  /// Creates new token credentials with the specified authentication method
  /// - Parameters:
  ///   - method: The authentication method to use
  ///   - metadata: Optional metadata for tracking purposes
  public init(method: AuthenticationMethod, metadata: [String: String] = [:]) {
    self.method = method
    self.metadata = metadata
  }
}

// MARK: - Token Manager Protocol

/// Protocol for managing authentication tokens and credentials for CloudKit Web Services
public protocol TokenManager: Sendable {
  /// Validates the current authentication credentials
  /// - Returns: True if credentials are valid and usable
  /// - Throws: TokenManagerError if validation fails
  func validateCredentials() async throws -> Bool

  /// Retrieves the current token credentials
  /// - Returns: Current TokenCredentials or nil if none available
  /// - Throws: TokenManagerError if retrieval fails
  func getCurrentCredentials() async throws -> TokenCredentials?

  /// Refreshes the authentication credentials if supported
  /// - Returns: New TokenCredentials if refresh was successful
  /// - Throws: TokenManagerError if refresh fails or is not supported
  func refreshCredentials() async throws -> TokenCredentials?

  /// Checks if the token manager supports credential refresh
  var supportsRefresh: Bool { get }

  /// Checks if credentials are currently available
  var hasCredentials: Bool { get async }
}

// MARK: - Token Manager Errors

/// Errors that can occur during token management operations
public enum TokenManagerError: Error, LocalizedError, Sendable {
  /// Invalid or malformed credentials
  case invalidCredentials(reason: String)

  /// Authentication failed with external service
  case authenticationFailed(underlying: (any Error)?)

  /// Token refresh is not supported by this manager
  case refreshNotSupported

  /// Token has expired and cannot be used
  case tokenExpired

  /// Network or communication error during authentication
  case networkError(underlying: any Error)

  /// Internal error in token management
  case internalError(reason: String)

  public var errorDescription: String? {
    switch self {
    case .invalidCredentials(let reason):
      return "Invalid credentials: \(reason)"
    case .authenticationFailed(let error):
      return "Authentication failed: \(error?.localizedDescription ?? "Unknown error")"
    case .refreshNotSupported:
      return "Token refresh is not supported by this authentication method"
    case .tokenExpired:
      return "Authentication token has expired"
    case .networkError(let error):
      return "Network error during authentication: \(error.localizedDescription)"
    case .internalError(let reason):
      return "Internal token manager error: \(reason)"
    }
  }
}

// MARK: - Authentication Method Extensions

extension AuthenticationMethod {
  /// Returns the API token for all authentication methods
  public var apiToken: String {
    switch self {
    case .apiToken(let token):
      return token
    case .webAuthToken(let apiToken, _):
      return apiToken
    case .serverToServer:
      return "" // Server-to-server doesn't use API tokens in the same way
    }
  }

  /// Returns the web auth token if available
  public var webAuthToken: String? {
    switch self {
    case .apiToken:
      return nil
    case .webAuthToken(_, let webToken):
      return webToken
    case .serverToServer:
      return nil
    }
  }

  /// Returns the server-to-server key ID if applicable
  public var serverKeyID: String? {
    switch self {
    case .apiToken, .webAuthToken:
      return nil
    case .serverToServer(let keyID, _):
      return keyID
    }
  }

  /// Returns the private key data for server-to-server authentication
  public var privateKeyData: Data? {
    switch self {
    case .apiToken, .webAuthToken:
      return nil
    case .serverToServer(_, let privateKey):
      return privateKey
    }
  }

  /// Returns a string representation of the authentication method type
  public var methodType: String {
    switch self {
    case .apiToken:
      return "api-token"
    case .webAuthToken:
      return "web-auth-token"
    case .serverToServer:
      return "server-to-server"
    }
  }
}

// MARK: - Token Credentials Extensions

extension TokenCredentials {
  /// Convenience initializer for API token authentication
  /// - Parameter apiToken: The API token string
  public static func apiToken(_ apiToken: String) -> TokenCredentials {
    TokenCredentials(method: .apiToken(apiToken))
  }

  /// Convenience initializer for web authentication
  /// - Parameters:
  ///   - apiToken: The API token string
  ///   - webToken: The web authentication token string
  public static func webAuthToken(apiToken: String, webToken: String) -> TokenCredentials {
    TokenCredentials(method: .webAuthToken(apiToken: apiToken, webToken: webToken))
  }

  /// Convenience initializer for server-to-server authentication
  /// - Parameters:
  ///   - keyID: The key identifier
  ///   - privateKey: The ECDSA P-256 private key data
  public static func serverToServer(keyID: String, privateKey: Data) -> TokenCredentials {
    TokenCredentials(method: .serverToServer(keyID: keyID, privateKey: privateKey))
  }

  /// Returns true if these credentials support user-specific operations
  public var supportsUserOperations: Bool {
    switch method {
    case .apiToken:
      return false
    case .webAuthToken, .serverToServer:
      return true
    }
  }

  /// Returns the authentication method type as a string
  public var methodType: String {
    method.methodType
  }
}