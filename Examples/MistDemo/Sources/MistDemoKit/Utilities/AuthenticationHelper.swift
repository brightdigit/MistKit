// swiftlint:disable file_length
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
    databaseOverride: String? = nil
  ) async throws -> AuthenticationResult {
    if let keyID {
      return try await setupServerToServer(
        apiToken: apiToken,
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

  // MARK: - Private Helpers

  private static func setupServerToServer(
    apiToken: String,
    keyID: String,
    privateKey: String?,
    privateKeyFile: String?,
    databaseOverride: String?
  ) async throws -> AuthenticationResult {
    let database = MistKit.Database.public

    if let override = databaseOverride, override == "private" {
      throw AuthenticationError.serverToServerRequiresPublicDatabase
    }

    let manager = try await createServerToServerManager(
      keyID: keyID,
      privateKey: privateKey,
      privateKeyFile: privateKeyFile
    )

    let method =
      "\u{1F510} Server-to-server authentication"
      + " (public database only)"
    return AuthenticationResult(
      tokenManager: manager,
      database: database,
      authMethod: method
    )
  }

  private static func setupWebAuth(
    apiToken: String,
    webAuthToken: String,
    databaseOverride: String?
  ) async throws -> AuthenticationResult {
    let database: MistKit.Database
    if let override = databaseOverride {
      database = override == "public" ? .public : .private
    } else {
      database = .private
    }

    let manager = try await createWebAuthManager(
      apiToken: apiToken,
      webAuthToken: webAuthToken
    )

    let method =
      "\u{1F310} Web authentication (\(database) database)"
    return AuthenticationResult(
      tokenManager: manager,
      database: database,
      authMethod: method
    )
  }

  private static func setupAPIOnly(
    apiToken: String,
    databaseOverride: String?
  ) async throws -> AuthenticationResult {
    let database = MistKit.Database.public

    if let override = databaseOverride, override == "private" {
      throw AuthenticationError.privateRequiresWebAuth
    }

    let manager = APITokenManager(apiToken: apiToken)

    let isValid = try await manager.validateCredentials()
    guard isValid else {
      throw AuthenticationError.invalidAPIToken
    }

    let method =
      "\u{1F511} API-only authentication (public database only)"
    return AuthenticationResult(
      tokenManager: manager,
      database: database,
      authMethod: method
    )
  }

  private static func createServerToServerManager(
    keyID: String,
    privateKey: String?,
    privateKeyFile: String?
  ) async throws -> any TokenManager {
    let privateKeyPEM: String
    if let keyFile = privateKeyFile {
      do {
        privateKeyPEM = try String(
          contentsOfFile: keyFile, encoding: .utf8
        )
      } catch {
        throw AuthenticationError.failedToReadPrivateKeyFile(
          path: keyFile,
          errorDescription: error.localizedDescription
        )
      }
    } else if let key = privateKey {
      privateKeyPEM = key
    } else {
      throw AuthenticationError.missingPrivateKey
    }

    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      throw AuthenticationError.serverToServerNotSupported
    }

    let manager = try ServerToServerAuthManager(
      keyID: keyID,
      pemString: privateKeyPEM
    )

    let isValid = try await manager.validateCredentials()
    guard isValid else {
      throw AuthenticationError.invalidServerToServerCredentials
    }

    return manager
  }

  private static func createWebAuthManager(
    apiToken: String,
    webAuthToken: String
  ) async throws -> any TokenManager {
    let manager = WebAuthTokenManager(
      apiToken: apiToken,
      webAuthToken: webAuthToken
    )

    let isValid = try await manager.validateCredentials()
    guard isValid else {
      throw AuthenticationError.invalidWebAuthCredentials
    }

    return manager
  }
}
