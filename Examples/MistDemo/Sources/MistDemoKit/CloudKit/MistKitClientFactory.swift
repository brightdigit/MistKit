//
//  MistKitClientFactory.swift
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
public import MistKit

/// Factory for creating MistKit CloudKitService instances from MistDemo configuration
public struct MistKitClientFactory: Sendable {
  /// Create a CloudKitService for `config.database`, choosing auth method automatically.
  ///
  /// - `.public`: requires `CLOUDKIT_KEY_ID` + `CLOUDKIT_PRIVATE_KEY[_FILE]`
  /// - `.private` / `.shared`: requires `CLOUDKIT_API_TOKEN` + `CLOUDKIT_WEB_AUTH_TOKEN`
  ///
  /// When `config.badCredentials == true`, this short-circuits database-based auth
  /// selection and returns a service backed by a deliberately invalid web-auth
  /// `TokenManager` so the next CloudKit call yields a typed HTTP 401. Because
  /// that path always uses web auth, it is **not** supported on `.public` (which
  /// requires server-to-server signing) and will throw
  /// `ConfigurationError.badCredentialsOnPublicDB`.
  ///
  /// - Parameter config: The base MistDemo configuration.
  /// - Throws: `ConfigurationError` if required credentials are
  ///   missing, or if `badCredentials` is requested with `.public`.
  /// - Returns: A configured `CloudKitService` instance.
  public static func create(
    for config: MistDemoConfig
  ) throws -> CloudKitService {
    #if os(WASI)
      throw ConfigurationError.unsupportedPlatform(
        "MistDemo CLI requires URLSession; WASI builds must inject a transport explicitly"
      )
    #else
      if config.badCredentials {
        guard config.database != .public else {
          throw ConfigurationError.badCredentialsOnPublicDB
        }
        return try create(from: config, tokenManager: makeBadCredentialsTokenManager())
      }
      let credentials = try config.toDatabaseCredentials()
      let tokenManager = try credentials.makeTokenManager()
      return try CloudKitService(
        containerIdentifier: config.containerIdentifier,
        tokenManager: tokenManager,
        environment: config.environment,
        database: credentials.database
      )
    #endif
  }

  /// Build a `WebAuthTokenManager` whose tokens pass `validateCredentials()`'s
  /// local format check (64-char hex API token, ≥10-char web-auth token) but are
  /// guaranteed to be rejected by Apple's servers, producing a real HTTP 401.
  ///
  /// Used by both the factory's `badCredentials` short-circuit and by
  /// `DemoErrorsRunner.runUnauthorized` so the same definition feeds every
  /// 401-demo path.
  internal static func makeBadCredentialsTokenManager() -> WebAuthTokenManager {
    WebAuthTokenManager(
      apiToken: String(repeating: "0", count: 64),
      webAuthToken: String(repeating: "a", count: 100)
    )
  }

  /// Create a CloudKitService with a caller-supplied TokenManager, targeting
  /// `config.database`.
  public static func create(
    from config: MistDemoConfig,
    tokenManager: any TokenManager
  ) throws -> CloudKitService {
    #if os(WASI)
      throw ConfigurationError.unsupportedPlatform(
        "MistDemo CLI requires URLSession; WASI builds must inject a transport explicitly"
      )
    #else
      return try CloudKitService(
        containerIdentifier: config.containerIdentifier,
        tokenManager: tokenManager,
        environment: config.environment,
        database: config.database
      )
    #endif
  }
}

