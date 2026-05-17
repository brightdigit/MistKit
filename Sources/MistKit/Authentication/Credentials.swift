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
  /// Server-to-server signing credentials; valid only against the public database.
  public let serverToServer: ServerToServerCredentials?
  /// API-token credentials; required for private/shared databases and user-context routes.
  public let apiAuth: APICredentials?

  /// Construct credentials.
  ///
  /// At least one of `serverToServer` or `apiAuth` must be non-nil. In debug
  /// builds an empty `Credentials` triggers an `assert` so the misconfiguration
  /// surfaces during development; in release builds the same misconfiguration
  /// throws `CredentialsValidationError.empty` so callers loading credentials
  /// from dynamic config (env vars, JSON, keychain) get a typed, recoverable
  /// error instead of a crash.
  public init(
    serverToServer: ServerToServerCredentials? = nil,
    apiAuth: APICredentials? = nil
  ) throws(CredentialsValidationError) {
    assert(
      serverToServer != nil || apiAuth != nil,
      "Credentials must include at least one of serverToServer or apiAuth"
    )
    guard serverToServer != nil || apiAuth != nil else {
      throw .empty
    }
    self.serverToServer = serverToServer
    self.apiAuth = apiAuth
  }
}
