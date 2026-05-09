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

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Credentials {
  /// Resolve the appropriate token manager for an outgoing request.
  ///
  /// Picks among the populated `serverToServer` and `apiAuth` credentials
  /// based on the target `database` and whether the route requires
  /// user-context authentication:
  ///
  /// - `requiresUserContext == true`: web-auth is mandatory regardless of
  ///   database. CloudKit's user-identity routes (`fetchCaller`,
  ///   `lookupUsersByEmail`, `lookupUsersByRecordName`,
  ///   `discoverAllUserIdentities`) live on `.public` but still need
  ///   web-auth to identify the caller.
  /// - `.public` + no user context: prefers server-to-server signing, falls
  ///   back to web-auth, then bare API-token.
  /// - `.private` / `.shared`: requires `apiAuth.webAuthToken`. CloudKit
  ///   rejects server-to-server signing for these databases, so any
  ///   `serverToServer` material is ignored on this path.
  ///
  /// - Throws: `CloudKitError.missingCredentials` when no populated credential
  ///   set can satisfy the requested combination, or any error from
  ///   `ServerToServerAuthManager.init` when the PEM is malformed.
  internal func makeTokenManager(
    for database: Database,
    requiresUserContext: Bool = false
  ) throws -> any TokenManager {
    if requiresUserContext {
      guard let api = apiAuth, let webAuthToken = api.webAuthToken else {
        throw CloudKitError.missingCredentials(
          database: database,
          reason: "user-context routes require apiAuth with a webAuthToken"
        )
      }
      return WebAuthTokenManager(
        apiToken: api.apiToken,
        webAuthToken: webAuthToken
      )
    }

    switch database {
    case .public:
      if let s2s = serverToServer {
        let pem = try s2s.privateKey.loadPEM()
        return try ServerToServerAuthManager(
          keyID: s2s.keyID,
          pemString: pem
        )
      }
      if let api = apiAuth {
        if let webAuthToken = api.webAuthToken {
          return WebAuthTokenManager(
            apiToken: api.apiToken,
            webAuthToken: webAuthToken
          )
        }
        return APITokenManager(apiToken: api.apiToken)
      }
      throw CloudKitError.missingCredentials(
        database: .public,
        reason: "expected serverToServer or apiAuth credentials"
      )
    case .private, .shared:
      guard let api = apiAuth, let webAuthToken = api.webAuthToken else {
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
