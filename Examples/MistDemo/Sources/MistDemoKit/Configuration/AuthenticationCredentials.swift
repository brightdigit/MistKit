//
//  AuthenticationCredentials.swift
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
import MistKit

/// How MistDemo authenticates with CloudKit.
///
/// Distinct from the database (`MistKit.Database`) the request targets — the
/// public/private/shared database axis and the auth-method axis are orthogonal.
/// CloudKit accepts:
///
/// - public + server-to-server (CRUD with developer credentials)
/// - public + web-auth (user-context endpoints like `users/caller`,
///   `users/discover`, `users/lookup/*`)
/// - private + web-auth, shared + web-auth (per-user data)
///
/// Server-to-server signing against the private/shared databases is rejected
/// by Apple, so `DatabaseConfiguration.make(database:authentication:)`
/// validates the combination at construction time.
internal enum AuthenticationCredentials: Sendable {
  case serverToServer(keyID: String, privateKey: PrivateKeyMaterial)
  case webAuth(apiToken: String, webAuthToken: String)

  /// Construct the appropriate `TokenManager` for these credentials.
  ///
  /// - Throws: A `ConfigurationError` (for unsupported platforms) or an error
  ///   from `ServerToServerAuthManager` if the PEM string is malformed.
  internal func makeTokenManager() throws -> any TokenManager {
    switch self {
    case .serverToServer(let keyID, let privateKey):
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        throw ConfigurationError.unsupportedPlatform(
          "Server-to-server authentication requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+"
        )
      }
      let pem = try privateKey.loadPEM()
      return try ServerToServerAuthManager(keyID: keyID, pemString: pem)
    case .webAuth(let apiToken, let webAuthToken):
      return WebAuthTokenManager(apiToken: apiToken, webAuthToken: webAuthToken)
    }
  }
}
