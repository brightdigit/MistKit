//
//  AuthenticationHelper.swift
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

/// Helper utilities for managing CloudKit authentication.
internal enum AuthenticationHelper {
  /// A function that maps an environment-variable name to its value.
  internal typealias EnvironmentReader =
    @Sendable (String) -> String?

  /// Default reader backed by `ProcessInfo` via `EnvironmentConfig`.
  internal static let processEnvironmentReader: EnvironmentReader = {
    EnvironmentConfig.getOptional($0)
  }

  // MARK: - Public API

  /// Creates appropriate TokenManager and determines database.
  internal static func setupAuthentication(
    apiToken: String,
    webAuthToken: String?,
    keyID: String?,
    privateKey: String?,
    privateKeyFile: String?,
    databaseOverride: MistKit.Database? = nil
  ) async throws -> AuthenticationResult {
    if let keyID {
      return try await setupServerToServer(
        keyID: keyID,
        privateKey: privateKey,
        privateKeyFile: privateKeyFile,
        databaseOverride: databaseOverride
      )
    }

    if let webAuthToken, !webAuthToken.isEmpty {
      return try await setupWebAuth(
        apiToken: apiToken,
        webAuthToken: webAuthToken,
        databaseOverride: databaseOverride
      )
    }

    return try await setupAPIOnly(
      apiToken: apiToken,
      databaseOverride: databaseOverride
    )
  }

  /// Resolves API token from option or environment variable.
  internal static func resolveAPIToken(
    _ apiToken: String,
    environment: EnvironmentReader = processEnvironmentReader
  ) -> String {
    apiToken.isEmpty
      ? environment(EnvironmentConfig.Keys.cloudKitAPIToken) ?? ""
      : apiToken
  }

  /// Resolves web auth token from option or environment variable.
  internal static func resolveWebAuthToken(
    _ webAuthToken: String,
    environment: EnvironmentReader = processEnvironmentReader
  ) -> String? {
    let envKey = MistDemoConstants.EnvironmentVars.cloudKitWebAuthToken
    let token =
      webAuthToken.isEmpty
      ? environment(envKey) ?? ""
      : webAuthToken
    return token.isEmpty ? nil : token
  }
}
