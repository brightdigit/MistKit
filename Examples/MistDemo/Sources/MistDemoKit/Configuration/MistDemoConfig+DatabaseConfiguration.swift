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

internal import Foundation
internal import MistKit

extension MistDemoConfig {
  /// Build `Credentials` for the primary `CloudKitService` targeting
  /// `self.database`.
  ///
  /// - `.public`: requires server-to-server material (`keyID` +
  ///   `privateKey`/`privateKeyFile`). If web-auth env vars are also set,
  ///   they're populated alongside so the same `Credentials` can back a
  ///   user-context service.
  /// - `.private` / `.shared`: requires `apiToken` + `webAuthToken`.
  ///
  /// - Throws: `ConfigurationError.missingRequired` if any required field for
  ///   the chosen database is missing or empty.
  internal func toPrimaryCredentials() throws -> Credentials {
    switch database {
    case .public:
      let s2s = try resolveServerToServerCredentials()
      // Optional: also include web-auth so a single service can serve
      // user-identity routes (`fetchCaller`, `lookupUsers*`) alongside
      // S2S-signed record operations on `.public`.
      let webAuth = try? resolveAPICredentials()
      return try Credentials(serverToServer: s2s, apiAuth: webAuth)
    case .private, .shared:
      let apiAuth = try resolveAPICredentials()
      return try Credentials(apiAuth: apiAuth)
    }
  }

  /// Indicates whether `toPrimaryCredentials()` will produce credentials that
  /// can satisfy user-identity endpoints (`fetchCaller`, `lookupUsers*`).
  ///
  /// Those routes require web-auth even on `.public`. Used by the integration
  /// runner to decide whether to schedule user-identity phases.
  internal var hasUserContextCredentials: Bool {
    (try? resolveAPICredentials()) != nil
  }

  // MARK: - Resolution helpers

  private func resolveServerToServerCredentials() throws -> ServerToServerCredentials {
    guard let keyID, !keyID.isEmpty else {
      throw ConfigurationError.missingRequired(
        "key.id",
        suggestion: "Provide via CLOUDKIT_KEY_ID environment variable"
      )
    }
    let material = try resolvePrivateKeyMaterial()
    return ServerToServerCredentials(keyID: keyID, privateKey: material)
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

  private func resolveAPICredentials() throws -> APICredentials {
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
    return APICredentials(
      apiToken: resolvedAPIToken,
      webAuthToken: resolvedWebAuth
    )
  }
}
