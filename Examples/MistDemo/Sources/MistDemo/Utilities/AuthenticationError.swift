//
//  AuthenticationError.swift
//  MistDemo
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

import Foundation

/// Errors that can occur during authentication setup
enum AuthenticationError: LocalizedError, Sendable {
  case serverToServerRequiresPublicDatabase
  case failedToReadPrivateKeyFile(path: String, errorDescription: String)
  case missingPrivateKey
  case serverToServerNotSupported
  case invalidServerToServerCredentials
  case privateRequiresWebAuth
  case invalidWebAuthCredentials
  case invalidAPIToken
  case noValidAuthenticationMethod

  // MARK: Internal

  var errorDescription: String? {
    switch self {
    case .serverToServerRequiresPublicDatabase:
      "Server-to-server authentication only supports public database access"
    case let .failedToReadPrivateKeyFile(path, errorDescription):
      "Failed to read private key file at \(path): \(errorDescription)"
    case .missingPrivateKey:
      "Server-to-server authentication requires a private key (use --private-key or --private-key-file)"
    case .serverToServerNotSupported:
      "Server-to-server authentication requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+"
    case .invalidServerToServerCredentials:
      "Server-to-server credentials validation failed. Check your key ID and private key."
    case .privateRequiresWebAuth:
      "Private database access requires web authentication token. Use 'mistdemo auth' to sign in with Apple ID or provide --web-auth-token"
    case .invalidWebAuthCredentials:
      "Web authentication credentials validation failed. Token may be expired."
    case .invalidAPIToken:
      "API token validation failed. Check your CloudKit API token."
    case .noValidAuthenticationMethod:
      "No valid authentication method could be determined from provided credentials"
    }
  }
}
