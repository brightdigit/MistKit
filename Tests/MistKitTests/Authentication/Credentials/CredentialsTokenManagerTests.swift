//
//  CredentialsTokenManagerTests.swift
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

import Crypto
import Foundation
import Testing

@testable import MistKit

/// Direct unit coverage for `Credentials.makeTokenManager(for:requiresUserContext:)`.
///
/// Each `CloudKitService` operation calls this resolver to pick a token
/// manager based on the target database and whether the route requires
/// user-context auth. The test cases below cover every cell of the routing
/// matrix: the four combinations on `.public` plus the two error cases on
/// `.private`/`.shared`, and the user-context branch.
@Suite("Credentials.makeTokenManager", .enabled(if: Platform.isCryptoAvailable))
internal struct CredentialsTokenManagerTests {
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  private static func makeServerToServerCredentials() -> ServerToServerCredentials {
    let pem = P256.Signing.PrivateKey().pemRepresentation
    return ServerToServerCredentials(
      keyID: "test-key-id-12345678",
      privateKey: .raw(pem)
    )
  }

  private static func makeAPICredentialsWithWebAuth() -> APICredentials {
    APICredentials(
      apiToken: TestConstants.apiToken,
      webAuthToken: TestConstants.webAuthToken
    )
  }

  private static func makeAPICredentialsTokenOnly() -> APICredentials {
    APICredentials(apiToken: TestConstants.apiToken)
  }

  // MARK: - .public

  @Test(".public + serverToServer → ServerToServerAuthManager")
  internal func publicPicksServerToServer() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("ServerToServerAuthManager is not available on this operating system.")
      return
    }
    let credentials = try Credentials(
      serverToServer: Self.makeServerToServerCredentials()
    )
    let manager = try credentials.makeTokenManager(for: .public)
    #expect(manager is ServerToServerAuthManager)
  }

  @Test(".public + apiAuth.webAuthToken → WebAuthTokenManager")
  internal func publicPicksWebAuthOverAPIToken() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(apiAuth: Self.makeAPICredentialsWithWebAuth())
    let manager = try credentials.makeTokenManager(for: .public)
    #expect(manager is WebAuthTokenManager)
  }

  @Test(".public + apiAuth (token only) → APITokenManager")
  internal func publicPicksAPITokenWhenNoWebAuth() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(apiAuth: Self.makeAPICredentialsTokenOnly())
    let manager = try credentials.makeTokenManager(for: .public)
    #expect(manager is APITokenManager)
  }

  @Test(".public + serverToServer prefers S2S over apiAuth")
  internal func publicPrefersServerToServerOverAPIAuth() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(
      serverToServer: Self.makeServerToServerCredentials(),
      apiAuth: Self.makeAPICredentialsWithWebAuth()
    )
    let manager = try credentials.makeTokenManager(for: .public)
    #expect(manager is ServerToServerAuthManager)
  }

  // MARK: - .private / .shared

  @Test(".private + apiAuth.webAuthToken → WebAuthTokenManager")
  internal func privatePicksWebAuth() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(apiAuth: Self.makeAPICredentialsWithWebAuth())
    let manager = try credentials.makeTokenManager(for: .private)
    #expect(manager is WebAuthTokenManager)
  }

  @Test(".shared + apiAuth.webAuthToken → WebAuthTokenManager")
  internal func sharedPicksWebAuth() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(apiAuth: Self.makeAPICredentialsWithWebAuth())
    let manager = try credentials.makeTokenManager(for: .shared)
    #expect(manager is WebAuthTokenManager)
  }

  @Test(".private + serverToServer only → throws missingCredentials")
  internal func privateRejectsServerToServerOnly() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(
      serverToServer: Self.makeServerToServerCredentials()
    )
    #expect(throws: CloudKitError.self) {
      _ = try credentials.makeTokenManager(for: .private)
    }
  }

  @Test(".shared + serverToServer only → throws missingCredentials")
  internal func sharedRejectsServerToServerOnly() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(
      serverToServer: Self.makeServerToServerCredentials()
    )
    #expect(throws: CloudKitError.self) {
      _ = try credentials.makeTokenManager(for: .shared)
    }
  }

  @Test(".private + apiAuth without webAuthToken → throws missingCredentials")
  internal func privateRejectsAPITokenOnly() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(apiAuth: Self.makeAPICredentialsTokenOnly())
    #expect(throws: CloudKitError.self) {
      _ = try credentials.makeTokenManager(for: .private)
    }
  }

  // MARK: - User-context branch

  @Test("requiresUserContext on .public → WebAuthTokenManager")
  internal func userContextOnPublicPicksWebAuth() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(
      serverToServer: Self.makeServerToServerCredentials(),
      apiAuth: Self.makeAPICredentialsWithWebAuth()
    )
    let manager = try credentials.makeTokenManager(
      for: .public, requiresUserContext: true
    )
    // S2S is present, but user-context routes ignore it — must pick web-auth.
    #expect(manager is WebAuthTokenManager)
  }

  @Test("requiresUserContext without web-auth → throws missingCredentials")
  internal func userContextWithoutWebAuthThrows() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(
      serverToServer: Self.makeServerToServerCredentials()
    )
    #expect(throws: CloudKitError.self) {
      _ = try credentials.makeTokenManager(
        for: .public, requiresUserContext: true
      )
    }
  }

  @Test("requiresUserContext with apiAuth (token only) → throws missingCredentials")
  internal func userContextWithAPITokenOnlyThrows() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else { return }
    let credentials = try Credentials(apiAuth: Self.makeAPICredentialsTokenOnly())
    #expect(throws: CloudKitError.self) {
      _ = try credentials.makeTokenManager(
        for: .public, requiresUserContext: true
      )
    }
  }
}
