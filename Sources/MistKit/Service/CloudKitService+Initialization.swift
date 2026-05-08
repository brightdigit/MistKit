//
//  CloudKitService+Initialization.swift
//  MistKit
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
public import OpenAPIRuntime

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

// MARK: - Credentials-based Initializer (All Platforms)

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Initialize CloudKit service with `Credentials`.
  ///
  /// Accepts any combination of `serverToServer` and `apiAuth` material.
  /// The token manager is selected based on the target `database` and what
  /// credentials are populated:
  ///
  /// - `.public`: prefers `serverToServer`. Falls back to `apiAuth` (web-auth
  ///   if `webAuthToken` is set, otherwise API-token-only).
  /// - `.private` / `.shared`: requires `apiAuth.webAuthToken`. CloudKit
  ///   rejects server-to-server signing for these databases, so any
  ///   `serverToServer` credential is ignored on this code path.
  ///
  /// - Throws: `CloudKitError.missingCredentials` when the target `database`
  ///   cannot be served by any populated credential set, or any error from
  ///   `ServerToServerAuthManager.init` when the PEM is malformed.
  public init(
    containerIdentifier: String,
    credentials: Credentials,
    environment: Environment = .development,
    database: Database = .public,
    transport: any ClientTransport
  ) throws {
    let tokenManager = try Self.makeTokenManager(
      credentials: credentials,
      database: database
    )

    self.containerIdentifier = containerIdentifier
    self.environment = environment
    self.database = database

    self.mistKitClient = try MistKitClient(
      container: containerIdentifier,
      environment: environment,
      database: database,
      tokenManager: tokenManager,
      transport: transport
    )
  }

  /// Initialize CloudKit service with a caller-supplied `TokenManager`.
  ///
  /// Useful for tests and bespoke auth setups where the standard
  /// `Credentials`-driven token-manager selection isn't appropriate.
  public init(
    containerIdentifier: String,
    tokenManager: any TokenManager,
    environment: Environment = .development,
    database: Database = .private,
    transport: any ClientTransport
  ) throws {
    self.containerIdentifier = containerIdentifier
    self.environment = environment
    self.database = database

    self.mistKitClient = try MistKitClient(
      container: containerIdentifier,
      environment: environment,
      database: database,
      tokenManager: tokenManager,
      transport: transport
    )
  }

  internal static func makeTokenManager(
    credentials: Credentials,
    database: Database
  ) throws -> any TokenManager {
    switch database {
    case .public:
      if let s2s = credentials.serverToServer {
        let pem = try s2s.privateKey.loadPEM()
        return try ServerToServerAuthManager(
          keyID: s2s.keyID,
          pemString: pem
        )
      }
      if let api = credentials.apiAuth {
        if let webAuthToken = api.webAuthToken {
          return WebAuthTokenManager(
            apiToken: api.apiToken,
            webAuthToken: webAuthToken
          )
        }
        return try APITokenManager(apiToken: api.apiToken)
      }
      throw CloudKitError.missingCredentials(
        database: .public,
        reason: "expected serverToServer or apiAuth credentials"
      )
    case .private, .shared:
      guard let api = credentials.apiAuth, let webAuthToken = api.webAuthToken else {
        throw CloudKitError.missingCredentials(
          database: database,
          reason:
            "private and shared databases require apiAuth with a webAuthToken"
        )
      }
      return WebAuthTokenManager(
        apiToken: api.apiToken,
        webAuthToken: webAuthToken
      )
    }
  }
}

// MARK: - URLSession Convenience Initializers (Non-WASI Platforms)

#if !os(WASI)
  internal import OpenAPIURLSession

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  extension CloudKitService {
    /// Initialize CloudKit service with `Credentials` using default
    /// `URLSessionTransport`.
    ///
    /// Available on platforms that support URLSession. For WASI builds, use
    /// the generic initializer that accepts a transport parameter.
    public init(
      containerIdentifier: String,
      credentials: Credentials,
      environment: Environment = .development,
      database: Database = .public
    ) throws {
      try self.init(
        containerIdentifier: containerIdentifier,
        credentials: credentials,
        environment: environment,
        database: database,
        transport: URLSessionTransport()
      )
    }

    /// Initialize CloudKit service with a custom `TokenManager` using default
    /// `URLSessionTransport`.
    ///
    /// Available on platforms that support URLSession. For WASI builds, use
    /// the generic initializer that accepts a transport parameter.
    public init(
      containerIdentifier: String,
      tokenManager: any TokenManager,
      environment: Environment = .development,
      database: Database = .private
    ) throws {
      try self.init(
        containerIdentifier: containerIdentifier,
        tokenManager: tokenManager,
        environment: environment,
        database: database,
        transport: URLSessionTransport()
      )
    }
  }
#endif
