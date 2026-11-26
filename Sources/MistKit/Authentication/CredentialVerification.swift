//
//  CredentialVerification.swift
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

/// The result of ``CloudKitService/verifyCredentials()``: one
/// ``CredentialStatus`` per ``CredentialKind``.
///
/// Kinds the service has no credential for are
/// ``CredentialStatus/notConfigured``. Holds no credential material, so it's
/// safe to log or show.
public struct CredentialVerification: Sendable {
  /// The API token plus web-auth token, checked with `users/caller`.
  public let webAuth: CredentialStatus

  /// The server-to-server key, checked with the public database's
  /// `zones/list`.
  public let serverToServer: CredentialStatus

  /// The API token when there's no web-auth token, checked with
  /// `users/caller` signed with the API token alone.
  ///
  /// ``CredentialStatus/notConfigured`` when a web-auth token is configured:
  /// ``webAuth`` checks the API token then.
  public let apiTokenOnly: CredentialStatus

  /// The kinds the service has a credential for, in ``CredentialKind``
  /// declaration order.
  public var configuredKinds: [CredentialKind] {
    CredentialKind.allCases.filter { self[$0].isConfigured }
  }

  /// Whether at least one credential is configured and CloudKit accepted
  /// every configured credential.
  public var allAccepted: Bool {
    let kinds = configuredKinds
    return !kinds.isEmpty && kinds.allSatisfy { self[$0].isAccepted }
  }

  /// Creates a verification result.
  public init(
    webAuth: CredentialStatus = .notConfigured,
    serverToServer: CredentialStatus = .notConfigured,
    apiTokenOnly: CredentialStatus = .notConfigured
  ) {
    self.webAuth = webAuth
    self.serverToServer = serverToServer
    self.apiTokenOnly = apiTokenOnly
  }

  /// The status for `kind`.
  public subscript(kind: CredentialKind) -> CredentialStatus {
    switch kind {
    case .webAuth:
      webAuth
    case .serverToServer:
      serverToServer
    case .apiTokenOnly:
      apiTokenOnly
    }
  }
}
