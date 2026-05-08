//
//  Credentials.swift
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

/// Server-to-server signing credentials for the public CloudKit database.
///
/// CloudKit accepts server-to-server signing only against the **public**
/// database. Private and shared databases require web-auth credentials.
public struct ServerToServerCredentials: Sendable {
  public let keyID: String
  public let privateKey: PrivateKeyMaterial

  public init(keyID: String, privateKey: PrivateKeyMaterial) {
    self.keyID = keyID
    self.privateKey = privateKey
  }
}

/// API-token credentials, optionally augmented with a web-auth token for
/// user-context routes.
///
/// - `apiToken` alone is sufficient for read access against the public
///   database.
/// - `webAuthToken` is required for any route that operates as a specific
///   user — that includes every user-identity endpoint (`fetchCaller`,
///   `lookupUsersByEmail`, …) and any write/read against the private or
///   shared databases.
public struct APICredentials: Sendable {
  public let apiToken: String
  public let webAuthToken: String?

  public init(apiToken: String, webAuthToken: String? = nil) {
    self.apiToken = apiToken
    self.webAuthToken = webAuthToken
  }
}

/// CloudKit credentials for a `CloudKitService`.
///
/// Holds either set of authentication material — server-to-server (public
/// database only) and/or API/web-auth (any database). At call time
/// `CloudKitService` picks the appropriate token manager based on the
/// operation's database and whether user-context auth is required.
///
/// Provide both when a single service must hit public-database routes via
/// server-to-server signing **and** user-context routes via web-auth.
public struct Credentials: Sendable {
  public let serverToServer: ServerToServerCredentials?
  public let apiAuth: APICredentials?

  /// Construct credentials.
  ///
  /// - Precondition: at least one of `serverToServer` or `apiAuth` must be
  ///   non-nil. A `Credentials` with neither populated would fail every
  ///   request with a missing-credentials error.
  public init(
    serverToServer: ServerToServerCredentials? = nil,
    apiAuth: APICredentials? = nil
  ) {
    precondition(
      serverToServer != nil || apiAuth != nil,
      "Credentials must include at least one of serverToServer or apiAuth"
    )
    self.serverToServer = serverToServer
    self.apiAuth = apiAuth
  }
}
