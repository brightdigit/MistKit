//
//  CloudKitService+VerifyCredentials.swift
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

extension CloudKitService {
  /// Check each credential this service holds against CloudKit, for a
  /// "Test Connection".
  ///
  /// Sends one request per configured ``CredentialKind``, concurrently:
  ///
  /// | Kind | Request | Accepted on |
  /// |---|---|---|
  /// | ``CredentialKind/webAuth`` | `users/caller` (``fetchCaller()``) | success |
  /// | ``CredentialKind/serverToServer`` | public `zones/list`, key-signed | success |
  /// | ``CredentialKind/apiTokenOnly`` | `users/caller`, API token | `AUTHENTICATION_REQUIRED` |
  ///
  /// A failing credential is reported as ``CredentialStatus/rejected(_:)``,
  /// never thrown, so one bad credential doesn't hide the others' results.
  /// A service built with a fixed `TokenManager` has no `Credentials`, so every
  /// kind is ``CredentialStatus/notConfigured``.
  ///
  /// - Returns: One status per kind; the result holds no credential material.
  /// - Throws: `CancellationError` when the task is cancelled, since requests
  ///   cut short by cancellation say nothing about the credentials.
  public func verifyCredentials() async throws(CancellationError)
    -> CredentialVerification
  {
    async let webAuth = verifyWebAuth()
    async let serverToServer = verifyServerToServer()
    async let apiTokenOnly = verifyAPITokenOnly()
    let verification = await CredentialVerification(
      webAuth: webAuth,
      serverToServer: serverToServer,
      apiTokenOnly: apiTokenOnly
    )
    if Task.isCancelled {
      throw CancellationError()
    }
    return verification
  }

  private func verifyWebAuth() async -> CredentialStatus {
    guard credentials?.apiAuth?.webAuthToken != nil else {
      return .notConfigured
    }
    do {
      _ = try await fetchCaller()
      return .accepted
    } catch {
      return .rejected(error)
    }
  }

  private func verifyServerToServer() async -> CredentialStatus {
    guard credentials?.serverToServer != nil else {
      return .notConfigured
    }
    do {
      _ = try await listZones(database: .public(.requires(.serverToServer)))
      return .accepted
    } catch {
      return .rejected(error)
    }
  }

  private func verifyAPITokenOnly() async -> CredentialStatus {
    guard let apiAuth = credentials?.apiAuth, apiAuth.webAuthToken == nil else {
      return .notConfigured
    }
    do {
      try await fetchCallerSignedWithAPIToken(
        apiAuth.apiToken,
        context: "verifyCredentials"
      )
      return .accepted
    } catch {
      if case .authenticationRequired = error {
        return .accepted
      }
      return .rejected(error)
    }
  }
}
