//
//  Credentials+TokenManager.swift
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

extension Credentials {
  /// Resolve the appropriate token manager for an outgoing request.
  ///
  /// The signing choice is encoded in `database`:
  /// - `.public(let auth)` consults `auth` and the populated credential sets
  ///   per the table below.
  /// - `.private` / `.shared` always use web-auth — CloudKit rejects
  ///   server-to-server signing on those scopes — and require
  ///   `apiAuth.webAuthToken`.
  ///
  /// Resolution for `.public(let auth)`:
  /// - `auth.required` + mode's creds present → use `auth.mode`.
  /// - `auth.required` + mode's creds absent → throw `.preferenceRequired`.
  /// - `auth.prefers` + mode's creds present → use `auth.mode`.
  /// - `auth.prefers` + mode's creds absent → fall back to the other mode.
  /// - `auth.prefers` + neither mode configured → throw `.notConfigured`.
  ///
  /// - Throws: `CloudKitError.missingCredentials` when no populated credential
  ///   set can satisfy the requested combination,
  ///   `CloudKitError.invalidPrivateKey` when a `.file(path:)` PEM cannot be
  ///   read, or any error from `ServerToServerAuthManager.init` when the PEM
  ///   is malformed.
  internal func makeTokenManager(
    for database: Database
  ) throws -> any TokenManager {
    switch database {
    case .public(let auth):
      return try makePublicTokenManager(auth: auth)
    case .private, .shared:
      return try makePrivateOrSharedTokenManager(database)
    }
  }

  private func makePublicTokenManager(
    auth: PublicAuthPreference
  ) throws -> any TokenManager {
    switch auth.mode {
    case .serverToServer:
      return try makePublicWithS2SPreference(auth: auth)
    case .webAuth:
      return try makePublicWithWebAuthPreference(auth: auth)
    }
  }

  private func makePublicWithS2SPreference(
    auth: PublicAuthPreference
  ) throws -> any TokenManager {
    if let s2s = serverToServer {
      return try makeServerToServerManager(s2s)
    }
    if auth.required {
      throw CloudKitError.missingCredentials(
        database: .public(auth),
        availability: .preferenceRequired,
        reason: "PublicAuthPreference.requires(.serverToServer) "
          + "but no serverToServer credentials are configured"
      )
    }
    if let api = apiAuth {
      return makeAPITokenManager(api)
    }
    throw CloudKitError.missingCredentials(
      database: .public(auth),
      availability: .notConfigured,
      reason: "expected serverToServer or apiAuth credentials"
    )
  }

  private func makePublicWithWebAuthPreference(
    auth: PublicAuthPreference
  ) throws -> any TokenManager {
    if let api = apiAuth, let webAuthToken = api.webAuthToken {
      return WebAuthTokenManager(
        apiToken: api.apiToken,
        webAuthToken: webAuthToken
      )
    }
    if auth.required {
      throw CloudKitError.missingCredentials(
        database: .public(auth),
        availability: .preferenceRequired,
        reason: "PublicAuthPreference.requires(.webAuth) "
          + "but no apiAuth.webAuthToken is configured"
      )
    }
    if let s2s = serverToServer {
      return try makeServerToServerManager(s2s)
    }
    if let api = apiAuth {
      return makeAPITokenManager(api)
    }
    throw CloudKitError.missingCredentials(
      database: .public(auth),
      availability: .notConfigured,
      reason: "expected apiAuth.webAuthToken or serverToServer credentials"
    )
  }

  private func makePrivateOrSharedTokenManager(
    _ database: Database
  ) throws -> any TokenManager {
    guard let api = apiAuth, let webAuthToken = api.webAuthToken else {
      throw CloudKitError.missingCredentials(
        database: database,
        availability: .notConfigured,
        reason:
          "private and shared databases require apiAuth with a webAuthToken"
      )
    }
    return WebAuthTokenManager(
      apiToken: api.apiToken,
      webAuthToken: webAuthToken
    )
  }

  private func makeServerToServerManager(
    _ s2s: ServerToServerCredentials
  ) throws -> any TokenManager {
    let pem: String
    do {
      pem = try s2s.privateKey.loadPEM()
    } catch {
      throw CloudKitError.invalidPrivateKey(
        path: s2s.privateKey.filePath,
        underlying: error
      )
    }
    return try ServerToServerAuthManager(
      keyID: s2s.keyID,
      pemString: pem
    )
  }

  private func makeAPITokenManager(
    _ api: APICredentials
  ) -> any TokenManager {
    if let webAuthToken = api.webAuthToken {
      return WebAuthTokenManager(
        apiToken: api.apiToken,
        webAuthToken: webAuthToken
      )
    }
    return APITokenManager(apiToken: api.apiToken)
  }
}
