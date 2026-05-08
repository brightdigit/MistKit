//
//  DatabaseCredentials.swift
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

/// Source of a server-to-server private key — either inline PEM or a path to a `.pem` file.
internal enum PrivateKeyMaterial: Sendable {
  case raw(String)
  case file(path: String)

  internal func loadPEM() throws -> String {
    switch self {
    case .raw(let pem):
      return pem.replacingOccurrences(of: "\\n", with: "\n")
    case .file(let path):
      do {
        return try String(contentsOfFile: path, encoding: .utf8)
      } catch {
        throw ConfigurationError.missingRequired(
          "private.key",
          suggestion:
            "Failed to read private key from '\(path)': \(error.localizedDescription)"
        )
      }
    }
  }
}

/// A database choice paired with the credentials required to access it.
///
/// Bundling these together means a constructed value cannot represent an
/// invalid combination (e.g. `.public` without server-to-server signing
/// credentials), shifting the validation that previously lived in
/// `MistKitClientFactory.create(for:)` into the type system.
internal enum DatabaseCredentials: Sendable {
  case publicDatabase(keyID: String, privateKey: PrivateKeyMaterial)
  case privateDatabase(apiToken: String, webAuthToken: String)
  case sharedDatabase(apiToken: String, webAuthToken: String)

  /// The corresponding `MistKit.Database` for this credentials variant.
  internal var database: MistKit.Database {
    switch self {
    case .publicDatabase: return .public
    case .privateDatabase: return .private
    case .sharedDatabase: return .shared
    }
  }

  /// Construct the appropriate `TokenManager` for these credentials.
  ///
  /// - Throws: A `ConfigurationError` (for unsupported platforms) or an error
  ///   from `ServerToServerAuthManager` if the PEM string is malformed.
  internal func makeTokenManager() throws -> any TokenManager {
    switch self {
    case .publicDatabase(let keyID, let privateKey):
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        throw ConfigurationError.unsupportedPlatform(
          "Public database access requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+"
        )
      }
      let pem = try privateKey.loadPEM()
      return try ServerToServerAuthManager(keyID: keyID, pemString: pem)
    case .privateDatabase(let apiToken, let webAuthToken),
      .sharedDatabase(let apiToken, let webAuthToken):
      return WebAuthTokenManager(apiToken: apiToken, webAuthToken: webAuthToken)
    }
  }
}

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
