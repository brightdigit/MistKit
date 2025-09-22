//
//  TokenManagerError.swift
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

/// Errors that can occur during token management operations
public enum TokenManagerError: Error, LocalizedError, Sendable {
  /// Invalid or malformed credentials
  case invalidCredentials(reason: String)

  /// Authentication failed with external service
  case authenticationFailed(underlying: (any Error)?)


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
    case .tokenExpired:
      return "Authentication token has expired"
    case .networkError(let error):
      return "Network error during authentication: \(error.localizedDescription)"
    case .internalError(let reason):
      return "Internal token manager error: \(reason)"
    }
  }
}
