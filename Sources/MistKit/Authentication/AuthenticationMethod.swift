//
//  AuthenticationMethod.swift
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

/// Represents the different authentication methods supported by CloudKit Web Services
public enum AuthenticationMethod: Sendable, Equatable {
  /// Simple API token authentication
  case apiToken(String)

  /// API token with web authentication token for user-specific operations
  case webAuthToken(apiToken: String, webToken: String)

  /// Server-to-server authentication using ECDSA P-256 private key
  case serverToServer(keyID: String, privateKey: Data)
}

// MARK: - AuthenticationMethod Extensions

extension AuthenticationMethod {
  /// Returns the API token for all authentication methods
  public var apiToken: String {
    switch self {
    case .apiToken(let token):
      return token
    case .webAuthToken(let apiToken, _):
      return apiToken
    case .serverToServer:
      return ""  // Server-to-server doesn't use API tokens in the same way
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
