//
//  MistDemoConfig+DatabaseConfiguration.swift
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

extension MistDemoConfig {
  /// Build the primary `DatabaseConfiguration` matching `self.database`.
  ///
  /// - `.public` → server-to-server (requires `keyID` + `privateKey`/`privateKeyFile`)
  /// - `.private`, `.shared` → web-auth (requires `apiToken` + `webAuthToken`)
  ///
  /// - Throws: `ConfigurationError.missingRequired` if any required field for
  ///   the chosen database is missing or empty.
  internal func toPrimaryConfiguration() throws -> DatabaseConfiguration {
    let auth: AuthenticationCredentials
    switch database {
    case .public:
      auth = try resolveServerToServerAuth()
    case .private, .shared:
      auth = try resolveWebAuth()
    }
    return try DatabaseConfiguration.make(
      database: database,
      authentication: auth
    )
  }

  /// Build a public+web-auth `DatabaseConfiguration` for user-context endpoints
  /// (`users/caller`, `users/discover`, `users/lookup/*`).
  ///
  /// Returns `nil` when web-auth tokens are not available, allowing callers to
  /// gracefully skip user-identity coverage instead of failing.
  internal func toUserContextConfiguration() -> DatabaseConfiguration? {
    guard let auth = try? resolveWebAuth() else { return nil }
    return try? DatabaseConfiguration.make(
      database: .public,
      authentication: auth
    )
  }

  // MARK: - Auth resolution helpers

  private func resolveServerToServerAuth() throws -> AuthenticationCredentials {
    guard let keyID, !keyID.isEmpty else {
      throw ConfigurationError.missingRequired(
        "key.id",
        suggestion: "Provide via CLOUDKIT_KEY_ID environment variable"
      )
    }
    let material = try resolvePrivateKeyMaterial()
    return .serverToServer(keyID: keyID, privateKey: material)
  }

  private func resolvePrivateKeyMaterial() throws -> PrivateKeyMaterial {
    if let raw = privateKey, !raw.isEmpty {
      return .raw(raw)
    } else if let path = privateKeyFile, !path.isEmpty {
      return .file(path: path)
    }
    throw ConfigurationError.missingRequired(
      "private.key",
      suggestion: "Provide via CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH"
    )
  }

  private func resolveWebAuth() throws -> AuthenticationCredentials {
    let resolvedAPIToken = AuthenticationHelper.resolveAPIToken(apiToken)
    guard !resolvedAPIToken.isEmpty else {
      throw ConfigurationError.missingRequired(
        "api.token",
        suggestion: "Provide via CLOUDKIT_API_TOKEN environment variable"
      )
    }
    let resolvedWebAuth = webAuthToken.flatMap {
      AuthenticationHelper.resolveWebAuthToken($0)
    }
    guard let resolvedWebAuth, !resolvedWebAuth.isEmpty else {
      throw ConfigurationError.missingRequired(
        "web.auth.token",
        suggestion: "Provide via CLOUDKIT_WEB_AUTH_TOKEN or run `mistdemo auth-token`"
      )
    }
    return .webAuth(apiToken: resolvedAPIToken, webAuthToken: resolvedWebAuth)
  }
}
