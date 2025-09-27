//
//  TokenCredentials.swift
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

/// Encapsulates authentication credentials for CloudKit Web Services
public struct TokenCredentials: Sendable, Equatable {
  /// The authentication method and associated credentials
  public let method: AuthenticationMethod

  /// Optional metadata for tracking token creation or expiry
  public let metadata: [String: String]

  /// Returns true if these credentials support user-specific operations
  public var supportsUserOperations: Bool {
    switch method {
    case .apiToken, .serverToServer:
      return false
    case .webAuthToken:
      return true
    }
  }

  /// Returns the authentication method type as a string
  public var methodType: String {
    method.methodType
  }

  /// Creates new token credentials with the specified authentication method
  /// - Parameters:
  ///   - method: The authentication method to use
  ///   - metadata: Optional metadata for tracking purposes
  public init(method: AuthenticationMethod, metadata: [String: String] = [:]) {
    self.method = method
    self.metadata = metadata
  }

  /// Convenience initializer for API token authentication
  /// - Parameter apiToken: The API token string
  /// - Returns: TokenCredentials configured for API token authentication
  public static func apiToken(_ apiToken: String) -> TokenCredentials {
    TokenCredentials(method: .apiToken(apiToken))
  }

  /// Convenience initializer for web authentication
  /// - Parameters:
  ///   - apiToken: The API token string
  ///   - webToken: The web authentication token string
  /// - Returns: TokenCredentials configured for web authentication
  public static func webAuthToken(apiToken: String, webToken: String) -> TokenCredentials {
    TokenCredentials(method: .webAuthToken(apiToken: apiToken, webToken: webToken))
  }

  /// Convenience initializer for server-to-server authentication
  /// - Parameters:
  ///   - keyID: The key identifier
  ///   - privateKey: The ECDSA P-256 private key data
  /// - Returns: TokenCredentials configured for server-to-server authentication
  public static func serverToServer(keyID: String, privateKey: Data) -> TokenCredentials {
    TokenCredentials(method: .serverToServer(keyID: keyID, privateKey: privateKey))
  }
}
