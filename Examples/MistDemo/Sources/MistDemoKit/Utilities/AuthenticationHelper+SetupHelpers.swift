//
//  AuthenticationHelper+SetupHelpers.swift
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

extension AuthenticationHelper {
  internal static func setupServerToServer(
    keyID: String,
    privateKey: String?,
    privateKeyFile: String?,
    databaseOverride: MistKit.Database?
  ) async throws -> AuthenticationResult {
    let database: MistKit.Database = .public(.prefers(.serverToServer))

    if databaseOverride == .private {
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

  internal static func setupWebAuth(
    apiToken: String,
    webAuthToken: String,
    databaseOverride: MistKit.Database?
  ) async throws -> AuthenticationResult {
    let database: MistKit.Database = databaseOverride ?? .private

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

  internal static func setupAPIOnly(
    apiToken: String,
    databaseOverride: MistKit.Database?
  ) async throws -> AuthenticationResult {
    let database: MistKit.Database = .public(.prefers(.serverToServer))

    if databaseOverride == .private {
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

  internal static func createServerToServerManager(
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

  internal static func createWebAuthManager(
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
