//
//  MistDemoConfig+DatabaseCredentials.swift
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
  /// Bundle this config's flat auth fields into a `DatabaseCredentials` value
  /// matching `self.database`, validating that the required credentials are
  /// present.
  ///
  /// - Throws: `ConfigurationError.missingRequired` if any required field for
  ///   the chosen database is missing or empty.
  internal func toDatabaseCredentials() throws -> DatabaseCredentials {
    switch database {
    case .public:
      guard let keyID, !keyID.isEmpty else {
        throw ConfigurationError.missingRequired(
          "key.id",
          suggestion: "Provide via CLOUDKIT_KEY_ID environment variable"
        )
      }
      let material: PrivateKeyMaterial
      if let raw = privateKey, !raw.isEmpty {
        material = .raw(raw)
      } else if let path = privateKeyFile, !path.isEmpty {
        material = .file(path: path)
      } else {
        throw ConfigurationError.missingRequired(
          "private.key",
          suggestion: "Provide via CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH"
        )
      }
      return .publicDatabase(keyID: keyID, privateKey: material)

    case .private, .shared:
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
      return database == .private
        ? .privateDatabase(apiToken: resolvedAPIToken, webAuthToken: resolvedWebAuth)
        : .sharedDatabase(apiToken: resolvedAPIToken, webAuthToken: resolvedWebAuth)
    }
  }
}
